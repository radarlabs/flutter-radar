import 'package:meta/meta.dart';

import 'parsing.dart';

/// The status of a Radar request.
enum RadarStatus implements RadarWireEnum {
  /// The request succeeded.
  success('SUCCESS'),

  /// The SDK is not initialized.
  errorPublishableKey('ERROR_PUBLISHABLE_KEY'),

  /// Location permissions are not granted.
  errorPermissions('ERROR_PERMISSIONS'),

  /// Location services failed or timed out (20 seconds).
  errorLocation('ERROR_LOCATION'),

  /// Beacon ranging failed or timed out (5 seconds).
  errorBluetooth('ERROR_BLUETOOTH'),

  /// The network request failed or timed out (10 seconds by default; set
  /// `RadarInitializeOptions.networkTimeout` to change it).
  errorNetwork('ERROR_NETWORK'),

  /// Bad request (missing or invalid params).
  errorBadRequest('ERROR_BAD_REQUEST'),

  /// Unauthorized (invalid API key).
  errorUnauthorized('ERROR_UNAUTHORIZED'),

  /// Payment required (organization disabled or usage exceeded).
  errorPaymentRequired('ERROR_PAYMENT_REQUIRED'),

  /// Forbidden (insufficient permissions or no beta access).
  errorForbidden('ERROR_FORBIDDEN'),

  /// Not found.
  errorNotFound('ERROR_NOT_FOUND'),

  /// A required plugin is missing.
  errorPlugin('ERROR_PLUGIN'),

  /// Too many requests (rate limit exceeded).
  errorRateLimit('ERROR_RATE_LIMIT'),

  /// Internal server error.
  errorServer('ERROR_SERVER'),

  /// Unknown error. Also used for unrecognized status strings.
  errorUnknown('ERROR_UNKNOWN'),

  /// The feature is not available. The current native SDKs do not report
  /// this status.
  notAvailable('NOT_AVAILABLE');

  const RadarStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Whether this is [success].
  bool get isSuccess => this == success;

  @internal
  static RadarStatus fromWire(Object? value) =>
      readEnum(values, value, errorUnknown);
}
