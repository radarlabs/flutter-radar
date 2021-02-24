package io.radar.example;

import io.flutter.app.FlutterApplication;
import io.flutter.view.FlutterMain;
import io.radar.sdk.Radar;

public class MainApplication extends FlutterApplication {

    @Override
    public void onCreate() {
        super.onCreate();
        Radar.initialize(this, "org_test_pk_5857c63d9c1565175db8b00750808a66a002acb8");
        FlutterMain.startInitialization(this);
    }

}