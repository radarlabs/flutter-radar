import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_event.dart';
import 'radar_reveal_risk_token.dart';
import 'radar_user.dart';

/// A verified location token, from [Radar.trackVerified] or
/// [Radar.getVerifiedLocationToken].
///
/// Both native SDKs send the API's response as-is, so the nested [user] and
/// [events] are in the API's format rather than the native SDKs' serialized
/// format.
final class RadarVerifiedLocationToken {
  const RadarVerifiedLocationToken({
    this.token,
    this.format = RadarResponseFormat.jws,
    this.id,
    this.user,
    this.events = const [],
    this.expiresAt,
    this.expiresIn,
    this.passed = false,
    this.failureReasons = const [],
    this.raw = const {},
  });

  /// The token to relay to your backend for verification. A [RadarResponseFormat.jws]
  /// token is a signed JWT containing the user and events; a
  /// [RadarResponseFormat.jwe] token must first be decrypted by your backend.
  /// Null for [RadarResponseFormat.id] responses.
  final String? token;

  /// The response format selected by the server. [user], [events], and
  /// [failureReasons] are only available for [RadarResponseFormat.jws].
  final RadarResponseFormat format;

  /// The Radar ID of the location check.
  final String? id;
  final RadarUser? user;
  final List<RadarEvent> events;

  /// When the token expires.
  final DateTime? expiresAt;

  /// How long the token was valid for when it was issued.
  final Duration? expiresIn;

  /// Whether the user passed all jurisdiction and fraud detection checks.
  final bool passed;

  /// The reasons any jurisdiction or fraud detection checks failed.
  final List<String> failureReasons;

  /// The full API response the token was parsed from.
  final Map<String, Object?> raw;

  @internal
  factory RadarVerifiedLocationToken.fromMap(ChannelMap map) =>
      RadarVerifiedLocationToken(
        token: readString(map['token']),
        format: RadarResponseFormat.fromWire(map['format']),
        id: readString(map['_id']),
        user: readObject(map['user'], RadarUser.fromMap),
        events: readList(map['events'], RadarEvent.fromMap),
        expiresAt: readDate(map['expiresAt']),
        expiresIn: readSeconds(map['expiresIn']),
        passed: readBool(map['passed']) ?? false,
        failureReasons: readStringList(map['failureReasons']),
        raw: readJson(map) ?? const {},
      );
}
