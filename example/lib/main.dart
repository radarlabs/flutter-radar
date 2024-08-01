import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    minimumSize: Size(88, 36),
    padding: EdgeInsets.symmetric(horizontal: 16),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
  );

  @override
  void initState() {
    super.initState();
    initRadar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      Radar.logResigningActive();
    } else if (state == AppLifecycleState.paused) {
      Radar.logBackgrounding();
    }
  }

  // Add this to iOS callback for termination; Android calls this automatically
  // Radar.logTermination();
  @pragma('vm:entry-point')
  static void onLocation(Map res) {
    print('📍📍 onLocation: $res');
  }

  @pragma('vm:entry-point')
  static void onClientLocation(Map res) {
    print('📍📍 onClientLocation: $res');
  }

  @pragma('vm:entry-point')
  static void onError(Map res) {
    print('📍📍 onError: $res');
  }

  @pragma('vm:entry-point')
  static void onLog(Map res) {
    print('📍📍 onLog: $res');
  }

  @pragma('vm:entry-point')
  static void onEvents(Map res) {
    print('📍📍 onEvents: $res');
  }

  @pragma('vm:entry-point')
  static void onToken(Map res) {
    print('📍📍 onToken: $res');
  }

  Future<void> initRadar() async {
    Radar.initialize(
        publishableKey: 'prj_test_pk_0000000000000000000000000000000000000000');
    Radar.setUserId(userId: 'flutter');
    Radar.setDescription(description: 'Flutter');
    Radar.setMetadata(metadata: {'foo': 'bar', 'bax': true, 'qux': 1});
    Radar.setLogLevel(logLevel: 'info');
    Radar.setAnonymousTrackingEnabled(enabled: false);

    Radar.onLocation(onLocation);
    Radar.onClientLocation(onClientLocation);
    Radar.onError(onError);
    Radar.onEvents(onEvents);
    Radar.onLog(onLog);
    Radar.onToken(onToken);

    await Radar.requestPermissions(background: false);

    await Radar.requestPermissions(background: true);
    var permissionStatus = await Radar.getPermissionsStatus();
    if (permissionStatus != "DENIED") {
      var b = await Radar.startTrackingCustom(options: {
        ...Radar.presetResponsive,
        "showBlueBar": true,
      });
      //Radar.startTracking('continuous');

      var c = await Radar.getTrackingOptions();
      print("Tracking options $c");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('flutter_radar_example'),
      ),
      body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            child: Column(children: [
              Permissions(),
              TrackOnce(),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var status =
                      await Radar.requestPermissions(background: false);
                  print(status);
                  if (status == 'GRANTED_FOREGROUND') {
                    status = await Radar.requestPermissions(background: true);
                    print(status);
                  }
                },
                child: Text('requestPermissions()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  Radar.setForegroundServiceOptions(foregroundServiceOptions: {
                    'title': 'Tracking',
                    'text': 'Trip tracking started',
                    'icon': 2131165271,
                    'importance': 2,
                    'updatesOnly': false,
                    'activity': 'io.radar.example.MainActivity'
                  });
                  var resp = await Radar.startTrip(tripOptions: {
                    "externalId": '299',
                    "destinationGeofenceTag": 'store',
                    "destinationGeofenceExternalId": '123',
                    "mode": 'car',
                    "scheduledArrivalAt": "2020-08-20T10:30:55.837Z",
                    "metadata": {"test": 123}
                  }, trackingOptions: {
                    "desiredStoppedUpdateInterval": 30,
                    "fastestStoppedUpdateInterval": 30,
                    "desiredMovingUpdateInterval": 30,
                    "fastestMovingUpdateInterval": 30,
                    "desiredSyncInterval": 20,
                    "desiredAccuracy": "high",
                    "stopDuration": 0,
                    "stopDistance": 0,
                    "replay": "none",
                    "sync": "all",
                    "showBlueBar": true,
                    "useStoppedGeofence": false,
                    "stoppedGeofenceRadius": 0,
                    "useMovingGeofence": false,
                    "movingGeofenceRadius": 0,
                    "syncGeofences": false,
                    "syncGeofencesLimit": 0,
                    "beacons": false,
                    "foregroundServiceEnabled": true
                  });
                  print("startTrip: $resp");
                },
                child: Text('startTrip'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.completeTrip();
                  print("completeTrip: $resp");
                },
                child: Text('completeTrip'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  PermissionStatus status =
                      await Permission.activityRecognition.request();
                  if (status.isGranted) {
                    print('Permission granted');
                  } else {
                    print('Permission denied');
                  }
                },
                child: Text('request activity permissions'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.cancelTrip();
                  print("cancelTrip: $resp");
                },
                child: Text('cancelTrip'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.getTrackingOptions();
                  print("getTrackingOptions: $resp");
                },
                child: Text('getTrackingOptions'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp =
                      await Radar.updateTrip(status: 'arrived', options: {
                    "externalId": '299',
                    "metadata": {"parkingSpot": '5'}
                  });
                  print("updateTrip: $resp");
                },
                child: Text('updateTrip'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.logConversion(
                      name: "in_app_purchase",
                      revenue: 0.2,
                      metadata: {"price": "150USD"});
                  print("logConversion: $resp");
                },
                child: Text('logConversion'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  await Radar.setNotificationOptions(
                      notificationOptions: {'iconString': 'icon'});
                },
                child: Text('setNotificationOptions'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.searchPlaces(
                    radius: 1000,
                    limit: 10,
                    near: {
                      'latitude': 40.783826,
                      'longitude': -73.975363,
                    },
                    chains: ["starbucks"],
                    chainMetadata: {"customFlag": "true"},
                  );
                  print("searchPlaces: $resp");
                },
                child: Text('searchPlaces()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.searchGeofences(
                    near: {
                      'latitude': 40.783826,
                      'longitude': -73.975363,
                    },
                    radius: 1000,
                    limit: 10,
                    includeGeometry: true,
                    tags: List.empty(),
                    metadata: {},
                  );
                  print("searchGeofences: $resp");
                },
                child: Text('searchGeofences()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.geocode(
                    query: '20 jay st brooklyn',
                  );
                  print("geocode: $resp");
                },
                child: Text('geocode()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.reverseGeocode();
                  print("reverseGeocode: $resp");
                },
                child: Text('reverseGeocode()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.autocomplete(
                      query: 'brooklyn roasting',
                      limit: 10,
                      near: {
                        'latitude': 40.783826,
                        'longitude': -73.975363,
                      },
                      layers: ['address', 'street'],
                      country: 'US',
                      mailable: false);
                  print("autocomplete: $resp");
                },
                child: Text('autocomplete'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  var resp = await Radar.getMatrix(
                    origins: [
                      {
                        'latitude': 40.78382,
                        'longitude': -73.97536,
                      },
                      {
                        'latitude': 40.70390,
                        'longitude': -73.98670,
                      },
                    ],
                    destinations: [
                      {
                        'latitude': 40.64189,
                        'longitude': -73.78779,
                      },
                      {
                        'latitude': 35.99801,
                        'longitude': -78.94294,
                      },
                    ],
                    mode: 'car',
                    units: 'imperial',
                  );
                  print("getMatrix: $resp");
                },
                child: Text('getMatrix'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () {
                  Radar.startTracking(preset: 'responsive');
                },
                child: Text('startTracking(\'responsive\')'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () {
                  Radar.setForegroundServiceOptions(foregroundServiceOptions: {
                    'title': 'Tracking',
                    'text': 'Continuous tracking started',
                    'icon': 2131165271,
                    'importance': 2,
                    'updatesOnly': false,
                    'activity': 'io.radar.example.MainActivity'
                  });
                  Radar.startTrackingCustom(options: {
                    'desiredStoppedUpdateInterval': 120,
                    'fastestStoppedUpdateInterval': 120,
                    'desiredMovingUpdateInterval': 30,
                    'fastestMovingUpdateInterval': 30,
                    'desiredSyncInterval': 20,
                    'desiredAccuracy': 'high',
                    'stopDuration': 140,
                    'stopDistance': 70,
                    'sync': 'all',
                    'replay': 'none',
                    'showBlueBar': true,
                    'foregroundServiceEnabled': true
                  });
                },
                child: Text('startTrackingCustom()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () {
                  Radar.startTrackingVerified(interval: 30, beacons: false);
                },
                child: Text('startTrackingVerified()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () {
                  Radar.stopTrackingVerified();
                },
                child: Text('stopTrackingVerified()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () {
                  Radar.stopTracking();
                },
                child: Text('stopTracking()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () {
                  Radar.mockTracking(origin: {
                    'latitude': 40.78382,
                    'longitude': -73.97536
                  }, destination: {
                    'latitude': 40.70390,
                    'longitude': -73.98670
                  }, mode: 'car', steps: 3, interval: 3);
                },
                child: Text('mockTracking()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  Map? location = await Radar.getLocation(accuracy: 'high');
                  print(location);
                },
                child: Text('getLocation()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  Map? resp = await Radar.trackVerified();
                  print("trackVerified: $resp");
                },
                child: Text('trackVerified()'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  bool? resp = await Radar.isUsingRemoteTrackingOptions();
                  print("isUsingRemoteTrackingOptions: $resp");
                },
                child: Text('isUsingRemoteTrackingOptions'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  Map? resp = await Radar.validateAddress(address: {
                    "city": "NEW YORK",
                    "stateCode": "NY",
                    "postalCode": "10003",
                    "countryCode": "US",
                    "street": "BROADWAY",
                    "number": "841",
                  });
                  print("validateAddress: $resp");
                },
                child: Text('validateAddress'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  await Radar.acceptEvent(
                      eventId: 'event-id',
                      VerifiedPlaceId: 'verified-place-id');
                  ;
                  print("accept event");
                },
                child: Text('acceptEvent'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  await Radar.rejectEvent(eventId: 'event-id');
                  ;
                  print("reject event");
                },
                child: Text('rejectEvent'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  Map? res = await Radar.getContext(
                      location: {'latitude': 40.78382, 'longitude': -73.97536});
                  ;
                  print("getContext: $res");
                },
                child: Text('getContext'),
              ),
              ElevatedButton(
                style: raisedButtonStyle,
                onPressed: () async {
                  Map? res = await Radar.getDistance(destination: {
                    'latitude': 40.78382,
                    'longitude': -73.97536
                  }, modes: [
                    'car'
                  ], units: 'imperial');
                  ;
                  print("getDistance: $res");
                },
                child: Text('getDistance'),
              ),
            ]),
          )),
    ));
  }
}

class Permissions extends StatefulWidget {
  @override
  _PermissionsState createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  String? _status = 'NOT_DETERMINED';
  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    minimumSize: Size(88, 36),
    padding: EdgeInsets.symmetric(horizontal: 16),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
  );

  @override
  void initState() {
    super.initState();
    _getPermissionsStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$_status',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          style: raisedButtonStyle,
          child: Text('getPermissionsStatus()'),
          onPressed: () {
            _getPermissionsStatus();
          },
        ),
      ],
    );
  }

  Future _getPermissionsStatus() async {
    String? status = await Radar.getPermissionsStatus();
    setState(() {
      _status = status;
    });
    print('Permissions status: $status');
  }
}

class TrackOnce extends StatefulWidget {
  @override
  _TrackOnceState createState() => _TrackOnceState();
}

class _TrackOnceState extends State<TrackOnce> {
  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    minimumSize: Size(88, 36),
    padding: EdgeInsets.symmetric(horizontal: 16),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('trackOnce()'),
      style: raisedButtonStyle,
      onPressed: () {
        _showTrackOnceDialog();
      },
    );
  }

  Future<void> _showTrackOnceDialog() async {
    var trackResponse = await Radar.trackOnce();
    print("trackResponse: $trackResponse");

    Widget okButton = TextButton(
      child: Text('OK'),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text('flutter_radar_example'),
      content: Text(trackResponse?['status'] ?? ''),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

showAlertDialog(BuildContext context, String text) {
  Widget okButton = TextButton(
    child: Text('OK'),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  AlertDialog alert = AlertDialog(
    title: Text('flutter_radar_example'),
    content: Text(text),
    actions: [
      okButton,
    ],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
