import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, listEquals;
import 'package:meta/meta.dart';

import 'parsing.dart';

/// The location accuracy to request.
///
/// Used by [RadarTrackingOptions.desiredAccuracy], and by `Radar.trackOnce`
/// and `Radar.getLocation`.
enum RadarTrackingOptionsDesiredAccuracy implements RadarWireEnum {
  high('high'),
  medium('medium'),
  low('low'),

  /// Android only. iOS treats it as [medium], and `Radar.getLocation` treats
  /// it as the SDK default on both platforms.
  none('none');

  const RadarTrackingOptionsDesiredAccuracy(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses an accuracy string. Unrecognized values become [medium], matching
  /// both native SDKs.
  @internal
  static RadarTrackingOptionsDesiredAccuracy fromWire(Object? value) =>
      readEnum(values, value, medium);
}

/// Which failed location updates to replay when the network is back.
enum RadarTrackingOptionsReplay implements RadarWireEnum {
  /// Replays failed stops.
  stops('stops'),

  /// Replays no location updates.
  none('none'),

  /// Replays all failed location updates.
  all('all');

  const RadarTrackingOptionsReplay(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a replay string. Unrecognized values become [none], matching both
  /// native SDKs.
  @internal
  static RadarTrackingOptionsReplay fromWire(Object? value) =>
      readEnum(values, value, none);
}

/// Which location updates to sync to the server.
enum RadarTrackingOptionsSyncLocations implements RadarWireEnum {
  /// Syncs all location updates.
  all('all'),

  /// Syncs only stops and exits.
  stopsAndExits('stopsAndExits'),

  /// Syncs only location updates that generate events.
  events('events'),

  /// Syncs no location updates.
  none('none');

  const RadarTrackingOptionsSyncLocations(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a sync string. Unrecognized values become [all].
  @internal
  static RadarTrackingOptionsSyncLocations fromWire(Object? value) =>
      readEnum(values, value, all);
}

/// Where a set of tracking options came from. Set by the SDK on options
/// returned from `Radar.getTrackingOptions` when remote tracking options are
/// in use.
enum RadarTrackingOptionsType implements RadarWireEnum {
  defaultType('default'),
  onTrip('on-trip'),
  inGeofence('in-geofence'),
  isUser('is-user');

  const RadarTrackingOptionsType(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a type string. Unrecognized values become [defaultType].
  @internal
  static RadarTrackingOptionsType fromWire(Object? value) =>
      readEnum(values, value, defaultType);
}

/// A built-in tracking preset, for `Radar.startTracking`.
///
/// Starting tracking with a preset uses the native SDK's own preset options,
/// which may differ from [RadarTrackingOptions.responsive] and friends if the
/// native SDK changes them.
enum RadarTrackingPreset implements RadarWireEnum {
  responsive('responsive'),
  continuous('continuous'),
  efficient('efficient');

  const RadarTrackingPreset(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a preset string. Unrecognized values become [responsive],
  /// matching both native bridges.
  @internal
  static RadarTrackingPreset fromWire(Object? value) =>
      readEnum(values, value, responsive);

  /// The tracking options for this preset on the current platform.
  RadarTrackingOptions get options => switch (this) {
    responsive => RadarTrackingOptions.responsive,
    continuous => RadarTrackingOptions.continuous,
    efficient => RadarTrackingOptions.efficient,
  };
}

/// Options for background tracking, for `Radar.startTrackingCustom`.
///
/// Start from a preset and adjust it with [copyWith]:
///
/// ```dart
/// Radar.startTrackingCustom(
///   RadarTrackingOptions.responsive.copyWith(beacons: true),
/// );
/// ```
///
/// Fields marked Android only or iOS only are ignored by the other platform.
/// Platform-only fields that are null are left out of [toMap], so the native
/// SDK uses its default.
final class RadarTrackingOptions {
  const RadarTrackingOptions({
    required this.desiredStoppedUpdateInterval,
    required this.desiredMovingUpdateInterval,
    required this.desiredSyncInterval,
    required this.desiredAccuracy,
    required this.stopDuration,
    required this.stopDistance,
    required this.replay,
    required this.syncLocations,
    required this.useStoppedGeofence,
    required this.stoppedGeofenceRadius,
    required this.useMovingGeofence,
    required this.movingGeofenceRadius,
    required this.syncGeofences,
    required this.beacons,
    required this.useMotion,
    required this.usePressure,
    this.startTrackingAfter,
    this.stopTrackingAfter,
    this.batchInterval = Duration.zero,
    this.batchSize = 0,
    this.type = RadarTrackingOptionsType.defaultType,
    this.fastestStoppedUpdateInterval,
    this.fastestMovingUpdateInterval,
    this.syncGeofencesLimit,
    this.foregroundServiceEnabled,
    this.showBlueBar,
    this.useVisits,
    this.useSignificantLocationChanges,
    this.useIndoorScan,
  });

  /// How often to request location updates when stopped. Use zero to shut
  /// down when stopped. Sent to the native SDK in whole seconds.
  final Duration desiredStoppedUpdateInterval;

  /// How often to request location updates when moving. Sent in whole
  /// seconds.
  final Duration desiredMovingUpdateInterval;

  /// How often to sync location updates to the server. Sent in whole seconds.
  final Duration desiredSyncInterval;

  final RadarTrackingOptionsDesiredAccuracy desiredAccuracy;

  /// How long the device must stay within [stopDistance] to be considered
  /// stopped. Sent in whole seconds.
  final Duration stopDuration;

  /// How far, in meters, the device can move within [stopDuration] and still
  /// be considered stopped.
  final int stopDistance;

  final RadarTrackingOptionsReplay replay;

  /// Which location updates to sync to the server. Sent as `sync`.
  final RadarTrackingOptionsSyncLocations syncLocations;

  /// Whether to create a client geofence around the device's location when
  /// stopped, to wake the app on exit.
  final bool useStoppedGeofence;

  /// The radius, in meters, of the stopped geofence.
  final int stoppedGeofenceRadius;

  /// Whether to create a client geofence around the device's location when
  /// moving, to wake the app on exit.
  final bool useMovingGeofence;

  /// The radius, in meters, of the moving geofence.
  final int movingGeofenceRadius;

  /// Whether to sync nearby geofences from the server to the client to
  /// improve responsiveness.
  ///
  /// The Android SDK also has a campaign-only mode, which currently behaves
  /// like `true`. It can't be set from Dart, and reads back as `true`.
  final bool syncGeofences;

  /// Whether to monitor beacons.
  final bool beacons;

  /// Whether to use the motion sensors. Requires the motion add-on.
  final bool useMotion;

  /// Whether to use the barometer. Requires the motion add-on.
  final bool usePressure;

  /// When to start tracking. Null starts tracking immediately.
  final DateTime? startTrackingAfter;

  /// When to stop tracking. Null tracks until stopped.
  final DateTime? stopTrackingAfter;

  /// The time between batched location syncs. Zero disables interval-based
  /// batching. Sent in whole seconds.
  final Duration batchInterval;

  /// The number of location updates to batch before syncing. Zero disables
  /// size-based batching.
  final int batchSize;

  /// Where these options came from. Read-only in practice: the native SDK
  /// sets it on remote tracking options.
  final RadarTrackingOptionsType type;

  /// Android only. The fastest rate at which the app will accept location
  /// updates when stopped. Sent in whole seconds.
  final Duration? fastestStoppedUpdateInterval;

  /// Android only. The fastest rate at which the app will accept location
  /// updates when moving. Sent in whole seconds.
  final Duration? fastestMovingUpdateInterval;

  /// Android only. The maximum number of geofences to sync. The SDK defaults
  /// to 10 when omitted.
  final int? syncGeofencesLimit;

  /// Android only. Whether to run a foreground service while tracking. See
  /// `Radar.setForegroundServiceOptions`.
  final bool? foregroundServiceEnabled;

  /// iOS only. Whether to show the blue status bar while tracking in the
  /// background.
  final bool? showBlueBar;

  /// iOS only. Whether to use the iOS visit monitoring service.
  final bool? useVisits;

  /// iOS only. Whether to use the iOS significant location change service.
  final bool? useSignificantLocationChanges;

  /// iOS only. Whether to scan for indoor location. Requires the indoors
  /// add-on.
  final bool? useIndoorScan;

  /// Responsive tracking for the current platform: updates about every 2.5
  /// minutes when moving and shuts down when stopped.
  static RadarTrackingOptions get responsive =>
      _isIOS ? responsiveIOS : responsiveAndroid;

  /// Continuous tracking for the current platform: updates about every 30
  /// seconds.
  static RadarTrackingOptions get continuous =>
      _isIOS ? continuousIOS : continuousAndroid;

  /// Efficient tracking for the current platform: low battery use, with
  /// updates mostly at stops.
  static RadarTrackingOptions get efficient =>
      _isIOS ? efficientIOS : efficientAndroid;

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static const responsiveIOS = RadarTrackingOptions(
    desiredStoppedUpdateInterval: Duration.zero,
    desiredMovingUpdateInterval: Duration(seconds: 150),
    desiredSyncInterval: Duration(seconds: 20),
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.medium,
    stopDuration: Duration(seconds: 140),
    stopDistance: 70,
    replay: RadarTrackingOptionsReplay.stops,
    syncLocations: RadarTrackingOptionsSyncLocations.all,
    useStoppedGeofence: true,
    stoppedGeofenceRadius: 100,
    useMovingGeofence: true,
    movingGeofenceRadius: 100,
    syncGeofences: true,
    beacons: false,
    useMotion: false,
    usePressure: false,
    showBlueBar: false,
    useVisits: true,
    useSignificantLocationChanges: true,
    useIndoorScan: false,
  );

  static const responsiveAndroid = RadarTrackingOptions(
    desiredStoppedUpdateInterval: Duration.zero,
    fastestStoppedUpdateInterval: Duration.zero,
    desiredMovingUpdateInterval: Duration(seconds: 150),
    fastestMovingUpdateInterval: Duration(seconds: 30),
    desiredSyncInterval: Duration(seconds: 20),
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.medium,
    stopDuration: Duration(seconds: 140),
    stopDistance: 70,
    replay: RadarTrackingOptionsReplay.stops,
    syncLocations: RadarTrackingOptionsSyncLocations.all,
    useStoppedGeofence: true,
    stoppedGeofenceRadius: 100,
    useMovingGeofence: true,
    movingGeofenceRadius: 100,
    syncGeofences: true,
    syncGeofencesLimit: 10,
    foregroundServiceEnabled: false,
    beacons: false,
    useMotion: false,
    usePressure: false,
  );

  static const continuousIOS = RadarTrackingOptions(
    desiredStoppedUpdateInterval: Duration(seconds: 30),
    desiredMovingUpdateInterval: Duration(seconds: 30),
    desiredSyncInterval: Duration(seconds: 20),
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,
    stopDuration: Duration(seconds: 140),
    stopDistance: 70,
    replay: RadarTrackingOptionsReplay.none,
    syncLocations: RadarTrackingOptionsSyncLocations.all,
    useStoppedGeofence: false,
    stoppedGeofenceRadius: 0,
    useMovingGeofence: false,
    movingGeofenceRadius: 0,
    syncGeofences: true,
    beacons: false,
    useMotion: false,
    usePressure: false,
    showBlueBar: true,
    useVisits: false,
    useSignificantLocationChanges: false,
    useIndoorScan: false,
  );

  static const continuousAndroid = RadarTrackingOptions(
    desiredStoppedUpdateInterval: Duration(seconds: 30),
    fastestStoppedUpdateInterval: Duration(seconds: 30),
    desiredMovingUpdateInterval: Duration(seconds: 30),
    fastestMovingUpdateInterval: Duration(seconds: 30),
    desiredSyncInterval: Duration(seconds: 20),
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,
    stopDuration: Duration(seconds: 140),
    stopDistance: 70,
    replay: RadarTrackingOptionsReplay.none,
    syncLocations: RadarTrackingOptionsSyncLocations.all,
    useStoppedGeofence: false,
    stoppedGeofenceRadius: 0,
    useMovingGeofence: false,
    movingGeofenceRadius: 0,
    syncGeofences: true,
    syncGeofencesLimit: 0,
    foregroundServiceEnabled: true,
    beacons: false,
    useMotion: false,
    usePressure: false,
  );

  static const efficientIOS = RadarTrackingOptions(
    desiredStoppedUpdateInterval: Duration.zero,
    desiredMovingUpdateInterval: Duration.zero,
    desiredSyncInterval: Duration.zero,
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.medium,
    stopDuration: Duration.zero,
    stopDistance: 0,
    replay: RadarTrackingOptionsReplay.stops,
    syncLocations: RadarTrackingOptionsSyncLocations.all,
    useStoppedGeofence: false,
    stoppedGeofenceRadius: 0,
    useMovingGeofence: false,
    movingGeofenceRadius: 0,
    syncGeofences: true,
    beacons: false,
    useMotion: false,
    usePressure: false,
    showBlueBar: false,
    useVisits: true,
    useSignificantLocationChanges: false,
    useIndoorScan: false,
  );

  static const efficientAndroid = RadarTrackingOptions(
    desiredStoppedUpdateInterval: Duration(seconds: 3600),
    fastestStoppedUpdateInterval: Duration(seconds: 1200),
    desiredMovingUpdateInterval: Duration(seconds: 1200),
    fastestMovingUpdateInterval: Duration(seconds: 360),
    desiredSyncInterval: Duration(seconds: 140),
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.medium,
    stopDuration: Duration(seconds: 140),
    stopDistance: 70,
    replay: RadarTrackingOptionsReplay.stops,
    syncLocations: RadarTrackingOptionsSyncLocations.all,
    useStoppedGeofence: false,
    stoppedGeofenceRadius: 0,
    useMovingGeofence: false,
    movingGeofenceRadius: 0,
    syncGeofences: true,
    syncGeofencesLimit: 10,
    foregroundServiceEnabled: false,
    beacons: false,
    useMotion: false,
    usePressure: false,
  );

  /// Parses the options returned by `Radar.getTrackingOptions`. Missing
  /// values fall back to what the native SDKs use for a missing key.
  @internal
  factory RadarTrackingOptions.fromMap(ChannelMap map) => RadarTrackingOptions(
    desiredStoppedUpdateInterval:
        _readSeconds(map['desiredStoppedUpdateInterval']) ?? Duration.zero,
    desiredMovingUpdateInterval:
        _readSeconds(map['desiredMovingUpdateInterval']) ?? Duration.zero,
    desiredSyncInterval:
        _readSeconds(map['desiredSyncInterval']) ?? Duration.zero,
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.fromWire(
      map['desiredAccuracy'],
    ),
    stopDuration: _readSeconds(map['stopDuration']) ?? Duration.zero,
    stopDistance: readInt(map['stopDistance']) ?? 0,
    replay: RadarTrackingOptionsReplay.fromWire(map['replay']),
    syncLocations: RadarTrackingOptionsSyncLocations.fromWire(map['sync']),
    useStoppedGeofence: readBool(map['useStoppedGeofence']) ?? false,
    stoppedGeofenceRadius: readInt(map['stoppedGeofenceRadius']) ?? 0,
    useMovingGeofence: readBool(map['useMovingGeofence']) ?? false,
    movingGeofenceRadius: readInt(map['movingGeofenceRadius']) ?? 0,
    syncGeofences: _readSyncGeofences(map['syncGeofences']),
    beacons: readBool(map['beacons']) ?? false,
    useMotion: readBool(map['useMotion']) ?? false,
    usePressure: readBool(map['usePressure']) ?? false,
    startTrackingAfter: readDate(map['startTrackingAfter']),
    stopTrackingAfter: readDate(map['stopTrackingAfter']),
    batchInterval: _readSeconds(map['batchInterval']) ?? Duration.zero,
    batchSize: readInt(map['batchSize']) ?? 0,
    type: RadarTrackingOptionsType.fromWire(map['type']),
    fastestStoppedUpdateInterval: _readSeconds(
      map['fastestStoppedUpdateInterval'],
    ),
    fastestMovingUpdateInterval: _readSeconds(
      map['fastestMovingUpdateInterval'],
    ),
    syncGeofencesLimit: readInt(map['syncGeofencesLimit']),
    foregroundServiceEnabled: readBool(map['foregroundServiceEnabled']),
    showBlueBar: readBool(map['showBlueBar']),
    useVisits: readBool(map['useVisits']),
    useSignificantLocationChanges: readBool(
      map['useSignificantLocationChanges'],
    ),
    useIndoorScan: readBool(map['useIndoorScan']),
  );

  /// The map read by `RadarTrackingOptions.fromJson` on Android and
  /// `trackingOptionsFromDictionary:` on iOS. Each platform ignores the
  /// other's keys. Dates are sent as milliseconds since the epoch.
  @internal
  Map<String, Object?> toMap() => compact({
    'desiredStoppedUpdateInterval': wholeSeconds(
      desiredStoppedUpdateInterval,
      'desiredStoppedUpdateInterval',
    ),
    'desiredMovingUpdateInterval': wholeSeconds(
      desiredMovingUpdateInterval,
      'desiredMovingUpdateInterval',
    ),
    'desiredSyncInterval': wholeSeconds(
      desiredSyncInterval,
      'desiredSyncInterval',
    ),
    'desiredAccuracy': desiredAccuracy.wireValue,
    'stopDuration': wholeSeconds(stopDuration, 'stopDuration'),
    'stopDistance': stopDistance,
    'replay': replay.wireValue,
    'sync': syncLocations.wireValue,
    'useStoppedGeofence': useStoppedGeofence,
    'stoppedGeofenceRadius': stoppedGeofenceRadius,
    'useMovingGeofence': useMovingGeofence,
    'movingGeofenceRadius': movingGeofenceRadius,
    'syncGeofences': syncGeofences,
    'beacons': beacons,
    'useMotion': useMotion,
    'usePressure': usePressure,
    'startTrackingAfter': startTrackingAfter?.millisecondsSinceEpoch,
    'stopTrackingAfter': stopTrackingAfter?.millisecondsSinceEpoch,
    'batchInterval': wholeSeconds(batchInterval, 'batchInterval'),
    'batchSize': batchSize,
    'type': type.wireValue,
    'fastestStoppedUpdateInterval': switch (fastestStoppedUpdateInterval) {
      final value? => wholeSeconds(value, 'fastestStoppedUpdateInterval'),
      null => null,
    },
    'fastestMovingUpdateInterval': switch (fastestMovingUpdateInterval) {
      final value? => wholeSeconds(value, 'fastestMovingUpdateInterval'),
      null => null,
    },
    'syncGeofencesLimit': syncGeofencesLimit,
    'foregroundServiceEnabled': foregroundServiceEnabled,
    'showBlueBar': showBlueBar,
    'useVisits': useVisits,
    'useSignificantLocationChanges': useSignificantLocationChanges,
    'useIndoorScan': useIndoorScan,
  });

  /// Returns a copy with the given fields replaced. Nullable fields cannot be
  /// reset to null this way; construct a new instance instead.
  RadarTrackingOptions copyWith({
    Duration? desiredStoppedUpdateInterval,
    Duration? desiredMovingUpdateInterval,
    Duration? desiredSyncInterval,
    RadarTrackingOptionsDesiredAccuracy? desiredAccuracy,
    Duration? stopDuration,
    int? stopDistance,
    RadarTrackingOptionsReplay? replay,
    RadarTrackingOptionsSyncLocations? syncLocations,
    bool? useStoppedGeofence,
    int? stoppedGeofenceRadius,
    bool? useMovingGeofence,
    int? movingGeofenceRadius,
    bool? syncGeofences,
    bool? beacons,
    bool? useMotion,
    bool? usePressure,
    DateTime? startTrackingAfter,
    DateTime? stopTrackingAfter,
    Duration? batchInterval,
    int? batchSize,
    RadarTrackingOptionsType? type,
    Duration? fastestStoppedUpdateInterval,
    Duration? fastestMovingUpdateInterval,
    int? syncGeofencesLimit,
    bool? foregroundServiceEnabled,
    bool? showBlueBar,
    bool? useVisits,
    bool? useSignificantLocationChanges,
    bool? useIndoorScan,
  }) => RadarTrackingOptions(
    desiredStoppedUpdateInterval:
        desiredStoppedUpdateInterval ?? this.desiredStoppedUpdateInterval,
    desiredMovingUpdateInterval:
        desiredMovingUpdateInterval ?? this.desiredMovingUpdateInterval,
    desiredSyncInterval: desiredSyncInterval ?? this.desiredSyncInterval,
    desiredAccuracy: desiredAccuracy ?? this.desiredAccuracy,
    stopDuration: stopDuration ?? this.stopDuration,
    stopDistance: stopDistance ?? this.stopDistance,
    replay: replay ?? this.replay,
    syncLocations: syncLocations ?? this.syncLocations,
    useStoppedGeofence: useStoppedGeofence ?? this.useStoppedGeofence,
    stoppedGeofenceRadius: stoppedGeofenceRadius ?? this.stoppedGeofenceRadius,
    useMovingGeofence: useMovingGeofence ?? this.useMovingGeofence,
    movingGeofenceRadius: movingGeofenceRadius ?? this.movingGeofenceRadius,
    syncGeofences: syncGeofences ?? this.syncGeofences,
    beacons: beacons ?? this.beacons,
    useMotion: useMotion ?? this.useMotion,
    usePressure: usePressure ?? this.usePressure,
    startTrackingAfter: startTrackingAfter ?? this.startTrackingAfter,
    stopTrackingAfter: stopTrackingAfter ?? this.stopTrackingAfter,
    batchInterval: batchInterval ?? this.batchInterval,
    batchSize: batchSize ?? this.batchSize,
    type: type ?? this.type,
    fastestStoppedUpdateInterval:
        fastestStoppedUpdateInterval ?? this.fastestStoppedUpdateInterval,
    fastestMovingUpdateInterval:
        fastestMovingUpdateInterval ?? this.fastestMovingUpdateInterval,
    syncGeofencesLimit: syncGeofencesLimit ?? this.syncGeofencesLimit,
    foregroundServiceEnabled:
        foregroundServiceEnabled ?? this.foregroundServiceEnabled,
    showBlueBar: showBlueBar ?? this.showBlueBar,
    useVisits: useVisits ?? this.useVisits,
    useSignificantLocationChanges:
        useSignificantLocationChanges ?? this.useSignificantLocationChanges,
    useIndoorScan: useIndoorScan ?? this.useIndoorScan,
  );

  List<Object?> get _props => [
    desiredStoppedUpdateInterval,
    desiredMovingUpdateInterval,
    desiredSyncInterval,
    desiredAccuracy,
    stopDuration,
    stopDistance,
    replay,
    syncLocations,
    useStoppedGeofence,
    stoppedGeofenceRadius,
    useMovingGeofence,
    movingGeofenceRadius,
    syncGeofences,
    beacons,
    useMotion,
    usePressure,
    startTrackingAfter,
    stopTrackingAfter,
    batchInterval,
    batchSize,
    type,
    fastestStoppedUpdateInterval,
    fastestMovingUpdateInterval,
    syncGeofencesLimit,
    foregroundServiceEnabled,
    showBlueBar,
    useVisits,
    useSignificantLocationChanges,
    useIndoorScan,
  ];

  @override
  bool operator ==(Object other) =>
      other is RadarTrackingOptions && listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);

  @override
  String toString() => 'RadarTrackingOptions(${toMap()})';
}

Duration? _readSeconds(Object? value) {
  final seconds = readInt(value);
  return seconds == null ? null : Duration(seconds: seconds);
}

/// iOS sends a bool. Android's `toJson` sends `"none"`, `"nearest"`, or
/// `"campaign-only"`, and its `fromJson` maps `true` to `"nearest"`.
bool _readSyncGeofences(Object? value) => switch (value) {
  String() when value != 'true' && value != 'false' && value != 'null' =>
    value != 'none',
  _ => readBool(value) ?? false,
};
