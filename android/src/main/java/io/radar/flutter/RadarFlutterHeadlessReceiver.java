package io.radar.flutter;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterMain;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Build;
import android.os.Looper;
import android.os.Handler;
import android.util.Log;

import com.google.gson.Gson;

import org.json.JSONException;
import org.json.JSONObject;
import org.jetbrains.annotations.Nullable;

import io.radar.sdk.Radar;
import io.radar.sdk.RadarState;
import io.radar.sdk.RadarReceiver;
import io.radar.sdk.RadarVerifiedReceiver;
import io.radar.sdk.RadarNotificationOptions;
import io.radar.sdk.RadarTrackingOptions;
import io.radar.sdk.RadarTripOptions;
import io.radar.sdk.model.RadarAddress;
import io.radar.sdk.model.RadarContext;
import io.radar.sdk.model.RadarEvent;
import io.radar.sdk.model.RadarGeofence;
import io.radar.sdk.model.RadarPlace;
import io.radar.sdk.model.RadarRoutes;
import io.radar.sdk.model.RadarUser;
import io.radar.sdk.model.RadarTrip;
import io.radar.sdk.model.RadarRouteMatrix;
import io.radar.sdk.RadarTrackingOptions.RadarTrackingOptionsForegroundService;
import io.radar.sdk.model.RadarVerifiedLocationToken;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback;

import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterRunArguments;
import io.flutter.view.FlutterCallbackInformation;

public class RadarFlutterHeadlessReceiver extends RadarReceiver {
    private FlutterEngine sBackgroundFlutterEngine;
    private MethodChannel sBackgroundChannel;

    private static final Object lock = new Object();
    private static final String TAG = "RadarFlutterPersistentReceiver";
    private static final String CALLBACK_DISPATCHER_HANDLE_KEY = "callbackDispatcherHandle";
    private static final String HEADLESS_EVENT_CALLBACK_HANDLE_KEY = "headlesEventCallbackHandle";

    public RadarFlutterHeadlessReceiver(Context context) {
        notification(context, "Initializing");
        initializeBackgroundEngine(context);
    }

    public static void storeHandles(
        Context context, 
        Long headlessEventCallbackHandle, 
        Long callbackDispatcherHandle
    ) {
        SharedPreferences.Editor editor = context.getSharedPreferences(TAG, Context.MODE_PRIVATE).edit();
        editor.putLong(HEADLESS_EVENT_CALLBACK_HANDLE_KEY, headlessEventCallbackHandle);
        editor.putLong(CALLBACK_DISPATCHER_HANDLE_KEY, callbackDispatcherHandle);
        editor.apply();
    }

    public void onClientLocationUpdated(Context context, Location location, boolean stopped,
            Radar.RadarLocationSource source) {
        try {
            JSONObject obj = new JSONObject();
            obj.put("location", Radar.jsonForLocation(location));
            obj.put("stopped", stopped);
            obj.put("source", source.toString());

            JSONObject motionActivityJson = RadarState.getLastMotionActivity(context);
            if (motionActivityJson != null) {
                obj.put("activity", motionActivityJson.get("type"));
            }

            HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);

            SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
            Long headlessEventHandlerHandle = sharedPrefs.getLong("headlessEventCallbackHandle", 0);
            // notification(context, "Attempting");
            if (headlessEventHandlerHandle == 0L) {
                // notification(context, "Failed: " + headlessEventHandlerHandle.toString());
                return;
            }

            final ArrayList clientLocationArgs = new ArrayList();
            clientLocationArgs.add(headlessEventHandlerHandle);
            clientLocationArgs.add(res);
            synchronized (lock) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        sBackgroundChannel.invokeMethod("", clientLocationArgs);
                    }
                });
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
    }

    @Override
    public void onEventsReceived(Context context, RadarEvent[] events, RadarUser user) {
    }

    @Override
    public void onLocationUpdated(Context context, Location location, RadarUser user) {
    }

    @Override
    public void onError(Context context, Radar.RadarStatus status) {
    }

    @Override
    public void onLog(Context context, String message) {
    }

    private void initializeBackgroundEngine(Context context) {
        if (this.sBackgroundFlutterEngine == null) {
            FlutterMain.startInitialization(context.getApplicationContext());
            FlutterMain.ensureInitializationComplete(context.getApplicationContext(), null);

            SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
            long callbackDispatcherHandle = sharedPrefs.getLong(CALLBACK_DISPATCHER_HANDLE_KEY, 0);
            if (callbackDispatcherHandle == 0) {
                notification(context, "Failed to initialize");
                Log.e(TAG, "Error looking up callback dispatcher handle");
                return;
            }

            FlutterCallbackInformation callbackInfo = FlutterCallbackInformation
                    .lookupCallbackInformation(callbackDispatcherHandle);
            sBackgroundFlutterEngine = new FlutterEngine(context.getApplicationContext());

            DartCallback callback = new DartCallback(context.getAssets(), FlutterMain.findAppBundlePath(context),
                    callbackInfo);
            sBackgroundFlutterEngine.getDartExecutor().executeDartCallback(callback);
            sBackgroundChannel = new MethodChannel(sBackgroundFlutterEngine.getDartExecutor().getBinaryMessenger(),
                    "flutter_radar_background");
        }
    }

    private static void runOnMainThread(final Runnable runnable) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(runnable);
    }

    private void notification(Context context, String message) {
        NotificationManagerCompat manager = NotificationManagerCompat.from(context);
        NotificationChannel mChannel = new NotificationChannel("debug_channel", "debug chanenl", // name of the
                                                                                                 // channel
                NotificationManager.IMPORTANCE_MAX); // importance level
        // Configure the notification channel.
        mChannel.setDescription("blah");
        mChannel.enableLights(true);
        // Sets the notification light color for notifications posted to this channel,
        // if the device supports this feature.
        mChannel.enableVibration(true);
        mChannel.setShowBadge(true);
        mChannel.setVibrationPattern(new long[] { 100, 200, 300, 400, 500, 400, 300, 200, 400 });
        manager.createNotificationChannel(mChannel);

        int id = context.getResources().getIdentifier("ic_notification", "drawable", "com.dmp.gather");
        NotificationCompat.Builder builder = new NotificationCompat.Builder(context,
                "debug_channel")
                .setSmallIcon(id)
                .setContentTitle(message)
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                // .setImportance(NotificationCompat.IMPORTANCE_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC);
        manager.notify(new Random().nextInt(10000), builder.build());
    }
}