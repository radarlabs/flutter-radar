package io.radar.flutter;

import android.content.Context;
import android.content.SharedPreferences;

final class RadarFlutterBackgroundHandlerStore {
    private static final String PREFERENCES_NAME =
        "flutter_radar_background";
    private static final String DISPATCHER_HANDLE_KEY =
        "dispatcher_handle";
    private static final String CALLBACK_HANDLE_KEY =
        "callback_handle";

    static final class Handles {
        final long dispatcherHandle;
        final long callbackHandle;

        Handles(long dispatcherHandle, long callbackHandle) {
            this.dispatcherHandle = dispatcherHandle;
            this.callbackHandle = callbackHandle;
        }
    }

    private final SharedPreferences preferences;

    static RadarFlutterBackgroundHandlerStore fromContext(Context context) {
        SharedPreferences preferences = context
            .getApplicationContext()
            .getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE);

        return new RadarFlutterBackgroundHandlerStore(preferences);
    }

    RadarFlutterBackgroundHandlerStore(SharedPreferences preferences) {
        this.preferences = preferences;
    }

    void save(long dispatcherHandle, long callbackHandle) {
        preferences
            .edit()
            .putLong(DISPATCHER_HANDLE_KEY, dispatcherHandle)
            .putLong(CALLBACK_HANDLE_KEY, callbackHandle)
            .apply();
    }

    Handles load() {
        if (
            !preferences.contains(DISPATCHER_HANDLE_KEY) ||
            !preferences.contains(CALLBACK_HANDLE_KEY)
        ) {
            return null;
        }

        return new Handles(
            preferences.getLong(DISPATCHER_HANDLE_KEY, 0L),
            preferences.getLong(CALLBACK_HANDLE_KEY, 0L)
        );
    }

    void clear() {
        preferences
            .edit()
            .remove(DISPATCHER_HANDLE_KEY)
            .remove(CALLBACK_HANDLE_KEY)
            .apply();
    }
}