import 'package:meta/meta.dart';

import 'parsing.dart';

/// The status of a Radar request.
enum RadarStatus implements RadarWireEnum {
  success('SUCCESS'),
  errorPublishableKey('ERROR_PUBLISHABLE_KEY'),
  errorPermissions('ERROR_PERMISSIONS'),
  errorLocation('ERROR_LOCATION'),
  errorBluetooth('ERROR_BLUETOOTH'),
  errorNetwork('ERROR_NETWORK'),
  errorBadRequest('ERROR_BAD_REQUEST'),
  errorUnauthorized('ERROR_UNAUTHORIZED'),
  errorPaymentRequired('ERROR_PAYMENT_REQUIRED'),
  errorForbidden('ERROR_FORBIDDEN'),
  errorNotFound('ERROR_NOT_FOUND'),
  errorPlugin('ERROR_PLUGIN'),
  errorRateLimit('ERROR_RATE_LIMIT'),
  errorServer('ERROR_SERVER'),
  errorUnknown('ERROR_UNKNOWN'),
  notAvailable('NOT_AVAILABLE');

  const RadarStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  bool get isSuccess => this == success;

  /// Parses a native status string. Unrecognized values become [errorUnknown].
  @internal
  static RadarStatus fromWire(Object? value) =>
      readEnum(values, value, errorUnknown);
}
