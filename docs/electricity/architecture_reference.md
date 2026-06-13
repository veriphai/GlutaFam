# Electricity Module — Architecture Reference
### Exact APIs, file trees, and patterns from the shipped activities & shared systems
*(Generated from a deep code audit. Paths are absolute repo paths under `lib/`. When in doubt, open the referenced file — these activities ARE the style guide.)*

---

# PART 1 — HAND CRANK LAMP (Prologue P.1) & TRACE IT BACK (EP1 beat 1.1)

Both follow **controller-owns-geometry**: state lives in a ChangeNotifier, all pixel/motion
math lives there, the view is a pure renderer. State flows via ValueNotifiers + repaint
listenable painters.

## Hand Crank Lamp — file tree

```
lib/screens/missions/hand_crank_lamp/
├── hand_crank_lamp_screen.dart            (300) — Flutter shell, Ticker, audio
├── state/crank_controller.dart            (345) — ChangeNotifier; physics, geometry, step machine
├── state/crank_particles.dart             (160) — ParticleField (sparks, embers, wind, motes)
├── config/crank_config.dart               (120) — tunables, geometry factors, speed→brightness
├── config/output_defs.dart                (75)  — ActiveOutput enum, OutputDef (lamp/fan/heater/speaker)
├── config/sequence.dart                   (27)  — kSequence (StepDefs; prompt + optional diesText)
└── widgets/
    ├── crank_surface.dart                 (37)  — Listener + CustomPaint, forwards pointer
    ├── stage_painter.dart                 (699) — pure renderer (crank/wire/devices/particles/glow)
    ├── instruction_banner.dart            (143) — fade-out→swap→fade-in text + progress dots
    ├── bulb.dart                          (150) — paintBulb(); REUSED by trace_it_back
    └── energy_field_background.dart       (176) — dark cool vignette + circuit texture
```

### Controller pattern (CrankController)
- ValueNotifiers: `activeOutput`, `instruction`, `stepIndex`, `done`.
- Hot-path getters: `brightness`, `angularVelocity`, `energyInput`, `isGenerating`,
  `handleAngle`, `pulsePhase`, `spinAngle`, `particles`, `flashIntensity`.
- Input: `onPointerDown/Move/Up(Offset local)` — signed angle delta; **MOTION (not contact)
  gates generation** (`abs(angularVelocity) > ~1.3`); release → angular velocity = 0
  immediately (no inertia).
- `tick(double dt)` 60×/sec (Ticker in shell): energy from |ω|; brightness ripple-smoothed
  WHILE generating, **HARD-GATED to 0 on stop**; spin/pulse advance only while generating;
  particles cleared instantly on stop; step machine (device clearly lit ≥0.35 then released →
  discovery flash → advance; lamp shows "No Spin, No Light" held 1.8 s); haptic tick per
  quarter-turn; `notifyListeners()`.
- Polish hooks: `onCrankTick` → `HapticFeedback.selectionClick()`.

### Rendering
`CrankSurface` = `Listener` + `CustomPaint(painter: StagePainter(controller), repaint:
controller)`. StagePainter is stateless; paint order back→front: contact shadow → device bloom
(BlendMode.plus radial) → god-rays (lamp/heater) → wire + 3 traveling pulse packets → generator
box → device (bulb via `paintBulb`) → discovery ring → shaft → crank → particles. Stage size set
once in `paint()` via `setStageSize(size)`; ALL geometry is factor × stage size.

### Screen scaffold (the template)
```
Stack [
  EnergyFieldBackground(controller),
  SafeArea [ Column [
    _ActivityHeader(back, sound toggle),       // title Bricolage 21 w800; mono eyebrow 9.5 ls1.6
    InstructionBanner(controller),             // fixed h=96 so stage never resizes
    Expanded [ CrankSurface ],
    SizedBox(h=84) [ done ? _ContinueButton : shrink ],   // fixed-height CTA seat
  ]],
  Positioned.fill [ CollectibleEarnOverlay(card, onDone) ],  // when _showCard
]
```
Continue: gold gradient `#F5C451→#D9A43B`, pill radius, PlusJakartaSans 14.5 w800 + arrow,
h=52. Background: indigo→ink gradient, radial vignette darkest at the device, faint PCB lines,
drifting warm/cool motes (24 s loop, respects disableAnimations). The hero's warm response
bloom **snaps off** — never fades.

### Completion + card
```dart
if (next >= kSequence.length) { done.value = true; activeOutput.value = lamp; _autoCrank = true; }
// shell: Continue → setState(_showCard = true) →
CollectibleEarnOverlay(card: kConservationCard, onDone: _finish /* Navigator.maybePop */)
```

### Audio
`audioplayers`: BGM `/sounds/hand_crank_lamp/bgm.mp3` looped vol 0.18; AudioContext with
`AndroidAudioFocus.none` + iOS `mixWithOthers`; started in postFrameCallback; header toggle.

### Accessibility
`MediaQuery(...textScaler: TextScaler.noScaling)` wraps the screen.

---

## Trace It Back — file tree

```
lib/screens/missions/trace_it_back/
├── trace_it_back_screen.dart              (382) — shell, Flame GameWidget, episode board, overlays
├── state/trace_back_controller.dart       (500) — multi-beat physics + silent step machine
├── game/trace_back_game.dart              (56)  — FlameGame; creates/ticks scene layers
├── game/components/scene_components.dart  (842) — 10 Flame Component layers
├── config/trace_back_tuning.dart          (103) — TBTune: geometry factors, timing knobs
├── config/trace_back_beats.dart           (99)  — TBCaption enum + TBCopy (two-register copy)
├── config/source_defs.dart                (110) — EnergySource enum, SourceDef (6 sources)
├── engine/trace_back_bot_engine.dart      (9)   — TBPhase enum (intro/magnet/turbine/source/closing)
└── widgets/energy_field_background.dart   (100) — static dark vignette variant
```

### Controller (TraceBackController)
- ValueNotifiers: `caption: ValueNotifier<TBCaption>` (with style flags imperative vs
  meaning-line), `secondary`, `phase`, `activeSource`, `showNext`, `showCardEarn`, `canFinish`.
- Hot path: `brightness`, `energyInput`, `isGenerating`, `magnetAngle`, `turbineAngle`,
  `fieldBloom` (ONLY while magnet moves), `pulsePhase`, `shimmer`, entrance reveals
  (`bulbReveal`, `coilReveal`, `turbineReveal`, `sourceReveal`, `handoffRamp`, `coreFade`),
  `flashIntensity`, `discoveryDim`.
- Flow (timers via `_schedule(ms, fn)`): B1 "Spin the Magnet" → "Faster — Brighter" → 2.2 s →
  "Now Hold It Still" → stop-after-lit = DISCOVERY (flash + `heavyImpact`) → "Only a Moving
  Magnet Works" → 2.6 s → depth-stop long line → 4.4 s → B2 "Turn the Turbine" → meaning lines →
  B3 handoff "Now Something Turns It For You" → 6 sources, two converging captions each
  (input varies / result lands on the same spin word), advanced by a "Next →" button → closing
  synthesis "Almost Everything Spins a Magnet" → capture + card → Continue.
- Hooks: `onCrankTick`, `onGeneratingChanged`, `onDiscovery` (heavyImpact), `onSourceStep`
  (selectionClick), `onCapture(String id)`.
- `reducedMotion: bool` set from MediaQuery each build.

### Flame pattern (THE template for living scenes)
```dart
class TraceBackGame extends FlameGame {
  @override Color backgroundColor() => const Color(0x00000000); // Flutter bg shows through
  @override Future<void> onLoad() async { /* add ~10 layers back→front */ }
  @override void onGameResize(Vector2 s) { controller.setStageSize(...); }
  @override void update(double dt) { if (dt > 0 && dt < 0.1) controller.tick(dt); }
}
```
Layers (each a pure-render Component): AmbientMotes, BackgroundGlow, SourceFrontEnd (per-source
particle flows: steam/water/wind streaks/sun shimmer), Shaft, Turbine, Wire (3 pulse packets,
additive), CoilMagnet (field-line bloom gated on motion), Bulb (calls shared `paintBulb`),
DiscoveryRing, GrabHint. **Gesture stays in Flutter**: a transparent `Listener` above the
GameWidget forwards pointers to the controller. GameWidget is built ONCE in initState.

### Screen scaffold with evidence board
```
Stack [
  RepaintBoundary(key: _sceneKey) [ EnergyFieldBackground, GameWidget ],   // snapshot point
  Listener(forward pointer),
  SafeArea [ Column [
    back button,
    EpisodeBoardStrip(question: kEpisode1Question, capturedIds: _board.capturedIds,
                      images: _board.images, accent: CareerColors.gold),
    _TopText(caption, secondary),    // _FadeSwapCaption: 190ms out → swap → in; imperatives
                                     // Bricolage 28 w800; meaning-lines PJS 18; long lines smaller
    Expanded [],
    Next / Continue CTA,
  ]],
  CaptureFlash overlay, CollectibleEarnOverlay,
]
```

### Evidence capture (verbatim, copy this)
```dart
final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode1Id);
_board.load();
_controller.onCapture = _onCapture;

void _onCapture(String id) {
  HapticFeedback.lightImpact();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final bytes = await captureScenePng(_sceneKey, cropFactor: evidenceById(id)?.cropFactor);
    if (!mounted) return;
    _board.capture(id, imageBytes: bytes);
  });
}
```
Capture sites: `'still_magnet'` (B1 discovery), `'turbine_spin'` (B2 first turn),
`'same_magnet'` (closing synthesis).

### Shared timing conventions
Text swap 190 ms; auto-transitions 1.8–4.4 s; haptic per π/2 turn; discovery flash ~0.7 s
envelope; brightness ripple tau 0.11 s; gesture sample timeout 0.10 s (no motion within →
ω decays to 0).

---

# PART 2 — SOURCE PERSONALITIES (EP1 beat 1.2) & LEAKY BUCKET (retired)

## Source Personalities ("Power for a Day") — the town-sim + scrubber primitives

```
lib/screens/missions/source_personalities/
├── source_personalities_screen.dart       (428) — shell; Flame town, top chrome, dock, captures
├── state/source_personalities_controller.dart (289) — owns TownSimulation, phase machine,
│        instruction, explored set, catch detection, synthesis gate, card fire
├── state/town_simulation.dart             (121) — pluggable source, day cycle 7h→24h, pollutant/
│        cost accum, per-source supply, scrub (high-water mark), townLight + lit-state enum
├── config/source_personality_defs.dart    (132) — 6 × SourcePersonality (label, accent, icon,
│        hazeRate, costRate, buildCost, upside line, catchLine, flags)
├── config/town_sim_tuning.dart            (167) — day window, dayLengthSeconds 17, sun model
│        (sunrise 6, sunset 18.5, half-sine), multi-octave wind gusts + lull envelope, catch
│        thresholds (coal haze .6, wind lull .34 …), sky palettes
├── game/town_game.dart                    (56)  — FlameGame, 5 layers, ticks controller
├── game/components/sky_layer.dart         (150) — day/dusk/night gradient, sun+halo (haze-reddened),
│        moon, 70 stars, pollution desaturation
├── game/components/cloud_layer.dart       (98)  — 6 parallax puffs, golden-hour undersides
├── game/components/town_layer.dart        (377) — THE HERO: procedural town, depth bands,
│        window grid w/ occupancy + wake thresholds, fullyLit→dim→flickering→dark, blackout
│        emergency lights, streetlights w/ cones, town bloom, atmospheric perspective
├── game/components/haze_layer.dart        (102) — rooftop smog band + 22 drifting puffs,
│        density = controller.pollution
├── game/components/source_visual_layer.dart (383) — pylons + catenary lines w/ gliding warm
│        pulses; per-source art (solar arrays shimmer, wind tower w/ gust streaks, coal/gas
│        stack + plume, nuclear dome + clean steam, hydro dam + falling streams ∝ flow)
└── widgets/
    ├── time_scrubber.dart                 (215) — CURVE SCRUBBER: clock readout, gradient
    │        track (morning/noon/dusk/midnight), drag pauses + scrubs, release resumes,
    │        sun/moon thumb with drag glow
    ├── power_readout.dart                 (129) — POWER kW (mono 19) + ↑/↓ trend; driver line
    │        below (SUNLIGHT % / WIND km/h / WATER %) — co-varying live numbers
    ├── cost_meter.dart                    (86)  — thin bar, blue→orange lerp, relative number
    └── source_selector.dart               (137) — 6 chips: accent glow selected, green ✓ when
             catch witnessed, no ratings anywhere
```

Beat pattern (per source): tap chip → `instruction.value = s.upside` (Beat 1) → day plays →
catch threshold reached → `instruction.value = s.catchLine` + `onCapture?.call(captureId)` +
explored+= → all 6 explored → 2.4 s → synthesis "Every Source Is a Trade-Off" → 1.6 s → card.
Capture ids: `'coal_haze'` (pollution ≥ .6), `'nuclear_cost'` (cost ≥ .45), `'wind_drop'`
(gust ≤ .34 + time gate), `'solar_night'` (was lit, then ≥ 18.5 h). Gas/hydro catch but don't
capture (trimmed by the CER spec).

Key sim details worth reusing: deterministic multi-octave gust function (suspenseful, not a
tidy loop); scrub is a high-water-mark transport (rewind allowed, skipping ahead not);
`displayPowerKW` sampled ~5×/s so numbers tick legibly; town sags in the SAME frame the driver
dips (cause/effect glued).

## Leaky Bucket (retired from flow; architecture still instructive)

Snap-build (Draggable parts tray → DragTarget slots) → "Power It Up" → flow sweep 0→1 at
0.34/s; each machine "alive" as the sweep passes; per-step leak particles (heat `#FF7A2E`,
additive, 1.8 s lifetime, upward drift); Sankey stream tapers 100 → ≈38; number chips
("100 IN", "−N HEAT", "M REACHES THE BULB") appear as each leak reveals; meaning-line chain
on timers; Card 04. `lb_paint.dart` exports `lbGlow()` + `lbReveal()` (slide+scale+fade
entrance helper) — copy-adapt freely.

---

# PART 3 — CER ENGINE & EVIDENCE BOARD

## Episode board (capture infra) — REUSABLE AS-IS

```
lib/screens/missions/episode_board/
├── evidence_models.dart        (173) — EvidenceMotif enum, EvidenceTile, kEpisode1Evidence,
│        evidenceById(), kEpisode1DistractorIds, kEpisode1Id/'episode1_electricity',
│        kEpisode1Question
├── evidence_store.dart         (64)  — IDs in shared_preferences 'howwow_evidence_<episodeId>'
│        (cross-session) + in-memory PNG byte cache keyed '<episodeId>|<id>'; clear(episodeId)
├── episode_board_capture.dart  (80)  — EpisodeBoardCapture(episodeId): capturedIds/images/
│        flashing ValueNotifiers; load(); capture(id, imageBytes); flash queue; idempotent
├── scene_snapshot.dart         (52)  — captureScenePng(GlobalKey, {Rect? cropFactor,
│        pixelRatio = 1.6}) → RepaintBoundary → (cropped) PNG bytes; null-safe degrade
├── evidence_tile.dart          (158) — EvidenceTileView: real Image.memory frame OR drawn
│        motif fallback; selection check + glow; ≤3-word label + source chip
├── evidence_tile_painters.dart (311) — EvidenceMotifPainter switch over 7 EP1 motifs
├── episode_board_strip.dart    (154) — pinned question + "EVIDENCE BOARD" + up-to-5 mini tiles
│        (+k overflow), dark glass + gold border; read-only
└── capture_flash.dart          (196) — auto-play 1350 ms pop-in → hold → fly-up, camera corners
```

### EvidenceTile model
```dart
@immutable class EvidenceTile {
  final String id;            // stable persisted key
  final String label;         // ≤3 words under the tile
  final String caption;       // one-line in tap preview
  final EvidenceMotif motif;  // fallback painter
  final Color accent;
  final bool relevant;        // false = distractor
  final String sourceLabel;   // 'ACT 2' / 'ACT 3'
  final Rect cropFactor;      // normalized LTRB crop of the captured scene
}
```
EP1 catalog: 5 real (`same_magnet`, `coal_haze`, `nuclear_cost`, `wind_drop`, `solar_night`)
+ 2 distractors (`still_magnet`, `turbine_spin` — true, but answer *how it's made*).

### Core capture API (EpisodeBoardCapture.capture)
Idempotent: first call persists id + queues the flash animation; replays only backfill image
bytes. NOTE (shared-infra fix): it currently resolves tiles via EP1-only `evidenceById(id)` —
v2 must switch to an episode-scoped lookup so EP2+ ids capture correctly.

## Make Your Case (EP1 CER closer)

```
lib/screens/missions/make_your_case/
├── make_your_case_screen.dart   (197) — 3-screen AnimatedSwitcher + EvidencePreview modal +
│        CollectibleEarnOverlay + _CerBackground; pops via maybePop when finished
├── state/cer_controller.dart    (184) — CerScreen{evidence,claim,playback}; available/kept/
│        slot1/slot2; two-stage tile staging (_groupA = 4 catches, _groupB = act-2 set);
│        caseComplete heuristic; load()/toggleKeep()/setSlotN()/finish()/onCardCollected()
├── config/cer_copy.dart         (53)  — ALL strings: question, tasks, slot options
│        (['many','one','a few'] / ['is good at everything','is perfect','can do it all']),
│        capstone, nudges, earn copy   ← EP1-hardcoded, to be folded into CerConfig
└── widgets/
    ├── cer_chrome.dart            (138) — CerQuestionHeader (pinned + 3 progress dots), CerCtaPill
    ├── evidence_select_screen.dart(153) — staged grid ≤6, tap → preview modal, no ✓/✗ marking
    ├── claim_build_screen.dart    (210) — sentence template w/ 2 tap-fill slots, chips per slot
    ├── playback_screen.dart       (231) — staggered montage (650 ms/tile), capstone line,
    │        gentle incomplete nudge ("Add a clue" / "Finish anyway")
    └── evidence_preview.dart      (130) — full-size frame + caption + keep/remove
}
```

Completeness heuristic (keep semantics in v2):
```dart
bool get caseComplete {
  final relevant = available.where((t) => t.relevant).map((t) => t.id).toSet();
  final keptRelevant = kept.where(relevant.contains).length;
  final keptDistractor = kept.where((id) => !relevant.contains(id)).isNotEmpty;
  return keptRelevant == relevant.length && relevant.isNotEmpty && !keptDistractor;
}
```
Loading: captured tiles only; if NOTHING captured (dev entry), falls back to the full catalog
so the screen is always playable. Card earned on Finish (`kGridMixCard`, eyebrow 'CASE
CLOSED'), then auto-pop.

**v2 refactor (shared infra):** introduce `CerConfig` (id, question, evidence, stage groups,
claim template segments + slot options, capstone, nudge, card, earn copy);
`MakeYourCaseScreen({CerConfig config = kEp1CerConfig})`; screens read config via controller.
Per-episode evidence files define `kEpisodeNEvidence` + motifs + painters; a registry
`evidenceByIdFor(episodeId, id)` replaces the EP1-only lookup inside the capture engine.
Grand finale = config whose catalog spans episodes (episode badge on tiles), possibly 3 slots.

---

# PART 4 — COLLECTIBLES, LESSON RUNNER, DEPS, THEME

## Collectible cards

Files: `lib/screens/collectibles/collectible_models.dart` (catalog), `collectible_store.dart`
(persistence: shared_preferences `'howwow_collected_card_ids'`; `CollectibleStore.add/collected/
isCollected`), `collectible_painters.dart` (motif painters), `collectible_card_view.dart`
(5:7 flip view + `_motifPainter()` dispatch), `collectible_earn_overlay.dart` (earn moment).

Existing electricity cards (numbers /23): 01 `conservation_of_energy` "The Unbreakable Rule"
(foundational, prismatic; pre-rendered PNGs in assets/images/collectibles/), 02
`electromagnetic_induction` "The Magnet Trick", 03 `energy_trade_off` "No Free Lunch",
04 `energy_loss_in_conversion` "The Great Escape" (orphaned with leaky bucket; linked 01),
05 `grid_is_a_mix` "The Grid Is a Mix" (EP1 CER; linked 03). Sections enum:
`{foundations, generation, transmission, homeSafety, grid, theBill}` with accents
prismatic/#FF9B42/#3FB9F5/#3FD99B/#B08CF7/#E0A96D.

Earn invocation (the pattern every activity uses):
```dart
ValueListenableBuilder<bool>(
  valueListenable: _controller.showCardEarn,
  builder: (context, show, _) => show
    ? CollectibleEarnOverlay(
        card: kMagnetTrickCard, eyebrow: 'NEW CARD', brag: '<one-line reward copy>',
        showMascot: false, onDone: _controller.onCardCollected)
    : const IgnorePointer(child: SizedBox.shrink()),
)
```
Overlay behavior: scale-up 1300 ms easeOutBack + glow burst, medium haptic at 55%, flip hint +
"Add to your deck" (which calls `CollectibleStore.add(card.id)` then `onDone()`);
reduced-motion = simple scale-fade.

Adding a NEW card touches: `collectible_models.dart` (CardMotif enum + const + **deckTotal on
ALL constants**), `collectible_painters.dart` (painter), `collectible_card_view.dart`
(dispatch case). **Single-owner files — only the shared-infra agent edits them.**

## Lesson runner & episode flow

`lib/screens/missions/lessonRunner.dart`: `openLesson(context, resources, {lessonId,
startFromIndex})` pushes each resource route in order; media screens pop true/false; **for
activities ANY pop = completion** (success screens call `Navigator.maybePop`). With
`lessonId == null` (our local wowConcept seeds) NO progress POSTs are sent and episode
completion is not persisted server-side. Episode lock state for wowConcepts is the hardcoded
`isLocked` flag in `lib/screens/home/career/wowConcepts.dart` (unlock = set false + add
`resources` list). Activity registry: `lib/screens/missions/activityRegistry.dart`
(`buildActivityScreen(activityId)` switch — central integration point).

## Dependencies (pubspec) — already available

flame ^1.35.1 (NO flame_forge2d usage in shipped activities — and Forge2D is banned for these
builds anyway), flutter_animate ^4.5.2, lottie, confetti, phosphor_flutter ^2.1.0 (icon set,
renders inside Flame via text glyphs), google_fonts ^6.2.1 (Bricolage Grotesque, Plus Jakarta
Sans, IBM Plex Mono via runtime), shared_preferences ^2.2.3, audioplayers ^6.5.1 (+ S3 helpers
`lib/utils/s3_audio.dart` `audioSource()` / `precacheActivityAudio()`, manifests in
`assets/manifests/<activityId>.json`), cached_network_image + `lib/utils/s3_assets.dart`
(`netImage()` / `netImageWidget()`), provider ^6 (we use plain ChangeNotifier instead).
Flutter 3.35.3 via fvm (`fvm flutter` / `fvm dart`).

## Theme constants (`lib/screens/home/career/careerTheme.dart`)

```dart
CareerColors: bgTop #081B3F · bgMid #07162F · bgBottom #0B1028 · purple #7C4DFF ·
blue #00B8FF · gold #FFC83D · cyan #18D6FF · green #65D65E · pink #B45CFF · orange #FF8A3D ·
textPrimary #FFFFFF · textSecondary #A9B4E6 · textMuted #7E8AC0 ·
glassFill 0x14FFFFFF · glassFillStrong 0x1FFFFFFF · glassBorder 0x26FFFFFF
CareerRadii: card 24 · smallCard 20 · pill 30 · chip 12
CareerSpace: page 16 · section 26 · gap 12
CareerGradients.gold (CTA) · CareerText.* (Poppins styles for career chrome — activities use
the Bricolage/PJS/PlexMono trio instead)
```
`PressableScale` (tap-scale wrapper) lives in `careerCommon.dart`.

## Lint

`analysis_options.yaml`: flutter_lints with const-preference rules disabled; `avoid_print`
off. Match surrounding style; no `// Generated` banners; comment only constraints code can't
show.

## Activity-side integration checklist (the 7 steps every new activity follows)

1. Controller (ChangeNotifier, owns geometry + phase machine + ValueNotifiers; hard-gate
   cutoffs; pointer → signed angle/drag mapping where relevant).
2. Beats as a silent step machine with `_schedule(ms, fn)` timers; two-register captions.
3. Pure renderers (Flame layers for living scenes / CustomPainter for precision widgets);
   factor-based geometry; additive glows; entrance reveals.
4. Shell: noScaling MediaQuery, EnergyFieldBackground variant, header + InstructionBanner-
   style top text (fixed height), fixed-height CTA seat, GameWidget built once.
5. Completion: done gate → Continue → card overlay → `Navigator.maybePop`.
6. Evidence: RepaintBoundary + onCapture + EpisodeBoardStrip with the episode question.
7. Verify: `fvm dart analyze lib/screens/missions/<dir>` clean; reduced-motion respected;
   small-phone portrait layout sanity.
