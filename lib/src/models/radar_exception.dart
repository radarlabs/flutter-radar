import 'radar_status.dart';

/// Thrown when a Radar request fails, such as [Radar.trackOnce] without
/// location permissions or with no network.
///
/// Only Radar failures throw this. A failure in the plugin itself, such as a
/// native error, throws a `PlatformException`.
///
/// Errors from background tracking, where nothing is awaiting a result, are
/// delivered to [Radar.onError] and the background handler instead.
final class RadarException implements Exception {
  /// Creates a [RadarException] with the given [status].
  const RadarException(this.status);

  /// Why the request failed. Never [RadarStatus.success].
  final RadarStatus status;

  @override
  String toString() => 'RadarException(${status.name})';
}
