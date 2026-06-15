// Ember — contracts/light_source.dart
//
// A pure light/warmth emitter value type. Fire placeables PUBLISH these (via the
// fire leaf's behavior payload); the fire-coverage system READS them to compute
// lit/warm tile sets. No leaf imports another leaf — fire pushes LightSources
// into the placeable's ext bag and the sim reads them through this shared type.

import '../core/geometry.dart';

/// An immutable point light/warmth source on the grid.
///
/// [radius] is in tiles; [intensity] is a 0..1 multiplier (full fuel = 1.0,
/// guttering fire trends toward 0). Coverage falls off with distance so a tile
/// is "lit" while it is inside [radius] scaled by intensity.
class LightSource {
  const LightSource({
    required this.pos,
    required this.radius,
    this.intensity = 1.0,
  });

  /// Grid cell the source sits on.
  final GridCoord pos;

  /// Light radius in tiles at full intensity.
  final double radius;

  /// 0..1 brightness/warmth multiplier.
  final double intensity;

  /// Effective reach (tiles) after intensity scaling.
  double get effectiveRadius => radius * intensity.clamp(0.0, 1.0);

  /// Coverage strength (0..1) this source contributes at grid cell [c]:
  /// 1.0 at the source, linearly falling to 0 at [effectiveRadius].
  double coverageAt(GridCoord c) {
    final double r = effectiveRadius;
    if (r <= 0) return 0.0;
    final double d = pos.euclideanTo(c);
    if (d >= r) return 0.0;
    return (1.0 - d / r).clamp(0.0, 1.0);
  }

  LightSource copyWith({
    GridCoord? pos,
    double? radius,
    double? intensity,
  }) {
    return LightSource(
      pos: pos ?? this.pos,
      radius: radius ?? this.radius,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pos': pos.toJson(),
        'radius': radius,
        'intensity': intensity,
      };

  factory LightSource.fromJson(Map<String, dynamic> j) => LightSource(
        pos: GridCoord.fromJson((j['pos'] as Map).cast<String, dynamic>()),
        radius: (j['radius'] as num?)?.toDouble() ?? 0.0,
        intensity: (j['intensity'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  bool operator ==(Object other) =>
      other is LightSource &&
      other.pos == pos &&
      other.radius == radius &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(pos, radius, intensity);

  @override
  String toString() =>
      'LightSource(pos: $pos, radius: $radius, intensity: $intensity)';
}
