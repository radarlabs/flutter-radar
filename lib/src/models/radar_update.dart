import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_event.dart';
import 'radar_location.dart';
import 'radar_status.dart';
import 'radar_user.dart';
import 'radar_verified_location_token.dart';

/// Something the native Radar SDK reports on its own, when it happens, rather
/// than in response to a call. For example:
///
/// - [RadarEventsUpdate]: the user entered or exited a geofence, or arrived
///   at a trip destination.
/// - [RadarLocationUpdate]: the user's location was sent to Radar while
///   tracking.
/// - [RadarErrorUpdate]: getting or sending a location failed, for example
///   because location permission is missing or a request to Radar failed.
///
/// Each kind is delivered to its own listener, such as [Radar.onEvents], and
/// every kind is delivered to the handler passed to
/// [Radar.registerBackgroundHandler], whether the app is in the foreground or
/// the background.
///
/// The class is sealed, so a background handler can `switch` over every kind
/// of update. Without a `default` case, the switch stops compiling if a new
/// kind is added, so it can't be missed. Add a `default` case instead to
/// ignore kinds added later:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> radarBackgroundHandler(RadarUpdate update) async {
///   switch (update) {
///     case RadarEventsUpdate(:final events):
///       // ...
///     case RadarLocationUpdate(:final location, :final user):
///       // ...
///     case RadarClientLocationUpdate() ||
///         RadarErrorUpdate() ||
///         RadarLogUpdate() ||
///         RadarTokenUpdate() ||
///         RadarIpChangedUpdate() ||
///         RadarSharingChangedUpdate():
///       break;
///   }
/// }
/// ```
sealed class RadarUpdate {
  const RadarUpdate();

  /// Parses an update from the method name and payload the native side sends.
  /// Returns null for an unknown method, or a payload missing a value both
  /// native SDKs always send.
  @internal
  static RadarUpdate? fromMethodCall(String method, ChannelMap payload) =>
      switch (method) {
        'location' => RadarLocationUpdate.fromMap(payload),
        'clientLocation' => RadarClientLocationUpdate.fromMap(payload),
        'events' => RadarEventsUpdate.fromMap(payload),
        'error' => RadarErrorUpdate.fromMap(payload),
        'log' => RadarLogUpdate.fromMap(payload),
        'token' => RadarTokenUpdate.fromMap(payload),
        'ipChanged' => const RadarIpChangedUpdate(),
        'sharingChanged' => RadarSharingChangedUpdate.fromMap(payload),
        _ => null,
      };
}

/// The user's location was sent to the server. Delivered to
/// [Radar.onLocation].
final class RadarLocationUpdate extends RadarUpdate {
  const RadarLocationUpdate({required this.location, required this.user});

  /// The location that was sent.
  final RadarLocation location;

  /// The current user.
  final RadarUser user;

  @internal
  static RadarLocationUpdate? fromMap(ChannelMap map) {
    final location = RadarLocation.fromMap(readMap(map['location']));
    final user = readObject(map['user'], RadarUser.fromMap);
    if (location == null || user == null) return null;
    return RadarLocationUpdate(location: location, user: user);
  }
}

/// The device's location changed, whether or not it was sent to the server.
/// Delivered to [Radar.onClientLocation].
final class RadarClientLocationUpdate extends RadarUpdate {
  const RadarClientLocationUpdate({
    required this.location,
    required this.stopped,
    required this.source,
  });

  /// The device's location.
  final RadarLocation location;

  /// Whether the device is stopped.
  final bool stopped;

  /// The source of the location.
  final RadarLocationSource source;

  @internal
  static RadarClientLocationUpdate? fromMap(ChannelMap map) {
    final location = RadarLocation.fromMap(readMap(map['location']));
    if (location == null) return null;
    return RadarClientLocationUpdate(
      location: location,
      stopped: readBool(map['stopped']) ?? false,
      source: RadarLocationSource.fromWire(map['source']),
    );
  }
}

/// The server returned events. Delivered to [Radar.onEvents].
final class RadarEventsUpdate extends RadarUpdate {
  const RadarEventsUpdate({required this.events, this.user});

  /// The events received.
  final List<RadarEvent> events;

  /// The user, if any.
  final RadarUser? user;

  @internal
  factory RadarEventsUpdate.fromMap(ChannelMap map) => RadarEventsUpdate(
    events: readList(map['events'], RadarEvent.fromMap),
    user: readObject(map['user'], RadarUser.fromMap),
  );
}

/// A request failed. Delivered to [Radar.onError].
final class RadarErrorUpdate extends RadarUpdate {
  const RadarErrorUpdate({required this.status});

  /// The status of the failed request.
  final RadarStatus status;

  @internal
  factory RadarErrorUpdate.fromMap(ChannelMap map) =>
      RadarErrorUpdate(status: RadarStatus.fromWire(map['status']));
}

/// The SDK logged a message. Delivered to [Radar.onLog].
final class RadarLogUpdate extends RadarUpdate {
  const RadarLogUpdate({required this.message});

  /// The log message.
  final String message;

  @internal
  factory RadarLogUpdate.fromMap(ChannelMap map) =>
      RadarLogUpdate(message: readString(map['message']) ?? '');
}

/// A new verified location token was issued. Delivered to [Radar.onToken].
final class RadarTokenUpdate extends RadarUpdate {
  const RadarTokenUpdate({required this.token});

  /// The new verified location token. Verify it server-side with your secret
  /// key.
  final RadarVerifiedLocationToken token;

  @internal
  static RadarTokenUpdate? fromMap(ChannelMap map) {
    final token = readObject(map['token'], RadarVerifiedLocationToken.fromMap);
    return token == null ? null : RadarTokenUpdate(token: token);
  }
}

/// The device's IP address changed while IP change monitoring is active.
/// Delivered to [Radar.onIpChanged].
final class RadarIpChangedUpdate extends RadarUpdate {
  const RadarIpChangedUpdate();
}

/// The device's screen sharing state changed. Delivered to
/// [Radar.onSharingChanged].
final class RadarSharingChangedUpdate extends RadarUpdate {
  const RadarSharingChangedUpdate({required this.sharing});

  /// Whether the device is screen sharing.
  final bool sharing;

  @internal
  factory RadarSharingChangedUpdate.fromMap(ChannelMap map) =>
      RadarSharingChangedUpdate(sharing: readBool(map['sharing']) ?? false);
}
