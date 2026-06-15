// Ember — contracts/gather_modifier.dart
//
// The PUSH seam by which the stone-tools leaf speeds up / boosts gathering.
// The resource system reads the EFFECTIVE GatherModifier through SimRegistry; it
// never imports a leaf. Default is x1.0 (no tools = baseline). A leaf returns its
// own GatherModifier from ConceptModule.gatherModifier; the registry composes the
// effective one and the sim consumes it here.

import '../core/enums.dart';
import '../data/models/world_state.dart';

/// Multiplies the yield and/or speed of gathering a [ResourceType].
///
/// Both methods take the full [EmberWorldState] so a modifier can be conditional
/// (e.g. "only while a toolRack is built"). They MUST be pure and deterministic —
/// no clock, no random.
abstract interface class GatherModifier {
  /// Multiplier applied to the units granted per gather of [type] (>= 0).
  double yieldMultiplier(ResourceType type, EmberWorldState state);

  /// Multiplier applied to gather speed/frequency for [type] (>= 0). 1.0 = base.
  double speedMultiplier(ResourceType type, EmberWorldState state);
}

/// Baseline modifier: everything at x1.0. Used when no leaf has pushed tools.
class DefaultGatherModifier implements GatherModifier {
  const DefaultGatherModifier();

  @override
  double yieldMultiplier(ResourceType type, EmberWorldState state) => 1.0;

  @override
  double speedMultiplier(ResourceType type, EmberWorldState state) => 1.0;
}

/// Composes several [GatherModifier]s by multiplying their factors together.
/// The registry uses this to fold all installed leaves' modifiers into one
/// effective modifier the sim reads. Pure.
class CompositeGatherModifier implements GatherModifier {
  const CompositeGatherModifier(this.parts);

  final List<GatherModifier> parts;

  @override
  double yieldMultiplier(ResourceType type, EmberWorldState state) {
    double m = 1.0;
    for (final GatherModifier p in parts) {
      m *= p.yieldMultiplier(type, state);
    }
    return m;
  }

  @override
  double speedMultiplier(ResourceType type, EmberWorldState state) {
    double m = 1.0;
    for (final GatherModifier p in parts) {
      m *= p.speedMultiplier(type, state);
    }
    return m;
  }
}
