import 'package:meta/meta.dart';

import 'parsing.dart';
import 'radar_address.dart';
import 'radar_location.dart';

/// A place chain, such as a restaurant or store brand.
final class RadarChain {
  const RadarChain({
    required this.slug,
    required this.name,
    this.externalId,
    this.metadata,
  });

  /// The unique ID of the chain, such as `starbucks`.
  final String slug;
  final String name;
  final String? externalId;
  final Map<String, Object?>? metadata;

  @internal
  factory RadarChain.fromMap(ChannelMap map) => RadarChain(
    slug: readString(map['slug']) ?? '',
    name: readString(map['name']) ?? '',
    externalId: readString(map['externalId']),
    metadata: readJson(map['metadata']),
  );
}

/// A place from Radar's places database.
final class RadarPlace {
  const RadarPlace({
    required this.id,
    required this.name,
    this.categories = const [],
    this.chain,
    this.location,
    this.group,
    this.metadata,
    this.address,
    this.geometryRadius,
  });

  final String id;
  final String name;
  final List<String> categories;
  final RadarChain? chain;
  final RadarCoordinate? location;

  /// The place group, for places that are part of a group.
  final String? group;
  final Map<String, Object?>? metadata;
  final RadarAddress? address;

  /// The radius of the place's geometry in meters. Android only.
  final double? geometryRadius;

  @internal
  factory RadarPlace.fromMap(ChannelMap map) => RadarPlace(
    id: readString(map['_id']) ?? '',
    name: readString(map['name']) ?? '',
    categories: readStringList(map['categories']),
    chain: readObject(map['chain'], RadarChain.fromMap),
    location: RadarCoordinate.fromMap(readMap(map['location'])),
    group: readString(map['group']),
    metadata: readJson(map['metadata']),
    address: readObject(map['address'], RadarAddress.fromMap),
    geometryRadius: readDouble(map['geometryRadius']),
  );
}
