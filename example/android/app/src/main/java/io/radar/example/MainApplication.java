package io.radar.example;

import io.flutter.app.FlutterApplication;
import io.flutter.view.FlutterMain;
import io.radar.sdk.Radar;

public class MainApplication extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();
        Radar.initialize(this, "prj_test_pk_0000000000000000000000000000000000000000");
        FlutterMain.startInitialization(this);
    }

}