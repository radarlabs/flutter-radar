package io.radar.flutter;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.gson.Gson;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;

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
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;
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
import io.radar.sdk.model.RadarRouteMatrix;
import io.radar.sdk.model.RadarRoutes;
import io.radar.sdk.model.RadarUser;

@SuppressWarnings("rawtypes")
public class RadarFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, RequestPermissionsResultListener {

    private static final String[] STRING_ARRAY = new String[0];
    private static final String TAG = "RadarFlutterPlugin";
    private static final RadarFlutterReceiver sReceiver = new RadarFlutterReceiver();
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
        MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_radar");
        channel.setMethodCallHandler(this);
        initializeEventChannels(binding.getBinaryMessenger());
        initializeFromResourceString(mContext);
    }

    private static void initializeFromResourceString(Context context) {
        String publishableKey = context.getString(R.string.radar_publishableKey);
        if (publishableKey == null || TextUtils.isEmpty(publishableKey)) {
            boolean ignoreWarning = context.getResources().getBoolean(R.bool.ignore_radar_initialize_warning);
            if (!ignoreWarning) {
                Log.w(TAG, "Radar could not initialize. Did you set string 'radar_publishableKey' in strings.xml?");
            }
        } else {
            Radar.initialize(context, publishableKey, sReceiver);
        }
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

        initializeEventChannels(registrar.messenger());
        initializeFromResourceString(plugin.mContext);
    }

    /**
     * Initialize the Radar SDK using
     * @param context
     */
    public static void initialize(Context context) {
        initializeFromResourceString(context);
    }

    public static void initialize(Context context, String publishableKey) {
        Radar.initialize(context, publishableKey, sReceiver);
    }

    private void runOnMainThread(final Runnable runnable) {
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
                case "getMatrix":
                    getMatrix(call, result);
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
        } catch (Error | Exception e) {
            result.error(e.toString(), e.getMessage(), e.getMessage());
        }
    }

    private void initialize(MethodCall call, Result result) {
        String publishableKey = call.argument("publishableKey");
        Radar.initialize(mContext, publishableKey, sReceiver);
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
            if (result != null) {
                result.success(status);
            }
            return;
        }
        if (ContextCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_DENIED
                && ActivityCompat.shouldShowRequestPermissionRationale(mActivity, Manifest.permission.ACCESS_FINE_LOCATION)
                || ContextCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_DENIED
                && ActivityCompat.shouldShowRequestPermissionRationale(mActivity, Manifest.permission.ACCESS_COARSE_LOCATION)) {
            status = "DENIED";
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                ContextCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            status = "GRANTED_BACKGROUND";
        } else if (ContextCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(mContext, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            status = "GRANTED_FOREGROUND";
        }

        result.success(status);
    }

    private void requestPermissions(MethodCall call, Result result) {
        Boolean background = call.argument("background");
        mPermissionsRequestResult = result;
        if (mActivity != null) {
            if (Build.VERSION.SDK_INT >= 23) {
                if (Boolean.TRUE == background && Build.VERSION.SDK_INT >= 29) {
                    ActivityCompat.requestPermissions(mActivity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_BACKGROUND_LOCATION}, PERMISSIONS_REQUEST_CODE);
                } else {
                    ActivityCompat.requestPermissions(mActivity, new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, PERMISSIONS_REQUEST_CODE);
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

    private void getLocation(MethodCall call, final Result result) {
        Radar.RadarLocationCallback callback = new Radar.RadarLocationCallback() {
            @Override
            public void onComplete(@NonNull final Radar.RadarStatus status, final Location location, final boolean stopped) {
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

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
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
            public void onComplete(@NonNull final Radar.RadarStatus status,
                                   final Location location,
                                   final RadarEvent[] events,
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

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        HashMap locationMap = call.argument("location");
        if (locationMap != null) {
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
        HashMap optionsMap = (HashMap) call.arguments;
        JSONObject optionsJson = new JSONObject(optionsMap);
        RadarTrackingOptions options = RadarTrackingOptions.fromJson(optionsJson);
        Radar.startTracking(options);
        result.success(true);
    }

    @NonNull
    private Radar.RadarRouteUnits getUnits(String unitsStr) {
        if ("metric".equalsIgnoreCase(unitsStr)) {
            return Radar.RadarRouteUnits.METRIC;
        }
        return Radar.RadarRouteUnits.IMPERIAL;
    }

    @NonNull
    private Radar.RadarRouteMode getMode(String modeStr) {
        if (modeStr == null) {
            return Radar.RadarRouteMode.CAR;
        }
        switch (modeStr) {
            case "FOOT":
            case "foot":
                return Radar.RadarRouteMode.FOOT;
            case "BIKE":
            case "bike":
                return Radar.RadarRouteMode.BIKE;
            case "CAR":
            case "car":
                return Radar.RadarRouteMode.CAR;
            default:
                Log.w(TAG, "No mode for string " + modeStr);
                return Radar.RadarRouteMode.CAR;
        }
    }

    public void mockTracking(MethodCall call, final Result result) {
        HashMap originMap = call.argument("origin");
        HashMap destinationMap = call.argument("destination");
        if (originMap == null || destinationMap == null) {
            result.error(Radar.RadarStatus.ERROR_BAD_REQUEST.name(), null, null);
            return;
        }
        Location origin = locationForMap(originMap);
        Location destination = locationForMap(destinationMap);
        String modeStr = call.argument("mode");
        Radar.RadarRouteMode mode = getMode(modeStr);
        Integer steps = call.argument("steps");
        Integer interval = call.argument("interval");

        Radar.mockTracking(origin, destination, mode, steps == null ? 10 : steps, interval == null ? 1 : interval, (Radar.RadarTrackCallback) null);
        result.success(null);
    }

    private void stopTracking(Result result) {
        Radar.stopTracking();
        result.success(true);
    }

    private void isTracking(Result result) {
        Boolean isTracking = Radar.isTracking();
        result.success(isTracking);
    }

    public void getMatrix(MethodCall call, Result result) throws JSONException {
        ArrayList origins = call.argument("origins");
        ArrayList destinations = call.argument("destinations");
        String modeStr = call.argument("mode");
        String unitsStr = call.argument("units");
        if (origins == null || destinations == null || modeStr == null || unitsStr == null) {
            result.error(Radar.RadarStatus.ERROR_BAD_REQUEST.name(), null, null);
        } else {
            Location[] originsArray = new Location[origins.size()];
            for (int i = 0; i < originsArray.length; i++) {
                originsArray[i] = locationForMap((HashMap) origins.get(i));
            }
            Location[] destinationsArray = new Location[destinations.size()];
            for (int i = 0; i < destinationsArray.length; i++) {
                destinationsArray[i] = locationForMap((HashMap) destinations.get(i));
            }
            Radar.RadarRouteMode mode = getMode(modeStr);
            Radar.RadarRouteUnits units = getUnits(unitsStr);
            Radar.getMatrix(originsArray, destinationsArray, mode, units, new Radar.RadarMatrixCallback() {
                @Override
                public void onComplete(@NonNull Radar.RadarStatus radarStatus,
                                       @Nullable RadarRouteMatrix radarRouteMatrix) {
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            try {
                                JSONObject obj = new JSONObject();
                                obj.put("status", radarStatus.toString());
                                if (radarRouteMatrix != null) {
                                    obj.put("matrix", radarRouteMatrix.toJson());
                                }

                                result.success(new Gson().fromJson(obj.toString(), HashMap.class));
                            } catch (Exception e) {
                                result.error(e.toString(), e.getMessage(), e.getMessage());
                            }
                        }
                    });
                }
            });
        }
    }

    public void startTrip(MethodCall call, Result result) throws JSONException {
        HashMap tripOptionsMap = (HashMap) call.arguments;
        JSONObject tripOptionsJson = jsonForMap(tripOptionsMap);
        RadarTripOptions tripOptions = RadarTripOptions.fromJson(tripOptionsJson);
        Radar.startTrip(tripOptions, (Radar.RadarTripCallback) null);
        result.success(true);
    }

    public void getTripOptions(Result result) {
        RadarTripOptions tripOptions = Radar.getTripOptions();
        if (tripOptions == null) {
            result.success(null);
        } else {
            result.success(new Gson().fromJson(tripOptions.toJson().toString(), HashMap.class));
        }
    }

    public void completeTrip(Result result) {
        Radar.completeTrip((Radar.RadarTripCallback) null);
        result.success(true);
    }

    public void cancelTrip(Result result) {
        Radar.cancelTrip((Radar.RadarTripCallback) null);
        result.success(true);
    }

    public void getContext(MethodCall call, final Result result) {
        Radar.RadarContextCallback callback = new Radar.RadarContextCallback() {
            @Override
            public void onComplete(@NonNull final Radar.RadarStatus status, final Location location, final RadarContext context) {
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

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        HashMap locationMap = call.argument("location");
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
            public void onComplete(@NonNull final Radar.RadarStatus status, final Location location, final RadarGeofence[] geofences) {
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

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        Location near = null;
        HashMap nearMap = call.argument("near");
        if (nearMap != null) {
            near = locationForMap(nearMap);
        }
        Integer radius = call.argument("radius");
        ArrayList<String> tagsList = call.argument("tags");

        String[] tags = tagsList == null ? STRING_ARRAY : tagsList.toArray(STRING_ARRAY);
        HashMap metadataMap = call.argument("metadata");
        JSONObject metadata = jsonForMap(metadataMap);
        Integer limit = call.argument("limit");

        if (near != null) {
            Radar.searchGeofences(near, radius == null ? 1000 : radius, tags, metadata, limit == null ? 10 : limit, callback);
        } else {
            Radar.searchGeofences(radius == null ? 1000 : radius, tags, metadata, limit == null ? 10 : limit, callback);
        }
    }

    public void searchPlaces(MethodCall call, final Result result) {
        Radar.RadarSearchPlacesCallback callback = new Radar.RadarSearchPlacesCallback() {
            @Override
            public void onComplete(@NonNull final Radar.RadarStatus status, final Location location, final RadarPlace[] places) {
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

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        Location near = null;
        HashMap nearMap = call.argument("near");
        if (nearMap != null) {
            near = locationForMap(nearMap);
        }
        Integer radius = call.argument("radius");
        ArrayList<String> chainsList = call.argument("chains");
        String[] chains = chainsList == null ? STRING_ARRAY : chainsList.toArray(STRING_ARRAY);
        ArrayList<String> categoriesList = call.argument("categories");
        String[] categories = categoriesList == null ? STRING_ARRAY : categoriesList.toArray(STRING_ARRAY);
        ArrayList<String> groupsList = call.argument("groups");
        String[] groups = groupsList == null ? STRING_ARRAY : groupsList.toArray(STRING_ARRAY);
        Integer limit = call.argument("limit");

        int r = radius == null ? 1000 : radius;
        int l = limit == null ? 10 : limit;
        if (near != null) {
            Radar.searchPlaces(near, r, chains, categories, groups, l, callback);
        } else {
            Radar.searchPlaces(r, chains, categories, groups, l, callback);
        }
    }

    public void autocomplete(MethodCall call, final Result result) {
        String query = call.argument("query");
        if (query == null) {
            result.error(Radar.RadarStatus.ERROR_PUBLISHABLE_KEY.name(), null, null);
            return;
        }
        HashMap nearMap = call.argument("near");
        Location near = null;
        if (nearMap != null) {
            near = locationForMap(nearMap);
        }
        Integer limit = call.argument("limit") ;

        Radar.autocomplete(query, near, limit == null ? 10 : limit, new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(@NonNull final Radar.RadarStatus status, final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
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
        if (query == null) {
            result.error(Radar.RadarStatus.ERROR_PUBLISHABLE_KEY.name(), null, null);
            return;
        }

        Radar.geocode(query, new Radar.RadarGeocodeCallback() {
            @Override
            public void onComplete(@NonNull final Radar.RadarStatus status, final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
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
            public void onComplete(@NonNull final Radar.RadarStatus status, final RadarAddress[] addresses) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (addresses != null) {
                                obj.put("addresses", RadarAddress.toJson(addresses));
                            }

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        HashMap locationMap = call.argument("location");
        if (locationMap != null) {
            Location location = locationForMap(locationMap);
            Radar.reverseGeocode(location, callback);
        } else {
            Radar.reverseGeocode(callback);
        }
    }

    public void ipGeocode(MethodCall call, final Result result) {
        Radar.ipGeocode(new Radar.RadarIpGeocodeCallback() {
            @Override
            public void onComplete(@NonNull final Radar.RadarStatus status, final RadarAddress address, final boolean proxy) {
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

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
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
            public void onComplete(@NonNull final Radar.RadarStatus status, final RadarRoutes routes) {
                runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            JSONObject obj = new JSONObject();
                            obj.put("status", status.toString());
                            if (routes != null) {
                                obj.put("routes", routes.toJson());
                            }

                            result.success(new Gson().fromJson(obj.toString(), HashMap.class));
                        } catch (Exception e) {
                            result.error(e.toString(), e.getMessage(), e.getMessage());
                        }
                    }
                });
            }
        };

        HashMap destinationMap = call.argument("destination");
        if (destinationMap == null) {
            result.error(Radar.RadarStatus.ERROR_PUBLISHABLE_KEY.name(), null, null);
            return;
        }
        Location origin = null;
        HashMap originMap = call.argument("origin");
        if (originMap != null) {
            origin = locationForMap(originMap);
        }
        Location destination = locationForMap(destinationMap);
        EnumSet<Radar.RadarRouteMode> modes = EnumSet.noneOf(Radar.RadarRouteMode.class);
        ArrayList<String> modesList = call.argument("modes");
        if (modesList == null || modesList.isEmpty()) {
            modes.add(Radar.RadarRouteMode.CAR);
        } else {
            for (String modeStr : modesList) {
                modes.add(getMode(modeStr));
            }
        }

        String unitsStr = call.argument("units");
        Radar.RadarRouteUnits units = getUnits(unitsStr);

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
            Boolean clickable = call.argument("clickable");

            intent.setAction("start");
            intent.putExtra("title", title)
                    .putExtra("text", text)
                    .putExtra("icon", icon)
                    .putExtra("importance", importance)
                    .putExtra("id", id)
                    .putExtra("clickable", Boolean.TRUE == clickable)
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
        Double latitude = (Double) locationMap.get("latitude");
        Double longitude = (Double) locationMap.get("longitude");
        if (latitude == null) {
            throw new IllegalArgumentException("latitude required");
        } else if (longitude == null) {
            throw new IllegalArgumentException("longitude required");
        } else {
            Location location = new Location("RadarSDK");
            location.setLatitude(latitude);
            location.setLongitude(longitude);
            Double accuracy = (Double) locationMap.get("accuracy");
            if (accuracy != null) {
                location.setAccuracy(accuracy.floatValue());
            }
            return location;
        }
    }

    private JSONObject jsonForMap(HashMap map) {
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
        public void onEventsReceived(@NonNull Context context, @NonNull RadarEvent[] events, RadarUser user) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("events", RadarEvent.toJson(events));
                obj.put("user", user.toJson());

                if (sEventsSink != null) {
                    sEventsSink.success(new Gson().fromJson(obj.toString(), HashMap.class));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onLocationUpdated(@NonNull Context context, @NonNull Location location, @NonNull RadarUser user) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("user", user.toJson());

                if (sLocationSink != null) {
                    sLocationSink.success(new Gson().fromJson(obj.toString(), HashMap.class));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        public void onClientLocationUpdated(@NonNull Context context, @NonNull Location location, boolean stopped, @NonNull Radar.RadarLocationSource source) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("location", Radar.jsonForLocation(location));
                obj.put("stopped", stopped);
                obj.put("source", source.toString());

                if (sClientLocationSink != null) {
                    sClientLocationSink.success(new Gson().fromJson(obj.toString(), HashMap.class));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onError(@NonNull Context context, @NonNull Radar.RadarStatus status) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("status", status.toString());

                if (sErrorSink != null) {
                    sErrorSink.success(new Gson().fromJson(obj.toString(), HashMap.class));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onLog(@NonNull Context context, @NonNull String message) {
            RadarFlutterPlugin.initializeBackgroundEngine(context);

            try {
                JSONObject obj = new JSONObject();
                obj.put("message", message);

                if (sLogSink != null) {
                    sLogSink.success(new Gson().fromJson(obj.toString(), HashMap.class));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

    }

}