// Ember — activity/apply_reducer.dart
//
// The PURE engine that folds an ActivityResult into a new EmberWorldState. It is
// a closed, exhaustive dispatch over the sealed ApplyEffect set — the analyzer
// guarantees every effect is handled, and this file is NEVER edited per concept
// (a leaf only ever EMITS effects). No Riverpod, no clock, no random.
//
// Codex entries live outside the world model, so a granted entry is recorded as a
// knowledge flag ("codex.<id>") — the codex UI reads these flags. Population-cap
// bumps and resource grants flow through the existing model helpers.

import '../core/ember_rng.dart';
import '../core/enums.dart';
import '../core/ids.dart';
import '../data/models/activity_progress.dart';
import '../data/models/concept.dart';
import '../data/models/placeable.dart';
import '../data/models/player_knowledge.dart';
import '../data/models/tile.dart';
import '../data/models/tile_grid.dart';
import '../data/models/village.dart';
import '../data/models/world_state.dart';
import 'activity_result.dart';
import 'apply_effect.dart';

/// Knowledge-flag namespace prefix for granted codex entries.
const String kCodexFlagPrefix = 'codex.';

class ApplyReducer {
  const ApplyReducer();

  /// Returns a NEW state with [result]'s effects applied, progress recorded, and
  /// any placement hint materialised. Pure: same (state,result) -> same output.
  EmberWorldState apply(EmberWorldState state, ActivityResult result) {
    EmberWorldState s = state;

    // 1) Apply every declared effect (closed dispatch).
    for (final ApplyEffect effect in result.effects) {
      s = _applyEffect(s, effect);
    }

    // 2) Record activity progress (attempts/stars/completion/upgrade flag).
    s = _recordProgress(s, result);

    // 3) Materialise any placement hint (e.g. a built hearth at the chosen tile).
    if (result.placeHint != null) {
      s = _applyPlaceHint(s, result.placeHint!);
    }

    return s;
  }

  // ---- Closed effect dispatch -------------------------------------------

  EmberWorldState _applyEffect(EmberWorldState s, ApplyEffect effect) {
    switch (effect) {
      case UnlockPlaceable():
        // Placeable availability is tracked as a knowledge flag the build menu
        // reads ("unlock.<type>") — no separate collection needed.
        return s.copyWith(
          knowledge: s.knowledge.set('unlock.${effect.type.name}'),
        );

      case SetKnowledgeFlag():
        return s.copyWith(
          knowledge: s.knowledge.set(effect.flag, effect.value),
        );

      case MarkConceptDone():
        return _markConceptDone(s, effect.concept);

      case GrantCodexEntry():
        return s.copyWith(
          knowledge: s.knowledge.set('$kCodexFlagPrefix${effect.entryId}'),
        );

      case UpgradeModel():
        // The model-upgrade belief flag is set via the activity's knowledgeFlags
        // (BeatController includes modelUpgrade.flag). Here we mark the per-
        // concept progress modelUpgraded = true.
        return _markModelUpgraded(s, effect.concept);

      case GrantResources():
        return s.copyWith(stock: s.stock.addCost(effect.resources));

      case SetWorldFlag():
        return s.copyWith(
          knowledge: s.knowledge.set(effect.flag, effect.value),
        );

      case EnableActivity():
        return s.copyWith(
          knowledge: s.knowledge.set('activity.enabled.${effect.activityId}'),
        );

      case RaisePopulationCap():
        final Village v = s.village;
        return s.copyWith(
          village: v.copyWith(populationCap: v.populationCap + effect.by),
        );
    }
  }

  // ---- Concept tree updates ---------------------------------------------

  /// Marks [concept] completed and cascade-unlocks any concept whose
  /// prerequisites are now all completed.
  EmberWorldState _markConceptDone(EmberWorldState s, ConceptId concept) {
    final List<Concept> next = <Concept>[
      for (final Concept c in s.concepts)
        if (c.id == concept) c.copyWith(completed: true, unlocked: true) else c,
    ];
    // Cascade unlock: any concept whose prereqs are all completed becomes
    // unlocked.
    final Set<ConceptId> completed = <ConceptId>{
      for (final Concept c in next)
        if (c.completed) c.id,
    };
    final List<Concept> cascaded = <Concept>[
      for (final Concept c in next)
        if (!c.unlocked &&
                c.prerequisites.isNotEmpty &&
                c.prerequisites.every(completed.contains))
            c.copyWith(unlocked: true)
        else
            c,
    ];
    return s.copyWith(concepts: cascaded);
  }

  EmberWorldState _markModelUpgraded(EmberWorldState s, ConceptId concept) {
    final List<ActivityProgress> next = <ActivityProgress>[
      for (final ActivityProgress p in s.activityProgress)
        if (p.conceptId == concept) p.copyWith(modelUpgraded: true) else p,
    ];
    return s.copyWith(activityProgress: next);
  }

  // ---- Progress recording ------------------------------------------------

  EmberWorldState _recordProgress(EmberWorldState s, ActivityResult result) {
    bool found = false;
    final List<ActivityProgress> next = <ActivityProgress>[];
    for (final ActivityProgress p in s.activityProgress) {
      if (p.conceptId != result.conceptId) {
        next.add(p);
        continue;
      }
      found = true;
      next.add(
        p.copyWith(
          attempts: p.attempts + result.attempts,
          completed: p.completed || result.completed,
          // Keep the best star result.
          qualityStars: result.qualityStars > p.qualityStars
              ? result.qualityStars
              : p.qualityStars,
          failuresSeen: <String>{
            ...p.failuresSeen,
            ...result.failuresSeen,
          },
        ),
      );
    }
    if (!found) {
      next.add(
        ActivityProgress(
          conceptId: result.conceptId,
          attempts: result.attempts,
          completed: result.completed,
          qualityStars: result.qualityStars,
          failuresSeen: result.failuresSeen.toSet(),
        ),
      );
    }
    // Also fold any explicit knowledge flags from the result.
    PlayerKnowledge k = s.knowledge;
    if (result.knowledgeFlags.isNotEmpty) {
      k = k.setAll(result.knowledgeFlags);
    }
    return s.copyWith(activityProgress: next, knowledge: k);
  }

  // ---- Placement hint ----------------------------------------------------

  /// Drops a placeable into the world from a [PlaceHint]. The id is minted from
  /// the world rng so it stays deterministic; the rng advance is reflected back
  /// into the returned state.
  EmberWorldState _applyPlaceHint(EmberWorldState s, PlaceHint hint) {
    // Mint a deterministic id by advancing a CLONE of the rng (so the input state
    // is not mutated — the reducer stays pure), then thread the advanced clone
    // into the returned state so the entropy stream keeps moving.
    final EmberRng rng = s.rng.clone();
    final EntityId id = ids.mint('placeable', rng);
    final Placeable placeable = Placeable(
      id: id,
      type: hint.type,
      tier: hint.tier,
      coord: hint.coord,
      state: hint.built ? PlaceableState.built : PlaceableState.ghost,
      buildProgress: hint.built ? 1.0 : 0.0,
      ext: Map<String, dynamic>.of(hint.ext),
    );
    // Stamp the occupant onto the footprint tiles (1x1 by default for hints).
    final Tile? t = s.tiles.at(hint.coord);
    final TileGrid updatedTiles = t == null
        ? s.tiles
        : s.tiles.withTile(t.copyWith(occupantId: id));
    return s.copyWith(
      placeables: <Placeable>[...s.placeables, placeable],
      tiles: updatedTiles,
      rng: rng,
    );
  }
}
