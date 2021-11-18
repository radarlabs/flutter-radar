package io.radar.example;

import io.flutter.app.FlutterApplication;
import io.radar.flutter.RadarFlutterPlugin;

public class MainApplication extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();
        RadarFlutterPlugin.initialize(getApplicationContext(), "prj_test_pk_0000000000000000000000000000000000000000");
    }
}