package io.radar.flutter;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

/**
 * Installs Radar's process-wide receivers before Application.onCreate() so
 * background events do not require a customer-defined Application subclass.
 *
 * Only lightweight wiring occurs here. The Flutter engine remains lazy and is
 * created only when an event requires headless Dart delivery.
 *
 * @see <a href="https://developer.android.com/topic/libraries/app-startup">
 *     Android App Startup</a>
 */
public final class RadarFlutterInitializationProvider
    extends ContentProvider {

    private static final String TAG = "RadarFlutterPlugin";
    private RadarFlutterBackgroundEngine backgroundEngine;
    private RadarFlutterBackgroundEventSink backgroundEventSink;

    @Override
    public boolean onCreate() {
        Context context = getContext();

        if (context == null) {
            return false;
        }

        Handler mainHandler = new Handler(Looper.getMainLooper());

        backgroundEngine = new RadarFlutterBackgroundEngine(
            mainHandler::post,
            new RadarFlutterBackgroundEngineFactory(context),
            (message, error) -> Log.e(TAG, message, error)
        );

        backgroundEventSink = new RadarFlutterBackgroundEventSink(
            RadarFlutterBackgroundHandlerStore.fromContext(context),
            backgroundEngine
        );

        RadarFlutterPlugin.setBackgroundEventSink(backgroundEventSink);
        RadarFlutterPlugin.installReceivers();

        return true;
    }

    @Override
    public Cursor query(
        Uri uri,
        String[] projection,
        String selection,
        String[] selectionArgs,
        String sortOrder
    ) {
        return null;
    }

    @Override
    public String getType(Uri uri) {
        return null;
    }

    @Override
    public Uri insert(Uri uri, ContentValues values) {
        return null;
    }

    @Override
    public int delete(
        Uri uri,
        String selection,
        String[] selectionArgs
    ) {
        return 0;
    }

    @Override
    public int update(
        Uri uri,
        ContentValues values,
        String selection,
        String[] selectionArgs
    ) {
        return 0;
    }
}