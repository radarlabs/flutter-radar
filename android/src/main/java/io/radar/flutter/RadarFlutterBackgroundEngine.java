package io.radar.flutter;

import java.util.ArrayDeque;
import java.util.Map;
import java.util.Queue;
import java.util.concurrent.Executor;

final class RadarFlutterBackgroundEngine
    implements RadarFlutterBackgroundEventSink.Dispatcher {

    interface Engine {
        void start(long dispatcherHandle, Runnable onInitialized);

        void invokeMethod(
            String method,
            Map<String, Object> arguments,
            Runnable completion
        );

        void destroy();
    }

    interface EngineFactory {
        Engine create();
    }

    interface ErrorHandler {
        void report(String message, Exception error);
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
    private final EngineFactory engineFactory;
    private final ErrorHandler errorHandler;
    private final Queue<PendingEvent> pendingEvents = new ArrayDeque<>();

    private Engine engine;
    private Long activeDispatcherHandle;
    private boolean ready;
    private boolean invocationInFlight;
    private long generation;

    RadarFlutterBackgroundEngine(
        Executor mainThreadExecutor,
        EngineFactory engineFactory,
        ErrorHandler errorHandler
    ) {
        this.mainThreadExecutor = mainThreadExecutor;
        this.engineFactory = engineFactory;
        this.errorHandler = errorHandler;
    }

    @Override
    public void dispatch(
        long dispatcherHandle,
        String method,
        Map<String, Object> arguments
    ) {
        mainThreadExecutor.execute(
            () -> enqueue(dispatcherHandle, method, arguments)
        );
    }

    void stop() {
        mainThreadExecutor.execute(() -> resetEngine(true));
    }

    private void enqueue(
        long dispatcherHandle,
        String method,
        Map<String, Object> arguments
    ) {
        if (
            activeDispatcherHandle != null &&
            activeDispatcherHandle.longValue() != dispatcherHandle
        ) {
            resetEngine(true);
        }

        pendingEvents.add(new PendingEvent(method, arguments));

        if (engine == null) {
            startEngine(dispatcherHandle);
        }

        drain();
    }

    private void startEngine(long dispatcherHandle) {
        activeDispatcherHandle = dispatcherHandle;
        ready = false;

        long engineGeneration = ++generation;

        try {
            engine = engineFactory.create();
            engine.start(
                dispatcherHandle,
                () -> mainThreadExecutor.execute(
                    () -> markReady(engineGeneration)
                )
            );
        } catch (Exception error) {
            errorHandler.report(
                "Could not start the Radar background Flutter engine.",
                error
            );
            resetEngine(true);
        }
    }

    private void markReady(long engineGeneration) {
        if (engineGeneration != generation || engine == null) {
            return;
        }

        ready = true;
        drain();
    }

    private void drain() {
        if (
            !ready ||
            invocationInFlight ||
            engine == null ||
            pendingEvents.isEmpty()
        ) {
            return;
        }

        PendingEvent event = pendingEvents.remove();
        long engineGeneration = generation;
        invocationInFlight = true;

        try {
            engine.invokeMethod(
                event.method,
                event.arguments,
                () -> mainThreadExecutor.execute(
                    () -> completeInvocation(engineGeneration)
                )
            );
        } catch (Exception error) {
            invocationInFlight = false;
            errorHandler.report(
                "Could not deliver a Radar background event.",
                error
            );
            drain();
        }
    }

    private void completeInvocation(long engineGeneration) {
        if (engineGeneration != generation) {
            return;
        }

        invocationInFlight = false;
        drain();
    }

    private void resetEngine(boolean clearPendingEvents) {
        generation++;
        ready = false;
        invocationInFlight = false;
        activeDispatcherHandle = null;

        Engine engineToDestroy = engine;
        engine = null;

        if (clearPendingEvents) {
            pendingEvents.clear();
        }

        if (engineToDestroy != null) {
            try {
                engineToDestroy.destroy();
            } catch (Exception error) {
                errorHandler.report(
                    "Could not destroy the Radar background Flutter engine.",
                    error
                );
            }
        }
    }

    @Override
    public void clearPendingEvents() {
        stop();
    }
}
