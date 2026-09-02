package io.radar.flutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertSame;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.SharedPreferences;

import java.util.HashMap;
import java.util.Map;

import org.junit.Before;
import org.junit.Test;

public class RadarFlutterBackgroundEventSinkTest {

    private SharedPreferences preferences;
    private RecordingDispatcher dispatcher;
    private RadarFlutterBackgroundEventSink sink;
    private Map<String, Object> payload;

    @Before
    public void setUp() {
        preferences = mock(SharedPreferences.class);
        dispatcher = new RecordingDispatcher();

        RadarFlutterBackgroundHandlerStore store =
            new RadarFlutterBackgroundHandlerStore(preferences);

        sink = new RadarFlutterBackgroundEventSink(store, dispatcher);

        payload = new HashMap<>();
        payload.put("location", "test-location");
    }

    @Test
    public void dispatchesRegisteredBackgroundEvent() {
        stubRegistration(123L, 456L);

        sink.send("location", payload);

        assertEquals(1, dispatcher.dispatchCount);
        assertEquals(123L, dispatcher.dispatcherHandle);
        assertEquals("location", dispatcher.method);
        assertEquals(2, dispatcher.arguments.size());
        assertEquals(456L, dispatcher.arguments.get("callbackHandle"));
        assertSame(payload, dispatcher.arguments.get("payload"));
    }

    @Test
    public void dropsEventWhenNoHandlerIsRegistered() {
        sink.send("location", payload);

        assertEquals(0, dispatcher.dispatchCount);
    }

    @Test
    public void loadsCurrentRegistrationForEveryEvent() {
        stubRegistration(123L, 456L);

        sink.send("location", payload);
        sink.send("location", payload);

        verify(preferences, times(2)).getLong("dispatcher_handle", 0L);
        verify(preferences, times(2)).getLong("callback_handle", 0L);
        assertEquals(2, dispatcher.dispatchCount);
    }

    private void stubRegistration(
        long dispatcherHandle,
        long callbackHandle
    ) {
        when(preferences.contains("dispatcher_handle")).thenReturn(true);
        when(preferences.contains("callback_handle")).thenReturn(true);
        when(
            preferences.getLong("dispatcher_handle", 0L)
        ).thenReturn(dispatcherHandle);
        when(
            preferences.getLong("callback_handle", 0L)
        ).thenReturn(callbackHandle);
    }

    private static final class RecordingDispatcher
        implements RadarFlutterBackgroundEventSink.Dispatcher {

        private int dispatchCount;
        private long dispatcherHandle;
        private String method;
        private Map<String, Object> arguments;

        @Override
        public void dispatch(
            long dispatcherHandle,
            String method,
            Map<String, Object> arguments
        ) {
            dispatchCount++;
            this.dispatcherHandle = dispatcherHandle;
            this.method = method;
            this.arguments = arguments;
        }
    }
}
