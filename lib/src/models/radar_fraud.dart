import 'package:meta/meta.dart';

import 'parsing.dart';

/// Fraud detection signals for a user or event.
///
/// These values should not be trusted unless they came from
/// [Radar.trackVerified] rather than [Radar.trackOnce]. Each flag is `false`
/// if Fraud is not enabled. See the
/// [fraud docs](https://radar.com/documentation/fraud).
final class RadarFraud {
  const RadarFraud({
    this.passed = false,
    this.bypassed = false,
    this.verified = false,
    this.proxy = false,
    this.mocked = false,
    this.compromised = false,
    this.jumped = false,
    this.inaccurate = false,
    this.sharing = false,
    this.blocked = false,
  });

  /// Whether the user passed fraud detection checks.
  final bool passed;

  /// Whether fraud detection checks were bypassed for the user for testing.
  final bool bypassed;

  /// Whether the request was made with SSL pinning configured successfully.
  final bool verified;

  /// Whether the user's IP address is a known proxy.
  final bool proxy;

  /// Whether the user's location is being mocked, such as in a simulator or
  /// with a location spoofing app.
  final bool mocked;

  /// Whether the user's device has been compromised, according to the Play
  /// Integrity API on Android or App Attest on iOS.
  final bool compromised;

  /// Whether the user moved too far too fast.
  final bool jumped;

  /// Whether the user's location is not accurate enough.
  final bool inaccurate;

  /// Whether the user is screen sharing.
  final bool sharing;

  /// Whether the user has been manually blocked.
  final bool blocked;

  @internal
  factory RadarFraud.fromMap(ChannelMap map) => RadarFraud(
    passed: readBool(map['passed']) ?? false,
    bypassed: readBool(map['bypassed']) ?? false,
    verified: readBool(map['verified']) ?? false,
    proxy: readBool(map['proxy']) ?? false,
    mocked: readBool(map['mocked']) ?? false,
    compromised: readBool(map['compromised']) ?? false,
    jumped: readBool(map['jumped']) ?? false,
    inaccurate: readBool(map['inaccurate']) ?? false,
    sharing: readBool(map['sharing']) ?? false,
    blocked: readBool(map['blocked']) ?? false,
  );
}
