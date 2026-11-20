import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_location.dart';

/// How confident Radar is in a geocoded address.
enum RadarAddressConfidence implements RadarWireEnum {
  exact('exact'),
  interpolated('interpolated'),
  fallback('fallback'),
  none('none');

  const RadarAddressConfidence(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a native confidence string. Unrecognized values become [none].
  @internal
  static RadarAddressConfidence fromWire(Object? value) =>
      readEnum(values, value, none);
}

/// The result of validating an address with [Radar.validateStreetAddress] or
/// [Radar.validateAddressLabel].
enum RadarAddressVerificationStatus implements RadarWireEnum {
  verified('VERIFIED'),
  partiallyVerified('PARTIALLY_VERIFIED'),
  ambiguous('AMBIGUOUS'),
  unverified('UNVERIFIED'),
  none('NONE');

  const RadarAddressVerificationStatus(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a native verification status. Android sends the enum name (for
  /// example `PARTIALLY_VERIFIED` or `NONE`); iOS sends the same names but
  /// `UNKNOWN` for none. The API's lowercase form (`partially verified`) is
  /// accepted too. Unrecognized values become [none].
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

  final RadarCoordinate? coordinate;
  final String? formattedAddress;
  final String? country;
  final String? countryCode;

  /// The country flag emoji.
  final String? countryFlag;

  /// The designated market area name.
  final String? dma;
  final String? dmaCode;
  final String? state;
  final String? stateCode;
  final String? postalCode;
  final String? city;
  final String? borough;
  final String? county;
  final String? neighborhood;
  final String? street;

  /// The street number.
  final String? number;
  final String? addressLabel;
  final String? placeLabel;
  final String? unit;

  /// The ZIP+4 extension (US only).
  final String? plus4;

  /// The distance to the search anchor in meters.
  final double? distance;

  /// The geocoding layer, such as `address`, `place`, or `postalCode`.
  final String? layer;
  final Map<String, Object?>? metadata;
  final RadarAddressConfidence confidence;
  final RadarTimeZone? timeZone;

  /// Place categories, for addresses of the `place` layer.
  final List<String> categories;

  /// The ID of the autocomplete result this address came from.
  final String? resultId;

  @internal
  factory RadarAddress.fromMap(ChannelMap map) {
    final latitude = readDouble(map['latitude']);
    final longitude = readDouble(map['longitude']);
    return RadarAddress(
      coordinate:
          latitude != null && longitude != null
              ? RadarCoordinate(latitude: latitude, longitude: longitude)
              : null,
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
