// Ember — sim/systems/build_system.dart
//
// Advances construction. A placeable enters as `ghost`, becomes `building` the
// moment work starts, accrues buildProgress at (dt / buildDurationMs) per tick,
// and flips to `built` (progress 1.0) when done — at which point its registered
// PlaceableBehavior.onBuilt fires once to seed runtime payload. Pure +
// offline-safe: a single large dt completes any in-flight builds correctly.
//
// Build duration comes from SimRegistry.defFor(type); unknown types use a sane
// default so the sim never stalls.

import '../../contracts/placeable_behavior.dart';
import '../../contracts/placeable_def.dart';
import '../../contracts/sim_registry.dart';
import '../../core/enums.dart';
import '../../data/models/placeable.dart';
import '../../data/models/world_state.dart';

class BuildSystem {
  const BuildSystem(this.registry);

  final SimRegistry registry;

  /// Default build time when a type has no def registered (10s of sim time).
  static const int _defaultBuildMs = 10000;

  /// Advances all in-progress builds by [dtSeconds]. Newly-built placeables get
  /// their behavior.onBuilt called once.
  EmberWorldState advance(EmberWorldState s, double dtSeconds) {
    if (dtSeconds <= 0) return s;
    bool changed = false;
    final List<Placeable> next = <Placeable>[];

    for (final Placeable p in s.placeables) {
      // Only ghost/building placeables progress.
      if (p.state != PlaceableState.ghost &&
          p.state != PlaceableState.building) {
        next.add(p);
        continue;
      }

      final PlaceableDef? def = registry.defFor(p.type);
      final int durationMs =
          (def?.buildDurationMs ?? _defaultBuildMs).clamp(1, 1 << 31);
      final double inc = (dtSeconds * 1000.0) / durationMs;
      final double progress = (p.buildProgress + inc).clamp(0.0, 1.0);

      if (progress >= 1.0) {
        // Completed this tick.
        final Placeable built = p.copyWith(
          state: PlaceableState.built,
          buildProgress: 1.0,
        );
        final PlaceableBehavior? behavior = registry.behaviorFor(p.type);
        behavior?.onBuilt(built, s);
        next.add(built);
        changed = true;
      } else {
        next.add(p.copyWith(
          state: PlaceableState.building,
          buildProgress: progress,
        ));
        changed = true;
      }
    }

    return changed ? s.copyWith(placeables: next) : s;
  }

  /// Ticks every active placeable's behavior (post-build runtime logic, e.g.
  /// fuel burn). Behaviors mutate the placeable's ext in place; we re-collect.
  EmberWorldState tickBehaviors(EmberWorldState s, double dtSeconds) {
    if (dtSeconds <= 0) return s;
    bool any = false;
    final List<Placeable> next = <Placeable>[];
    for (final Placeable p in s.placeables) {
      if (!p.isActive) {
        next.add(p);
        continue;
      }
      final PlaceableBehavior? behavior = registry.behaviorFor(p.type);
      if (behavior == null) {
        next.add(p);
        continue;
      }
      // Behaviors mutate a copy so the source list stays referentially clean.
      final Placeable working = p.copyWith();
      behavior.onTick(working, s, dtSeconds);
      next.add(working);
      any = true;
    }
    return any ? s.copyWith(placeables: next) : s;
  }
}
