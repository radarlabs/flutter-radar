package com.bg.radar_flutter_plugin_example;

import io.flutter.app.FlutterApplication;
import io.flutter.view.FlutterMain;
import io.radar.sdk.Radar;

public class MainApplication extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();
        Radar.initialize(this,"<yourRadarPublishableKey>");
        FlutterMain.startInitialization(this);
    }

}