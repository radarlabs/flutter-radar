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
    required this.updatedAt,
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
  final DateTime updatedAt;

  /// Returns null if [map] has no `updatedAt`. Both native SDKs always send
  /// one.
  @internal
  static RadarTripOrder? fromMap(ChannelMap map) {
    final updatedAt = readDate(map['updatedAt']);
    if (updatedAt == null) return null;
    return RadarTripOrder(
      id: readString(map['id']) ?? readString(map['_id']) ?? '',
      guid: readString(map['guid']),
      handoffMode: readString(map['handoffMode']),
      status: RadarTripOrderStatus.fromWire(map['status']),
      firedAt: readDate(map['firedAt']),
      firedAttempts: readInt(map['firedAttempts']),
      firedReason: readString(map['firedReason']),
      updatedAt: updatedAt,
    );
  }
}

/// A leg of a multi-destination trip.
///
/// Legs returned by Radar have an [id], [status], and ETA. To create a trip
/// with legs, build each leg with the constructor for its destination, such
/// as [RadarTripLeg.geofence] or [RadarTripLeg.address], and pass them in
/// [RadarTripOptions.legs].
final class RadarTripLeg {
  /// A leg with every field, as Radar returns it. To create a leg for a new
  /// trip, use the constructor for its destination instead.
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
    this.arrivalRadius = 0,
    this.stopDuration = Duration.zero,
    this.metadata,
  });

  /// A leg to the geofence with [tag] and [externalId].
  const RadarTripLeg.geofence({
    required String tag,
    required String externalId,
    Duration stopDuration = Duration.zero,
    Map<String, Object?>? metadata,
  }) : this(
         destinationType: RadarTripLegDestinationType.geofence,
         destinationGeofenceTag: tag,
         destinationGeofenceExternalId: externalId,
         stopDuration: stopDuration,
         metadata: metadata,
       );

  /// A leg to the geofence with the Radar ID [geofenceId].
  const RadarTripLeg.geofenceId(
    String geofenceId, {
    Duration stopDuration = Duration.zero,
    Map<String, Object?>? metadata,
  }) : this(
         destinationType: RadarTripLegDestinationType.geofence,
         destinationGeofenceId: geofenceId,
         stopDuration: stopDuration,
         metadata: metadata,
       );

  /// A leg to [address], which Radar geocodes.
  const RadarTripLeg.address(
    String address, {
    Duration stopDuration = Duration.zero,
    Map<String, Object?>? metadata,
  }) : this(
         destinationType: RadarTripLegDestinationType.address,
         address: address,
         stopDuration: stopDuration,
         metadata: metadata,
       );

  /// A leg to [coordinates]. The user arrives within [arrivalRadius] meters;
  /// 0 uses the project default.
  const RadarTripLeg.coordinates(
    RadarCoordinate coordinates, {
    int arrivalRadius = 0,
    Duration stopDuration = Duration.zero,
    Map<String, Object?>? metadata,
  }) : this(
         destinationType: RadarTripLegDestinationType.coordinates,
         coordinates: coordinates,
         arrivalRadius: arrivalRadius,
         stopDuration: stopDuration,
         metadata: metadata,
       );

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

  /// The ETA to the leg's destination. Set by Radar; not sent when starting a
  /// trip.
  final Duration? etaDuration;

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
  /// when [coordinates] is set. 0 uses the project default.
  final int arrivalRadius;

  /// How long the user is expected to stay at the destination. Sent in whole
  /// minutes.
  final Duration stopDuration;

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
      etaDuration: readMinutes(eta?['duration']),
      destinationGeofenceTag: tag,
      destinationGeofenceExternalId: externalId,
      destinationGeofenceId: geofenceId,
      address: address,
      coordinates: coordinates,
      arrivalRadius: arrivalRadius ?? 0,
      stopDuration: readMinutes(map['stopDuration']) ?? Duration.zero,
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
      'arrivalRadius': arrivalRadius > 0 ? arrivalRadius : null,
    });
    final stopMinutes = wholeMinutes(stopDuration, 'stopDuration');
    return compact({
      '_id': id,
      'status': status == RadarTripLegStatus.unknown ? null : status.wireValue,
      'destination': destination.isEmpty ? null : destination,
      'stopDuration': stopMinutes > 0 ? stopMinutes : null,
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

  /// For trips with a destination, the ETA to the destination geofence,
  /// based on the travel mode.
  final Duration? etaDuration;

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
      etaDuration: readMinutes(eta?['duration']),
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
    this.approachingThreshold = Duration.zero,
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

  /// How long before arrival the trip becomes approaching. Zero uses the
  /// project default. Sent in whole minutes.
  final Duration approachingThreshold;

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
    approachingThreshold:
        readMinutes(map['approachingThreshold']) ?? Duration.zero,
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
    'approachingThreshold': switch (wholeMinutes(
      approachingThreshold,
      'approachingThreshold',
    )) {
      0 => null,
      final minutes => minutes,
    },
    'startTracking': startTracking,
    'legs': legs.isEmpty ? null : [for (final leg in legs) leg.toMap()],
  });

  /// Returns a copy with the given fields replaced.
  RadarTripOptions copyWith({
    String? externalId,
    Map<String, Object?>? metadata,
    String? destinationGeofenceTag,
    String? destinationGeofenceExternalId,
    RadarRouteMode? mode,
    DateTime? scheduledArrivalAt,
    Duration? approachingThreshold,
    bool? startTracking,
    List<RadarTripLeg>? legs,
  }) => RadarTripOptions(
    externalId: externalId ?? this.externalId,
    metadata: metadata ?? this.metadata,
    destinationGeofenceTag:
        destinationGeofenceTag ?? this.destinationGeofenceTag,
    destinationGeofenceExternalId:
        destinationGeofenceExternalId ?? this.destinationGeofenceExternalId,
    mode: mode ?? this.mode,
    scheduledArrivalAt: scheduledArrivalAt ?? this.scheduledArrivalAt,
    approachingThreshold: approachingThreshold ?? this.approachingThreshold,
    startTracking: startTracking ?? this.startTracking,
    legs: legs ?? this.legs,
  );

  /// Options are equal when they send the same values to the native SDKs.
  @override
  bool operator ==(Object other) =>
      other is RadarTripOptions && deepEquals(other.toMap(), toMap());

  @override
  int get hashCode => Object.hash(externalId, destinationGeofenceTag, mode);
}
