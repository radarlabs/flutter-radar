import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_enums.dart';
import 'radar_location.dart';

/// The status of a trip.
///
/// Only [started], [approaching], [arrived], [completed], and [canceled] can
/// be passed to [Radar.updateTrip]; the native bridges send any other value
/// as unknown.
enum RadarTripStatus implements RadarWireEnum {
  unknown('unknown'),
  started('started'),
  approaching('approaching'),
  arrived('arrived'),
  expired('expired'),
  completed('completed'),
  canceled('canceled');

  const RadarTripStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarTripStatus fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// The status of a leg of a multi-destination trip.
enum RadarTripLegStatus implements RadarWireEnum {
  unknown('unknown'),
  pending('pending'),
  started('started'),
  approaching('approaching'),
  arrived('arrived'),
  completed('completed'),
  canceled('canceled'),
  expired('expired');

  const RadarTripLegStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarTripLegStatus fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// How the destination of a trip leg is specified.
enum RadarTripLegDestinationType implements RadarWireEnum {
  unknown('unknown'),
  geofence('geofence'),
  address('address'),
  coordinates('coordinates');

  const RadarTripLegDestinationType(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarTripLegDestinationType fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// The status of a trip order.
enum RadarTripOrderStatus implements RadarWireEnum {
  unknown('unknown'),
  pending('pending'),
  fired('fired'),
  canceled('canceled'),
  completed('completed');

  const RadarTripOrderStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarTripOrderStatus fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// An order associated with a trip.
final class RadarTripOrder {
  const RadarTripOrder({
    required this.id,
    this.guid,
    this.handoffMode,
    this.status = RadarTripOrderStatus.unknown,
    this.firedAt,
    this.firedAttempts,
    this.firedReason,
    this.updatedAt,
  });

  final String id;
  final String? guid;
  final String? handoffMode;
  final RadarTripOrderStatus status;

  /// When the order was fired.
  final DateTime? firedAt;
  final int? firedAttempts;

  /// Why the order was fired.
  final String? firedReason;
  final DateTime? updatedAt;

  @internal
  factory RadarTripOrder.fromMap(ChannelMap map) => RadarTripOrder(
    id: readString(map['id']) ?? readString(map['_id']) ?? '',
    guid: readString(map['guid']),
    handoffMode: readString(map['handoffMode']),
    status: RadarTripOrderStatus.fromWire(map['status']),
    firedAt: readDate(map['firedAt']),
    firedAttempts: readInt(map['firedAttempts']),
    firedReason: readString(map['firedReason']),
    updatedAt: readDate(map['updatedAt']),
  );
}

/// A leg of a multi-destination trip.
///
/// Legs returned by Radar have an [id], [status], and ETA. To create a trip
/// with legs, pass legs with only the destination fields set in
/// [RadarTripOptions.legs]. Set one destination: [destinationGeofenceTag]
/// and [destinationGeofenceExternalId], [destinationGeofenceId], [address],
/// or [coordinates].
final class RadarTripLeg {
  const RadarTripLeg({
    this.id,
    this.status = RadarTripLegStatus.unknown,
    this.destinationType = RadarTripLegDestinationType.unknown,
    this.createdAt,
    this.updatedAt,
    this.etaDistance,
    this.etaDuration,
    this.destinationGeofenceTag,
    this.destinationGeofenceExternalId,
    this.destinationGeofenceId,
    this.address,
    this.coordinates,
    this.arrivalRadius,
    this.stopDuration,
    this.metadata,
  });

  /// The Radar ID of the leg. Pass it to [Radar.updateTripLeg].
  final String? id;

  /// The status of the leg. Set by Radar.
  final RadarTripLegStatus status;

  /// How the destination is specified. Inferred from the destination fields
  /// when the native SDK does not send it. Not sent when starting a trip;
  /// Radar infers it from the destination fields you set.
  final RadarTripLegDestinationType destinationType;

  /// When the leg was created. Set by Radar; not sent when starting a trip.
  final DateTime? createdAt;

  /// When the leg was last updated. Set by Radar; not sent when starting a
  /// trip.
  final DateTime? updatedAt;

  /// The distance to the leg's destination in meters. Set by Radar; not sent
  /// when starting a trip.
  final double? etaDistance;

  /// The ETA to the leg's destination in minutes. Set by Radar; not sent when
  /// starting a trip.
  final double? etaDuration;

  /// The tag of the destination geofence. For a geofence destination, set
  /// with [destinationGeofenceExternalId].
  final String? destinationGeofenceTag;

  /// The external ID of the destination geofence. For a geofence destination,
  /// set with [destinationGeofenceTag].
  final String? destinationGeofenceExternalId;

  /// The Radar ID of the destination geofence. An alternative to
  /// [destinationGeofenceTag] and [destinationGeofenceExternalId].
  final String? destinationGeofenceId;

  /// The address of the destination, for an address destination.
  final String? address;

  /// The coordinates of the destination, for a coordinates destination.
  final RadarCoordinate? coordinates;

  /// The arrival radius in meters, for a coordinates destination. Only used
  /// when [coordinates] is set.
  final int? arrivalRadius;

  /// How long the user is expected to stay at the destination, in minutes.
  final int? stopDuration;

  /// Custom key-value pairs for the leg.
  final Map<String, Object?>? metadata;

  @internal
  factory RadarTripLeg.fromMap(ChannelMap map) {
    var type = RadarTripLegDestinationType.unknown;
    String? tag;
    String? externalId;
    String? geofenceId;
    String? address;
    RadarCoordinate? coordinates;
    int? arrivalRadius;

    final destination = readMap(map['destination']);
    if (destination != null) {
      type = RadarTripLegDestinationType.fromWire(destination['type']);
      final source = readMap(destination['source']);
      if (source != null) {
        switch (type) {
          case RadarTripLegDestinationType.geofence:
            geofenceId = readString(source['geofence']);
            final data = readMap(source['data']);
            if (data != null) {
              tag = readString(data['tag']);
              externalId = readString(data['externalId']);
            }
          case RadarTripLegDestinationType.address:
            address = readString(source['data']);
          case RadarTripLegDestinationType.coordinates:
          case RadarTripLegDestinationType.unknown:
            break;
        }
      } else {
        tag = readString(destination['destinationGeofenceTag']);
        externalId = readString(destination['destinationGeofenceExternalId']);
        geofenceId = readString(destination['destinationGeofenceId']);
        address = readString(destination['address']);
        coordinates = RadarCoordinate.fromLngLat(destination['coordinates']);
      }
      coordinates =
          RadarCoordinate.fromMap(readMap(destination['location'])) ??
          coordinates;
      arrivalRadius = readInt(destination['arrivalRadius']);

      if (type == RadarTripLegDestinationType.unknown) {
        if ((tag != null && externalId != null) || geofenceId != null) {
          type = RadarTripLegDestinationType.geofence;
        } else if (address != null) {
          type = RadarTripLegDestinationType.address;
        } else if (coordinates != null) {
          type = RadarTripLegDestinationType.coordinates;
        }
      }
    }

    final eta = readMap(map['eta']);
    return RadarTripLeg(
      id: readString(map['_id']),
      status: RadarTripLegStatus.fromWire(map['status']),
      destinationType: type,
      createdAt: readDate(map['createdAt']),
      updatedAt: readDate(map['updatedAt']),
      etaDistance: readDouble(eta?['distance']),
      etaDuration: readDouble(eta?['duration']),
      destinationGeofenceTag: tag,
      destinationGeofenceExternalId: externalId,
      destinationGeofenceId: geofenceId,
      address: address,
      coordinates: coordinates,
      arrivalRadius: arrivalRadius,
      stopDuration: readInt(map['stopDuration']),
      metadata: readJson(map['metadata']),
    );
  }

  @internal
  Map<String, Object?> toMap() {
    final coordinates = this.coordinates;
    final destination = compact({
      'destinationGeofenceTag': destinationGeofenceTag,
      'destinationGeofenceExternalId': destinationGeofenceExternalId,
      'destinationGeofenceId': destinationGeofenceId,
      'address': address,
      'coordinates':
          coordinates == null
              ? null
              : [coordinates.longitude, coordinates.latitude],
      'arrivalRadius': (arrivalRadius ?? 0) > 0 ? arrivalRadius : null,
    });
    return compact({
      '_id': id,
      'status': status == RadarTripLegStatus.unknown ? null : status.wireValue,
      'destination': destination.isEmpty ? null : destination,
      'stopDuration': (stopDuration ?? 0) > 0 ? stopDuration : null,
      'metadata': metadata,
    });
  }
}

/// A trip.
final class RadarTrip {
  const RadarTrip({
    required this.id,
    required this.externalId,
    this.metadata,
    this.destinationGeofenceTag,
    this.destinationGeofenceExternalId,
    this.destinationLocation,
    this.mode,
    this.etaDistance,
    this.etaDuration,
    this.status = RadarTripStatus.unknown,
    this.orders = const [],
    this.legs = const [],
    this.currentLegId,
  });

  /// The Radar ID of the trip.
  final String id;

  /// The external ID of the trip, set in [RadarTripOptions.externalId].
  final String externalId;

  /// Custom key-value pairs for the trip.
  final Map<String, Object?>? metadata;

  /// For trips with a destination, the tag of the destination geofence.
  final String? destinationGeofenceTag;

  /// For trips with a destination, the external ID of the destination
  /// geofence.
  final String? destinationGeofenceExternalId;

  /// For trips with a destination, the location of the destination geofence.
  final RadarCoordinate? destinationLocation;

  /// The travel mode. Null if the native SDK did not report one.
  final RadarRouteMode? mode;

  /// For trips with a destination, the distance to the destination geofence
  /// in meters, based on the travel mode.
  final double? etaDistance;

  /// For trips with a destination, the ETA to the destination geofence in
  /// minutes, based on the travel mode.
  final double? etaDuration;

  /// The status of the trip.
  final RadarTripStatus status;

  /// The orders associated with the trip. Empty if there are none.
  final List<RadarTripOrder> orders;

  /// For multi-destination trips, the legs of the trip.
  final List<RadarTripLeg> legs;

  /// For multi-destination trips, the ID of the current leg.
  final String? currentLegId;

  @internal
  factory RadarTrip.fromMap(ChannelMap map) {
    final eta = readMap(map['eta']);
    return RadarTrip(
      id: readString(map['_id']) ?? '',
      externalId: readString(map['externalId']) ?? '',
      metadata: readJson(map['metadata']),
      destinationGeofenceTag: readString(map['destinationGeofenceTag']),
      destinationGeofenceExternalId: readString(
        map['destinationGeofenceExternalId'],
      ),
      destinationLocation: RadarCoordinate.fromMap(
        readMap(map['destinationLocation']),
      ),
      mode: readEnumOrNull(RadarRouteMode.values, map['mode']),
      etaDistance: readDouble(eta?['distance']),
      etaDuration: readDouble(eta?['duration']),
      status: RadarTripStatus.fromWire(map['status']),
      orders: readList(map['orders'], RadarTripOrder.fromMap),
      legs: readList(map['legs'], RadarTripLeg.fromMap),
      currentLegId: readString(map['currentLeg']),
    );
  }
}

/// Options for starting or updating a trip, used by [Radar.startTrip] and
/// [Radar.updateTrip], and returned by [Radar.getTripOptions].
final class RadarTripOptions {
  const RadarTripOptions({
    required this.externalId,
    this.metadata,
    this.destinationGeofenceTag,
    this.destinationGeofenceExternalId,
    this.mode = RadarRouteMode.car,
    this.scheduledArrivalAt,
    this.approachingThreshold = 0,
    this.startTracking = true,
    this.legs = const [],
  });

  /// A stable unique ID for the trip.
  final String externalId;

  /// Custom key-value pairs for the trip.
  final Map<String, Object?>? metadata;

  /// For trips with a destination, the tag of the destination geofence.
  final String? destinationGeofenceTag;

  /// For trips with a destination, the external ID of the destination
  /// geofence.
  final String? destinationGeofenceExternalId;

  /// For trips with a destination, the travel mode.
  final RadarRouteMode mode;

  /// The scheduled arrival time for the trip.
  final DateTime? scheduledArrivalAt;

  /// The number of minutes before arrival at which the trip becomes
  /// approaching. 0 uses the project default.
  final int approachingThreshold;

  /// Whether to start tracking when the trip starts.
  final bool startTracking;

  /// For multi-destination trips, the legs of the trip.
  final List<RadarTripLeg> legs;

  @internal
  factory RadarTripOptions.fromMap(ChannelMap map) => RadarTripOptions(
    externalId: readString(map['externalId']) ?? '',
    metadata: readJson(map['metadata']),
    destinationGeofenceTag: readString(map['destinationGeofenceTag']),
    destinationGeofenceExternalId: readString(
      map['destinationGeofenceExternalId'],
    ),
    mode: RadarRouteMode.fromWire(map['mode']),
    scheduledArrivalAt: readDate(map['scheduledArrivalAt']),
    approachingThreshold: readInt(map['approachingThreshold']) ?? 0,
    startTracking: readBool(map['startTracking']) ?? true,
    legs: readList(map['legs'], RadarTripLeg.fromMap),
  );

  @internal
  Map<String, Object?> toMap() => compact({
    'externalId': externalId,
    'metadata': metadata,
    'destinationGeofenceTag': destinationGeofenceTag,
    'destinationGeofenceExternalId': destinationGeofenceExternalId,
    'mode': mode.wireValue,
    'scheduledArrivalAt': scheduledArrivalAt?.millisecondsSinceEpoch,
    'approachingThreshold':
        approachingThreshold > 0 ? approachingThreshold : null,
    'startTracking': startTracking,
    'legs': legs.isEmpty ? null : [for (final leg in legs) leg.toMap()],
  });
}
