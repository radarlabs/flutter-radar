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

  /// Parses a log level string. Unrecognized values become [none].
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

  bool get isGranted => this == grantedForeground || this == grantedBackground;

  /// Parses a native permissions status. Unrecognized values become
  /// [unknown].
  @internal
  static RadarPermissionsStatus fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// A travel mode for routing, used by `Radar.getDistance`, `Radar.getMatrix`,
/// and `Radar.mockTracking`.
///
/// [truck] and [motorbike] are only supported by `getMatrix`. `getDistance`
/// and `mockTracking` treat them as [car].
enum RadarRouteMode implements RadarWireEnum {
  foot('foot'),
  bike('bike'),
  car('car'),
  truck('truck'),
  motorbike('motorbike');

  const RadarRouteMode(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a route mode string. Unrecognized values become [car], matching
  /// the native bridges.
  @internal
  static RadarRouteMode fromWire(Object? value) => readEnum(values, value, car);
}

/// The distance units for routing.
enum RadarRouteUnits implements RadarWireEnum {
  imperial('imperial'),
  metric('metric');

  const RadarRouteUnits(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a units string. Unrecognized values become [imperial], matching
  /// the native bridges.
  @internal
  static RadarRouteUnits fromWire(Object? value) =>
      readEnum(values, value, imperial);
}
