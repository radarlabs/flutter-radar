package io.radar.flutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertSame;

import java.util.HashMap;
import java.util.Map;

import org.junit.Before;
import org.junit.Test;

public class RadarFlutterEventRouterTest {
    private RadarFlutterEventRouter router;
    private RecordingSink primarySink;
    private RecordingSink backgroundSink;
    private Map<String, Object> payload;

    @Before
    public void setUp() {
        router = new RadarFlutterEventRouter();
        primarySink = new RecordingSink();
        backgroundSink = new RecordingSink();

        payload = new HashMap<>();
        payload.put("sharing", true);
    }

    @Test
    public void routesToPrimarySink() {
        router.setPrimarySink(primarySink);

        router.route("sharingChanged", payload);

        assertDelivery(primarySink);
    }

    @Test
    public void routesToBackgroundSinkWhenPrimaryIsMissing() {
        router.setBackgroundSink(backgroundSink);

        router.route("sharingChanged", payload);

        assertDelivery(backgroundSink);
    }

    @Test
    public void prefersPrimarySinkOverBackgroundSink() {
        router.setPrimarySink(primarySink);
        router.setBackgroundSink(backgroundSink);

        router.route("sharingChanged", payload);

        assertDelivery(primarySink);
        assertEquals(0, backgroundSink.deliveryCount);
    }

    @Test
    public void fallsBackToBackgroundAfterPrimaryIsCleared() {
        router.setPrimarySink(primarySink);
        router.setBackgroundSink(backgroundSink);

        router.clearPrimarySink(primarySink);
        router.route("sharingChanged", payload);

        assertEquals(0, primarySink.deliveryCount);
        assertDelivery(backgroundSink);
    }

    @Test
    public void stalePrimaryDetachDoesNotClearReplacementSink() {
        RecordingSink replacementSink = new RecordingSink();

        router.setPrimarySink(primarySink);
        router.setPrimarySink(replacementSink);

        router.clearPrimarySink(primarySink);
        router.route("sharingChanged", payload);

        assertEquals(0, primarySink.deliveryCount);
        assertDelivery(replacementSink);
    }

    @Test
    public void staleBackgroundDetachDoesNotClearReplacementSink() {
        RecordingSink replacementSink = new RecordingSink();

        router.setBackgroundSink(backgroundSink);
        router.setBackgroundSink(replacementSink);

        router.clearBackgroundSink(backgroundSink);
        router.route("sharingChanged", payload);

        assertEquals(0, backgroundSink.deliveryCount);
        assertDelivery(replacementSink);
    }

    @Test
    public void safelyDropsEventWhenNoSinkExists() {
        router.route("sharingChanged", payload);
    }

    private void assertDelivery(RecordingSink sink) {
        assertEquals(1, sink.deliveryCount);
        assertEquals("sharingChanged", sink.method);
        assertSame(payload, sink.payload);
    }

    private static final class RecordingSink
        implements RadarFlutterEventRouter.EventSink {

        private int deliveryCount;
        private String method;
        private Map<String, Object> payload;

        @Override
        public void send(String method, Map<String, Object> payload) {
            deliveryCount++;
            this.method = method;
            this.payload = payload;
        }
    }
}
