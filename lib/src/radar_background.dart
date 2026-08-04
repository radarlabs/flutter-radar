enum RadarBackgroundEventType {
  location,
  clientLocation,
  events,
  error,
  log,
  token,
  ipChanged,
  sharingChanged,
}

final class RadarBackgroundEvent {
  const RadarBackgroundEvent({required this.type, required this.payload});

  final RadarBackgroundEventType type;
  final Map<String, dynamic> payload;
}

typedef RadarBackgroundHandler =
    Future<void> Function(RadarBackgroundEvent event);
