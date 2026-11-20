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

  /// The name of the chain. For a full list of chains, see
  /// https://radar.com/documentation/places/chains.
  final String name;

  /// The external ID of the chain.
  final String? externalId;

  /// The optional set of custom key-value pairs for the chain.
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

  /// The Radar ID of the place.
  final String id;

  /// The name of the place.
  final String name;

  /// The categories of the place. For a full list of categories, see
  /// https://radar.com/documentation/places/categories.
  final List<String> categories;

  /// The chain of the place. Null for places without a chain. For a full list
  /// of chains, see https://radar.com/documentation/places/chains.
  final RadarChain? chain;

  /// The location of the place.
  final RadarCoordinate? location;

  /// The place group, for places that are part of a group.
  final String? group;

  /// The metadata for the place, if part of a group. For details of metadata
  /// fields, see https://radar.com/documentation/places/groups.
  final Map<String, Object?>? metadata;

  /// The address of the place.
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
