package io.radar.flutter;

import java.util.Map;

final class RadarFlutterEventRouter {

    interface EventSink {
        void send(String method, Map<String, Object> payload);
    }

    private final Object lock = new Object();

    private EventSink primarySink;
    private EventSink backgroundSink;

    void setPrimarySink(EventSink sink) {
        synchronized (lock) {
            primarySink = sink;
        }
    }

    void clearPrimarySink(EventSink sink) {
        synchronized (lock) {
            if (primarySink == sink) {
                primarySink = null;
            }
        }
    }

    void setBackgroundSink(EventSink sink) {
        synchronized (lock) {
            backgroundSink = sink;
        }
    }

    void clearBackgroundSink(EventSink sink) {
        synchronized (lock) {
            if (backgroundSink == sink) {
                backgroundSink = null;
            }
        }
    }

    void route(String method, Map<String, Object> payload) {
        final EventSink sink;

        synchronized (lock) {
            sink = primarySink != null ? primarySink : backgroundSink;
        }

        if (sink != null) {
            sink.send(method, payload);
        }
    }
}