package io.radar.flutter;

import android.Manifest;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Build;
import android.os.Looper;
import android.os.Handler;
import android.util.Log;

import com.google.gson.Gson;

import org.json.JSONException;
import org.json.JSONObject;

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
import io.radar.sdk.model.RadarPoint;
import io.radar.sdk.model.RadarRoutes;
import io.radar.sdk.model.RadarUser;

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

    private static final int PERMISSIONS_REQUEST_CODE = 20160525;
    private Result mPermissionsRequestResult;
    
    private static void initializeBackgroundEngine(Context context) {
        FlutterMain.startInitialization(context.getApplicationContext());
        FlutterMain.ensureInitializationComplete(context.getApplicationContext(), null);

        if (sBackgroundFlutterEngine == null) {
            sBackgroundFlutterEngine = new FlutterEngine(context);
            initializeEventChannels(sBackgroundFlutterEngine.getDartExecutor());
        }
    }

    private static void initializeEventChannels(BinaryMessenger messenger) {
        sEventsChannel = new EventChannel(messenger, "flutter_radar/events");
        sEventsChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object listener, EventChannel.EventSink eventSink) {
                sEventsSink = eventSink;
            }

            @Override
            public void onCancel(Object listener) {
                sEventsSink = null;
            }
        });

        sLocationChannel = new EventChannel(messenger, "flutter_radar/location");
        sLocationChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object listener, EventChannel.EventSink eventSink) {
                sLocationSink = eventSink;
            }

            @Override
            public void onCancel(Object listener) {
                sLocationSink = null;
            }
        });

        sClientLocationChannel = new EventChannel(messenger, "flutter_radar/clientLocation");
        sClientLocationChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object listener, EventChannel.EventSink eventSink) {
                sClientLocationSink = eventSink;
            }

            @Override
            public void onCancel(Object listener) {
                sClientLocationSink = null;
            }
        });

        sErrorChannel = new EventChannel(messenger, "flutter_radar/error");
        sErrorChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object listener, EventChannel.EventSink eventSink) {
                sErrorSink = eventSink;
            }

            @Override
            public void onCancel(Object listener) {
                sErrorSink = null;
            }
        });

        sLogChannel = new EventChannel(messenger, "flutter_radar/log");
        sLogChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object listener, EventChannel.EventSink eventSink) {
                sLogSink = eventSink;
            }

            @Override
            public void onCancel(Object listener) {
                sLogSink = null;
            }
        });
    }
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        mContext = binding.getApplicationContext();
        MethodChannel channel = new MethodChannel(binding.getFlutterEngine().getDartExecutor(), "flutter_radar");
        channel.setMethodCallHandler(this);
        initializeEventChannels(binding.getFlutterEngine().getDartExecutor());
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
        binding.removeRequestPermissionsResultListener(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        mActivity = null;
        binding.removeRequestPermissionsResultListener(this);
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
        
        initializeEventChannels(registrar.messenger());
    }

    private void runOnMainThread(final Runnable runnable) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(runnable);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == PERMISSIONS_REQUEST_CODE && mPermissionsRequestResult != null) {
            getPermissionsStatus(mPermissionsRequestResult);
            mPermissionsRequestResult = null;
        }
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
                case "mockTracking":
                    mockTracking(call, result);
                    break;
                case "startTrip":
                    startTrip(call, result);
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
                case "startForegroundService":
                    startForegroundService(call, result);
                    break;
                case "stopForegroundService":
                    stopForegroundService(call, result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        } catch (Error | JSONException e) {
            result.error(e.toString(), e.getMessage(), e.getStackTrace());
        }
    }

    private void initialize(MethodCall call, Result result) {
        String publishableKey = call.argument("publishableKey");
        Radar.initialize(mContext, publishableKey);
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
        if (mActivity == null) {
            result(status);

            return;
        }

        boolean foreground = ActivityCompat.checkSelfPermission(mActivity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        boolean denied = !foreground && !ActivityCompat.shouldShowRequestPermissionRationale(mActivity, Manifest.permission.ACCESS_FINE_LOCATION);
        if (denied) {
            status = "DENIED";
        }
        if (foreground) {
            status = "GRANTED_FOREGROUND";
        }
        if (Build.VERSION.SDK_INT >= 29) {
            boolean background = ActivityCompat.checkSelfPermission(mActivity, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;
            if (background) {
                status = "GRANTED_BACKGROUND";
            }
        } else if (foreground) {
            status = "GRANTED_BACKGROUND";
        }
        result(status);
    }

    private void requestPermissions(MethodCall call, Result result) {
        boolean background = call.argument("background");
        mPermissionsRequestResult = result;
        if (mActivity != null) {
            if (Build.VERSION.SDK_INT >= 23) {
                if (background && Build.VERSION.SDK_INT >= 29) {
                    ActivityCompat.requestPermissions(mActivity, new String[] { Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_BACKGROUND_LOCATION }, PERMISSIONS_REQUEST_CODE);
                } else {
                    ActivityCompat.requestPermissions(mActivity, new String[] { Manifest.permission.ACCESS_FINE_LOCATION }, PERMISSIONS_REQUEST_CODE);
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
                        }
                    }
                });
            }
        };

        if (call.hasArgument("location")) {
            HashMap locationMap = (HashMap)call.argument("location");
            Location location = locationForMap(locationMap);
            Radar.trackOnce(location, callback);
        } else {
            Radar.trackOnce(callback);
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

    public void startTrip(MethodCall call, Result result) throws JSONException {
        HashMap tripOptionsMap = (HashMap)call.arguments;
        JSONObject tripOptionsJson = jsonForMap(tripOptionsMap);
        RadarTripOptions tripOptions = RadarTripOptions.fromJson(tripOptionsJson);
        Radar.startTrip(tripOptions);
        result.success(true);
    }

    public void getTripOptions(Result result) {
        RadarTripOptions tripOptions = Radar.getTripOptions();
        HashMap<String,Object> map = new Gson().fromJson(tripOptions.toJson().toString(), HashMap.class);
        result.success(map);
    }

    public void completeTrip(Result result) {
        Radar.completeTrip();
        result.success(true);
    }

    public void cancelTrip(Result result) {
        Radar.cancelTrip();
        result.success(true);
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
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
        ArrayList categoriesList = (ArrayList)call.argument("categories");
        String[] categories = (String[])categoriesList.toArray(new String[0]);
        ArrayList groupsList = (ArrayList)call.argument("groups");
        String[] groups = (String[])groupsList.toArray(new String[0]);
        int limit = call.hasArgument("limit") ? (int)call.argument("limit") : 10;

        if (near != null) {
            Radar.searchPlaces(near, radius, chains, categories, groups, limit, callback);
        } else {
            Radar.searchPlaces(radius, chains, categories, groups, limit, callback);
        }
    }

    public void autocomplete(MethodCall call, final Result result) {
        String query = call.argument("query");
        HashMap nearMap = (HashMap)call.argument("near");
        Location near = locationForMap(nearMap);
        int limit = call.hasArgument("limit") ? (int)call.argument("limit") : 10;

        Radar.autocomplete(query, near, limit, new Radar.RadarGeocodeCallback() {
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
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
                        } catch (JSONException e) {
                            result.error("geocode", "An unexpected error happened during the reverse geocode callback logic: " + e.getMessage(), null);
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
                        } catch (JSONException e) {
                            result.error(e.toString(), e.getMessage(), e.getStackTrace());
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
                        } catch (JSONException e) {
                            result.error("geocode", "An unexpected error happened during the ip geocode callback logic: " + e.getMessage(), null);
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

    public void startForegroundService(MethodCall call, Result result) {
        if (mActivity == null) {
            return;
        }

        if (Build.VERSION.SDK_INT >= 26) {
            Intent intent = new Intent(mActivity, RadarForegroundService.class);
            String title = call.argument("title");
            String text = call.argument("text");
            String icon = call.argument("icon");
            String importance = call.argument("importance");
            String id = call.argument("id");
            intent.setAction("start");
            intent.putExtra("title", title)
                .putExtra("text", text)
                .putExtra("icon", icon)
                .putExtra("importance", importance)
                .putExtra("id", id)
                .putExtra("activity", mActivity.getClass().getCanonicalName());
            mContext.startForegroundService(intent);
            result.success(true);
        }
    }

    public void stopForegroundService(MethodCall call, Result result) throws JSONException {
        if (mActivity == null) {
            return;
        }

        if (Build.VERSION.SDK_INT >= 26) {
            Intent intent = new Intent(mActivity, RadarForegroundService.class);
            intent.setAction("stop");
            mContext.startService(intent);
            result.success(true);
        }
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
        } catch (JSONException e) {
            Log.e("RadarFlutterPlugin", e.toString());
        }
        return obj;
    }

    public static class RadarFlutterReceiver extends RadarReceiver {

        @Override
        public void onEventsReceived(Context context, RadarEvent[] events, RadarUser user) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("events", RadarEvent.toJson(events));
                obj.put("user", user.toJson());

                HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                if (sEventsSink != null) {
                    sEventsSink.success(map);
                }
            } catch (JSONException e) {
                Log.e("RadarFlutterPlugin", e.toString());
            }
        }
    
        @Override
        public void onLocationUpdated(Context context, Location location, RadarUser user) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("user", user.toJson());

                HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                if (sLocationSink != null) {
                    sLocationSink.success(map);
                }
            } catch (JSONException e) {
                Log.e("RadarFlutterPlugin", e.toString());
            }
        }

        public void onClientLocationUpdated(Context context, Location location, boolean stopped, Radar.RadarLocationSource source) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("stopped", stopped);
                obj.put("source", source.toString());

                HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                if (sClientLocationSink != null) {
                    sClientLocationSink.success(map);
                }
            } catch (JSONException e) {
                Log.e("RadarFlutterPlugin", e.toString());
            }
        }
    
        @Override
        public void onError(Context context, Radar.RadarStatus status) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("status", status.toString());

                HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                if (sErrorSink != null) {
                    sErrorSink.success(map);
                }
            } catch (JSONException e) {
                Log.e("RadarFlutterPlugin", e.toString());
            }
        }
    
        @Override
        public void onLog(Context context, String message) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);
            
            try {
                JSONObject obj = new JSONObject();
                obj.put("message", message);

                HashMap<String, Object> map = new Gson().fromJson(obj.toString(), HashMap.class);
                if (sLogSink != null) {
                    sLogSink.success(map);
                }
            } catch (JSONException e) {
                Log.e("RadarFlutterPlugin", e.toString());
            }
        }

    }

};