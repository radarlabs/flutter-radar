package io.radar.flutter;

import java.util.Map;

final class RadarFlutterEventRouter {

    interface EventSink {
        void send(String method, Map<String, Object> payload);

        default void clearPendingEvents() {}
    }

    private final Object lock = new Object();

    private EventSink observerSink;
    private EventSink primarySink;
    private EventSink backgroundSink;

    void setObserverSink(EventSink sink) {
        synchronized (lock) {
            observerSink = sink;
        }
    }

    void clearObserverSink(EventSink sink) {
        synchronized (lock) {
            if (observerSink == sink) {
                observerSink = null;
            }
        }
    }

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

    void clearPendingEvents() {
        final EventSink primary;
        final EventSink background;

        synchronized (lock) {
            primary = primarySink;
            background = backgroundSink;
        }

        if (primary != null) {
            primary.clearPendingEvents();
        }

        if (background != null && background != primary) {
            background.clearPendingEvents();
        }
    }

    void route(String method, Map<String, Object> payload) {
        final EventSink observer;
        final EventSink durableSink;

        synchronized (lock) {
            observer = observerSink;
            durableSink = primarySink != null ? primarySink : backgroundSink;
        }

        if (observer != null) {
            observer.send(method, payload);
        }

        if (durableSink != null) {
            durableSink.send(method, payload);
        }
    }
}