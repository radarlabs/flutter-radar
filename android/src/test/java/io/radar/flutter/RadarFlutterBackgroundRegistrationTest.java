package io.radar.flutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.SharedPreferences;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import org.junit.Before;
import org.junit.Test;

public class RadarFlutterBackgroundRegistrationTest {
    private SharedPreferences preferences;
    private SharedPreferences.Editor editor;
    private MethodChannel.Result result;
    private RadarFlutterPlugin.RadarMethodCallHandler handler;
    private RadarFlutterEventRouter router;
    private RadarFlutterEventRouter.EventSink primaryDurableSink;
    private RadarFlutterEventRouter.EventSink backgroundSink;

    @Before
    public void setUp() {
        preferences = mock(SharedPreferences.class);
        editor = mock(SharedPreferences.Editor.class);
        result = mock(MethodChannel.Result.class);

        router = new RadarFlutterEventRouter();
        primaryDurableSink = mock(RadarFlutterEventRouter.EventSink.class);
        backgroundSink = mock(RadarFlutterEventRouter.EventSink.class);
        router.setBackgroundSink(backgroundSink);

        when(preferences.edit()).thenReturn(editor);
        when(editor.putLong(anyString(), anyLong())).thenReturn(editor);
        when(editor.remove(anyString())).thenReturn(editor);

        RadarFlutterBackgroundHandlerStore store =
            new RadarFlutterBackgroundHandlerStore(preferences);

        handler = new RadarFlutterPlugin.RadarMethodCallHandler(
            (method, payload) -> {},
            primaryDurableSink,
            store,
            router
        );
    }

    @Test
    public void registersBackgroundHandler() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("dispatcherHandle", 123);
        arguments.put("callbackHandle", 456L);

        handler.onMethodCall(
            new MethodCall("registerBackgroundHandler", arguments),
            result
        );

        verify(editor).putLong("dispatcher_handle", 123L);
        verify(editor).putLong("callback_handle", 456L);
        verify(editor).apply();
        verify(result).success(null);
    }

    @Test
    public void registrationMarksPrimaryDurableSinkReady() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("dispatcherHandle", 123L);
        arguments.put("callbackHandle", 456L);

        handler.onMethodCall(
            new MethodCall("registerBackgroundHandler", arguments),
            result
        );

        Map<String, Object> payload = new HashMap<>();
        payload.put("location", "test-location");
        router.route("location", payload);

        verify(primaryDurableSink).send("location", payload);
        verify(backgroundSink, never()).send(anyString(), any());
    }

    @Test
    public void rejectsMissingDispatcherHandle() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("callbackHandle", 456L);

        handler.onMethodCall(
            new MethodCall("registerBackgroundHandler", arguments),
            result
        );

        verifyInvalidRegistration();
    }

    @Test
    public void rejectsMissingCallbackHandle() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("dispatcherHandle", 123L);

        handler.onMethodCall(
            new MethodCall("registerBackgroundHandler", arguments),
            result
        );

        verifyInvalidRegistration();
    }

    @Test
    public void rejectsNonNumericHandles() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("dispatcherHandle", "123");
        arguments.put("callbackHandle", 456L);

        handler.onMethodCall(
            new MethodCall("registerBackgroundHandler", arguments),
            result
        );

        verifyInvalidRegistration();
    }

    @Test
    public void unregistersBackgroundHandler() {
        handler.onMethodCall(
            new MethodCall("unregisterBackgroundHandler", null),
            result
        );

        verify(editor).remove("dispatcher_handle");
        verify(editor).remove("callback_handle");
        verify(editor).apply();
        verify(result).success(null);
    }

    private void verifyInvalidRegistration() {
        verify(result).error(
            "invalid_background_handler",
            "dispatcherHandle and callbackHandle must be integers.",
            null
        );
        verify(preferences, never()).edit();
    }

    @Test
    public void unregistrationDetachesPrimaryDurableSink() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("dispatcherHandle", 123L);
        arguments.put("callbackHandle", 456L);

        handler.onMethodCall(
            new MethodCall("registerBackgroundHandler", arguments),
            result
        );

        handler.onMethodCall(
            new MethodCall("unregisterBackgroundHandler", null),
            result
        );

        Map<String, Object> payload = new HashMap<>();
        payload.put("location", "test-location");
        router.route("location", payload);

        verify(primaryDurableSink, never()).send(anyString(), any());
        verify(backgroundSink).send("location", payload);
    }

    @Test
    public void unregistrationClearsPendingDurableEvents() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("dispatcherHandle", 123L);
        arguments.put("callbackHandle", 456L);

        handler.onMethodCall(
            new MethodCall("registerBackgroundHandler", arguments),
            result
        );

        handler.onMethodCall(
            new MethodCall("unregisterBackgroundHandler", null),
            result
        );

        verify(primaryDurableSink).clearPendingEvents();
        verify(backgroundSink).clearPendingEvents();
    }
}
