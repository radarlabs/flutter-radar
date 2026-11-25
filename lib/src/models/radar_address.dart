import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_location.dart';

/// How confident Radar is in a geocoded address.
enum RadarAddressConfidence implements RadarWireEnum {
  /// Exact.
  exact('exact'),

  /// Interpolated.
  interpolated('interpolated'),

  /// Fallback.
  fallback('fallback'),

  /// Unknown, or a value this version of the plugin doesn't recognize.
  none('none');

  const RadarAddressConfidence(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarAddressConfidence fromWire(Object? value) =>
      readEnum(values, value, none);
}

/// The result of validating an address with [Radar.validateStreetAddress] or
/// [Radar.validateAddressLabel].
enum RadarAddressVerificationStatus implements RadarWireEnum {
  /// A complete match was made between the input and a single record from the
  /// available reference data.
  verified('VERIFIED'),

  /// A partial match was made between the input and a single record from the
  /// available reference data.
  partiallyVerified('PARTIALLY_VERIFIED'),

  /// More than one close reference data match.
  ambiguous('AMBIGUOUS'),

  /// Unable to verify. The output fields contain the input data.
  unverified('UNVERIFIED'),

  /// Unknown, or a value this version of the plugin doesn't recognize.
  none('NONE');

  const RadarAddressVerificationStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  @internal
  static RadarAddressVerificationStatus fromWire(Object? value) {
    if (value is String) {
      final normalized = value.replaceAll(' ', '_');
      return readEnum(values, normalized, none);
    }
    return none;
  }
}

/// A time zone, as attached to an address.
final class RadarTimeZone {
  const RadarTimeZone({
    required this.id,
    this.name,
    this.code,
    this.currentTime,
    this.utcOffset,
    this.dstOffset,
  });

  /// The IANA time zone ID, such as `America/New_York`.
  final String id;

  /// The name of the time zone.
  final String? name;

  /// The abbreviation, such as `EST`.
  final String? code;

  /// The current local time in the time zone.
  final DateTime? currentTime;

  /// The offset from UTC in seconds.
  final int? utcOffset;

  /// The daylight saving offset in seconds.
  final int? dstOffset;

  @internal
  factory RadarTimeZone.fromMap(ChannelMap map) => RadarTimeZone(
    id: readString(map['id']) ?? '',
    name: readString(map['name']),
    code: readString(map['code']),
    currentTime: readDate(map['currentTime']),
    utcOffset: readInt(map['utcOffset']),
    dstOffset: readInt(map['dstOffset']),
  );
}

/// An address, as returned by geocoding, autocomplete, and address
/// validation.
final class RadarAddress {
  const RadarAddress({
    this.coordinate,
    this.formattedAddress,
    this.country,
    this.countryCode,
    this.countryFlag,
    this.dma,
    this.dmaCode,
    this.state,
    this.stateCode,
    this.postalCode,
    this.city,
    this.borough,
    this.county,
    this.neighborhood,
    this.street,
    this.number,
    this.addressLabel,
    this.placeLabel,
    this.unit,
    this.plus4,
    this.distance,
    this.layer,
    this.metadata,
    this.confidence = RadarAddressConfidence.none,
    this.timeZone,
    this.categories = const [],
    this.resultId,
  });

  /// The location coordinate of the address.
  final RadarCoordinate? coordinate;

  /// The formatted string representation of the address.
  final String? formattedAddress;

  /// The name of the country of the address.
  final String? country;

  /// The unique code of the country of the address.
  final String? countryCode;

  /// The country flag emoji.
  final String? countryFlag;

  /// The designated market area name.
  final String? dma;

  /// The unique code of the DMA of the address.
  final String? dmaCode;

  /// The name of the state of the address.
  final String? state;

  /// The unique code of the state of the address.
  final String? stateCode;

  /// The postal code of the address.
  final String? postalCode;

  /// The city of the address.
  final String? city;

  /// The borough of the address.
  final String? borough;

  /// The county of the address.
  final String? county;

  /// The neighborhood of the address.
  final String? neighborhood;

  /// The street name of the address.
  final String? street;

  /// The street number.
  final String? number;

  /// The label of the address.
  final String? addressLabel;

  /// The label of the place.
  final String? placeLabel;

  /// The unit of the address.
  final String? unit;

  /// The ZIP+4 extension (US only).
  final String? plus4;

  /// The distance to the search anchor in meters.
  final double? distance;

  /// The geocoding layer, such as `address`, `place`, or `postalCode`.
  final String? layer;

  /// The metadata of the address.
  final Map<String, Object?>? metadata;

  /// The confidence level of the geocoding result.
  final RadarAddressConfidence confidence;

  /// The time zone of the address.
  final RadarTimeZone? timeZone;

  /// Place categories, for addresses of the `place` layer.
  final List<String> categories;

  /// The ID of the autocomplete result this address came from.
  final String? resultId;

  @internal
  factory RadarAddress.fromMap(ChannelMap map) {
    return RadarAddress(
      coordinate: _readCoordinate(map['latitude'], map['longitude']),
      formattedAddress: readString(map['formattedAddress']),
      country: readString(map['country']),
      countryCode: readString(map['countryCode']),
      countryFlag: readString(map['countryFlag']),
      dma: readString(map['dma']),
      dmaCode: readString(map['dmaCode']),
      state: readString(map['state']),
      stateCode: readString(map['stateCode']),
      postalCode: readString(map['postalCode']),
      city: readString(map['city']),
      borough: readString(map['borough']),
      county: readString(map['county']),
      neighborhood: readString(map['neighborhood']),
      street: readString(map['street']),
      number: readString(map['number']),
      addressLabel: readString(map['addressLabel']),
      placeLabel: readString(map['placeLabel']),
      unit: readString(map['unit']),
      plus4: readString(map['plus4']),
      distance: readDouble(map['distance']),
      layer: readString(map['layer']),
      metadata: readJson(map['metadata']),
      confidence: RadarAddressConfidence.fromWire(map['confidence']),
      timeZone: readObject(map['timeZone'], RadarTimeZone.fromMap),
      categories: readStringList(map['categories']),
      resultId: readString(map['resultId']),
    );
  }
}

/// Returns the address's coordinate, or null if it's missing or out of range.
///
/// The native SDKs always send a coordinate for an address, even when the
/// server sent none: iOS sends (-180, -180), its invalid coordinate, and
/// Android sends (0, 0) (FENCE-3224). The range check drops the iOS value.
/// (0, 0) is kept, because it's also a real location.
RadarCoordinate? _readCoordinate(Object? latitude, Object? longitude) {
  final lat = readDouble(latitude);
  final lng = readDouble(longitude);
  if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
    return null;
  }
  return RadarCoordinate(latitude: lat, longitude: lng);
}
