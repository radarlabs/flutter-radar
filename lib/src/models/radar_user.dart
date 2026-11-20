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
  /// A foreground location update.
  foregroundLocation('FOREGROUND_LOCATION'),

  /// A background location update.
  backgroundLocation('BACKGROUND_LOCATION'),

  /// A location passed in manually, such as to [Radar.trackOnce].
  manualLocation('MANUAL_LOCATION'),

  /// A visit arrival detected by the device. iOS only.
  visitArrival('VISIT_ARRIVAL'),

  /// A visit departure detected by the device. iOS only.
  visitDeparture('VISIT_DEPARTURE'),

  /// A geofence entry detected by the device.
  geofenceEnter('GEOFENCE_ENTER'),

  /// A geofence dwell detected by the device. Android only.
  geofenceDwell('GEOFENCE_DWELL'),

  /// A geofence exit detected by the device.
  geofenceExit('GEOFENCE_EXIT'),

  /// A mock location, such as from [Radar.mockTracking].
  mockLocation('MOCK_LOCATION'),

  /// A beacon entry detected by the device.
  beaconEnter('BEACON_ENTER'),

  /// A beacon exit detected by the device.
  beaconExit('BEACON_EXIT'),

  /// A location from the Radar indoors SDK. iOS only.
  indoors('INDOORS'),

  /// The source is unknown.
  unknown('UNKNOWN');

  const RadarLocationSource(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarLocationSource fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// The user's activity, as detected by the device's motion sensors.
enum RadarActivityType implements RadarWireEnum {
  /// The activity is unknown.
  unknown('unknown'),

  /// Stationary.
  stationary('stationary'),

  /// Walking.
  foot('foot'),

  /// Running.
  run('run'),

  /// Biking.
  bike('bike'),

  /// Driving.
  car('car');

  const RadarActivityType(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarActivityType fromWire(Object? value) =>
      readEnum(values, value, unknown);
}

/// A user segment.
final class RadarSegment {
  const RadarSegment({required this.description, required this.externalId});

  /// The description of the segment.
  final String description;

  /// The external ID of the segment.
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
    this.latitude,
    this.longitude,
    this.atAddress = false,
    this.confidence = RadarExpectedAddressConfidence.unknown,
    this.distance,
  });

  /// The expected address, as it was set.
  final String expectedAddress;

  /// The expected address as geocoded by Radar. Null if it could not be
  /// geocoded.
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  /// Whether the user is at the expected address.
  final bool atAddress;
  final RadarExpectedAddressConfidence confidence;

  /// The distance in meters between the user and the expected address.
  final double? distance;

  @internal
  factory RadarExpectedAddress.fromMap(ChannelMap map) => RadarExpectedAddress(
    expectedAddress: readString(map['expectedAddress']) ?? '',
    formattedAddress: readString(map['formattedAddress']),
    latitude: readDouble(map['latitude']),
    longitude: readDouble(map['longitude']),
    atAddress: readBool(map['atAddress']) ?? false,
    confidence: RadarExpectedAddressConfidence.fromWire(map['confidence']),
    distance: readDouble(map['distance']),
  );
}

/// The user's learned home, work, and travel state.
/// Currently only sent by iOS.
final class RadarLocationInsights {
  const RadarLocationInsights({
    this.atHome = false,
    this.atWork = false,
    this.traveling = false,
    this.commuting = false,
  });

  /// Whether the user is at their learned home location.
  final bool atHome;

  /// Whether the user is at their learned work location.
  final bool atWork;

  /// Whether the user is traveling away from home.
  final bool traveling;

  /// Whether the user is commuting. `false` if not reported.
  final bool commuting;

  @internal
  factory RadarLocationInsights.fromMap(ChannelMap map) =>
      RadarLocationInsights(
        atHome: readBool(map['atHome']) ?? false,
        atWork: readBool(map['atWork']) ?? false,
        traveling: readBool(map['traveling']) ?? false,
        commuting: readBool(map['commuting']) ?? false,
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
    this.location,
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

  /// The device ID of the user.
  final String? deviceId;

  /// The description set with `Radar.setDescription`.
  final String? description;

  /// The metadata set with `Radar.setMetadata`.
  final Map<String, Object?>? metadata;

  /// The user's current location. The native bridges only send coordinates;
  /// [RadarLocation.accuracy] is set only when the payload came from the API,
  /// as the user in a [RadarVerifiedLocationToken] does.
  final RadarLocation? location;

  /// The user's current activity type.
  final RadarActivityType activityType;

  /// The geofences the user is in. Empty if the user is not in any
  /// geofences. See the
  /// [geofences docs](https://radar.com/documentation/geofences).
  final List<RadarGeofence> geofences;

  /// The place the user is at. Null if the user is not at a place or Places
  /// is not enabled. See the
  /// [places docs](https://radar.com/documentation/places).
  final RadarPlace? place;

  /// The beacons the user is near. Empty if the user is not near any beacons
  /// or Beacons is not enabled. See the
  /// [beacons docs](https://radar.com/documentation/beacons).
  final List<RadarBeacon> beacons;

  /// Whether the user is stopped.
  final bool stopped;

  /// Whether the user was last updated in the foreground.
  final bool foreground;

  /// The user's current country. Null if country is not available or
  /// Regions is not enabled. See the [regions docs](https://radar.com/documentation/regions).
  final RadarRegion? country;

  /// The user's current state. Null if state is not available or Regions is
  /// not enabled. See the [regions docs](https://radar.com/documentation/regions).
  final RadarRegion? state;

  /// The user's current designated market area (DMA). Null if DMA is not
  /// available or Regions is not enabled. See the
  /// [regions docs](https://radar.com/documentation/regions).
  final RadarRegion? dma;

  /// The user's current postal code. Null if postal code is not available or
  /// Regions is not enabled. See the [regions docs](https://radar.com/documentation/regions).
  final RadarRegion? postalCode;

  /// The chains near the user. Empty if no chains are nearby or nearby chains
  /// are not enabled.
  final List<RadarChain> nearbyPlaceChains;

  /// The user's segments. Empty if segments are not enabled.
  final List<RadarSegment> segments;

  /// The user's top chains. Empty if segments are not enabled.
  final List<RadarChain> topChains;

  /// What triggered the user's current location.
  final RadarLocationSource source;

  /// The user's current trip. Null if the user is not on a trip. See the
  /// [trip tracking docs](https://radar.com/documentation/trip-tracking).
  final RadarTrip? trip;

  /// Whether the user has been marked as debug in the dashboard.
  final bool debug;

  /// The user's current fraud state. Null if Fraud is not enabled. See the
  /// [fraud docs](https://radar.com/documentation/fraud).
  final RadarFraud? fraud;

  /// The user's altitude in meters, from the barometer when available.
  final double? altitude;

  /// How the user's location compares to their expected address. Null if no
  /// expected address is set.
  final RadarExpectedAddress? expectedAddress;

  /// The user's learned home, work, and travel state. Null if location
  /// insights are not enabled. Currently only sent by iOS.
  final RadarLocationInsights? locationInsights;

  @internal
  factory RadarUser.fromMap(ChannelMap map) {
    final coordinate = RadarCoordinate.fromMap(readMap(map['location']));
    return RadarUser(
      id: readString(map['_id']) ?? '',
      userId: readString(map['userId']),
      deviceId: readString(map['deviceId']),
      description: readString(map['description']),
      metadata: readJson(map['metadata']),
      location:
          coordinate == null
              ? null
              : RadarLocation(
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
        RadarLocationInsights.fromMap,
      ),
    );
  }
}
