import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_beacon.dart';
import 'radar_fraud.dart';
import 'radar_geofence.dart';
import 'radar_location.dart';
import 'radar_place.dart';
import 'radar_region.dart';
import 'radar_trip.dart';

/// What triggered a location update.
enum RadarLocationSource implements RadarWireEnum {
  foregroundLocation('FOREGROUND_LOCATION'),
  backgroundLocation('BACKGROUND_LOCATION'),
  manualLocation('MANUAL_LOCATION'),

  /// iOS only.
  visitArrival('VISIT_ARRIVAL'),

  /// iOS only.
  visitDeparture('VISIT_DEPARTURE'),
  geofenceEnter('GEOFENCE_ENTER'),

  /// Android only.
  geofenceDwell('GEOFENCE_DWELL'),
  geofenceExit('GEOFENCE_EXIT'),
  mockLocation('MOCK_LOCATION'),
  beaconEnter('BEACON_ENTER'),
  beaconExit('BEACON_EXIT'),

  /// iOS only.
  indoors('INDOORS'),
  unknown('UNKNOWN');

  const RadarLocationSource(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a native location source. Unrecognized values become [unknown].
  @internal
  static RadarLocationSource fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// The user's activity, as detected by the device's motion sensors.
enum RadarActivityType implements RadarWireEnum {
  unknown('unknown'),
  stationary('stationary'),
  foot('foot'),
  run('run'),
  bike('bike'),
  car('car');

  const RadarActivityType(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses an activity type. Unrecognized values become [unknown].
  @internal
  static RadarActivityType fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// A user segment.
final class RadarSegment {
  const RadarSegment({required this.description, required this.externalId});

  final String description;
  final String externalId;

  @internal
  factory RadarSegment.fromMap(ChannelMap map) => RadarSegment(
    description: readString(map['description']) ?? '',
    externalId: readString(map['externalId']) ?? '',
  );
}

/// How confident Radar is that the user is at their expected address.
enum RadarExpectedAddressConfidence implements RadarWireEnum {
  high('high'),
  medium('medium'),
  low('low'),
  unknown('unknown');

  const RadarExpectedAddressConfidence(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a confidence string. Unrecognized values become [unknown].
  @internal
  static RadarExpectedAddressConfidence fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// A comparison between the user's location and the expected address set
/// with `Radar.setExpectedAddress`.
final class RadarExpectedAddress {
  const RadarExpectedAddress({
    required this.expectedAddress,
    this.formattedAddress,
    this.coordinate,
    this.atAddress = false,
    this.confidence = RadarExpectedAddressConfidence.unknown,
    this.distance,
  });

  /// The expected address, as it was set.
  final String expectedAddress;

  /// The expected address as geocoded by Radar. Null if it could not be
  /// geocoded.
  final String? formattedAddress;

  /// The coordinate of the geocoded expected address. Null if it could not be
  /// geocoded.
  final RadarCoordinate? coordinate;

  /// Whether the user is at the expected address.
  final bool atAddress;
  final RadarExpectedAddressConfidence confidence;

  /// The distance in meters between the user and the expected address.
  final double? distance;

  @internal
  factory RadarExpectedAddress.fromMap(ChannelMap map) => RadarExpectedAddress(
    expectedAddress: readString(map['expectedAddress']) ?? '',
    formattedAddress: readString(map['formattedAddress']),
    coordinate: _readCoordinate(map['latitude'], map['longitude']),
    atAddress: readBool(map['atAddress']) ?? false,
    confidence: RadarExpectedAddressConfidence.fromWire(map['confidence']),
    distance: readDouble(map['distance']),
  );
}

RadarCoordinate? _readCoordinate(Object? latitude, Object? longitude) {
  final lat = readDouble(latitude);
  final lng = readDouble(longitude);
  return lat == null || lng == null
      ? null
      : RadarCoordinate(latitude: lat, longitude: lng);
}

/// Insights about where the user is relative to their usual locations.
/// Currently only sent by iOS.
final class RadarUserLocationInsights {
  const RadarUserLocationInsights({
    this.atHome = false,
    this.atWork = false,
    this.traveling = false,
    this.commuting,
  });

  final bool atHome;
  final bool atWork;
  final bool traveling;

  /// Whether the user is commuting. Null when iOS doesn't know.
  final bool? commuting;

  @internal
  factory RadarUserLocationInsights.fromMap(ChannelMap map) =>
      RadarUserLocationInsights(
        atHome: readBool(map['atHome']) ?? false,
        atWork: readBool(map['atWork']) ?? false,
        traveling: readBool(map['traveling']) ?? false,
        commuting: readBool(map['commuting']),
      );
}

/// The current state of the user, as returned by the server after a location
/// update.
final class RadarUser {
  const RadarUser({
    required this.id,
    this.userId,
    this.deviceId,
    this.description,
    this.metadata,
    required this.location,
    this.activityType = RadarActivityType.unknown,
    this.geofences = const [],
    this.place,
    this.beacons = const [],
    this.stopped = false,
    this.foreground = false,
    this.country,
    this.state,
    this.dma,
    this.postalCode,
    this.nearbyPlaceChains = const [],
    this.segments = const [],
    this.topChains = const [],
    this.source = RadarLocationSource.unknown,
    this.trip,
    this.debug = false,
    this.fraud,
    this.altitude,
    this.expectedAddress,
    this.locationInsights,
  });

  /// The Radar ID of the user.
  final String id;

  /// The ID set with `Radar.setUserId`. Null if the user is not identified.
  final String? userId;
  final String? deviceId;

  /// The description set with `Radar.setDescription`.
  final String? description;

  /// The metadata set with `Radar.setMetadata`.
  final Map<String, Object?>? metadata;

  /// The user's current location. The native bridges only send coordinates;
  /// [RadarLocation.accuracy] is set only when the payload came from the API,
  /// as the user in a [RadarVerifiedLocationToken] does.
  final RadarLocation location;
  final RadarActivityType activityType;

  /// The geofences the user is in.
  final List<RadarGeofence> geofences;

  /// The place the user is at. Null if the user is not at a place or Places
  /// is not enabled.
  final RadarPlace? place;

  /// The beacons the user is near.
  final List<RadarBeacon> beacons;

  /// Whether the user is stopped.
  final bool stopped;

  /// Whether the user was last updated in the foreground.
  final bool foreground;
  final RadarRegion? country;
  final RadarRegion? state;

  /// The user's designated market area.
  final RadarRegion? dma;
  final RadarRegion? postalCode;
  final List<RadarChain> nearbyPlaceChains;
  final List<RadarSegment> segments;
  final List<RadarChain> topChains;

  /// What triggered the user's current location.
  final RadarLocationSource source;

  /// The user's current trip. Null if the user is not on a trip.
  final RadarTrip? trip;

  /// Whether debug mode is on for the user.
  final bool debug;
  final RadarFraud? fraud;

  /// The user's altitude in meters, from the barometer when available.
  final double? altitude;

  /// How the user's location compares to their expected address. Null if no
  /// expected address is set.
  final RadarExpectedAddress? expectedAddress;

  /// Currently only sent by iOS.
  final RadarUserLocationInsights? locationInsights;

  /// Returns null if [map] has no location. Both native SDKs always send one.
  @internal
  static RadarUser? fromMap(ChannelMap map) {
    final coordinate = RadarCoordinate.fromMap(readMap(map['location']));
    if (coordinate == null) return null;
    return RadarUser(
      id: readString(map['_id']) ?? '',
      userId: readString(map['userId']),
      deviceId: readString(map['deviceId']),
      description: readString(map['description']),
      metadata: readJson(map['metadata']),
      location: RadarLocation(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        accuracy: readDouble(map['locationAccuracy']),
      ),
      activityType: RadarActivityType.fromWire(map['activityType']),
      geofences: readList(map['geofences'], RadarGeofence.fromMap),
      place: readObject(map['place'], RadarPlace.fromMap),
      beacons: readList(map['beacons'], RadarBeacon.fromMap),
      stopped: readBool(map['stopped']) ?? false,
      foreground: readBool(map['foreground']) ?? false,
      country: readObject(map['country'], RadarRegion.fromMap),
      state: readObject(map['state'], RadarRegion.fromMap),
      dma: readObject(map['dma'], RadarRegion.fromMap),
      postalCode: readObject(map['postalCode'], RadarRegion.fromMap),
      nearbyPlaceChains: readList(map['nearbyPlaceChains'], RadarChain.fromMap),
      segments: readList(map['segments'], RadarSegment.fromMap),
      topChains: readList(map['topChains'], RadarChain.fromMap),
      source: RadarLocationSource.fromWire(map['source']),
      trip: readObject(map['trip'], RadarTrip.fromMap),
      debug: readBool(map['debug']) ?? false,
      fraud: readObject(map['fraud'], RadarFraud.fromMap),
      altitude:
          readDouble(map['barometricAltitude']) ?? readDouble(map['altitude']),
      expectedAddress: readObject(
        map['expectedAddress'],
        RadarExpectedAddress.fromMap,
      ),
      locationInsights: readObject(
        map['locationInsights'],
        RadarUserLocationInsights.fromMap,
      ),
    );
  }
}
