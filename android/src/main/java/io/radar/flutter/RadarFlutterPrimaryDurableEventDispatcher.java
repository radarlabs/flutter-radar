package io.radar.flutter;

import java.util.ArrayDeque;
import java.util.Map;
import java.util.Queue;
import java.util.concurrent.Executor;

final class RadarFlutterPrimaryDurableEventDispatcher
    implements RadarFlutterBackgroundEventSink.Dispatcher {

    interface MethodInvoker {
        void invokeMethod(
            String method,
            Map<String, Object> arguments,
            Runnable completion
        );
    }

    private static final class PendingEvent {
        final String method;
        final Map<String, Object> arguments;

        PendingEvent(String method, Map<String, Object> arguments) {
            this.method = method;
            this.arguments = arguments;
        }
    }

    private final Executor mainThreadExecutor;
    private final MethodInvoker methodInvoker;
    private final Queue<PendingEvent> pendingEvents = new ArrayDeque<>();

    private boolean invocationInFlight;

    RadarFlutterPrimaryDurableEventDispatcher(
        Executor mainThreadExecutor,
        MethodInvoker methodInvoker
    ) {
        this.mainThreadExecutor = mainThreadExecutor;
        this.methodInvoker = methodInvoker;
    }

    @Override
    public void dispatch(
        long dispatcherHandle,
        String method,
        Map<String, Object> arguments
    ) {
        mainThreadExecutor.execute(
            () -> {
                pendingEvents.add(new PendingEvent(method, arguments));
                drain();
            }
        );
    }

    @Override
    public void clearPendingEvents() {
        mainThreadExecutor.execute(pendingEvents::clear);
    }

    private void drain() {
        if (invocationInFlight || pendingEvents.isEmpty()) {
            return;
        }

        PendingEvent event = pendingEvents.remove();
        invocationInFlight = true;

        methodInvoker.invokeMethod(
            event.method,
            event.arguments,
            () -> mainThreadExecutor.execute(this::completeInvocation)
        );
    }

    private void completeInvocation() {
        invocationInFlight = false;
        drain();
    }
}