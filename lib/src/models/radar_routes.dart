import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_location.dart';

/// The distance of a route.
final class RadarRouteDistance {
  const RadarRouteDistance({required this.value, required this.text});

  /// The distance in feet (imperial units) or meters (metric units).
  final double value;

  /// A display string for the distance, such as `1.2 mi`.
  final String text;

  @internal
  factory RadarRouteDistance.fromMap(ChannelMap map) => RadarRouteDistance(
    value: readDouble(map['value']) ?? 0,
    text: readString(map['text']) ?? '',
  );
}

/// The duration of a route.
final class RadarRouteDuration {
  const RadarRouteDuration({required this.value, required this.text});

  /// The duration.
  final Duration value;

  /// A display string for the duration, such as `8 mins`.
  final String text;

  @internal
  factory RadarRouteDuration.fromMap(ChannelMap map) => RadarRouteDuration(
    value: readMinutes(map['value']) ?? Duration.zero,
    text: readString(map['text']) ?? '',
  );
}

/// The geometry of a route, a GeoJSON `LineString`.
final class RadarRouteGeometry {
  const RadarRouteGeometry({this.coordinates = const []});

  final List<RadarCoordinate> coordinates;

  @internal
  factory RadarRouteGeometry.fromMap(ChannelMap map) {
    final coordinates = map['coordinates'];
    return RadarRouteGeometry(
      coordinates:
          coordinates is List
              ? [
                for (final pair in coordinates)
                  if (RadarCoordinate.fromLngLat(pair) case final coordinate?)
                    coordinate,
              ]
              : const [],
    );
  }
}

/// A route between an origin and a destination. See the
/// [routing API docs](https://radar.com/documentation/api#routing).
final class RadarRoute {
  const RadarRoute({this.distance, this.duration, this.geometry});

  /// The distance of the route.
  final RadarRouteDistance? distance;

  /// The duration of the route.
  final RadarRouteDuration? duration;

  /// The geometry of the route.
  final RadarRouteGeometry? geometry;

  @internal
  factory RadarRoute.fromMap(ChannelMap map) => RadarRoute(
    distance: readObject(map['distance'], RadarRouteDistance.fromMap),
    duration: readObject(map['duration'], RadarRouteDuration.fromMap),
    geometry: readObject(map['geometry'], RadarRouteGeometry.fromMap),
  );
}

/// Routes between an origin and a destination for each travel mode, from
/// [Radar.getDistance]. A mode is null if it was not requested. See the
/// [distance API docs](https://radar.com/documentation/api#distance).
final class RadarRoutes {
  const RadarRoutes({
    this.geodesic,
    this.foot,
    this.bike,
    this.car,
    this.truck,
    this.motorbike,
  });

  /// The straight-line distance.
  final RadarRouteDistance? geodesic;

  /// The route by foot. Null if the mode was not requested or the route is
  /// unavailable.
  final RadarRoute? foot;

  /// The route by bike. Null if the mode was not requested or the route is
  /// unavailable.
  final RadarRoute? bike;

  /// The route by car. Null if the mode was not requested or the route is
  /// unavailable.
  final RadarRoute? car;

  /// The route by truck. Null if the mode was not requested or the route is
  /// unavailable.
  final RadarRoute? truck;

  /// The route by motorbike. Null if the mode was not requested or the route
  /// is unavailable.
  final RadarRoute? motorbike;

  @internal
  factory RadarRoutes.fromMap(ChannelMap map) => RadarRoutes(
    geodesic: _readGeodesic(map['geodesic']),
    foot: readObject(map['foot'], RadarRoute.fromMap),
    bike: readObject(map['bike'], RadarRoute.fromMap),
    car: readObject(map['car'], RadarRoute.fromMap),
    truck: readObject(map['truck'], RadarRoute.fromMap),
    motorbike: readObject(map['motorbike'], RadarRoute.fromMap),
  );
}

/// A matrix of routes between multiple origins and destinations, from
/// [Radar.getMatrix]. See the
/// [matrix API docs](https://radar.com/documentation/api#matrix).
final class RadarRouteMatrix {
  const RadarRouteMatrix({this.rows = const []});

  /// One row per origin, each with one route per destination. A route is
  /// null if the native SDK could not parse it.
  final List<List<RadarRoute?>> rows;

  @internal
  static RadarRouteMatrix? fromWire(Object? value) {
    if (value is! List) return null;
    return RadarRouteMatrix(
      rows: [
        for (final row in value)
          if (row is List)
            [for (final route in row) readObject(route, RadarRoute.fromMap)]
          else
            const <RadarRoute?>[],
      ],
    );
  }

  /// The route from the origin at [originIndex] to the destination at
  /// [destinationIndex], or null if either index is out of range.
  RadarRoute? routeBetween(int originIndex, int destinationIndex) {
    if (originIndex < 0 || originIndex >= rows.length) return null;
    final row = rows[originIndex];
    if (destinationIndex < 0 || destinationIndex >= row.length) return null;
    return row[destinationIndex];
  }
}

/// Android wraps the geodesic distance as `{distance: {value, text}}`, and iOS
/// sends the distance itself.
RadarRouteDistance? _readGeodesic(Object? value) {
  final map = readMap(value);
  if (map == null) return null;
  return RadarRouteDistance.fromMap(readMap(map['distance']) ?? map);
}
