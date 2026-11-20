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

  /// The duration in minutes.
  final double value;

  /// A display string for the duration, such as `8 mins`.
  final String text;

  @internal
  factory RadarRouteDuration.fromMap(ChannelMap map) => RadarRouteDuration(
    value: readDouble(map['value']) ?? 0,
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

/// A route between an origin and a destination.
final class RadarRoute {
  const RadarRoute({this.distance, this.duration, this.geometry});

  final RadarRouteDistance? distance;
  final RadarRouteDuration? duration;
  final RadarRouteGeometry? geometry;

  @internal
  factory RadarRoute.fromMap(ChannelMap map) => RadarRoute(
    distance: readObject(map['distance'], RadarRouteDistance.fromMap),
    duration: readObject(map['duration'], RadarRouteDuration.fromMap),
    geometry: readObject(map['geometry'], RadarRouteGeometry.fromMap),
  );
}

/// Routes between an origin and a destination for each travel mode, from
/// [Radar.getDistance]. A mode is null if it was not requested.
final class RadarRoutes {
  const RadarRoutes({
    this.geodesic,
    this.foot,
    this.bike,
    this.car,
    this.truck,
    this.motorbike,
  });

  /// The straight-line distance. Has no duration or geometry.
  final RadarRoute? geodesic;
  final RadarRoute? foot;
  final RadarRoute? bike;
  final RadarRoute? car;
  final RadarRoute? truck;
  final RadarRoute? motorbike;

  @internal
  factory RadarRoutes.fromMap(ChannelMap map) => RadarRoutes(
    geodesic: readObject(map['geodesic'], RadarRoute.fromMap),
    foot: readObject(map['foot'], RadarRoute.fromMap),
    bike: readObject(map['bike'], RadarRoute.fromMap),
    car: readObject(map['car'], RadarRoute.fromMap),
    truck: readObject(map['truck'], RadarRoute.fromMap),
    motorbike: readObject(map['motorbike'], RadarRoute.fromMap),
  );
}

/// A matrix of routes between multiple origins and destinations, from
/// [Radar.getMatrix].
final class RadarRouteMatrix {
  const RadarRouteMatrix({this.rows = const []});

  /// One row per origin, each with one route per destination. A route is
  /// null if the native SDK could not parse it.
  final List<List<RadarRoute?>> rows;

  /// Parses the native matrix, which both platforms send as a list of rows
  /// (not a map). Returns null if [value] is not a list.
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
