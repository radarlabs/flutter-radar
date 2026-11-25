import 'package:meta/meta.dart';

import 'parsing.dart';

/// The level of logging the native SDK writes, set with `Radar.setLogLevel`.
enum RadarLogLevel implements RadarWireEnum {
  none('none'),
  error('error'),
  warning('warning'),
  info('info'),
  debug('debug');

  const RadarLogLevel(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarLogLevel fromWire(Object? value) => readEnum(values, value, none);
}

/// The app's location permissions status, from `Radar.getPermissionsStatus`.
enum RadarPermissionsStatus implements RadarWireEnum {
  /// The user granted foreground ("when in use") location permissions.
  grantedForeground('GRANTED_FOREGROUND'),

  /// The user granted background ("always") location permissions. On Android
  /// below API 29, this is reported whenever fine location is granted.
  grantedBackground('GRANTED_BACKGROUND'),

  /// The user denied location permissions. On iOS, this includes the
  /// restricted status.
  denied('DENIED'),

  /// The user has not been asked for location permissions yet. On Android,
  /// this is only reported when the plugin is not attached to an activity.
  notDetermined('NOT_DETERMINED'),

  /// The native side returned a value this version of the plugin does not
  /// recognize.
  unknown('UNKNOWN');

  const RadarPermissionsStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Whether foreground or background permissions are granted.
  bool get isGranted => this == grantedForeground || this == grantedBackground;

  @internal
  static RadarPermissionsStatus fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// A travel mode for routing, used by `Radar.getDistance`, `Radar.getMatrix`,
/// and `Radar.mockTracking`.
enum RadarRouteMode implements RadarWireEnum {
  /// Foot.
  foot('foot'),

  /// Bike.
  bike('bike'),

  /// Car.
  car('car'),

  /// Truck.
  truck('truck'),

  /// Motorbike.
  motorbike('motorbike');

  const RadarRouteMode(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarRouteMode fromWire(Object? value) => readEnum(values, value, car);
}

/// The distance units for routing.
enum RadarRouteUnits implements RadarWireEnum {
  /// Imperial (feet).
  imperial('imperial'),

  /// Metric (meters).
  metric('metric');

  const RadarRouteUnits(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarRouteUnits fromWire(Object? value) =>
      readEnum(values, value, imperial);
}
