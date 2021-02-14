package com.bg.radar_flutter_plugin;

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

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

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

/** RadarFlutterPlugin */
public class RadarFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    public static MethodChannel channel;
    private Activity activity;
    private Registrar registrar;

    private Context applicationContext;
    // private BroadcastReceiver radarFlutterReceiver;

//    private void setContext(Context context) {
//        this.applicationContext = context;
//    }

   private Activity getActivity() {
       return registrar != null ? registrar.activity() : activity;
   }
//
//    private void setActivity(Activity activity) {
//        this.activity = activity;
//    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
//        setActivity(activityPluginBinding.getActivity());
        activity = activityPluginBinding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
        this.activity = activityPluginBinding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
    //    setActivity(null);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        // see https://github.com/FirebaseExtended/flutterfire/pull/2605
        channel.setMethodCallHandler(null);
        // applicationContext.unregisterReceiver(radarFlutterReceiver);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "radar_flutter_plugin");
        channel.setMethodCallHandler(this);
        applicationContext = flutterPluginBinding.getApplicationContext();
        // radarFlutterReceiver = new RadarFlutterReceiver();
        // IntentFilter filter = new IntentFilter();
        // filter.addAction("io.radar.sdk.RECEIVED");
        // applicationContext.registerReceiver(radarFlutterReceiver,filter);
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "radar_flutter_plugin");
        final RadarFlutterPlugin plugin = new RadarFlutterPlugin();
        channel.setMethodCallHandler(plugin);
        plugin.applicationContext = registrar.context();
        plugin.activity = registrar.activity();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        try {
            switch (call.method) {
                case "initialize":
                    initialize(call, result);
                    break;
                case "getPermissionsStatus":
                    getPermissionStatus(result);
                    break;
                case "setLogLevel":
                    setLogLevel(call, result);
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
                case "setMetadata":
                    setMetadata(call, result);
                    break;
                case "getDescription":
                    getDescription(result);
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
                case "getMetadata":
                    getMetadata(result);
                    break;
                case "searchGeofences":
                    searchGeofences(call,result);
                    break;
                case "searchPlaces":
                    searchPlaces(call,result);
                    break;
                case "searchPoints":
                    searchPoints(call,result);
                    break;  
                case "getContext":
                    getContext(call,result);
                    break;
                case "autocomplete":
                    autocomplete(call,result);
                    break; 
                case "forwardGeocode":
                    geocode(call,result);
                    break;
                case "reverseGeocode":
                    reverseGeocode(call,result);
                    break;
                case "ipGeocode":
                    ipGeocode(call,result);
                    break;
                case "getDistance":
                    getDistance(call,result);
                    break;
                case "startTrip":
                    startTrip(call,result);
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
                case "startForegroundService":
                    startForegroundService(call,result);
                    break;
                case "stopForegroundService":
                    stopForegroundService(call,result);
                    break;
                // case "mockTracking":
                //     mockTracking(call,result);
                //     break;
                default:
                    result.notImplemented();
                    break;
            }
        } catch (Error | JSONException e) {
            result.error(e.toString(), e.getMessage(), e.getCause());
        }
    }

    private void initialize(MethodCall call, Result result) {
        final String publishableKey = call.argument("publishableKey");
        Radar.initialize(applicationContext,publishableKey);
        result.success(true);
    }

    private void runOnMainThread(final Runnable runnable) {
        if (Looper.getMainLooper().getThread() == Thread.currentThread())
           runnable.run();
        else {
           Handler handler = new Handler(Looper.getMainLooper());
           handler.post(runnable);
        }
     }

    private void invokeMethodOnUiThread(final String methodName, final HashMap map) {
        final MethodChannel channel = this.channel;
        runOnMainThread(new Runnable() {
           @Override
           public void run() {
              channel.invokeMethod(methodName, map);
           }
        });
     }

    private void getPermissionStatus(Result result) {
        boolean foreground = ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        if (Build.VERSION.SDK_INT >= 29) {
            if (foreground) {
                boolean background = ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;
                result.success(background ? "GRANTED_BACKGROUND" : "GRANTED_FOREGROUND");
            } else {
                result.success("DENIED");
            }
        } else {
            result.success(foreground ? "GRANTED_BACKGROUND" : "DENIED");
        }
    }

    private void setLogLevel(MethodCall call, Result result) {
        final String level = call.argument("logLevel");
        switch (level) {
            case "DEBUG":
                Radar.setLogLevel(Radar.RadarLogLevel.DEBUG);
                break;
            case "ERROR":
                Radar.setLogLevel(Radar.RadarLogLevel.ERROR);
                break;
            case "INFO":
                Radar.setLogLevel(Radar.RadarLogLevel.INFO);
                break;
            case "WARNING":
                Radar.setLogLevel(Radar.RadarLogLevel.WARNING);
                break;
            default:
                Radar.setLogLevel(Radar.RadarLogLevel.NONE);
                break;
        }
        result.success(true);
    }

    private void requestPermissions(MethodCall call, Result result) {
        final Boolean background = call.argument("background");
        if (activity != null) {
            if (Build.VERSION.SDK_INT >= 23) {
                int requestCode = 0;
                if (background && Build.VERSION.SDK_INT >= 29) {
                    ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_BACKGROUND_LOCATION}, requestCode);
                } else {
                    ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, requestCode);
                }
            }
        }
        result.success(true);
    }

    private void setUserId(MethodCall call, Result result) {
        final String userId = call.argument("userId");
        Radar.setUserId(userId);
        result.success(true);
    }

    private void getUserId(Result result) {
        final String userId =  Radar.getUserId();
        result.success(userId);
    }

    private void setMetadata(MethodCall call, Result result) {
        final HashMap metadata = (HashMap) call.arguments;
        JSONObject jsonMetadata = new JSONObject(metadata);
        Radar.setMetadata(jsonMetadata);
        result.success(true);
    }

    private void setDescription(MethodCall call, Result result) {
        final String description = call.argument("description");
        Radar.setDescription(description);
        result.success(true);
    }

    private void getDescription(Result result) {
        final String currentDescription = Radar.getDescription();
        result.success(currentDescription);
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
                        HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                        result.success(hObj);
                    } catch (JSONException e) {
                        result.error("GET_LOCATION_ERROR", "An unexpected error happened during the location callback logic" + e.getMessage(), null);
                    }
                }
            });
        }
        };
        final String accuracy = call.argument("accuracy");
        if (accuracy != null) {
            switch (accuracy) {
                case "high":
                    Radar.getLocation(RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.HIGH,callback);
                    break;
                case "medium":
                    Radar.getLocation(RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.MEDIUM,callback);
                    break;
                case "low":
                    Radar.getLocation(RadarTrackingOptions.RadarTrackingOptionsDesiredAccuracy.LOW,callback);
                    break;
                default:
                    Radar.getLocation(callback);
                    break;
            }
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
                        JSONObject obj = new JSONObject();
                        try {
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            if (events != null) {
                                obj.put("events", RadarEvent.toJson(events));
                            }                                     if (events != null) {
                                obj.put("events", RadarEvent.toJson(events));
                            }
                            if (user != null) {
                                obj.put("user", user.toJson());
                            }
                        } catch (JSONException e) {
                            result.error("TRACK_ONCE_ERROR", "An unexpected error happened during the trackOnce callback logic" + e.getMessage(), null);
                        }
                        HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                        result.success(hObj);
                    }});
            }
        };
        if (call.hasArgument("location")) {
            final HashMap locationMap = (HashMap) call.argument("location");
            Location location = locationMapToLocation(locationMap,"RadarFlutterPlugin");
            Radar.trackOnce(location, callback);
        }
        else {
            Radar.trackOnce(callback);
        }
    }

    private void startTracking(MethodCall call, Result result) {
        final String preset = call.argument("preset");
        switch (preset) {
            case "efficient":
                Radar.startTracking(RadarTrackingOptions.EFFICIENT);
                break;
            case "continuous":
                Radar.startTracking(RadarTrackingOptions.CONTINUOUS);
                break;
            case "responsive":
                Radar.startTracking(RadarTrackingOptions.RESPONSIVE);
                break;
            default:
                Radar.startTracking(RadarTrackingOptions.RESPONSIVE);
                break;
        }
        result.success(true);
    }

    private void startTrackingCustom(MethodCall call, Result result) {
        final HashMap trackingOptions = (HashMap) call.arguments;
        JSONObject jsonTrackingOptions = new JSONObject(trackingOptions);
        RadarTrackingOptions options = RadarTrackingOptions.fromJson(jsonTrackingOptions);
        Radar.startTracking(options);
        result.success(true);
    }

    private void stopTracking(Result result) {
        Radar.stopTracking();
        result.success(true);
    }

    private void isTracking(Result result) {
        final Boolean isTracking = Radar.isTracking();
        result.success(isTracking);
    }

    private void getMetadata(Result result) {
        if (Radar.getMetadata() != null) {
            HashMap<String, Object> hObj = new Gson().fromJson(Radar.getMetadata().toString(), HashMap.class);
            result.success(hObj);
        } else {
            result.success(true);
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
                        HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                        result.success(hObj);
                    } catch (JSONException e) {
                        result.error("SEARCH_GEOFENCE_ERROR", "An unexpected error happened during the searchGeofences callback logic: " + e.getMessage(), null);
                    }
                }});
        };
    };
        Location near = null;
        if (call.argument("near") != null) {
            final HashMap locationMap = (HashMap) call.argument("near");
            near = locationMapToLocation(locationMap,"RadarFlutterPlugin");
        }
        JSONObject metadata = call.argument("metadata") != null ? getJsonFromMetadata((HashMap) call.argument("metadata")) : null;
        int radius = call.argument("radius") != null  ? (int) call.argument("radius") : 1000;
        String[] tags = new String[0];
        try {
            tags = call.argument("tags") != null ? strArrayForArrList((ArrayList) call.argument("tags")) : null;
        } catch (JSONException e) {
            e.printStackTrace();
        }
        int limit = call.argument("limit")  != null  ? (int) call.argument("limit") : 10;

        if (near != null) {
            Radar.searchGeofences(near, radius, tags, metadata, limit, callback);
        } else {
            Radar.searchGeofences(radius, tags, metadata, limit, callback);
        }
    }


    public void getContext(MethodCall call,final Result result) {
        Radar.RadarContextCallback callback = new Radar.RadarContextCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final Location location,final RadarContext context) {
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
                            HashMap<String, Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(hObj);

                        } catch (JSONException e) {
                            result.error("GET_CONTEXT_ERROR", "An unexpected error happened during the getContext callback logic: " + e.getMessage(), null);
                        }
                    }});
            }
        };
        Location location = null;
        if (call.hasArgument("near")) {
            final HashMap locationMap = (HashMap) call.argument("location");
            location = locationMapToLocation(locationMap,"RadarFlutterPlugin");
            Radar.getContext(location, callback);
        } else {
            Radar.getContext(callback);
        }
    }

    public void searchPlaces(MethodCall call,final Result result) {
        Radar.RadarSearchPlacesCallback callback = new Radar.RadarSearchPlacesCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final Location location,final RadarPlace[] places) {
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
                    HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                    result.success(hObj);
                } catch (JSONException e) {
                    result.error("SEARCH_PLACES_ERROR", "An unexpected error happened during the searchPlaces callback logic: " + e.getMessage(), null);
                }
            }});
            }
        };

        Location near = null;
        if (call.argument("near") != null) {
            final HashMap locationMap = (HashMap) call.argument("near");
            near = locationMapToLocation(locationMap,"RadarFlutterPlugin");
        }
        JSONObject metadata = call.argument("metadata") != null ? (JSONObject) call.argument("metadata") : null;
        int radius = call.argument("radius") != null ? (int) call.argument("radius") : 1000;
        int limit = 10;
        String[] chains = new String[0];
        String[] categories = new String[0];
        String[] groups = new String[0];
        try {
            limit = call.argument("limit") != null ? (int) call.argument("limit") : 10;
            chains = call.argument("chains") != null ? strArrayForArrList((ArrayList) call.argument("chains")) : null;
            categories = call.argument("categories") != null ? strArrayForArrList((ArrayList) call.argument("categories")) : null;
            groups = call.argument("groups") != null ? strArrayForArrList((ArrayList) call.argument("groups")) : null;
        } catch (JSONException e) {
            e.printStackTrace();
        }
        if (near != null) {
            Radar.searchPlaces(near, radius, chains, categories, groups, limit, callback);
        } else {
            Radar.searchPlaces(radius, chains, categories, groups, limit, callback);
        }
    }

    public void searchPoints(MethodCall call,final Result result) {
        Radar.RadarSearchPointsCallback callback = new Radar.RadarSearchPointsCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final Location location,final RadarPoint[] points) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (location != null) {
                                obj.put("location", Radar.jsonForLocation(location));
                            }
                            if (points != null) {
                                obj.put("points", RadarPoint.toJson(points));
                            }
                            HashMap<String, Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(hObj);
                        } catch (JSONException e) {
                            result.error("SEARCH_POINTS_ERROR", "An unexpected error happened during the searchPoints callback logic: " + e.getMessage(), null);
                        }
                    }});
            }
        };

        Location near = null;
        if (call.argument("near") != null) {
            final HashMap locationMap = (HashMap) call.argument("near");
            near = locationMapToLocation(locationMap,"RadarFlutterPlugin");
        }
        int radius = call.argument("radius") != null ? (int) call.argument("radius") : 1000;
        String[] tags = new String[0];
        try {
            tags = call.argument("tags") != null ? strArrayForArrList((ArrayList) call.argument("tags")) : null;
        } catch (JSONException e) {
            e.printStackTrace();
        }
        int limit = call.argument("limit") != null ? (int) call.argument("limit") : 10;

        if (near != null) {
            Radar.searchPoints(near, radius, tags, limit, callback);
        } else {
            Radar.searchPoints(radius, tags, limit, callback);
        }
    }

    public void autocomplete(MethodCall call,final Result result) {
        String query = call.argument("query");
        Location near = null;
        if (call.argument("near") != null) {
            final HashMap locationMap = (HashMap) call.argument("near");
            near = locationMapToLocation(locationMap,"RadarFlutterPlugin");
        }
        int limit = call.argument("limit") != null ? (int) call.argument("limit") : 10;

        Radar.autocomplete(query, near, limit, new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }
                            HashMap<String, Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(hObj);
                        } catch (JSONException e) {
                            result.error("autocomplete", "An unexpected error happened during the autocomplete callback logic: " + e.getMessage(), null);
                        }
                    }});
            }
        });
    }

    public void geocode(MethodCall call,final Result result) {
        String query = call.argument("query");

        Radar.geocode(query, new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }
                            HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(hObj);
                        } catch (JSONException e) {
                            result.error("geocode", "An unexpected error happened during the geocode callback logic: " + e.getMessage(), null);
                        }
                    }
                });
            }
        });
    }

    public void reverseGeocode(MethodCall call,final Result result) {
        Radar.RadarGeocodeCallback callback = new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }
                            HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(hObj);
                        } catch (JSONException e) {
                            result.error("geocode", "An unexpected error happened during the reverse geocode callback logic: " + e.getMessage(), null);
                        }
                    }
                });
            }
        };
        Location location = null;
        if (call.argument("location") != null) {
            final HashMap locationMap = (HashMap) call.argument("location");
            location = locationMapToLocation(locationMap,"RadarFlutterPlugin");
            Radar.reverseGeocode(location, callback);
        } else {
            Radar.reverseGeocode(callback);
        }
    }

    public void ipGeocode(MethodCall call,final Result result) {
        Radar.ipGeocode(new Radar.RadarIpGeocodeCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final RadarAddress address,final boolean proxy) {
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
                            HashMap<String, Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(hObj);
                        } catch (JSONException e) {
                            result.error("geocode", "An unexpected error happened during the ip geocode callback logic: " + e.getMessage(), null);
                        }
                    }});
            }
        });
    }

    public void getDistance(MethodCall call,final Result result) throws JSONException {
        Radar.RadarRouteCallback callback = new Radar.RadarRouteCallback() {
            @Override
            public void onComplete(final Radar.RadarStatus status,final RadarRoutes routes) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (routes != null) {
                                obj.put("routes", routes.toJson());
                            }
                            HashMap<String, Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                            result.success(hObj);
                        } catch (JSONException e) {
                            result.error("geocode", "An unexpected error happened during the ip geocode callback logic: " + e.getMessage(), null);
                        }
                    }});
            }
        };

        Location origin = null;
        Location destination = null;
        if (call.argument("origin") != null) {
            final HashMap locationMap = (HashMap) call.argument("origin");
            origin = locationMapToLocation(locationMap,"RadarFlutterPluginOrigin");
        }
        if (call.argument("destination") != null) {
            final HashMap locationMap = (HashMap) call.argument("destination");
            destination = locationMapToLocation(locationMap,"RadarFlutterPluginDestination");
        }
        EnumSet<Radar.RadarRouteMode> modes = EnumSet.noneOf(Radar.RadarRouteMode.class);
        ArrayList<String> modesArrayList = call.argument("modes");
        String[] modesList = strArrayForArrList((ArrayList) modesArrayList);
        for (String modeStr : modesList) {
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

    public void startTrip(MethodCall call,Result result) {
        final HashMap tripOptionsMap = (HashMap) call.arguments;
        // only works for Map<String, String>
        // JSONObject jsonTripOptions = new JSONObject(tripOptionsMap);
        // RadarTripOptions options = RadarTripOptions.fromJson(jsonTripOptions);
        JSONObject tripOptionsJson = null;
        try {
            tripOptionsJson = getJsonFromTripOptionsMap(tripOptionsMap);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        RadarTripOptions options = RadarTripOptions.fromJson(tripOptionsJson);
        Radar.startTrip(options);
        result.success(true);
    }

    public void getTripOptions(Result result) {
        RadarTripOptions options = Radar.getTripOptions();
        HashMap<String,Object> hObj = new Gson().fromJson(options.toJson().toString(), HashMap.class);
        result.success(hObj);
    }

    public void completeTrip(Result result) {
        Radar.completeTrip();
        result.success(true);
    }

    public void cancelTrip(Result result) {
        Radar.cancelTrip();
        result.success(true);
    }

    public void startForegroundService(MethodCall call, Result result) {
        if (Build.VERSION.SDK_INT >= 26) {
            Intent intent = new Intent(activity, RadarForegroundService.class);
            final String title = call.argument("title");
            final String text = call.argument("text");
            final String icon = call.argument("icon");
            final String importance = call.argument("importance");
            final String id = call.argument("id");
            intent.setAction("start");
            intent.putExtra("title", title)
                .putExtra("text", text)
                .putExtra("icon", icon)
                .putExtra("importance", importance)
                .putExtra("id", id)
                .putExtra("activity", activity.getClass().getCanonicalName());
            applicationContext.startForegroundService(intent);
            result.success(true);
        }
    }

    public void stopForegroundService(MethodCall call, Result result) throws JSONException {
        if (Build.VERSION.SDK_INT >= 26) {
            Intent intent = new Intent(activity, RadarForegroundService.class);
            intent.setAction("stop");
            applicationContext.startService(intent);
            result.success(true);
        }
    }

    // public void mockTracking(MethodCall call,final Result result) {

    //     final HashMap originMap = (HashMap) call.argument("origin");
    //     Location origin = locationMapToLocation(originMap,"RadarFlutterPluginOrigin");
    //     final HashMap destinationMap = (HashMap) call.argument("destination");
    //     Location destination = locationMapToLocation(destinationMap,"RadarFlutterPluginDesitnation");    
    //     String modeStr = call.argument("mode");
    //     Radar.RadarRouteMode mode = Radar.RadarRouteMode.CAR;
    //     if (modeStr.equals("FOOT") || modeStr.equals("foot")) {
    //         mode = Radar.RadarRouteMode.FOOT;
    //     } else if (modeStr.equals("BIKE") || modeStr.equals("bike")) {
    //         mode = Radar.RadarRouteMode.BIKE;
    //     } else if (modeStr.equals("CAR") || modeStr.equals("car")) {
    //         mode = Radar.RadarRouteMode.CAR;
    //     }
    //     int steps = call.argument("steps") != null ? (int) call.argument("steps") : 10;
    //     int interval = call.argument("interval") != null ? (int) call.argument("interval") : 1;

    //     Radar.mockTracking(origin, destination, mode, steps, interval, new Radar.RadarTrackCallback() {
    //         @Override
    //         public void onComplete(Radar.RadarStatus status, Location location, RadarEvent[] events, RadarUser user) {
    //             try {
    //                 JSONObject obj = new JSONObject();
    //                 obj.put("status", status.toString());
    //                 if (location != null) {
    //                     obj.put("location", Radar.jsonForLocation(location));
    //                 }
    //                 if (events != null) {
    //                     obj.put("events", RadarEvent.toJson(events));
    //                 }
    //                 if (user != null) {
    //                     obj.put("user", user.toJson());
    //                 }
    //                 result.success(obj);
    //             } catch (JSONException e) {
    //                 result.error("mock tracking", "An unexpected error happened during the mock tracking callback logic: " + e.getMessage(), null);
    //             }
    //         }
    //     });
    // }

    private Location locationMapToLocation(HashMap locationMap, String locationName) {
        double latitude = (Double) locationMap.get("latitude");
        double longitude = (Double) locationMap.get("longitude");
        Location location = new Location(locationName);
        location.setLatitude(latitude);
        location.setLongitude(longitude);
        double accuracy;
        if (locationMap.containsKey("accuracy")) {
            accuracy = (Double) locationMap.get("accuracy");
            float fAccuracy = (float)accuracy;
            location.setAccuracy(fAccuracy);
        }
        return location;
    }

    private JSONObject getJsonFromTripOptionsMap(HashMap map) throws JSONException {
        JSONObject jsonData = new JSONObject();
        try {
            jsonData.put("destinationGeofenceExternalId",map.get("destinationGeofenceExternalId"));
            jsonData.put("destinationGeofenceTag",map.get("destinationGeofenceTag"));
            jsonData.put("externalId",map.get("externalId"));
            if (map.containsKey("metadata")) {
                JSONObject jsonMetadata = new JSONObject();
                Map<String, Object> metadata = (Map<String, Object>) map.get("metadata");
                for (String key : metadata.keySet()) {
                    Object value = metadata.get(key);
                    jsonMetadata.put(key, value);
                }
                jsonData.put("metadata",jsonMetadata);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonData;
    }

    private JSONObject getJsonFromMetadata(HashMap metadata) throws JSONException {
        JSONObject jsonMetadata = new JSONObject();
        try {
            for (Object key : metadata.keySet()) {
                String keyString = String.valueOf(key);
                Object value = metadata.get(keyString);
                jsonMetadata.put(keyString, value);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonMetadata;
    }

    private static String[] strArrayForArrList(ArrayList arrList) throws JSONException {
        // if (arrList == null) {
        //     return null;
        // }

        // String[] arr = new String[arrList.size()];
        // for (int i = 0; i < arr.length; i++) {
        //     arr[i] = arrList.optString(i);
        // }
        // return arr;
        String[] stringArray = (String[]) arrList.toArray(new String[0]);
        return stringArray;
    }

    public static class RadarFlutterReceiver extends RadarReceiver {
        @Override
        public void onEventsReceived(Context context, RadarEvent[] events, RadarUser user) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("events", RadarEvent.toJson(events));
                obj.put("user", user.toJson());
                HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                RadarFlutterPlugin.channel.invokeMethod("onEvents",hObj);
            } catch (JSONException e) {
                Log.d("RadarFlutterPlugin", "Error in client location handling: " + e.getMessage());
            }
//            invokeMethodOnUiThread("clientLocation",hObj);
//            this.channel.invokeMethod("clientLocation",hObj);
        }
    
        public void onClientLocationUpdated(Context context, Location location, boolean stopped, Radar.RadarLocationSource locationSource) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("stopped", stopped);
                obj.put("locationSource", locationSource.name());
                HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                RadarFlutterPlugin.channel.invokeMethod("onClientLocation",hObj);
            } catch (JSONException e) {
                Log.d("RadarFlutterPlugin", "Error in client location handling: "  + e.getMessage());
            }
//            invokeMethodOnUiThread("clientLocation",hObj);
//            this.channel.invokeMethod("clientLocation",hObj);
        }
    
        @Override
        public void onLocationUpdated(Context context, Location location, RadarUser user) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("user", user.toJson());
                HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                RadarFlutterPlugin.channel.invokeMethod("onLocation",hObj);
            } catch (JSONException e) {
                Log.d("RadarFlutterPlugin", "Error in location handling: "  + e.getMessage());
            }
        }
    
        @Override
        public void onError(Context context, Radar.RadarStatus status) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("status", status.toString());
                HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                RadarFlutterPlugin.channel.invokeMethod("onError",hObj);
            } catch (JSONException e) {
                Log.d("RadarFlutterPlugin", "Error in error handling:  "  + e.getMessage());
            }
        }
    
        @Override
        public void onLog(Context context,String message) {
            try {
                JSONObject obj = new JSONObject();
                obj.put("message", message);
                HashMap<String,Object> hObj = new Gson().fromJson(obj.toString(), HashMap.class);
                RadarFlutterPlugin.channel.invokeMethod("onLog",hObj);
            } catch (JSONException e) {
                Log.d("RadarFlutterPlugin", "Error in log handling:  "  + e.getMessage());
            }
        }
    }

};