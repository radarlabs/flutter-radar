import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_radar/flutter_radar.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    primary: Colors.blueAccent,
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

  Future<void> initRadar() async {
    Radar.initialize("prj_test_pk_0000000000000000000000000000");
    Radar.setUserId('flutter');
    Radar.setDescription('Flutter');
    Radar.setMetadata({'foo': 'bar', 'bax': true, 'qux': 1});
    Radar.setLogLevel('info');
    Radar.setAnonymousTrackingEnabled(false);

    Radar.onEvents((result) {
      print('onEvents: $result');
    });
    Radar.onLocation((result) {
      print('onLocation: $result');
    });
    Radar.onClientLocation((result) {
      print('onClientLocation: $result');
    });
    Radar.onError((result) {
      print('onError: $result');
    });
    Radar.onLog((result) {
      print('onLog: $result');
    });
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
                var resp = await Radar.startTrip(
                    tripOptions: {
                    "externalId": '299',
                    "destinationGeofenceTag": 'store',
                    "destinationGeofenceExternalId": '123',
                    "mode": 'car',
                    "scheduledArrivalAt": "2020-08-20T10:30:55.837Z",
                    "metadata": {"test": 123}
                    },
                    trackingOptions: {
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
                      "foregroundServiceEnabled": false
                    }
                );
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
                var resp = await Radar.updateTrip(
                  status:'arrived',
                  options: {
                    "externalId": '299',
                    "metadata": {
                      "parkingSpot": '5'
                    }
                  }
                );
                print("updateTrip: $resp");
              },
              child: Text('updateTrip'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () async {
                var resp = await Radar.sendEvent(
                  customType: "in_app_purchase",
                  location: {
                    "latitude": 35.0,
                    "longitude": -75.0
                  },
                  metadata: {"price": "150USD"}
                );
                print("sendEvent: $resp");
              },
              child: Text('sendEvent'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () async {
                var resp = await Radar.searchPlaces(
                  near: {
                    'latitude': 40.783826,
                    'longitude': -73.975363,
                  },
                  radius: 1000,
                  chains: ["starbucks"],
                  chainMetadata: {
                    "customFlag": "true"
                  },
                  limit: 10,
                );
                print("searchPlaces: $resp");
              },
              child: Text('searchPlaces'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () async {
                var resp = await Radar.autocomplete(
                  query: 'brooklyn roasting',
                  near: {
                    'latitude': 40.783826,
                    'longitude': -73.975363,
                  },
                  limit: 10,
                  layers: ['address', 'street'],
                  country: 'US'
                );
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
                Radar.startTracking('responsive');
              },
              child: Text('startTracking(\'responsive\')'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () {
                Radar.startTrackingCustom({
                  'desiredStoppedUpdateInterval': 60,
                  'fastestStoppedUpdateInterval': 60,
                  'desiredMovingUpdateInterval': 30,
                  'fastestMovingUpdateInterval': 30,
                  'desiredSyncInterval': 20,
                  'desiredAccuracy': 'high',
                  'stopDuration': 140,
                  'stopDistance': 70,
                  'sync': 'all',
                  'replay': 'none',
                  'showBlueBar': true
                });
              },
              child: Text('startTrackingCustom()'),
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
                Radar.mockTracking(
                    origin: {'latitude': 40.78382, 'longitude': -73.97536},
                    destination: {'latitude': 40.70390, 'longitude': -73.98670},
                    mode: 'car',
                    steps: 3,
                    interval: 3);
              },
              child: Text('mockTracking()'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () async {
                var status = await Radar.requestPermissions(false);
                print(status);
                if (status == 'GRANTED_FOREGROUND') {
                  status = await Radar.requestPermissions(true);
                  print(status);
                }
              },
              child: Text('requestPermissions()'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () async {
                Map? location = await Radar.getLocation('high');
                print(location);
              },
              child: Text('getLocation()'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () {
                Radar.startForegroundService({
                  'title': 'Tracking',
                  'text': 'Continuous tracking started',
                  'icon': 'car_icon',
                  'importance': '2',
                  'id': '12555541',
                  'clickable': true
                });
              },
              child: Text('startForegroundService(), Android only'),
            ),
            ElevatedButton(
              style: raisedButtonStyle,
              onPressed: () {
                Radar.stopForegroundService();
              },
              child: Text('stopForegroundService(), Android only'),
            )
          ]),
        )
      ),
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
    primary: Colors.blueAccent,
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
  }
}

class TrackOnce extends StatefulWidget {
  @override
  _TrackOnceState createState() => _TrackOnceState();
}

class _TrackOnceState extends State<TrackOnce> {
  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    primary: Colors.blueAccent,
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
    var trackResponse = await Radar.trackOnce(location: {
      "latitude": 39.2904,
      "longitude": -76.6122,
      "accuracy": 60.0
    });
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
