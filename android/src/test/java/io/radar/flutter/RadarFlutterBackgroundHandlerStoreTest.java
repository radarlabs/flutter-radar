package io.radar.flutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.SharedPreferences;

import org.junit.Before;
import org.junit.Test;

public class RadarFlutterBackgroundHandlerStoreTest {
    private static final String DISPATCHER_HANDLE_KEY =
        "dispatcher_handle";
    private static final String CALLBACK_HANDLE_KEY =
        "callback_handle";

    private SharedPreferences preferences;
    private SharedPreferences.Editor editor;
    private RadarFlutterBackgroundHandlerStore store;

    @Before
    public void setUp() {
        preferences = mock(SharedPreferences.class);
        editor = mock(SharedPreferences.Editor.class);

        when(preferences.edit()).thenReturn(editor);
        when(editor.putLong(anyString(), anyLong())).thenReturn(editor);
        when(editor.remove(anyString())).thenReturn(editor);

        store = new RadarFlutterBackgroundHandlerStore(preferences);
    }

    @Test
    public void savesBothHandlesTogether() {
        store.save(123L, 456L);

        verify(editor).putLong(DISPATCHER_HANDLE_KEY, 123L);
        verify(editor).putLong(CALLBACK_HANDLE_KEY, 456L);
        verify(editor).apply();
    }

    @Test
    public void loadsBothHandles() {
        when(preferences.contains(DISPATCHER_HANDLE_KEY)).thenReturn(true);
        when(preferences.contains(CALLBACK_HANDLE_KEY)).thenReturn(true);
        when(
            preferences.getLong(DISPATCHER_HANDLE_KEY, 0L)
        ).thenReturn(123L);
        when(
            preferences.getLong(CALLBACK_HANDLE_KEY, 0L)
        ).thenReturn(456L);

        RadarFlutterBackgroundHandlerStore.Handles handles = store.load();

        assertNotNull(handles);
        assertEquals(123L, handles.dispatcherHandle);
        assertEquals(456L, handles.callbackHandle);
    }

    @Test
    public void returnsNullWhenDispatcherHandleIsMissing() {
        when(preferences.contains(DISPATCHER_HANDLE_KEY)).thenReturn(false);

        assertNull(store.load());
    }

    @Test
    public void returnsNullWhenCallbackHandleIsMissing() {
        when(preferences.contains(DISPATCHER_HANDLE_KEY)).thenReturn(true);
        when(preferences.contains(CALLBACK_HANDLE_KEY)).thenReturn(false);

        assertNull(store.load());
    }

    @Test
    public void clearsBothHandlesTogether() {
        store.clear();

        verify(editor).remove(DISPATCHER_HANDLE_KEY);
        verify(editor).remove(CALLBACK_HANDLE_KEY);
        verify(editor).apply();
    }
}
