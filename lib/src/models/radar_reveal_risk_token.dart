import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_address.dart';
import 'radar_location.dart';

/// The risk level of a reveal risk check.
enum RadarRevealRiskLevel implements RadarWireEnum {
  none('none'),
  low('low'),
  medium('medium'),
  high('high');

  const RadarRevealRiskLevel(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a risk level. Unrecognized values become [none].
  @internal
  static RadarRevealRiskLevel fromWire(Object? value) =>
      readEnum(values, value, none);
}

/// The response format selected by the server for [Radar.trackVerified],
/// [Radar.getVerifiedLocationToken], and [Radar.revealRisk].
enum RadarResponseFormat implements RadarWireEnum {
  /// A response with readable result fields and an optional signed token.
  jws('jws'),

  /// An encrypted token that your backend decrypts and verifies.
  jwe('jwe'),

  /// An evaluation ID that your backend uses to retrieve the result.
  id('id');

  const RadarResponseFormat(this.wireValue);

  @override
  @internal
  final String wireValue;

  /// Parses a response format. A missing or unrecognized value becomes [jws],
  /// as in the native SDKs.
  @internal
  static RadarResponseFormat fromWire(Object? value) =>
      readEnum(values, value, jws);
}

/// Device and network risk signals from [Radar.revealRisk].
///
/// Both platforms pass through the API response (minus `meta`), so [raw]
/// holds every field, including any not modeled here.
final class RadarRevealRiskToken {
  const RadarRevealRiskToken({
    required this.id,
    this.format = RadarResponseFormat.jws,
    this.risk,
    this.network,
    this.device,
    this.token,
    this.expiresAt,
    this.expiresIn,
    this.raw = const {},
  });

  final String id;

  /// The response format selected by the server.
  final RadarResponseFormat format;
  final RadarRevealRiskTokenRisk? risk;
  final RadarRevealRiskTokenNetwork? network;
  final RadarRevealRiskTokenDevice? device;

  /// A signed JWT containing the risk, network, and device information.
  /// Verify it server-side with your secret key.
  final String? token;
  final DateTime? expiresAt;

  /// Seconds until the token expires.
  final int? expiresIn;

  /// The full response map.
  final Map<String, Object?> raw;

  @internal
  factory RadarRevealRiskToken.fromMap(ChannelMap map) => RadarRevealRiskToken(
    id: readString(map['_id']) ?? '',
    format: RadarResponseFormat.fromWire(map['format']),
    risk: readObject(map['risk'], RadarRevealRiskTokenRisk.fromMap),
    network: readObject(map['network'], RadarRevealRiskTokenNetwork.fromMap),
    device: readObject(map['device'], RadarRevealRiskTokenDevice.fromMap),
    token: readString(map['token']),
    expiresAt: readDate(map['expiresAt']),
    expiresIn: readInt(map['expiresIn']),
    raw: readJson(map) ?? const {},
  );
}

/// The risk assessment of a reveal risk check.
final class RadarRevealRiskTokenRisk {
  const RadarRevealRiskTokenRisk({
    this.level = RadarRevealRiskLevel.none,
    this.reasons = const [],
  });

  final RadarRevealRiskLevel level;

  /// The risk signals that contributed to [level].
  final List<String> reasons;

  @internal
  factory RadarRevealRiskTokenRisk.fromMap(ChannelMap map) =>
      RadarRevealRiskTokenRisk(
        level: RadarRevealRiskLevel.fromWire(map['level']),
        reasons: readStringList(map['reasons']),
      );
}

/// The network information of a reveal risk check.
final class RadarRevealRiskTokenNetwork {
  const RadarRevealRiskTokenNetwork({this.ipAddress, this.privacy, this.asn});

  final RadarRevealRiskTokenNetworkIpAddress? ipAddress;
  final RadarRevealRiskTokenNetworkPrivacy? privacy;
  final RadarRevealRiskTokenNetworkAsn? asn;

  @internal
  factory RadarRevealRiskTokenNetwork.fromMap(ChannelMap map) =>
      RadarRevealRiskTokenNetwork(
        ipAddress: readObject(
          map['ipAddress'],
          RadarRevealRiskTokenNetworkIpAddress.fromMap,
        ),
        privacy: readObject(
          map['privacy'],
          RadarRevealRiskTokenNetworkPrivacy.fromMap,
        ),
        asn: readObject(map['asn'], RadarRevealRiskTokenNetworkAsn.fromMap),
      );
}

/// The IP address and its geolocation for a reveal risk check.
final class RadarRevealRiskTokenNetworkIpAddress {
  const RadarRevealRiskTokenNetworkIpAddress({
    this.ip,
    this.coordinate,
    this.formattedAddress,
    this.addressLabel,
    this.placeLabel,
    this.number,
    this.street,
    this.neighborhood,
    this.borough,
    this.city,
    this.county,
    this.postalCode,
    this.state,
    this.stateCode,
    this.country,
    this.countryCode,
    this.countryFlag,
    this.dma,
    this.dmaCode,
    this.distance,
    this.layer,
    this.confidence,
    this.stateConfidence,
    this.countryConfidence,
    this.stateAllowed,
    this.countryAllowed,
    this.connectionType,
    this.timeZone,
    this.categories = const [],
    this.chainSlug,
    this.ssid,
    this.bssid,
  });

  final String? ip;

  /// The IP geolocation, from `latitude`/`longitude` or the GeoJSON
  /// `geometry`.
  final RadarCoordinate? coordinate;
  final String? formattedAddress;
  final String? addressLabel;
  final String? placeLabel;
  final String? number;
  final String? street;
  final String? neighborhood;
  final String? borough;
  final String? city;
  final String? county;
  final String? postalCode;
  final String? state;
  final String? stateCode;
  final String? country;
  final String? countryCode;
  final String? countryFlag;
  final String? dma;
  final String? dmaCode;
  final double? distance;
  final String? layer;
  final String? confidence;
  final String? stateConfidence;
  final String? countryConfidence;
  final bool? stateAllowed;
  final bool? countryAllowed;

  /// The connection type, such as `wifi` or `cellular`.
  final String? connectionType;

  /// The time zone of the IP geolocation.
  final RadarTimeZone? timeZone;
  final List<String> categories;
  final String? chainSlug;
  final String? ssid;
  final String? bssid;

  @internal
  factory RadarRevealRiskTokenNetworkIpAddress.fromMap(ChannelMap map) {
    final latitude = readDouble(map['latitude']);
    final longitude = readDouble(map['longitude']);
    return RadarRevealRiskTokenNetworkIpAddress(
      ip: readString(map['ip']),
      coordinate:
          latitude != null && longitude != null
              ? RadarCoordinate(latitude: latitude, longitude: longitude)
              : RadarCoordinate.fromMap(readMap(map['geometry'])),
      formattedAddress: readString(map['formattedAddress']),
      addressLabel: readString(map['addressLabel']),
      placeLabel: readString(map['placeLabel']),
      number: readString(map['number']),
      street: readString(map['street']),
      neighborhood: readString(map['neighborhood']),
      borough: readString(map['borough']),
      city: readString(map['city']),
      county: readString(map['county']),
      postalCode: readString(map['postalCode']),
      state: readString(map['state']),
      stateCode: readString(map['stateCode']),
      country: readString(map['country']),
      countryCode: readString(map['countryCode']),
      countryFlag: readString(map['countryFlag']),
      dma: readString(map['dma']),
      dmaCode: readString(map['dmaCode']),
      distance: readDouble(map['distance']),
      layer: readString(map['layer']),
      confidence: readString(map['confidence']),
      stateConfidence: readString(map['stateConfidence']),
      countryConfidence: readString(map['countryConfidence']),
      stateAllowed: readBool(map['stateAllowed']),
      countryAllowed: readBool(map['countryAllowed']),
      connectionType: readString(map['connectionType']),
      timeZone: readObject(map['timeZone'], RadarTimeZone.fromMap),
      categories: readStringList(map['categories']),
      chainSlug: readString(map['chainSlug']),
      ssid: readString(map['ssid']),
      bssid: readString(map['bssid']),
    );
  }
}

/// IP privacy signals for a reveal risk check.
final class RadarRevealRiskTokenNetworkPrivacy {
  const RadarRevealRiskTokenNetworkPrivacy({
    this.vpn,
    this.proxy,
    this.tor,
    this.relay,
    this.hosting,
    this.residentialProxy,
    this.service,
  });

  final bool? vpn;
  final bool? proxy;
  final bool? tor;
  final bool? relay;
  final bool? hosting;
  final bool? residentialProxy;

  /// The name of the VPN or proxy service, if known.
  final String? service;

  @internal
  factory RadarRevealRiskTokenNetworkPrivacy.fromMap(ChannelMap map) =>
      RadarRevealRiskTokenNetworkPrivacy(
        vpn: readBool(map['vpn']),
        proxy: readBool(map['proxy']),
        tor: readBool(map['tor']),
        relay: readBool(map['relay']),
        hosting: readBool(map['hosting']),
        residentialProxy: readBool(map['residentialProxy']),
        service: readString(map['service']),
      );
}

/// The autonomous system (ASN) of the IP for a reveal risk check.
final class RadarRevealRiskTokenNetworkAsn {
  const RadarRevealRiskTokenNetworkAsn({
    this.asn,
    this.name,
    this.domain,
    this.route,
    this.type,
    this.country,
    this.network,
  });

  final String? asn;
  final String? name;
  final String? domain;
  final String? route;

  /// The ASN type, such as `isp` or `hosting`.
  final String? type;
  final String? country;
  final String? network;

  @internal
  factory RadarRevealRiskTokenNetworkAsn.fromMap(ChannelMap map) =>
      RadarRevealRiskTokenNetworkAsn(
        asn: _readStringOrNum(map['asn']),
        name: readString(map['name']),
        domain: readString(map['domain']),
        route: readString(map['route']),
        type: readString(map['type']),
        country: readString(map['country']),
        network: readString(map['network']),
      );
}

/// The device information for a reveal risk check.
final class RadarRevealRiskTokenDevice {
  const RadarRevealRiskTokenDevice({
    this.deviceId,
    this.deviceType,
    this.deviceMake,
    this.deviceModel,
    this.deviceOSName,
    this.deviceOSVersion,
    this.sdkVersion,
    this.xPlatformType,
    this.installId,
    this.appId,
    this.appName,
    this.appVersion,
    this.appBuild,
  });

  final String? deviceId;
  final String? deviceType;
  final String? deviceMake;
  final String? deviceModel;
  final String? deviceOSName;
  final String? deviceOSVersion;
  final String? sdkVersion;

  /// The cross-platform SDK type, such as `Flutter`.
  final String? xPlatformType;
  final String? installId;
  final String? appId;
  final String? appName;
  final String? appVersion;
  final String? appBuild;

  @internal
  factory RadarRevealRiskTokenDevice.fromMap(ChannelMap map) =>
      RadarRevealRiskTokenDevice(
        deviceId: readString(map['deviceId']),
        deviceType: readString(map['deviceType']),
        deviceMake: readString(map['deviceMake']),
        deviceModel: readString(map['deviceModel']),
        deviceOSName: readString(map['deviceOSName']),
        deviceOSVersion: readString(map['deviceOSVersion']),
        sdkVersion: readString(map['sdkVersion']),
        xPlatformType: readString(map['xPlatformType']),
        installId: readString(map['installId']),
        appId: readString(map['appId']),
        appName: readString(map['appName']),
        appVersion: readString(map['appVersion']),
        appBuild: readString(map['appBuild']),
      );
}

String? _readStringOrNum(Object? value) =>
    value is num ? value.toString() : readString(value);
