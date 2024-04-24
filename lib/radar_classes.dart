import 'dart:io' show Platform;

class RadarNear {
  final double latitude;
  final double longitude;

  RadarNear({required this.latitude, required this.longitude});

  Map<String, double> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static RadarNear fromMap(Map<String, dynamic> map) {
    return RadarNear(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
    );
  }
}

class RadarLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;

  RadarLocation({required this.latitude, required this.longitude, this.accuracy});

  Map<String, double?> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }

  static RadarLocation fromMap(Map<String, dynamic> map) {
    return RadarLocation(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      accuracy: map['accuracy'] as double?,
    );
  }
}

class RadarTrackingOptions {
  int desiredStoppedUpdateInterval;
  int desiredMovingUpdateInterval;
  int desiredSyncInterval;
  String desiredAccuracy; // Assuming RadarTrackingOptionsDesiredAccuracy is an enum, you might want to create a Dart enum and use it here
  int stopDuration;
  int stopDistance;
  String? startTrackingAfter;
  String? stopTrackingAfter;
  String replay; // Assuming RadarTrackingOptionsReplay is an enum, you might want to create a Dart enum and use it here
  String syncLocations; // Assuming RadarTrackingOptionsSyncLocations is an enum, you might want to create a Dart enum and use it here
  bool showBlueBar;
  bool useStoppedGeofence;
  int stoppedGeofenceRadius;
  bool useMovingGeofence;
  int movingGeofenceRadius;
  bool syncGeofences;
  bool useVisits;
  bool useSignificantLocationChanges;
  bool beacons;

  RadarTrackingOptions({
    required this.desiredStoppedUpdateInterval,
    required this.desiredMovingUpdateInterval,
    required this.desiredSyncInterval,
    required this.desiredAccuracy,
    required this.stopDuration,
    required this.stopDistance,
    this.startTrackingAfter,
    this.stopTrackingAfter,
    required this.replay,
    required this.syncLocations,
    required this.showBlueBar,
    required this.useStoppedGeofence,
    required this.stoppedGeofenceRadius,
    required this.useMovingGeofence,
    required this.movingGeofenceRadius,
    required this.syncGeofences,
    required this.useVisits,
    required this.useSignificantLocationChanges,
    required this.beacons,
  });

  Map<String, dynamic> toMap() {
    return {
      'desiredStoppedUpdateInterval': desiredStoppedUpdateInterval,
      'desiredMovingUpdateInterval': desiredMovingUpdateInterval,
      'desiredSyncInterval': desiredSyncInterval,
      'desiredAccuracy': desiredAccuracy,
      'stopDuration': stopDuration,
      'stopDistance': stopDistance,
      'startTrackingAfter': startTrackingAfter,
      'stopTrackingAfter': stopTrackingAfter,
      'replay': replay,
      'syncLocations': syncLocations,
      'showBlueBar': showBlueBar,
      'useStoppedGeofence': useStoppedGeofence,
      'stoppedGeofenceRadius': stoppedGeofenceRadius,
      'useMovingGeofence': useMovingGeofence,
      'movingGeofenceRadius': movingGeofenceRadius,
      'syncGeofences': syncGeofences,
      'useVisits': useVisits,
      'useSignificantLocationChanges': useSignificantLocationChanges,
      'beacons': beacons,
    };
  }

  static RadarTrackingOptions fromMap(Map<String, dynamic> map) {
    return RadarTrackingOptions(
      desiredStoppedUpdateInterval: map['desiredStoppedUpdateInterval'] as int,
      desiredMovingUpdateInterval: map['desiredMovingUpdateInterval'] as int,
      desiredSyncInterval: map['desiredSyncInterval'] as int,
      desiredAccuracy: map['desiredAccuracy'] as String,
      stopDuration: map['stopDuration'] as int,
      stopDistance: map['stopDistance'] as int,
      startTrackingAfter: map['startTrackingAfter'] as String?,
      stopTrackingAfter: map['stopTrackingAfter'] as String?,
      replay: map['replay'] as String,
      syncLocations: map['syncLocations'] as String,
      showBlueBar: map['showBlueBar'] as bool,
      useStoppedGeofence: map['useStoppedGeofence'] as bool,
      stoppedGeofenceRadius: map['stoppedGeofenceRadius'] as int,
      useMovingGeofence: map['useMovingGeofence'] as bool,
      movingGeofenceRadius: map['movingGeofenceRadius'] as int,
      syncGeofences: map['syncGeofences'] as bool,
      useVisits: map['useVisits'] as bool,
      useSignificantLocationChanges: map['useSignificantLocationChanges'] as bool,
      beacons: map['beacons'] as bool,
    );
  }
    static Map<String, dynamic> presetContinuousIOS = {
  "desiredStoppedUpdateInterval": 30,
  "desiredMovingUpdateInterval": 30,
  "desiredSyncInterval": 20,
  "desiredAccuracy":'high',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'none',
  "useStoppedGeofence": false,
  "showBlueBar": true,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "useVisits": false,
  "useSignificantLocationChanges": false,
  "beacons": false,
  "sync": 'all',
};

  static Map<String, dynamic> presetContinuousAndroid =  {
  "desiredStoppedUpdateInterval": 30,
  "fastestStoppedUpdateInterval": 30,
  "desiredMovingUpdateInterval": 30,
  "fastestMovingUpdateInterval": 30,
  "desiredSyncInterval": 20,
  "desiredAccuracy": 'high',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'none',
  "sync": 'all',
  "useStoppedGeofence": false,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "syncGeofencesLimit": 0,
  "foregroundServiceEnabled": true,
  "beacons": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
};

  static Map<String, dynamic> presetResponsiveIOS = {
    "desiredStoppedUpdateInterval": 0,
    "desiredMovingUpdateInterval": 150,
    "desiredSyncInterval": 20,
    "desiredAccuracy": 'medium',
    "stopDuration": 140,
    "stopDistance": 70,
    "replay": 'stops',
    "useStoppedGeofence": true,
    "showBlueBar": false,
    "startTrackingAfter": null,
    "stopTrackingAfter": null,
    "stoppedGeofenceRadius": 100,
    "useMovingGeofence": true,
    "movingGeofenceRadius": 100,
    "syncGeofences": true,
    "useVisits": true,
    "useSignificantLocationChanges": true,
    "beacons": false,
    "sync": 'all',
  };

  static Map<String, dynamic> presetResponsiveAndroid = {
    "desiredStoppedUpdateInterval": 0,
    "fastestStoppedUpdateInterval": 0,
    "desiredMovingUpdateInterval": 150,
    "fastestMovingUpdateInterval": 30,
    "desiredSyncInterval": 20,
    "desiredAccuracy": "medium",
    "stopDuration": 140,
    "stopDistance": 70,
    "replay": 'stops',
    "sync": 'all',
    "useStoppedGeofence": true,
    "stoppedGeofenceRadius": 100,
    "useMovingGeofence": true,
    "movingGeofenceRadius": 100,
    "syncGeofences": true,
    "syncGeofencesLimit": 10,
    "foregroundServiceEnabled": false,
    "beacons": false,
    "startTrackingAfter": null,
    "stopTrackingAfter": null,
  };

  static Map<String, dynamic> presetEfficientIOS = {
  "desiredStoppedUpdateInterval": 0,
  "desiredMovingUpdateInterval": 0,
  "desiredSyncInterval": 0,
  "desiredAccuracy": "medium",
  "stopDuration": 0,
  "stopDistance": 0,
  "replay": 'stops',
  "useStoppedGeofence": false,
  "showBlueBar": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "useVisits": true,
  "useSignificantLocationChanges": false,
  "beacons": false,
  "sync": 'all',
};

  static Map<String, dynamic> presetEfficientAndroid ={
  "desiredStoppedUpdateInterval": 3600,
  "fastestStoppedUpdateInterval": 1200,
  "desiredMovingUpdateInterval": 1200,
  "fastestMovingUpdateInterval": 360,
  "desiredSyncInterval": 140,
  "desiredAccuracy": 'medium',
  "stopDuration": 140,
  "stopDistance": 70,
  "replay": 'stops',
  "sync": 'all',
  "useStoppedGeofence": false,
  "stoppedGeofenceRadius": 0,
  "useMovingGeofence": false,
  "movingGeofenceRadius": 0,
  "syncGeofences": true,
  "syncGeofencesLimit": 10,
  "foregroundServiceEnabled": false,
  "beacons": false,
  "startTrackingAfter": null,
  "stopTrackingAfter": null,
};

  static Map<String, dynamic> presetResponsive =
      Platform.isIOS ? presetResponsiveIOS : presetResponsiveAndroid;
  static Map<String, dynamic> presetContinuous =
      Platform.isIOS ? presetContinuousIOS : presetContinuousAndroid;
    static Map<String, dynamic> presetEfficient=
      Platform.isIOS ? presetEfficientIOS : presetEfficientAndroid;
}

class RadarTripOptions {
  String externalId;
  Map<String, dynamic>? metadata;
  String? destinationGeofenceTag;
  String? destinationGeofenceExternalId;
  String? scheduledArrivalAt;
  String? mode; // Assuming RadarRouteMode is an enum, you might want to create a Dart enum and use it here
  int? approachingThreshold;

  RadarTripOptions({
    required this.externalId,
    this.metadata,
    this.destinationGeofenceTag,
    this.destinationGeofenceExternalId,
    this.scheduledArrivalAt,
    this.mode,
    this.approachingThreshold,
  });

  Map<String, dynamic> toMap() {
    return {
      'externalId': externalId,
      'metadata': metadata,
      'destinationGeofenceTag': destinationGeofenceTag,
      'destinationGeofenceExternalId': destinationGeofenceExternalId,
      'scheduledArrivalAt': scheduledArrivalAt,
      'mode': mode,
      'approachingThreshold': approachingThreshold,
    };
  }

  static RadarTripOptions fromMap(Map<String, dynamic> map) {
    return RadarTripOptions(
      externalId: map['externalId'] as String,
      metadata: map['metadata'] as Map<String, dynamic>?,
      destinationGeofenceTag: map['destinationGeofenceTag'] as String?,
      destinationGeofenceExternalId: map['destinationGeofenceExternalId'] as String?,
      scheduledArrivalAt: map['scheduledArrivalAt'] as String?,
      mode: map['mode'] as String?,
      approachingThreshold: map['approachingThreshold'] as int?,
    );
  }
}

class RadarNotificationOptions{
 String? iconString;
  String? iconColor;
  String? foregroundServiceIconString;
  String? foregroundServiceIconColor;
  String? eventIconString;
  String? eventIconColor;

  RadarNotificationOptions({
    this.iconString,
    this.iconColor,
    this.foregroundServiceIconString,
    this.foregroundServiceIconColor,
    this.eventIconString,
    this.eventIconColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'iconString': iconString,
      'iconColor': iconColor,
      'foregroundServiceIconString': foregroundServiceIconString,
      'foregroundServiceIconColor': foregroundServiceIconColor,
      'eventIconString': eventIconString,
      'eventIconColor': eventIconColor,
    };
  }

  static RadarNotificationOptions fromMap(Map<String, dynamic> map) {
    return RadarNotificationOptions(
      iconString: map['iconString'] as String?,
      iconColor: map['iconColor'] as String?,
      foregroundServiceIconString: map['foregroundServiceIconString'] as String?,
      foregroundServiceIconColor: map['foregroundServiceIconColor'] as String?,
      eventIconString: map['eventIconString'] as String?,
      eventIconColor: map['eventIconColor'] as String?,
    );
  }
}

class RadarForegroundServiceOptions{
  String? iconString;
  String? iconColor;
  String? foregroundServiceIconString;
  String? foregroundServiceIconColor;
  String? eventIconString;
  String? eventIconColor;
  String? text;
  String? title;
  bool updatesOnly;
  String? activity;
  int? importance;
  int? id;
  String? channelName;

  RadarForegroundServiceOptions({
    this.iconString,
    this.iconColor,
    this.foregroundServiceIconString,
    this.foregroundServiceIconColor,
    this.eventIconString,
    this.eventIconColor,
    this.text,
    this.title,
    this.updatesOnly = false,
    this.activity,
    this.importance,
    this.id,
    this.channelName,
  });

  Map<String, dynamic> toMap() {
    return {
      'iconString': iconString,
      'iconColor': iconColor,
      'foregroundServiceIconString': foregroundServiceIconString,
      'foregroundServiceIconColor': foregroundServiceIconColor,
      'eventIconString': eventIconString,
      'eventIconColor': eventIconColor,
      'text': text,
      'title': title,
      'updatesOnly': updatesOnly,
      'activity': activity,
      'importance': importance,
      'id': id,
      'channelName': channelName,
    };
  }

  static RadarForegroundServiceOptions fromMap(Map<String, dynamic> map) {
    return RadarForegroundServiceOptions(
      iconString: map['iconString'] as String?,
      iconColor: map['iconColor'] as String?,
      foregroundServiceIconString: map['foregroundServiceIconString'] as String?,
      foregroundServiceIconColor: map['foregroundServiceIconColor'] as String?,
      eventIconString: map['eventIconString'] as String?,
      eventIconColor: map['eventIconColor'] as String?,
      text: map['text'] as String?,
      title: map['title'] as String?,
      updatesOnly: map['updatesOnly'] as bool,
      activity: map['activity'] as String?,
      importance: map['importance'] as int?,
      id: map['id'] as int?,
      channelName: map['channelName'] as String?,
    );
  }
}