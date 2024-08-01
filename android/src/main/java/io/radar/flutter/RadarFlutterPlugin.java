package io.radar.flutter;

import android.Manifest;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

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

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

import io.radar.sdk.Radar;
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

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback;

import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterRunArguments;
import io.flutter.view.FlutterCallbackInformation;

public class RadarFlutterPlugin
        implements FlutterPlugin, MethodCallHandler, ActivityAware, RequestPermissionsResultListener {

    private static FlutterEngine sBackgroundFlutterEngine;

    private Activity mActivity;
    private Context mContext;

    private static final String TAG = "RadarFlutterPlugin";
    private static final String CALLBACK_DISPATCHER_HANDLE_KEY = "callbackDispatcherHandle";
    private static MethodChannel sBackgroundChannel;
    private MethodChannel channel;

    private static final Object lock = new Object();

    private static final int PERMISSIONS_REQUEST_CODE = 20160525;
    private Result mPermissionsRequestResult;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        mContext = binding.getApplicationContext();
        channel = new MethodChannel(binding.getFlutterEngine().getDartExecutor(), "flutter_radar");
        Radar.setReceiver(new RadarFlutterReceiver(channel));
        Radar.setVerifiedReceiver(new RadarFlutterVerifiedReceiver(channel));
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        mContext = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
        binding.addRequestPermissionsResultListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        mActivity = null;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        mActivity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
        binding.addRequestPermissionsResultListener(this);
    }

    public static void registerWith(Registrar registrar) {
        RadarFlutterPlugin plugin = new RadarFlutterPlugin();

        MethodChannel channel = new MethodChannel(registrar.messenger(), "radar_flutter_plugin");
        channel.setMethodCallHandler(plugin);
        plugin.mContext = registrar.context();
        plugin.mActivity = registrar.activity();
    }

    private static void runOnMainThread(final Runnable runnable) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(runnable);
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == PERMISSIONS_REQUEST_CODE && mPermissionsRequestResult != null) {
            getPermissionStatus(mPermissionsRequestResult);
            mPermissionsRequestResult = null;
        }
        return true;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        try {
            switch (call.method) {
                case "initialize":
                    initialize(call, result);
                    break;
                case "setLogLevel":
                    setLogLevel(call, result);
                    break;
                case "getPermissionsStatus":
                    getPermissionStatus(result);
                    break;
                case "requestPermissions":
                    requestPermissions(call, result);
                    break;
                case "setUserId":
                    setUserId(call, result);
                    break;
                case "getUserId":
                    getUserId(result);
                    break;
                case "setDescription":
                    setDescription(call, result);
                    break;
                case "getDescription":
                    getDescription(result);
                    break;
                case "setMetadata":
                    setMetadata(call, result);
                    break;
                case "getMetadata":
                    getMetadata(result);
                    break;
                case "setAnonymousTrackingEnabled":
                    setAnonymousTrackingEnabled(call, result);
                    break;
                case "getLocation":
                    getLocation(call, result);
                    break;
                case "trackOnce":
                    trackOnce(call, result);
                    break;
                case "startTracking":
                    startTracking(call, result);
                    break;
                case "startTrackingCustom":
                    startTrackingCustom(call, result);
                    break;
                case "startTrackingVerified":
                    startTrackingVerified(call, result);
                    break;
                case "stopTrackingVerified":
                    stopTrackingVerified(call, result);
                    break;
                case "stopTracking":
                    stopTracking(result);
                    break;
                case "isTracking":
                    isTracking(result);
                    break;
                case "isUsingRemoteTrackingOptions":
                    isUsingRemoteTrackingOptions(result);
                    break;
                case "getTrackingOptions":
                    getTrackingOptions(result);
                    break;
                case "mockTracking":
                    mockTracking(call, result);
                    break;
                case "startTrip":
                    startTrip(call, result);
                    break;
                case "updateTrip":
                    updateTrip(call, result);
                    break;
                case "getTripOptions":
                    getTripOptions(result);
                    break;
                case "completeTrip":
                    completeTrip(result);
                    break;
                case "cancelTrip":
                    cancelTrip(result);
                    break;
                case "acceptEvent":
                    acceptEvent(call, result);
                    break;
                case "rejectEvent":
                    rejectEvent(call, result);
                    break;
                case "getContext":
                    getContext(call, result);
                    break;
                case "searchGeofences":
                    searchGeofences(call, result);
                    break;
                case "searchPlaces":
                    searchPlaces(call, result);
                    break;
                case "autocomplete":
                    autocomplete(call, result);
                    break;
                case "forwardGeocode":
                    geocode(call, result);
                    break;
                case "reverseGeocode":
                    reverseGeocode(call, result);
                    break;
                case "ipGeocode":
                    ipGeocode(call, result);
                    break;
                case "getDistance":
                    getDistance(call, result);
                    break;
                case "logConversion":
                    logConversion(call, result);
                    break;
                case "logTermination":
                    // do nothing
                    break;
                case "logBackgrounding":
                    logBackgrounding(result);
                    break;
                case "logResigningActive":
                    logResigningActive(result);
                    break;
                case "getMatrix":
                    getMatrix(call, result);
                    break;
                case "setNotificationOptions":
                    setNotificationOptions(call, result);
                    break;
                case "setForegroundServiceOptions":
                    setForegroundServiceOptions(call, result);
                    break;
                case "trackVerified":
                    trackVerified(call, result);
                    break;
                case "validateAddress":
                    validateAddress(call, result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        } catch (Error | Exception e) {
            result.error(e.toString(), e.getMessage(), e.getMessage());
        }
    }

    private String getStringFromMethodCall(MethodCall call, String key) {
        try {
            final Map<String, Object> arguments = call.arguments();
            if (arguments.containsKey(key)) {
                Object value = arguments.get(key);
                if (value instanceof String) {
                    return (String) value; // Return the string value if it exists and is a string
                }
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
        return null; // Return null if the key does not exist or is not a string
    }

    private boolean getBooleanFromMethodCall(MethodCall call, String key, boolean defaultValue) {
        try {
            final Map<String, Object> arguments = call.arguments();
            if (arguments.containsKey(key)) {
                Object value = arguments.get(key);
                if (value instanceof Boolean) {
                    return (Boolean) value;
                }
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
        return defaultValue;
    }

    private HashMap<String, Object> getHashMapFromMethodCall(MethodCall call, String key) {
        try {
            final Map<String, Object> arguments = call.arguments();
            if (arguments.containsKey(key)) {
                Object value = arguments.get(key);
                if (value instanceof HashMap) {
                    return (HashMap<String, Object>) value;
                }
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
        return null;
    }

    private int getIntFromMethodCall(MethodCall call, String key, int defaultValue) {
        try {
            final Map<String, Object> arguments = call.arguments();
            if (arguments.containsKey(key)) {
                Object value = arguments.get(key);
                if (value instanceof Integer) {
                    return (Integer) value;
                }
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
        return defaultValue;
    }

    private ArrayList<Object> getArrayListFromMethodCall(MethodCall call, String key) {
        try {
            final Map<String, Object> arguments = call.arguments();
            if (arguments.containsKey(key)) {
                Object value = arguments.get(key);
                if (value instanceof ArrayList) {
                    return (ArrayList<Object>) value;
                }
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
        return null;
    }

    private String[] getStringArrayFromMethodCall(MethodCall call, String key) {
        ArrayList<Object> list = getArrayListFromMethodCall(call, key);
        if (list != null) {
            return list.toArray(new String[0]);
        }
        return null;
    }

    private void initialize(MethodCall call, Result result) {
        String publishableKey = getStringFromMethodCall(call, "publishableKey");
        boolean fraud = getBooleanFromMethodCall(call, "fraud", false);
        SharedPreferences.Editor editor = mContext.getSharedPreferences("RadarSDK", Context.MODE_PRIVATE).edit();
        editor.putString("x_platform_sdk_type", "Flutter");
        editor.putString("x_platform_sdk_version", "3.10.0-beta.3");
        editor.apply();
        Radar.initialize(mContext, publishableKey, null, Radar.RadarLocationServicesProvider.GOOGLE, fraud);
        Radar.setReceiver(new RadarFlutterReceiver(channel));
        Radar.setVerifiedReceiver(new RadarFlutterVerifiedReceiver(channel));
        result.success(true);
    }

    private void setNotificationOptions(MethodCall call, Result result) {
        HashMap notificationOptionsMap = (HashMap) call.arguments;
        JSONObject notificationOptionsJson = new JSONObject(notificationOptionsMap);
        RadarNotificationOptions options = RadarNotificationOptions.fromJson(notificationOptionsJson);
        Radar.setNotificationOptions(options);
        result.success(true);
    }

    private void setForegroundServiceOptions(MethodCall call, Result result) {
        HashMap foregroundServiceOptionsMap = (HashMap) call.arguments;
        JSONObject foregroundServiceOptionsJson = new JSONObject(foregroundServiceOptionsMap);
        RadarTrackingOptionsForegroundService options = RadarTrackingOptionsForegroundService
                .fromJson(foregroundServiceOptionsJson);
        Radar.setForegroundServiceOptions(options);
        result.success(true);
    }

    private void setLogLevel(MethodCall call, Result result) {
        String logLevel = getStringFromMethodCall(call, "logLevel");
        if (logLevel == null) {
            Radar.setLogLevel(Radar.RadarLogLevel.NONE);
        } else if (logLevel.equals("debug")) {
            Radar.setLogLevel(Radar.RadarLogLevel.DEBUG);
        } else if (logLevel.equals("info")) {
            Radar.setLogLevel(Radar.RadarLogLevel.INFO);
        } else if (logLevel.equals("warning")) {
            Radar.setLogLevel(Radar.RadarLogLevel.WARNING);
        } else if (logLevel.equals("error")) {
            Radar.setLogLevel(Radar.RadarLogLevel.ERROR);
        } else {
            Radar.setLogLevel(Radar.RadarLogLevel.NONE);
        }
        result.success(true);
    }

    private void getPermissionStatus(Result result) {
        String status = "NOT_DETERMINED";

        if (mActivity == null || result == null) {
            result.success(status);

            return;
        }

        boolean foreground = ActivityCompat.checkSelfPermission(mActivity,
                Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        if (Build.VERSION.SDK_INT >= 29) {
            if (foreground) {
                boolean background = ActivityCompat.checkSelfPermission(mActivity,
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;
                status = background ? "GRANTED_BACKGROUND" : "GRANTED_FOREGROUND";
            } else {
                status = "DENIED";
            }
        } else {
            status = foreground ? "GRANTED_BACKGROUND" : "DENIED";
        }

        result.success(status);
    }

    private void requestPermissions(MethodCall call, Result result) {
        boolean background = getBooleanFromMethodCall(call, "background", false);
        mPermissionsRequestResult = result;
        if (mActivity != null) {
            if (Build.VERSION.SDK_INT >= 23) {
                if (background && Build.VERSION.SDK_INT >= 29) {
                    ActivityCompat.requestPermissions(mActivity,
                            new String[] { Manifest.permission.ACCESS_COARSE_LOCATION,
                                    Manifest.permission.ACCESS_FINE_LOCATION,
                                    Manifest.permission.ACCESS_BACKGROUND_LOCATION },
                            PERMISSIONS_REQUEST_CODE);
                } else {
                    ActivityCompat.requestPermissions(mActivity, new String[] {
                            Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION },
                            PERMISSIONS_REQUEST_CODE);
                }
            }
        }
    }

    private void setUserId(MethodCall call, Result result) {
        String userId = getStringFromMethodCall(call, "userId");
        Radar.setUserId(userId);
        result.success(true);
    }

    private void getUserId(Result result) {
        String userId = Radar.getUserId();
        result.success(userId);
    }

    private void setDescription(MethodCall call, Result result) {
        String description = getStringFromMethodCall(call, "description");
        Radar.setDescription(description);
        result.success(true);
    }

    private void getDescription(Result result) {
        String description = Radar.getDescription();
        result.success(description);
    }

    private void setMetadata(MethodCall call, Result result) {
        HashMap metadataMap = (HashMap) call.arguments;
        JSONObject metadata = new JSONObject(metadataMap);
        Radar.setMetadata(metadata);
        result.success(true);
    }

    private void getMetadata(Result result) {
        JSONObject metadata = Radar.getMetadata();
        HashMap metadataMap = null;
        if (metadata != null) {
            metadataMap = new Gson().fromJson(metadata.toString(), HashMap.class);
        }
        result.success(metadataMap);
    }

    private void setAnonymousTrackingEnabled(MethodCall call, Result result) {
        boolean enabled = getBooleanFromMethodCall(call, "enabled", false);
        Radar.setAnonymousTrackingEnabled(enabled);
        result.success(true);
    }

    private void getLocation(MethodCall call, final Result result) {
        Radar.RadarLocationCallback callback = new Radar.RadarLocationCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location, final boolean stopped) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            obj.put("stopped", stopped);

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        String accuracy = getStringFromMethodCall(call, "accuracy");
        if (accuracy == null) {
            Radar.getLocation(callback);
        } else if (accuracy.equals("high")) {
            Radar.getLocation(RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.HIGH, callback);
        } else if (accuracy.equals("medium")) {
            Radar.getLocation(RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.MEDIUM, callback);
        } else if (accuracy.equals("low")) {
            Radar.getLocation(RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.LOW, callback);
        } else {
            Radar.getLocation(callback);
        }
    }

    private void trackOnce(MethodCall call, final Result result) {
        Radar.RadarTrackCallback callback = new Radar.RadarTrackCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location, final RadarEvent[] events,
                    final RadarUser user) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            if (events != null) {
                                obj.put("events", RadarEvent.toJson(events));
                            }
                            if (user != null) {
                                obj.put("user", user.toJson());
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        HashMap locationMap = getHashMapFromMethodCall(call, "location");
        if (locationMap != null) {
            Location location = locationForMap(locationMap);
            Radar.trackOnce(location, callback);
        } else {
            RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy accuracyLevel = RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.MEDIUM;
            boolean beaconsTrackingOption = getBooleanFromMethodCall(call, "beacons", false);
            String desiredAccuracy = (getStringFromMethodCall(call, "desiredAccuracy"));
            if (desiredAccuracy != null){
                desiredAccuracy = desiredAccuracy.toLowerCase();
                if (desiredAccuracy.equals("none")) {
                    accuracyLevel = RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.NONE;
                } else if (desiredAccuracy.equals("low")) {
                    accuracyLevel = RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.LOW;
                } else if (desiredAccuracy.equals("medium")) {
                    accuracyLevel = RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.MEDIUM;
                } else if (desiredAccuracy.equals("high")) {
                    accuracyLevel = RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.HIGH;
                }
            }

            Radar.trackOnce(accuracyLevel, beaconsTrackingOption, callback);
        }
    }

    private void startTracking(MethodCall call, Result result) {
        String preset = getStringFromMethodCall(call, "preset");
        if (preset == null) {
            Radar.startTracking(RadarTrackingOptions.RESPONSIVE);
        } else if (preset.equals("continuous")) {
            Radar.startTracking(RadarTrackingOptions.CONTINUOUS);
        } else if (preset.equals("responsive")) {
            Radar.startTracking(RadarTrackingOptions.RESPONSIVE);
        } else if (preset.equals("efficient")) {
            Radar.startTracking(RadarTrackingOptions.EFFICIENT);
        } else {
            Radar.startTracking(RadarTrackingOptions.RESPONSIVE);
        }
        result.success(true);
    }

    private void startTrackingCustom(MethodCall call, Result result) {
        HashMap optionsMap = (HashMap) call.arguments;
        JSONObject optionsJson = new JSONObject(optionsMap);
        RadarTrackingOptions options = RadarTrackingOptions.fromJson(optionsJson);
        Radar.startTracking(options);
        result.success(true);
    }

    private void startTrackingVerified(MethodCall call, Result result) {
        int interval = getIntFromMethodCall(call, "interval", 1);
        Boolean beacons = getBooleanFromMethodCall(call, "beacons", false);
        Radar.startTrackingVerified(interval, beacons);
        result.success(true);
    }

    private void stopTrackingVerified(MethodCall call, Result result) {
        Radar.stopTrackingVerified();
        result.success(true);
    }

    public void mockTracking(MethodCall call, final Result result) {
        HashMap originMap = getHashMapFromMethodCall(call, "origin");
        Location origin = locationForMap(originMap);
        HashMap destinationMap = getHashMapFromMethodCall(call, "destination");
        Location destination = locationForMap(destinationMap);
        String modeStr = getStringFromMethodCall(call, "mode");
        Radar.RadarRouteMode mode = Radar.RadarRouteMode.CAR;
        if (modeStr != null) {
            if (modeStr.equals("FOOT") || modeStr.equals("foot")) {
                mode = Radar.RadarRouteMode.FOOT;
            } else if (modeStr.equals("BIKE") || modeStr.equals("bike")) {
                mode = Radar.RadarRouteMode.BIKE;
            } else if (modeStr.equals("CAR") || modeStr.equals("car")) {
                mode = Radar.RadarRouteMode.CAR;
            }
        }
        
        int steps = getIntFromMethodCall(call, "steps", 10);
        int interval = getIntFromMethodCall(call, "interval", 1);

        Radar.mockTracking(origin, destination, mode, steps, interval, new Radar.RadarTrackCallback() {
            @Override
            public void onComplete(Radar.RadarStatus status, Location location, RadarEvent[] events, RadarUser user) {

            }
        });
    }

    private void stopTracking(Result result) {
        Radar.stopTracking();
        result.success(true);
    }

    private void isTracking(Result result) {
        Boolean isTracking = Radar.isTracking();
        result.success(isTracking);
    }

    private void getTrackingOptions(Result result) throws JSONException {
        RadarTrackingOptions options = Radar.getTrackingOptions();
        JSONObject optionsJson = options.toJson();
        HashMap optionsMap = null;
        if (optionsJson != null) {
            optionsMap = new Gson().fromJson(optionsJson.toString(), HashMap.class);
        }
        result.success(optionsMap);
    }

    public void startTrip(MethodCall call, Result result) throws JSONException {
        HashMap tripOptionsMap = getHashMapFromMethodCall(call, "tripOptions");
        JSONObject tripOptionsJson = jsonForMap(tripOptionsMap);
        RadarTripOptions tripOptions = RadarTripOptions.fromJson(tripOptionsJson);
        HashMap trackingOptionsMap = getHashMapFromMethodCall(call, "trackingOptions");
        JSONObject trackingOptionsJson = jsonForMap(trackingOptionsMap);
        RadarTrackingOptions trackingOptions = null;
        if (trackingOptionsJson != null) {
            trackingOptions = RadarTrackingOptions.fromJson(trackingOptionsJson);
        }
        Radar.startTrip(tripOptions, trackingOptions, new Radar.RadarTripCallback() {
            @Override
            public void onComplete(@NonNull Radar.RadarStatus status,
                    @Nullable RadarTrip trip,
                    @Nullable RadarEvent[] events) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (trip != null) {
                                obj.put("trip", trip.toJson());
                            }
                            if (events != null) {
                                obj.put("events", RadarEvent.toJson(events));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void updateTrip(MethodCall call, Result result) throws JSONException {
        HashMap tripOptionsMap = getHashMapFromMethodCall(call, "tripOptions");
        JSONObject tripOptionsJson = jsonForMap(tripOptionsMap);
        RadarTripOptions tripOptions = RadarTripOptions.fromJson(tripOptionsJson);
        String statusStr = getStringFromMethodCall(call, "status");
        RadarTrip.RadarTripStatus status = RadarTrip.RadarTripStatus.UNKNOWN;
        if (statusStr != null){
            statusStr = statusStr.toLowerCase();
            if (statusStr.equals("started")) {
                status = RadarTrip.RadarTripStatus.STARTED;
            } else if (statusStr.equals("approaching")) {
                status = RadarTrip.RadarTripStatus.APPROACHING;
            } else if (statusStr.equals("arrived")) {
                status = RadarTrip.RadarTripStatus.ARRIVED;
            } else if (statusStr.equals("completed")) {
                status = RadarTrip.RadarTripStatus.COMPLETED;
            } else if (statusStr.equals("canceled")) {
                status = RadarTrip.RadarTripStatus.CANCELED;
            }
        }

        Radar.updateTrip(tripOptions, status, new Radar.RadarTripCallback() {
            @Override
            public void onComplete(@NonNull Radar.RadarStatus status,
                    @Nullable RadarTrip trip,
                    @Nullable RadarEvent[] events) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (trip != null) {
                                obj.put("trip", trip.toJson());
                            }
                            if (events != null) {
                                obj.put("events", RadarEvent.toJson(events));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void getTripOptions(Result result) {
        RadarTripOptions tripOptions = Radar.getTripOptions();
        HashMap<String, Object> map = new Gson().fromJson(tripOptions.toJson().toString(), HashMap.class);
        result.success(map);
    }

    public void completeTrip(Result result) {
        Radar.completeTrip(new Radar.RadarTripCallback() {
            @Override
            public void onComplete(@NonNull Radar.RadarStatus status,
                    @Nullable RadarTrip trip,
                    @Nullable RadarEvent[] events) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (trip != null) {
                                obj.put("trip", trip.toJson());
                            }
                            if (events != null) {
                                obj.put("events", RadarEvent.toJson(events));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void cancelTrip(Result result) {
        Radar.cancelTrip(new Radar.RadarTripCallback() {
            @Override
            public void onComplete(@NonNull Radar.RadarStatus status,
                    @Nullable RadarTrip trip,
                    @Nullable RadarEvent[] events) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (trip != null) {
                                obj.put("trip", trip.toJson());
                            }
                            if (events != null) {
                                obj.put("events", RadarEvent.toJson(events));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void acceptEvent(MethodCall call, Result result) {
        String eventId = getStringFromMethodCall(call, "eventId");
        String verifiedPlaceId = getStringFromMethodCall(call, "verifiedPlaceId");
        Radar.acceptEvent(eventId, verifiedPlaceId);
        result.success(true);
    }

    public void rejectEvent(MethodCall call, Result result) {
        String eventId = getStringFromMethodCall(call, "eventId");
        Radar.rejectEvent(eventId);
        result.success(true);
    }

    public void getContext(MethodCall call, final Result result) {
        Radar.RadarContextCallback callback = new Radar.RadarContextCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location,
                    final RadarContext context) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            if (context != null) {
                                obj.put("context", context.toJson());
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };
        HashMap locationMap = getHashMapFromMethodCall(call, "location");
        if (locationMap != null) {
            Location location = locationForMap(locationMap);
            Radar.getContext(location, callback);
        } else {
            Radar.getContext(callback);
        }
    }

    private void searchGeofences(MethodCall call, final Result result) throws JSONException {
        Radar.RadarSearchGeofencesCallback callback = new Radar.RadarSearchGeofencesCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location,
                    final RadarGeofence[] geofences) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            if (geofences != null) {
                                obj.put("geofences", RadarGeofence.toJson(geofences));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        Location near = null;
        HashMap nearMap = getHashMapFromMethodCall(call, "near");
        if (nearMap != null) {
            near = locationForMap(nearMap);
        }
        int radius = getIntFromMethodCall(call, "radius", 1000);

        String[] tags = getStringArrayFromMethodCall(call, "tags");
        HashMap metadataMap = getHashMapFromMethodCall(call, "metadata");
        JSONObject metadata = jsonForMap(metadataMap);
        int limit = getIntFromMethodCall(call, "limit", 10);
        boolean includeGeometry = getBooleanFromMethodCall(call, "includeGeometry", false);

        if (near != null) {
            Radar.searchGeofences(near, radius, tags, metadata, limit, includeGeometry, callback);
        } else {
            Radar.searchGeofences(radius, tags, metadata, limit, includeGeometry, callback);
        }
    }

    public void searchPlaces(MethodCall call, final Result result) {
        Radar.RadarSearchPlacesCallback callback = new Radar.RadarSearchPlacesCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location, final RadarPlace[] places) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            if (places != null) {
                                obj.put("places", RadarPlace.toJson(places));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        Location near = null;
        HashMap nearMap = getHashMapFromMethodCall(call, "near");
        if (nearMap != null) {
            near = locationForMap(nearMap);
        }
        int radius = getIntFromMethodCall(call, "radius", 1000);
        String[] chains = getStringArrayFromMethodCall(call, "chains");
        Map<String, String> chainMetadata = (Map<String, String>) call.argument("chainMetadata");
        String[] categories = getStringArrayFromMethodCall(call, "categories");
        String[] groups = getStringArrayFromMethodCall(call, "groups");
        int limit = getIntFromMethodCall(call, "limit", 10);

        if (near != null) {
            Radar.searchPlaces(near, radius, chains, chainMetadata, categories, groups, limit, callback);
        } else {
            Radar.searchPlaces(radius, chains, chainMetadata, categories, groups, limit, callback);
        }
    }

    public void autocomplete(MethodCall call, final Result result) {
        String query = getStringFromMethodCall(call, "query");
        HashMap nearMap = getHashMapFromMethodCall(call, "near");
        Location near = locationForMap(nearMap);
        int limit = getIntFromMethodCall(call, "limit", 10);
        String country = getStringFromMethodCall(call, "country");
        String[] layers = getStringArrayFromMethodCall(call, "layers");
        Boolean mailable = getBooleanFromMethodCall(call, "mailable", false);

        Radar.autocomplete(query, near, layers, limit, country, true, mailable, new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void geocode(MethodCall call, final Result result) {
        String query = getStringFromMethodCall(call, "query");

        Radar.geocode(query, null, null, new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void reverseGeocode(MethodCall call, final Result result) {
        Radar.RadarGeocodeCallback callback = new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        String[] layers = getStringArrayFromMethodCall(call, "layers");
        HashMap locationMap = getHashMapFromMethodCall(call, "location");
        if (locationMap != null) {
            Location location = locationForMap(locationMap);
            Radar.reverseGeocode(location, layers, callback);
        } else {
            Radar.reverseGeocode(layers, callback);
        }
    }

    public void ipGeocode(MethodCall call, final Result result) {
        Radar.ipGeocode(new Radar.RadarIpGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final RadarAddress address, final boolean proxy) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (address != null) {
                                obj.put("address", address.toJson());
                                obj.put("proxy", proxy);
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void getDistance(MethodCall call, final Result result) throws JSONException {
        Radar.RadarRouteCallback callback = new Radar.RadarRouteCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final RadarRoutes routes) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (routes != null) {
                                obj.put("routes", routes.toJson());
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        Location origin = null;
        HashMap originMap = getHashMapFromMethodCall(call, "origin");
        if (originMap != null) {
            origin = locationForMap(originMap);
        }
        HashMap destinationMap = getHashMapFromMethodCall(call, "destination");
        Location destination = locationForMap(destinationMap);
        EnumSet<Radar.RadarRouteMode> modes = EnumSet.noneOf(Radar.RadarRouteMode.class);
        String[] modesArr = getStringArrayFromMethodCall(call, "modes");
        for (String modeStr : modesArr) {
            if (modeStr.equals("FOOT") || modeStr.equals("foot")) {
                modes.add(Radar.RadarRouteMode.FOOT);
            }
            if (modeStr.equals("BIKE") || modeStr.equals("bike")) {
                modes.add(Radar.RadarRouteMode.BIKE);
            }
            if (modeStr.equals("CAR") || modeStr.equals("car")) {
                modes.add(Radar.RadarRouteMode.CAR);
            }
        }
        String unitsStr = getStringFromMethodCall(call, "units");
        Radar.RadarRouteUnits units = unitsStr.equals("METRIC") || unitsStr.equals("metric")
                ? Radar.RadarRouteUnits.METRIC
                : Radar.RadarRouteUnits.IMPERIAL;

        if (origin != null) {
            Radar.getDistance(origin, destination, modes, units, callback);
        } else {
            Radar.getDistance(destination, modes, units, callback);
        }
    }

    public void logConversion(MethodCall call, final Result result) throws JSONException {
        Radar.RadarLogConversionCallback callback = new Radar.RadarLogConversionCallback() {
            @Override
            public void onComplete(@NonNull Radar.RadarStatus status, @Nullable RadarEvent event) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (event != null) {
                                obj.put("event", event.toJson());
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        String name = getStringFromMethodCall(call, "name");
        JSONObject metadataJson = null;
        HashMap metadataMap = getHashMapFromMethodCall(call, "metadata");
        if (metadataMap == null) {
            metadataJson = jsonForMap(metadataMap);
        }
        if (call.hasArgument("revenue") && call.argument("revenue") != null) {
            double revenue = (Double) call.argument("revenue");
            Radar.logConversion(name, revenue, metadataJson, callback);
        } else {
            Radar.logConversion(name, metadataJson, callback);
        }
    }

    public void logBackgrounding(Result result) {
        Radar.logBackgrounding();
        result.success(true);
    }

    public void logResigningActive(Result result) {
        Radar.logResigningActive();
        result.success(true);
    }

    public void getMatrix(MethodCall call, final Result result) throws JSONException {
        ArrayList<HashMap> originsArr = call.argument("origins");
        Location[] origins = new Location[originsArr.size()];
        for (int i = 0; i < originsArr.size(); i++) {
            origins[i] = locationForMap(originsArr.get(i));
        }
        ArrayList<HashMap> destinationsArr = call.argument("destinations");
        Location[] destinations = new Location[destinationsArr.size()];
        for (int i = 0; i < destinationsArr.size(); i++) {
            destinations[i] = locationForMap(destinationsArr.get(i));
        }
        String modeStr = getStringFromMethodCall(call, "mode");
        Radar.RadarRouteMode mode = Radar.RadarRouteMode.CAR;
        if (modeStr != null) {
            modeStr = modeStr.toLowerCase();
            if (modeStr.equals("foot")) {
                mode = Radar.RadarRouteMode.FOOT;
            } else if (modeStr.equals("bike")) {
                mode = Radar.RadarRouteMode.BIKE;
            } else if (modeStr.equals("car")) {
                mode = Radar.RadarRouteMode.CAR;
            } else if (modeStr.equals("truck")) {
                mode = Radar.RadarRouteMode.TRUCK;
            } else if (modeStr.equals("motorbike")) {
                mode = Radar.RadarRouteMode.MOTORBIKE;
            }
        }
        String unitsStr = getStringFromMethodCall(call, "units");
        Radar.RadarRouteUnits units = unitsStr != null && unitsStr.toLowerCase().equals("metric")
                ? Radar.RadarRouteUnits.METRIC
                : Radar.RadarRouteUnits.IMPERIAL;

        Radar.getMatrix(origins, destinations, mode, units, new Radar.RadarMatrixCallback() {
            @Override
            public void onComplete(@NonNull Radar.RadarStatus status, @Nullable RadarRouteMatrix matrix) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (matrix != null) {
                                obj.put("matrix", matrix.toJson());
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        });
    }

    public void trackVerified(MethodCall call, final Result result) {
        Boolean beacons = getBooleanFromMethodCall(call, "beacons", false);

        Radar.RadarTrackVerifiedCallback callback = new Radar.RadarTrackVerifiedCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final RadarVerifiedLocationToken token) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            obj.put("token", token.toJson());

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        Radar.trackVerified(beacons, callback);
    }

    private void isUsingRemoteTrackingOptions(Result result) {
        Boolean isRemoteTracking = Radar.isUsingRemoteTrackingOptions();
        result.success(isRemoteTracking);
    }

    public void validateAddress(MethodCall call, final Result result) throws JSONException {
        Radar.RadarValidateAddressCallback callback = new Radar.RadarValidateAddressCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final RadarAddress address,
                    final Radar.RadarAddressVerificationStatus verificationStatus) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (address != null) {
                                obj.put("address", address.toJson());
                            }
                            if (verificationStatus != null) {
                                obj.put("verificationStatus", verificationStatus.toString());
                            }

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        HashMap addressMap = getHashMapFromMethodCall(call, "address");
        JSONObject addressJSON = jsonForMap(addressMap);
        RadarAddress address = RadarAddress.fromJson(addressJSON);
        Radar.validateAddress(address, callback);
    }

    private Location locationForMap(HashMap locationMap) {
        double latitude = (Double) locationMap.get("latitude");
        double longitude = (Double) locationMap.get("longitude");
        Location location = new Location("RadarSDK");
        location.setLatitude(latitude);
        location.setLongitude(longitude);
        if (locationMap.containsKey("accuracy")) {
            double accuracyDouble = (Double) locationMap.get("accuracy");
            float accuracy = (float) accuracyDouble;
            location.setAccuracy(accuracy);
        }
        return location;
    }

    private JSONObject jsonForMap(HashMap map) throws JSONException {
        JSONObject obj = new JSONObject();
        try {
            for (Object key : map.keySet()) {
                String keyStr = String.valueOf(key);
                Object value = map.get(keyStr);
                obj.put(keyStr, value);
            }
        } catch (Exception e) {
            Log.e(TAG, e.toString());
        }
        return obj;
    }

    public static class RadarFlutterReceiver extends RadarReceiver {

        private MethodChannel channel;

        RadarFlutterReceiver(MethodChannel channel) {
            this.channel = channel;
        }

        @Override
        public void onEventsReceived(Context context, RadarEvent[] events, RadarUser user) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("events", RadarEvent.toJson(events));
                obj.put("user", user.toJson());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                final ArrayList eventsArgs = new ArrayList();
                eventsArgs.add(0);
                eventsArgs.add(res);
                synchronized(lock) {
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            channel.invokeMethod("events", eventsArgs);
                        }
                    });
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onLocationUpdated(Context context, Location location, RadarUser user) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("user", user.toJson());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);

                final ArrayList locationArgs = new ArrayList();
                locationArgs.add(0);
                locationArgs.add(res);
                synchronized(lock) {
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            channel.invokeMethod("location", locationArgs);
                        }
                    });
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        public void onClientLocationUpdated(Context context, Location location, boolean stopped,
                Radar.RadarLocationSource source) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("stopped", stopped);
                obj.put("source", source.toString());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                final ArrayList clientLocationArgs = new ArrayList();
                clientLocationArgs.add(0);
                clientLocationArgs.add(res);
                synchronized(lock){
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            channel.invokeMethod("clientLocation", clientLocationArgs);
                        }
                    });
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onError(Context context, Radar.RadarStatus status) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("status", status.toString());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                final ArrayList errorArgs = new ArrayList();
                errorArgs.add(0);
                errorArgs.add(res);
                synchronized(lock){
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            channel.invokeMethod("error", errorArgs);
                        }
                    });
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onLog(Context context, String message) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("message", message);

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                final ArrayList logArgs = new ArrayList();
                logArgs.add(0);
                logArgs.add(res);
                synchronized(lock) {
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            channel.invokeMethod("log", logArgs);
                        }
                    });
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }
    }

    public static class RadarFlutterVerifiedReceiver extends RadarVerifiedReceiver {

        private MethodChannel channel;

        RadarFlutterVerifiedReceiver(MethodChannel channel) {
            this.channel = channel;
        }

        @Override
        public void onTokenUpdated(Context context, RadarVerifiedLocationToken token) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("token", token.toJson());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                final ArrayList tokenArgs = new ArrayList();
                tokenArgs.add(0);
                tokenArgs.add(res);
                synchronized(lock) {
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            channel.invokeMethod("token", tokenArgs);
                        }
                    });
                }
                
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

    }
};
