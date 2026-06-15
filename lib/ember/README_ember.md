# Ember — standalone Stone Age world-builder module

Ember is a **self-contained segment** living under `lib/ember/`. It is a Flutter +
Flame educational world-builder (kids 7–14) where the science *is* the mechanic.
Spec: PRD-00 (world framework) + PRD-01 Fire / PRD-02 Stone Tools / PRD-03 Shelter.

## Hard rules (do not break)

1. **Zero coupling to the host app.** Nothing under `lib/ember/` may import from the
   rest of `eureka_app`, and the host app imports Ember **only** through
   `lib/ember/ember.dart` (the public barrel — exposes `EmberApp`). Ember ships its
   own theme, state, persistence, and assets (`assets/ember/`).
2. **One-directional dependency.** `leaf → foundation → core`. Never the reverse.
3. **Dir-lock for concept leaves.** Each concept lives in exactly one directory
   (`concepts/fire/`, `concepts/tools/`, `concepts/shelter/`). A leaf imports only
   the foundation and its own directory — **never another leaf**, **never
   `registry/ember_registry.dart`**. The only file that imports all three leaves is
   `registry/ember_registry.dart`, written last.
4. **Determinism.** No `DateTime.now()`, `Random()`, or `Stopwatch` anywhere under
   `core/`, `data/`, `sim/`, `contracts/`. Use `EmberClock` and `EmberRng` (seeded,
   serialized into the save) so live play, offline catch-up, and tests all share the
   one `WorldSimulation.advance()` tick.
5. **Always clean.** `fvm flutter analyze lib/ember` must report no issues.

## Layout

- `core/` — ids, enums, result, clock, rng, geometry, constants (pure Dart).
- `data/` — value models (`EmberWorldState` aggregate), Hive `SaveRepository`, seed.
- `sim/` — pure systems + `WorldSimulation` + `OfflineCatchup`.
- `contracts/` — the seams leaves implement (`ConceptModule` is the freeze point).
- `activity/` — the reusable Activity Framework (declarative `EmberActivity` +
  5-beat `BeatController` + closed `ApplyEffect` reducer).
- `state/` — Riverpod `WorldController` (owns state), `Intent`s, selectors, seams.
- `game/` — Flame `EmberGame`, iso projection/renderer, world, components, placement.
- `art/` `animation/` `audio/` — swappable facades (programmatic placeholder now;
  real sprites / Spine / SFX drop in behind the same interface).
- `ui/` — Flutter chrome over the canvas (HUD, build menu, dialogue, codex).
- `registry/` — collects `ConceptModule`s; `ember_registry.dart` wires the 3 leaves.
- `concepts/{fire,tools,shelter}/` — the dir-locked concept leaves.

## How to add a concept (the whole point)

Add one directory `concepts/<x>/` containing a `ConceptModule` that returns its
`PlaceableDef`s, `EmberActivity` + `ActivityScene` + `ActivitySim`, codex entries,
model upgrade, and `EventResolver`s — plus an `onInstall` that publishes any
cross-concept seam. Register it in `registry/ember_registry.dart`. No engine edits.

## Run / verify

- Analyze: `fvm flutter analyze lib/ember`
- Standalone launch (sim review loop): `fvm flutter run -t lib/ember/main_ember.dart`
  (boots straight into Ember with a debug scene picker — no app auth/onboarding).
