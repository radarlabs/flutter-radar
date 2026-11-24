import 'package:meta/meta.dart';

import 'parsing.dart';

/// A country, state, DMA, or postal code region.
final class RadarRegion {
  const RadarRegion({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.flag,
    this.allowed = false,
    this.passed = false,
    this.inExclusionZone = false,
    this.inBufferZone = false,
    this.distanceToBorder,
    this.expected = false,
  });

  final String id;
  final String name;

  /// The region code, such as `US` or `NY`.
  final String code;

  /// The region type: `country`, `state`, `dma`, or `postalCode`.
  final String type;

  /// The country flag emoji, for countries.
  final String? flag;

  /// Whether the region is allowed by the project's fraud settings.
  final bool allowed;

  /// Whether the region passed all fraud jurisdiction checks.
  final bool passed;
  final bool inExclusionZone;
  final bool inBufferZone;

  /// Distance to the region's border in meters.
  final double? distanceToBorder;

  /// Whether the user was expected to be in this region.
  final bool expected;

  @internal
  factory RadarRegion.fromMap(ChannelMap map) {
    final distance = readDouble(map['distanceToBorder']);
    return RadarRegion(
      id: readString(map['_id']) ?? '',
      name: readString(map['name']) ?? '',
      code: readString(map['code']) ?? '',
      type: readString(map['type']) ?? '',
      flag: readString(map['flag']),
      allowed: readBool(map['allowed']) ?? false,
      passed: readBool(map['passed']) ?? false,
      inExclusionZone: readBool(map['inExclusionZone']) ?? false,
      inBufferZone: readBool(map['inBufferZone']) ?? false,
      distanceToBorder: distance == null || distance.isNaN ? null : distance,
      expected: readBool(map['expected']) ?? false,
    );
  }
}
