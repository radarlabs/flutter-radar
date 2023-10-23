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

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback;

import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterRunArguments;
import io.flutter.view.FlutterCallbackInformation;

public class RadarFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, RequestPermissionsResultListener {

    private static FlutterEngine sBackgroundFlutterEngine;
    private static EventChannel sEventsChannel;
    private static EventChannel.EventSink sEventsSink;
    private static EventChannel sLocationChannel;
    private static EventChannel.EventSink sLocationSink;
    private static EventChannel sClientLocationChannel;
    private static EventChannel.EventSink sClientLocationSink;
    private static EventChannel sErrorChannel;
    private static EventChannel.EventSink sErrorSink;
    private static EventChannel sLogChannel;
    private static EventChannel.EventSink sLogSink;

    private Activity mActivity;
    private Context mContext;

    private static final String TAG = "RadarFlutterPlugin";
    private static final String CALLBACK_DISPATCHER_HANDLE_KEY = "callbackDispatcherHandle";
    private static MethodChannel sBackgroundChannel;

    private static final Object lock = new Object();

    private static final int PERMISSIONS_REQUEST_CODE = 20160525;
    private Result mPermissionsRequestResult;
    
    private static void initializeBackgroundEngine(Context context) {
        synchronized(lock) {
            if (sBackgroundFlutterEngine == null) {
                FlutterMain.startInitialization(context.getApplicationContext());
                FlutterMain.ensureInitializationComplete(context.getApplicationContext(), null);

                SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
                long callbackDispatcherHandle = sharedPrefs.getLong(CALLBACK_DISPATCHER_HANDLE_KEY, 0);
                if (callbackDispatcherHandle == 0) {
                    Log.e(TAG, "Error looking up callback dispatcher handle");
                    return;
                }

                FlutterCallbackInformation callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackDispatcherHandle);
                sBackgroundFlutterEngine = new FlutterEngine(context.getApplicationContext());

                DartCallback callback = new DartCallback(context.getAssets(), FlutterMain.findAppBundlePath(context), callbackInfo);
                sBackgroundFlutterEngine.getDartExecutor().executeDartCallback(callback);
                sBackgroundChannel = new MethodChannel(sBackgroundFlutterEngine.getDartExecutor().getBinaryMessenger(), "flutter_radar_background");
            }
        }
    }
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        Radar.setReceiver(new RadarFlutterReceiver());
        mContext = binding.getApplicationContext();
        MethodChannel channel = new MethodChannel(binding.getFlutterEngine().getDartExecutor(), "flutter_radar");
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
                case "setAdIdEnabled":
                    // do nothing
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
                case "getMatrix":
                    getMatrix(call, result);
                    break;
                case "setForegroundServiceOptions":
                    setForegroundServiceOptions(call, result);
                    break;
                case "trackVerified":
                    trackVerified(call, result);
                    break;
                case "trackVerifiedToken":
                    trackVerifiedToken(call, result);
                    break;
                case "attachListeners":
                    attachListeners(call, result);
                    break;
                case "detachListeners":
                    detachListeners(call, result);
                    break;
                case "on":
                    on(call, result);
                    break;
                case "off":
                    off(call, result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        } catch (Error | Exception e) {
            result.error(e.toString(), e.getMessage(), e.getMessage());
        }
    }

    private void initialize(MethodCall call, Result result) {
        String publishableKey = call.argument("publishableKey");
        Radar.initialize(mContext, publishableKey);
        result.success(true);
    }

    private void setForegroundServiceOptions(MethodCall call, Result result) {
        HashMap foregroundServiceOptionsMap = (HashMap)call.arguments;
        JSONObject foregroundServiceOptionsJson = new JSONObject(foregroundServiceOptionsMap);
        RadarTrackingOptionsForegroundService options = RadarTrackingOptionsForegroundService.fromJson(foregroundServiceOptionsJson);
        Radar.setForegroundServiceOptions(options);
        result.success(true);
    }

    private void setLogLevel(MethodCall call, Result result) {
        String logLevel = call.argument("logLevel");
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

        boolean foreground = ActivityCompat.checkSelfPermission(mActivity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        if (Build.VERSION.SDK_INT >= 29) {
            if (foreground) {
                boolean background = ActivityCompat.checkSelfPermission(mActivity, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;
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
        boolean background = call.argument("background");
        mPermissionsRequestResult = result;
        if (mActivity != null) {
            if (Build.VERSION.SDK_INT >= 23) {
                if (background && Build.VERSION.SDK_INT >= 29) {
                    ActivityCompat.requestPermissions(mActivity, new String[] { Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_BACKGROUND_LOCATION }, PERMISSIONS_REQUEST_CODE);
                } else {
                    ActivityCompat.requestPermissions(mActivity, new String[] { Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION }, PERMISSIONS_REQUEST_CODE);
                }
            }
        }
    }

    private void setUserId(MethodCall call, Result result) {
        String userId = call.argument("userId");
        Radar.setUserId(userId);
        result.success(true);
    }

    private void getUserId(Result result) {
        String userId = Radar.getUserId();
        result.success(userId);
    }

    private void setDescription(MethodCall call, Result result) {
        String description = call.argument("description");
        Radar.setDescription(description);
        result.success(true);
    }

    private void getDescription(Result result) {
        String description = Radar.getDescription();
        result.success(description);
    }

    private void setMetadata(MethodCall call, Result result) {
        HashMap metadataMap = (HashMap)call.arguments;
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
        boolean enabled = call.argument("enabled");
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

        String accuracy = call.argument("accuracy");
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
            public void onComplete(final Radar.RadarStatus status, final Location location, final RadarEvent[] events, final RadarUser user) {
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
      
        if (call.hasArgument("location") && call.argument("location") != null) {
            HashMap locationMap = (HashMap)call.argument("location");
            Location location = locationForMap(locationMap);
            Radar.trackOnce(location, callback);
        } else {
            RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy accuracyLevel = RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.MEDIUM;
            boolean beaconsTrackingOption = false;
      
            if (call.hasArgument("desiredAccuracy") && call.argument("desiredAccuracy") != null) {
                String desiredAccuracy = ((String)call.argument("desiredAccuracy")).toLowerCase();
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
            if (call.hasArgument("beacons") && call.argument("beacons") != null) {
                beaconsTrackingOption = call.argument("beacons");
            }
      
            Radar.trackOnce(accuracyLevel, beaconsTrackingOption, callback);
        }
    }      

    private void startTracking(MethodCall call, Result result) {
        String preset = call.argument("preset");
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
        HashMap optionsMap = (HashMap)call.arguments;
        JSONObject optionsJson = new JSONObject(optionsMap);
        RadarTrackingOptions options = RadarTrackingOptions.fromJson(optionsJson);
        Radar.startTracking(options);
        result.success(true);
    }

    public void mockTracking(MethodCall call, final Result result) {
        HashMap originMap = (HashMap)call.argument("origin");
        Location origin = locationForMap(originMap);
        HashMap destinationMap = (HashMap)call.argument("destination");
        Location destination = locationForMap(destinationMap);
        String modeStr = call.argument("mode");
        Radar.RadarRouteMode mode = Radar.RadarRouteMode.CAR;
        if (modeStr.equals("FOOT") || modeStr.equals("foot")) {
            mode = Radar.RadarRouteMode.FOOT;
        } else if (modeStr.equals("BIKE") || modeStr.equals("bike")) {
            mode = Radar.RadarRouteMode.BIKE;
        } else if (modeStr.equals("CAR") || modeStr.equals("car")) {
            mode = Radar.RadarRouteMode.CAR;
        }
        int steps = call.hasArgument("steps") ? (int)call.argument("steps") : 10;
        int interval = call.hasArgument("interval") ? (int)call.argument("interval") : 1;

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
        HashMap tripOptionsMap = (HashMap)call.argument("tripOptions");
        JSONObject tripOptionsJson = jsonForMap(tripOptionsMap);
        RadarTripOptions tripOptions = RadarTripOptions.fromJson(tripOptionsJson);
        HashMap trackingOptionsMap = (HashMap)call.argument("trackingOptions");
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
        HashMap tripOptionsMap = (HashMap)call.argument("tripOptions");
        JSONObject tripOptionsJson = jsonForMap(tripOptionsMap);
        RadarTripOptions tripOptions = RadarTripOptions.fromJson(tripOptionsJson);
        String statusStr = call.argument("status");
        RadarTrip.RadarTripStatus status = RadarTrip.RadarTripStatus.UNKNOWN;
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
        HashMap<String,Object> map = new Gson().fromJson(tripOptions.toJson().toString(), HashMap.class);
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

    public void getContext(MethodCall call, final Result result) {
        Radar.RadarContextCallback callback = new Radar.RadarContextCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location, final RadarContext context) {
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

        if (call.hasArgument("location")) {
            HashMap locationMap = (HashMap)call.argument("location");
            Location location = locationForMap(locationMap);
            Radar.getContext(location, callback);
        } else {
            Radar.getContext(callback);
        }
    }

    private void searchGeofences(MethodCall call, final Result result) throws JSONException {
        Radar.RadarSearchGeofencesCallback callback = new Radar.RadarSearchGeofencesCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location, final RadarGeofence[] geofences) {
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
        if (call.hasArgument("near")) {
            HashMap nearMap = (HashMap)call.argument("near");
            near = locationForMap(nearMap);
        }
        int radius = call.hasArgument("radius") ? (int)call.argument("radius") : 1000;
        ArrayList tagsList = (ArrayList)call.argument("tags");
        String[] tags = (String[])tagsList.toArray(new String[0]);
        HashMap metadataMap = (HashMap)call.argument("metadata");
        JSONObject metadata = jsonForMap(metadataMap);
        int limit = call.hasArgument("limit") ? (int)call.argument("limit") : 10;

        if (near != null) {
            Radar.searchGeofences(near, radius, tags, metadata, limit, callback);
        } else {
            Radar.searchGeofences(radius, tags, metadata, limit, callback);
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
        if (call.hasArgument("near")) {
            HashMap nearMap = (HashMap)call.argument("near");
            near = locationForMap(nearMap);
        }
        int radius = call.hasArgument("radius") ? (int)call.argument("radius") : 1000;
        ArrayList chainsList = (ArrayList)call.argument("chains");
        String[] chains = (String[])chainsList.toArray(new String[0]);        
        Map<String, String> chainMetadata = (Map<String, String>)call.argument("chainMetadata");
        ArrayList categoriesList = (ArrayList)call.argument("categories");
        String[] categories = categoriesList != null ? (String[])categoriesList.toArray(new String[0]) : new String[0];
        ArrayList groupsList = (ArrayList)call.argument("groups");
        String[] groups = groupsList != null ? (String[])groupsList.toArray(new String[0]) : new String[0];
        int limit = call.hasArgument("limit") ? (int)call.argument("limit") : 10;

        if (near != null) {
            Radar.searchPlaces(near, radius, chains, chainMetadata, categories, groups, limit, callback);
        } else {
            Radar.searchPlaces(radius, chains, chainMetadata, categories, groups, limit, callback);
        }
    }

    public void autocomplete(MethodCall call, final Result result) {
        String query = call.argument("query");
        HashMap nearMap = (HashMap)call.argument("near");
        Location near = locationForMap(nearMap);
        int limit = call.hasArgument("limit") ? (int)call.argument("limit") : 10;
        String country = call.argument("country");
        ArrayList layersList = (ArrayList)call.argument("layers");
        String[] layers = layersList != null ? (String[])layersList.toArray(new String[0]) : new String[0];
        Boolean expandUnits = call.argument("expandUnits");

        Radar.autocomplete(query, near, layers, limit, country, expandUnits, new Radar.RadarGeocodeCallback() {
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
        String query = call.argument("query");

        Radar.geocode(query, new Radar.RadarGeocodeCallback() {
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

        if (call.hasArgument("location")) {
            HashMap locationMap = (HashMap)call.argument("location");
            Location location = locationForMap(locationMap);
            Radar.reverseGeocode(location, callback);
        } else {
            Radar.reverseGeocode(callback);
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
        if (call.hasArgument("origin")) {
            HashMap originMap = (HashMap)call.argument("origin");
            origin = locationForMap(originMap);
        }
        HashMap destinationMap = (HashMap)call.argument("destination");
        Location destination = locationForMap(destinationMap);
        EnumSet<Radar.RadarRouteMode> modes = EnumSet.noneOf(Radar.RadarRouteMode.class);
        ArrayList<String> modesList = call.argument("modes");
        String[] modesArr = (String[])(new String[0]);
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
        String unitsStr = call.argument("units");
        Radar.RadarRouteUnits units = unitsStr.equals("METRIC") || unitsStr.equals("metric") ? Radar.RadarRouteUnits.METRIC : Radar.RadarRouteUnits.IMPERIAL;

        if (origin != null) {
            Radar.getDistance(origin, destination, modes, units, callback);
        } else {
            Radar.getDistance(destination, modes, units, callback);
        }
    }

    public void logConversion(MethodCall call, final Result result) throws JSONException  {
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

        String name = call.argument("name");
        HashMap metadataMap= call.argument("metadata");
        JSONObject metadataJson = jsonForMap(metadataMap);        
        if (call.hasArgument("revenue") && call.argument("revenue") != null) {
            double revenue = (Double)call.argument("revenue");
            Radar.logConversion(name, revenue, metadataJson, callback);
        } else {
            Radar.logConversion(name, metadataJson, callback);
        }
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
        String modeStr = call.argument("mode");
        Radar.RadarRouteMode mode = Radar.RadarRouteMode.CAR;
        if (modeStr != null) {
            modeStr = modeStr.toLowerCase();
            if ( modeStr.equals("foot")) {
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
        String unitsStr = call.argument("units");
        Radar.RadarRouteUnits units = unitsStr != null && unitsStr.toLowerCase().equals("metric") ? Radar.RadarRouteUnits.METRIC : Radar.RadarRouteUnits.IMPERIAL;

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
        Radar.RadarTrackCallback callback = new Radar.RadarTrackCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final Location location, final RadarEvent[] events, final RadarUser user) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            obj.put("events", RadarEvent.toJson(events));
                            if ( user != null) {
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

        Radar.trackVerified(callback);
    }

    public void trackVerifiedToken(MethodCall call, final Result result) {
        Radar.RadarTrackTokenCallback callback = new Radar.RadarTrackTokenCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status, final String token) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            obj.put("token", token);

                            HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(map);
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        Radar.trackVerifiedToken(callback);
    }

    private void isUsingRemoteTrackingOptions(Result result) {
        Boolean isRemoteTracking = Radar.isUsingRemoteTrackingOptions();
        result.success(isRemoteTracking);
    }

    private Location locationForMap(HashMap locationMap) {
        double latitude = (Double)locationMap.get("latitude");
        double longitude = (Double)locationMap.get("longitude");
        Location location = new Location("RadarSDK");
        location.setLatitude(latitude);
        location.setLongitude(longitude);
        if (locationMap.containsKey("accuracy")) {
            double accuracyDouble = (Double)locationMap.get("accuracy");
            float accuracy = (float)accuracyDouble;
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

        @Override
        public void onEventsReceived(Context context, RadarEvent[] events, RadarUser user) {
            try {
                SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
                long callbackHandle = sharedPrefs.getLong("events", 0L);

                if (callbackHandle == 0L) {
                    return;
                }

                RadarFlutterPlugin.initializeBackgroundEngine(context);
                
                JSONObject obj = new JSONObject();
                obj.put("events", RadarEvent.toJson(events));
                obj.put("user", user.toJson());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                synchronized(lock) {
                    final ArrayList args = new ArrayList();
                    args.add(callbackHandle);
                    args.add(res);
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            sBackgroundChannel.invokeMethod("", args);
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
                SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
                long callbackHandle = sharedPrefs.getLong("location", 0L);

                if (callbackHandle == 0L) {
                    Log.e(TAG, "callback handle is empty");
                    return;
                }

                RadarFlutterPlugin.initializeBackgroundEngine(context);
                
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("user", user.toJson());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                synchronized(lock) {
                    final ArrayList args = new ArrayList();
                    args.add(callbackHandle);
                    args.add(res);
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            sBackgroundChannel.invokeMethod("", args);
                        }
                    });
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        public void onClientLocationUpdated(Context context, Location location, boolean stopped, Radar.RadarLocationSource source) {
            try {
                SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
                long callbackHandle = sharedPrefs.getLong("clientLocation", 0L);

                if (callbackHandle == 0L) {
                    return;
                }

                RadarFlutterPlugin.initializeBackgroundEngine(context);
                
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("stopped", stopped);
                obj.put("source", source.toString());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                synchronized(lock) {
                    final ArrayList args = new ArrayList();
                    args.add(callbackHandle);
                    args.add(res);
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            sBackgroundChannel.invokeMethod("", args);
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
                SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
                long callbackHandle = sharedPrefs.getLong("error", 0L);

                if (callbackHandle == 0L) {
                    return;
                }

                RadarFlutterPlugin.initializeBackgroundEngine(context);
                
                JSONObject obj = new JSONObject();
                obj.put("status", status.toString());

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                synchronized(lock) {
                    final ArrayList args = new ArrayList();
                    args.add(callbackHandle);
                    args.add(res);
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            sBackgroundChannel.invokeMethod("", args);
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
                SharedPreferences sharedPrefs = context.getSharedPreferences(TAG, Context.MODE_PRIVATE);
                long callbackHandle = sharedPrefs.getLong("log", 0L);

                if (callbackHandle == 0L) {
                    return;
                }

                RadarFlutterPlugin.initializeBackgroundEngine(context);
                
                JSONObject obj = new JSONObject();
                obj.put("message", message);

                HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
                synchronized(lock) {
                    final ArrayList args = new ArrayList();
                    args.add(callbackHandle);
                    args.add(res);
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            sBackgroundChannel.invokeMethod("", args);
                        }
                    });
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

    }

    public void attachListeners(MethodCall call, Result result) {
        SharedPreferences sharedPrefs = mContext.getSharedPreferences(TAG, Context.MODE_PRIVATE);
        long callbackDispatcherHandle = ((Number)call.argument("callbackDispatcherHandle")).longValue();
        sharedPrefs.edit().putLong(CALLBACK_DISPATCHER_HANDLE_KEY, callbackDispatcherHandle).commit();
        result.success(true);
    }

    public void detachListeners(MethodCall call, Result result) {
        SharedPreferences sharedPrefs = mContext.getSharedPreferences(TAG, Context.MODE_PRIVATE);
        long callbackDispatcherHandle = call.argument("callbackDispatcherHandle");
        sharedPrefs.edit().putLong(CALLBACK_DISPATCHER_HANDLE_KEY, 0L).commit();
        result.success(true);
    }

    public void on(MethodCall call, Result result) {
        SharedPreferences sharedPrefs = mContext.getSharedPreferences(TAG, Context.MODE_PRIVATE);
        String listener = call.argument("listener");
        long callbackHandle = ((Number)call.argument("callbackHandle")).longValue();
        sharedPrefs.edit().putLong(listener, callbackHandle).commit();
        result.success(true);
    }

    public void off(MethodCall call, Result result) {
        SharedPreferences sharedPrefs = mContext.getSharedPreferences(TAG, Context.MODE_PRIVATE);
        String listener = call.argument("listener");
        sharedPrefs.edit().putLong(listener, 0L).commit();
        result.success(true);
    }

};
