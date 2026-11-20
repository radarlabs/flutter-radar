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

  /// The geofences for the location. Empty if the location is not in any
  /// geofences. See the [geofences docs](https://radar.com/documentation/geofences).
  final List<RadarGeofence> geofences;

  /// The place for the location. Null if the location is not at a place or if
  /// Places is not enabled. See the
  /// [places docs](https://radar.com/documentation/places).
  final RadarPlace? place;

  /// The country of the location. Null if country is not available or if
  /// Regions is not enabled. See the
  /// [regions docs](https://radar.com/documentation/regions).
  final RadarRegion? country;

  /// The state of the location. Null if state is not available or if Regions
  /// is not enabled.
  final RadarRegion? state;

  /// The designated market area (DMA) of the location. Null if DMA is not
  /// available or if Regions is not enabled.
  final RadarRegion? dma;

  /// The postal code of the location. Null if postal code is not available or
  /// if Regions is not enabled.
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
