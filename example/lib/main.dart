import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_radar/flutter_radar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initRadar();
  }

  static void onEvents(Map res) {
    print('📍 onEvents: $res');
  }

  static void onLocation(Map res) {
    print('📍 onLocation: $res');
  }

  static void onClientLocation(Map res) {
    print('📍 onClientLocation: $res');
  }

  static void onError(Map res) {
    print('📍 onError: $res');
  }

  static void onLog(Map res) {
    print('📍 onLog: $res');
  }

  Future<void> initRadar() async {
    Radar.setLogLevel('info');
    Radar.setUserId('flutter');
    Radar.setDescription('Flutter');
    Radar.setMetadata({'foo': 'bar', 'bax': true, 'qux': 1});

    Radar.attachListeners();
    Radar.onEvents(onEvents);
    Radar.onLocation(onLocation);
    Radar.onClientLocation(onClientLocation);
    Radar.onError(onError);
    Radar.onLog(onLog);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('flutter_radar_example'),
      ),
      body: Container(
        child: Column(children: [
          Permissions(),
          TrackOnce(),
          RaisedButton(
            color: Colors.blueAccent,
            onPressed: () {
              Radar.startTracking('responsive');
            },
            child: Text('startTracking(\'responsive\')'),
          ),
          RaisedButton(
            color: Colors.blueAccent,
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
          RaisedButton(
            color: Colors.blueAccent,
            onPressed: () {
              Radar.stopTracking();
            },
            child: Text('stopTracking()'),
          ),
          RaisedButton(
            color: Colors.blueAccent,
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
          RaisedButton(
            color: Colors.blueAccent,
            onPressed: () {
              Radar.requestPermissions(true);
            },
            child: Text('requestPermissions()'),
          ),
          RaisedButton(
            color: Colors.blueAccent,
            onPressed: () async {
              Map location = await Radar.getLocation('high');
              print(location);
            },
            child: Text('getLocation()'),
          ),
          RaisedButton(
            color: Colors.blueAccent,
            onPressed: () {
              Radar.startForegroundService({
                'title': 'Tracking',
                'text': 'Continuous tracking started',
                'icon': 'car_icon',
                'importance': '2',
                'id': '12555541'
              });
            },
            child: Text('startForegroundService(), Android only'),
          ),
          RaisedButton(
            color: Colors.blueAccent,
            onPressed: () {
              Radar.stopForegroundService();
            },
            child: Text('stopForegroundService(), Android only'),
          )
        ]),
      ),
    ));
  }
}

class Permissions extends StatefulWidget {
  @override
  _PermissionsState createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  String _permissionStatus = 'NOT_DETERMINED';

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
          '$_permissionStatus',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        RaisedButton(
          color: Colors.blueAccent,
          child: Text('getPermissionsStatus()'),
          onPressed: () {
            _getPermissionsStatus();
          },
        ),
      ],
    );
  }

  Future _getPermissionsStatus() async {
    String permissionsString = await Radar.getPermissionsStatus();
    setState(() {
      _permissionStatus = permissionsString;
    });
  }
}

class TrackOnce extends StatefulWidget {
  @override
  _TrackOnceState createState() => _TrackOnceState();
}

class _TrackOnceState extends State<TrackOnce> {
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text('trackOnce()'),
      color: Colors.blueAccent,
      onPressed: () {
        _showTrackOnceDialog();
      },
    );
  }

  Future<void> _showTrackOnceDialog() async {
    var trackResponse = await Radar.trackOnce();

    Widget okButton = FlatButton(
      child: Text('OK'),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text('flutter_radar_example'),
      content: Text(trackResponse['status']),
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
  Widget okButton = FlatButton(
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
