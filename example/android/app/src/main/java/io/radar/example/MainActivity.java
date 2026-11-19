package io.radar.example;

import android.content.SharedPreferences;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        registerE2EChannel(flutterEngine);
    }

    // Test-only hook for example/integration_test. The Radar SDK has no public
    // host setter; it reads these SharedPreferences keys on every request, so
    // writing them before Radar.initialize points the SDK at another API host.
    // A null value removes the key so the SDK falls back to production.
    private void registerE2EChannel(FlutterEngine flutterEngine) {
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "io.radar.example/e2e")
                .setMethodCallHandler((call, result) -> {
                    if (!call.method.equals("setHosts")) {
                        result.notImplemented();
                        return;
                    }
                    SharedPreferences.Editor editor =
                            getSharedPreferences("RadarSDK", MODE_PRIVATE).edit();
                    putOrRemove(editor, "host", call.argument("host"));
                    putOrRemove(editor, "verified_host", call.argument("verifiedHost"));
                    editor.commit();
                    result.success(null);
                });
    }

    private static void putOrRemove(SharedPreferences.Editor editor, String key, String value) {
        if (value == null || value.isEmpty()) {
            editor.remove(key);
        } else {
            editor.putString(key, value);
        }
    }
}
