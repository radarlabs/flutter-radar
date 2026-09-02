package io.radar.flutter;

import java.util.HashMap;
import java.util.Map;

final class RadarFlutterBackgroundEventSink
    implements RadarFlutterEventRouter.EventSink {

    interface Dispatcher {
        void dispatch(
            long dispatcherHandle,
            String method,
            Map<String, Object> arguments
        );

        default void clearPendingEvents() {}
    }

    private final RadarFlutterBackgroundHandlerStore store;
    private final Dispatcher dispatcher;

    RadarFlutterBackgroundEventSink(
        RadarFlutterBackgroundHandlerStore store,
        Dispatcher dispatcher
    ) {
        this.store = store;
        this.dispatcher = dispatcher;
    }

    @Override
    public void send(String method, Map<String, Object> payload) {
        RadarFlutterBackgroundHandlerStore.Handles handles = store.load();

        if (handles == null) {
            return;
        }

        Map<String, Object> arguments = new HashMap<>();
        arguments.put("callbackHandle", handles.callbackHandle);
        arguments.put("payload", payload);

        dispatcher.dispatch(
            handles.dispatcherHandle,
            method,
            arguments
        );
    }

    @Override
    public void clearPendingEvents() {
        dispatcher.clearPendingEvents();
    }
}
