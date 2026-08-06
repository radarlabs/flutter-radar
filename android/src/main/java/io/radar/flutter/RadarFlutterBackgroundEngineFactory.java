package io.radar.flutter;

import android.content.Context;
import android.util.Log;

import java.util.Map;

import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterCallbackInformation;

final class RadarFlutterBackgroundEngineFactory
    implements RadarFlutterBackgroundEngine.EngineFactory {

    private static final String TAG = "RadarFlutterPlugin";
    private static final String CHANNEL_NAME =
        "flutter_radar_background";

    private final Context applicationContext;

    RadarFlutterBackgroundEngineFactory(Context context) {
        applicationContext = context.getApplicationContext();
    }

    @Override
    public RadarFlutterBackgroundEngine.Engine create() {
        FlutterEngine flutterEngine =
            new FlutterEngine(applicationContext);

        return new EngineInstance(applicationContext, flutterEngine);
    }

    private static final class EngineInstance
        implements RadarFlutterBackgroundEngine.Engine {

        private final Context applicationContext;
        private final FlutterEngine flutterEngine;
        private final MethodChannel channel;

        private boolean started;
        private boolean initialized;

        EngineInstance(
            Context applicationContext,
            FlutterEngine flutterEngine
        ) {
            this.applicationContext = applicationContext;
            this.flutterEngine = flutterEngine;
            channel = new MethodChannel(
                flutterEngine
                    .getDartExecutor()
                    .getBinaryMessenger(),
                CHANNEL_NAME
            );
        }

        @Override
        public void start(
            long dispatcherHandle,
            Runnable onInitialized
        ) {
            if (started) {
                throw new IllegalStateException(
                    "Background Flutter engine has already started."
                );
            }

            started = true;

            FlutterCallbackInformation callbackInformation =
                FlutterCallbackInformation.lookupCallbackInformation(
                    dispatcherHandle
                );

            if (callbackInformation == null) {
                throw new IllegalStateException(
                    "Could not resolve the Radar background dispatcher."
                );
            }

            channel.setMethodCallHandler((call, result) -> {
                if (!"initialized".equals(call.method)) {
                    result.notImplemented();
                    return;
                }

                if (initialized) {
                    result.success(null);
                    return;
                }

                initialized = true;
                result.success(null);
                onInitialized.run();
            });

            DartExecutor.DartCallback dartCallback =
                new DartExecutor.DartCallback(
                    applicationContext.getAssets(),
                    FlutterInjector
                        .instance()
                        .flutterLoader()
                        .findAppBundlePath(),
                    callbackInformation
                );

            flutterEngine
                .getDartExecutor()
                .executeDartCallback(dartCallback);
        }

        @Override
        public void invokeMethod(
            String method,
            Map<String, Object> arguments,
            Runnable completion
        ) {
            channel.invokeMethod(
                method,
                arguments,
                new MethodChannel.Result() {
                    @Override
                    public void success(Object result) {
                        completion.run();
                    }

                    @Override
                    public void error(
                        String errorCode,
                        String errorMessage,
                        Object errorDetails
                    ) {
                        Log.e(
                            TAG,
                            "Radar background handler failed (" +
                                errorCode +
                                "): " +
                                errorMessage
                        );
                        completion.run();
                    }

                    @Override
                    public void notImplemented() {
                        Log.e(
                            TAG,
                            "Radar background handler was not implemented."
                        );
                        completion.run();
                    }
                }
            );
        }

        @Override
        public void destroy() {
            channel.setMethodCallHandler(null);
            flutterEngine.destroy();
        }
    }
}