// Ember — concepts/fire/model/fire_object.dart
//
// The TYPED VIEW over a generic [Placeable]'s untyped `ext` bag for fire objects.
// A fire instance stores its bespoke state (fire type, light/warmth radius, fuel,
// burn rate, lit flag) inside Placeable.ext under stable string keys; this class
// reads it back as a strongly-typed value, derives the published [LightSource]
// payload the fire-coverage system consumes, and writes the state back into a
// fresh ext map. It NEVER edits the shared Placeable model — it only ever round-
// trips through the open `ext` bag, which is the dir-lock contract.
//
// Pure value type: no Flame/Flutter, no clock/random. The behavior + component
// mutate fuel; this view is the single place those raw keys are named.

import '../../../contracts/light_source.dart';
import '../../../core/constants.dart';
import '../../../core/enums.dart';
import '../../../core/geometry.dart';
import '../../../data/models/placeable.dart';
import '../../../sim/systems/fire_coverage.dart';

/// The closed family of fire objects (mirrors the fire-owned [PlaceableType]s).
/// Stored as `.name` in the ext bag so it round-trips with the save.
enum FireType { hearth, torch, brazier, cookingFire }

/// Maps a [FireType] to its underlying [PlaceableType] and back.
FireType fireTypeFromPlaceable(PlaceableType t) => switch (t) {
      PlaceableType.hearth => FireType.hearth,
      PlaceableType.torch => FireType.torch,
      PlaceableType.brazier => FireType.brazier,
      PlaceableType.cookingFire => FireType.cookingFire,
      // Defensive: a non-fire placeable should never reach here; default hearth.
      _ => FireType.hearth,
    };

PlaceableType placeableTypeForFire(FireType t) => switch (t) {
      FireType.hearth => PlaceableType.hearth,
      FireType.torch => PlaceableType.torch,
      FireType.brazier => PlaceableType.brazier,
      FireType.cookingFire => PlaceableType.cookingFire,
    };

FireType _fireTypeFromName(Object? n) {
  if (n is String) {
    for (final FireType v in FireType.values) {
      if (v.name == n) return v;
    }
  }
  return FireType.hearth;
}

/// Stable ext-bag keys the fire leaf owns. Frozen so the behavior, component,
/// activity placeHint, and this view all agree.
class FireExtKeys {
  const FireExtKeys._();

  static const String fireType = 'fireType';
  static const String lightRadius = 'lightRadius';
  static const String warmthRadius = 'warmthRadius';
  static const String fuelLevel = 'fuelLevel';
  static const String fuelBurnRate = 'fuelBurnRate';
  static const String isLit = 'isLit';
  // (kLightSourcesExtKey from fire_coverage.dart is the published-source key.)
}

/// A strongly-typed view over a fire [Placeable]'s ext payload.
class FireObject {
  const FireObject({
    required this.fireType,
    required this.lightRadius,
    required this.warmthRadius,
    required this.fuelLevel,
    required this.fuelBurnRate,
    required this.isLit,
  });

  /// Which fire object this is.
  final FireType fireType;

  /// Light radius in tiles at FULL fuel (intensity scales the effective reach).
  final double lightRadius;

  /// Warmth radius in tiles at full fuel (reaches a touch further than light).
  final double warmthRadius;

  /// Remaining fuel (0..[EmberConstants.fireFuelCapacity]).
  final double fuelLevel;

  /// Fuel burned per second while lit (units/sec).
  final double fuelBurnRate;

  /// Whether the fire is currently burning.
  final bool isLit;

  /// 0..1 share of the fuel tank remaining — drives flame intensity + glow.
  double get fuelFraction =>
      (fuelLevel / EmberConstants.fireFuelCapacity).clamp(0.0, 1.0);

  /// Whether the fire has fuel left to burn.
  bool get hasFuel => fuelLevel > 0.0;

  /// The instantaneous brightness/warmth multiplier (0..1): a lit, fueled fire
  /// trends to 1.0; it dims toward 0 as the tank empties; an unlit fire is dark.
  double get intensity {
    if (!isLit || !hasFuel) return 0.0;
    // Keep a readable floor while still lit so a low fire isn't pitch black,
    // then ramp to full as fuel climbs.
    return (0.35 + 0.65 * fuelFraction).clamp(0.0, 1.0);
  }

  /// The defaults for a freshly-placed fire of [type] at [tier].
  factory FireObject.initial(FireType type, {int tier = 1}) {
    final double tierScale = 1.0 + 0.25 * (tier - 1);
    final double light = _baseLightRadius(type) * tierScale;
    return FireObject(
      fireType: type,
      lightRadius: light,
      // Warmth reaches ~25% further than usable light.
      warmthRadius: light * 1.25,
      fuelLevel: EmberConstants.fireFuelCapacity,
      fuelBurnRate: EmberConstants.fireFuelBurnPerSec * _burnScale(type),
      isLit: true,
    );
  }

  /// Reads a [FireObject] out of a placeable's ext bag (falling back to the
  /// initial defaults for that placeable's type if a key is missing).
  factory FireObject.fromPlaceable(Placeable p) {
    final Map<String, dynamic> e = p.ext;
    final FireType type = e.containsKey(FireExtKeys.fireType)
        ? _fireTypeFromName(e[FireExtKeys.fireType])
        : fireTypeFromPlaceable(p.type);
    final FireObject defaults = FireObject.initial(type, tier: p.tier);
    return FireObject(
      fireType: type,
      lightRadius:
          (e[FireExtKeys.lightRadius] as num?)?.toDouble() ?? defaults.lightRadius,
      warmthRadius: (e[FireExtKeys.warmthRadius] as num?)?.toDouble() ??
          defaults.warmthRadius,
      fuelLevel:
          (e[FireExtKeys.fuelLevel] as num?)?.toDouble() ?? defaults.fuelLevel,
      fuelBurnRate: (e[FireExtKeys.fuelBurnRate] as num?)?.toDouble() ??
          defaults.fuelBurnRate,
      isLit: e[FireExtKeys.isLit] as bool? ?? defaults.isLit,
    );
  }

  FireObject copyWith({
    FireType? fireType,
    double? lightRadius,
    double? warmthRadius,
    double? fuelLevel,
    double? fuelBurnRate,
    bool? isLit,
  }) {
    return FireObject(
      fireType: fireType ?? this.fireType,
      lightRadius: lightRadius ?? this.lightRadius,
      warmthRadius: warmthRadius ?? this.warmthRadius,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      fuelBurnRate: fuelBurnRate ?? this.fuelBurnRate,
      isLit: isLit ?? this.isLit,
    );
  }

  /// The [LightSource] this fire publishes at grid [pos]. The warmth seam uses
  /// the slightly larger [warmthRadius]; the coverage system distinguishes lit
  /// vs warm by its own thresholds, so we publish the warmth radius (the larger)
  /// and let the threshold carve out the usable-light core.
  LightSource lightSourceAt(GridCoord pos) => LightSource(
        pos: pos,
        radius: warmthRadius,
        intensity: intensity,
      );

  /// Serializes this fire view back into a flat ext map. [pos] is needed to bake
  /// the published [LightSource] list the coverage system reads (under the shared
  /// [kLightSourcesExtKey]); pass null to omit the source (e.g. while ghosting).
  Map<String, dynamic> toExt({GridCoord? pos}) {
    final Map<String, dynamic> out = <String, dynamic>{
      FireExtKeys.fireType: fireType.name,
      FireExtKeys.lightRadius: lightRadius,
      FireExtKeys.warmthRadius: warmthRadius,
      FireExtKeys.fuelLevel: fuelLevel,
      FireExtKeys.fuelBurnRate: fuelBurnRate,
      FireExtKeys.isLit: isLit,
    };
    if (pos != null && intensity > 0.0) {
      out[kLightSourcesExtKey] = <Map<String, dynamic>>[
        lightSourceAt(pos).toJson(),
      ];
    } else {
      // An unlit / unfueled fire publishes NO source (night stays dark).
      out[kLightSourcesExtKey] = const <Map<String, dynamic>>[];
    }
    return out;
  }

  /// Writes this fire view onto [p]'s ext bag IN PLACE (the behavior owns the
  /// doc and mutates its ext each tick). Bakes the published source at [p.coord].
  void applyTo(Placeable p) {
    final Map<String, dynamic> next = toExt(pos: p.coord);
    for (final MapEntry<String, dynamic> entry in next.entries) {
      p.ext[entry.key] = entry.value;
    }
  }

  static double _baseLightRadius(FireType t) => switch (t) {
        // A central hearth lights the whole camp.
        FireType.hearth => EmberConstants.fireBaseLightRadius,
        // A torch is a smaller, placed perimeter light.
        FireType.torch => EmberConstants.fireBaseLightRadius * 0.7,
        // A brazier sits between a torch and a hearth.
        FireType.brazier => EmberConstants.fireBaseLightRadius * 0.85,
        // A cooking fire is a small working fire.
        FireType.cookingFire => EmberConstants.fireBaseLightRadius * 0.75,
      };

  /// Per-type burn-rate multiplier (a big hearth eats more wood than a torch).
  static double _burnScale(FireType t) => switch (t) {
        FireType.hearth => 1.0,
        FireType.torch => 0.6,
        FireType.brazier => 0.8,
        FireType.cookingFire => 0.9,
      };

  @override
  bool operator ==(Object other) =>
      other is FireObject &&
      other.fireType == fireType &&
      other.lightRadius == lightRadius &&
      other.warmthRadius == warmthRadius &&
      other.fuelLevel == fuelLevel &&
      other.fuelBurnRate == fuelBurnRate &&
      other.isLit == isLit;

  @override
  int get hashCode => Object.hash(
        fireType,
        lightRadius,
        warmthRadius,
        fuelLevel,
        fuelBurnRate,
        isLit,
      );
}
