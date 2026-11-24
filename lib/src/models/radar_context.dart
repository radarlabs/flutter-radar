import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_geofence.dart';
import 'radar_place.dart';
import 'radar_region.dart';

/// The geofences, place, and regions at a location.
final class RadarContext {
  const RadarContext({
    this.geofences = const [],
    this.place,
    this.country,
    this.state,
    this.dma,
    this.postalCode,
  });

  final List<RadarGeofence> geofences;
  final RadarPlace? place;
  final RadarRegion? country;
  final RadarRegion? state;

  /// The designated market area.
  final RadarRegion? dma;
  final RadarRegion? postalCode;

  @internal
  factory RadarContext.fromMap(ChannelMap map) => RadarContext(
    geofences: readList(map['geofences'], RadarGeofence.fromMap),
    place: readObject(map['place'], RadarPlace.fromMap),
    country: readObject(map['country'], RadarRegion.fromMap),
    state: readObject(map['state'], RadarRegion.fromMap),
    dma: readObject(map['dma'], RadarRegion.fromMap),
    postalCode: readObject(map['postalCode'], RadarRegion.fromMap),
  );
}
