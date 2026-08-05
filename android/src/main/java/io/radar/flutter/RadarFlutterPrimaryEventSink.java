package io.radar.flutter;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.Executor;

final class RadarFlutterPrimaryEventSink
    implements RadarFlutterEventRouter.EventSink {

    interface MethodInvoker {
        void invokeMethod(String method, Object arguments);
    }

    private final MethodInvoker methodInvoker;
    private final Executor mainThreadExecutor;

    RadarFlutterPrimaryEventSink(
        MethodInvoker methodInvoker,
        Executor mainThreadExecutor
    ) {
        this.methodInvoker = methodInvoker;
        this.mainThreadExecutor = mainThreadExecutor;
    }

    @Override
    public void send(String method, Map<String, Object> payload) {
        final ArrayList<Object> arguments = new ArrayList<>(2);
        arguments.add(0);
        arguments.add(payload);

        mainThreadExecutor.execute(
            () -> methodInvoker.invokeMethod(method, arguments)
        );
    }
}
