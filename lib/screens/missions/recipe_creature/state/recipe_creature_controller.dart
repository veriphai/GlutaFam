// The activity controller — owns the Genome, the beat state machine, the
// animation envelopes, and drives the Helix engine. The CreaturePainter is a
// pure renderer reading these getters (repaint: this).
//
// THE LOAD-BEARING RULE (PRD §3.3, criterion 3/4): only the GENOME rebuilds the
// living, breathing, controllable creature. Bones → an inert grey wireframe;
// photo → a flat frozen snapshot; neither lives, neither obeys a control. That
// unmistakable "the remains are dead, the recipe is alive" contrast is the truth
// the whole build protects — there is NO score and NO "wrong" feedback for
// reaching for the bones or the photo (they are optional discoveries).
//
// Notification model: notifyListeners() drives the per-frame canvas repaint;
// discrete UI (Helix's line, the phase, advance/peek/fact/tray/card flags) rides
// dedicated ValueNotifiers so chrome rebuilds only on real changes.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/creature_tuning.dart';
import '../config/genome.dart';
import '../config/prologue_beats.dart';
import '../engine/helix_beat_engine.dart';

/// The Prologue's one continuous experience, as a state machine (PRD §6):
/// explore(0.1) → reveal(0.2) → extinction → selecting → rebuilt(0.3) → closing.
enum RCPhase { explore, reveal, extinction, selecting, rebuilt, closing }

/// The artifacts in the 0.3 "bring it back" tray.
enum Artifact { skeleton, photo, genome, torn }

class RecipeCreatureController extends ChangeNotifier {
  RecipeCreatureController() {
    _engine = HelixBeatEngine(
      onLine: (u) => botLine.value = u,
      onAfterCommitted: _onAfterCommitted,
      onFireCollectible: () => showCardEarn.value = true,
    );
  }

  late final HelixBeatEngine _engine;

  // First-session intro suppression (PRD §11). Tiny cross-session flag.
  static const String _seenKey = 'recipe_creature_seen_intro';

  // ── Discrete UI channels (rebuild only on change) ─────────────────────────
  final ValueNotifier<HelixUtterance?> botLine = ValueNotifier(null);
  final ValueNotifier<RCPhase> phase = ValueNotifier(RCPhase.explore);
  final ValueNotifier<bool> canAdvance = ValueNotifier(false);
  final ValueNotifier<bool> peekOpen = ValueNotifier(false);
  final ValueNotifier<bool> showFact = ValueNotifier(false);
  final ValueNotifier<bool> trayReady = ValueNotifier(false);
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<Set<Artifact>> tried = ValueNotifier(const {});

  /// The field the 0.2 peek is open on (the A/T/C/G read-out is of this gene).
  GeneField peekField = GeneField.colour;

  // ── Polish + audio hooks (audio later; haptics now) ───────────────────────
  void Function()? onTraitChanged; // light tick when a gene moves
  void Function()? onFirstMove; // the 0.1 discovery beat
  void Function()? onArtifact; // an artifact was tapped
  void Function()? onRebuild; // the genome rebuild splash

  /// Reduced motion (MediaQuery.disableAnimations): extinction + rebuild become
  /// clean cuts, idle breathing off (PRD §9, §11; criterion 10).
  bool reducedMotion = false;

  // ── Creature state ────────────────────────────────────────────────────────
  Genome _genome = const Genome(); // the live, editable creature
  Genome? _snapshot; // captured at extinction → bones/photo/rebuild use it
  CreatureRenderMode _mode = CreatureRenderMode.live;
  Artifact? _selected; // current 0.3 selection (null = nothing chosen yet)
  bool _terminal = false; // the genome was chosen → the run is committed

  // ── Animation envelopes (seconds-driven, advanced in tick) ────────────────
  double _clock = 0;
  double _extinctionT = 0; // 0→1 as the creature dissolves
  double _rebuildT = 0; // 0→1 as the genome rebuilds it
  bool _rebuilding = false;
  double _assembleT = 0; // 0→1 wireframe/photo/broken entrance
  double _flashT = 0; // trait-change pulse (decays)

  // 0.1 bookkeeping.
  bool _started = false;
  bool _discovered = false;
  double _idleMs = 0;

  // ── Read-only getters for the painter ─────────────────────────────────────
  double get clock => _clock;
  CreatureRenderMode get renderMode => _mode;
  double get extinctionProgress => _extinctionT;
  double get rebuildProgress => _rebuilding ? _rebuildT : (_mode == CreatureRenderMode.live ? 1 : 0);
  double get assembleProgress => _assembleT;
  double get traitFlash => _flashT;
  bool get liveMotion => !reducedMotion;

  /// The genome the current render mode should draw.
  Genome get displayGenome {
    switch (_mode) {
      case CreatureRenderMode.live:
        return _genome;
      case CreatureRenderMode.wireframe:
      case CreatureRenderMode.photo:
        return _snapshot ?? _genome;
      case CreatureRenderMode.broken:
        return (_snapshot ?? _genome).torn;
    }
  }

  /// The vanished creature's genome — drives the faint "bring it back" ghost on
  /// the empty 0.3 stage.
  Genome? get snapshotForGhost => _snapshot;

  /// Whether the creature is on stage at all this frame.
  bool get creatureVisible {
    switch (phase.value) {
      case RCPhase.explore:
      case RCPhase.reveal:
      case RCPhase.rebuilt:
      case RCPhase.closing:
        return true;
      case RCPhase.extinction:
        return _extinctionT < 1;
      case RCPhase.selecting:
        return _selected != null; // empty stage until an artifact is chosen
    }
  }

  /// Controls are live only while the creature is live AND editable.
  bool get controlsEditable =>
      phase.value == RCPhase.explore ||
      phase.value == RCPhase.reveal ||
      phase.value == RCPhase.rebuilt;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  Future<void> start() async {
    if (_started) return;
    _started = true;
    phase.value = RCPhase.explore;
    final seen = await _seenIntro();
    if (!seen) {
      _engine.emit(PrologueBeats.intro);
      await _markSeen();
    }
    // The intro doubles as 0.1's before-line, so don't re-emit one.
    _engine.enterBeat(PrologueBeats.explore, emitBefore: false);
    notifyListeners();
  }

  Future<bool> _seenIntro() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_seenKey) ?? false;
    } catch (_) {
      return false; // fail soft → play the intro
    }
  }

  Future<void> _markSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_seenKey, true);
    } catch (_) {/* best-effort */}
  }

  // ── Beat 0.1 — moving an instruction (controls bind here) ─────────────────
  void setTrait(GeneField f, double value) {
    if (!controlsEditable) return;
    _genome = _genome.withValue(f, value);
    _idleMs = 0;
    _flashT = 1; // pulse the trait response
    onTraitChanged?.call();
    if (phase.value == RCPhase.explore && !_discovered) {
      _discovered = true;
      onFirstMove?.call();
      _engine.reportDiscovery(); // "Whoa — you moved the instruction…" (surprised)
      _engine.playAfter(delayMs: PrologueBeats.discoveryToAfterMs); // → afterLine → canAdvance
    }
    notifyListeners();
  }

  // ── Beat advance (explore → reveal → extinction) ──────────────────────────
  void advance() {
    if (!canAdvance.value) return;
    canAdvance.value = false;
    switch (phase.value) {
      case RCPhase.explore:
        _enterReveal();
      case RCPhase.reveal:
        _enterExtinction();
      default:
        break;
    }
  }

  void _enterReveal() {
    phase.value = RCPhase.reveal;
    _engine.enterBeat(PrologueBeats.reveal); // before (idea): "Want to see what one instruction actually is?"
    notifyListeners();
  }

  // ── Beat 0.2 — peek under one instruction ─────────────────────────────────
  void openPeek(GeneField f) {
    if (phase.value != RCPhase.reveal || peekOpen.value) return;
    peekField = f;
    peekOpen.value = true;
    onArtifact?.call();
    _engine.playAfter(delayMs: PrologueBeats.peekToAfterMs); // reveal.after names DNA/genome → onAfterCommitted
    notifyListeners();
  }

  void _enterExtinction() {
    phase.value = RCPhase.extinction;
    _snapshot = _genome; // the creature as it was — bones/photo/rebuild use this
    _extinctionT = 0;
    peekOpen.value = false; // the 0.2 peek panel + fact belong to 0.2 only
    showFact.value = false;
    _engine.enterBeat(PrologueBeats.bringBack); // before (curious): "…and it's gone. Extinct…"
    if (reducedMotion) {
      _extinctionT = 1;
      _enterSelecting();
    }
    notifyListeners();
  }

  void _enterSelecting() {
    if (phase.value != RCPhase.extinction) return;
    phase.value = RCPhase.selecting;
    _selected = null;
    trayReady.value = true;
    notifyListeners();
  }

  // ── Beat 0.3 — bring it back ───────────────────────────────────────────────
  void selectArtifact(Artifact a) {
    if (phase.value != RCPhase.selecting || _terminal) return;
    onArtifact?.call();

    if (a == Artifact.genome) {
      _commitRebuild();
      return;
    }

    // Inert / broken optional discoveries — order-independent, never required,
    // never a quiz. Re-tapping the same one only fires the (stubbed)
    // counterproductive socket; the reaction line plays once per artifact.
    final firstTime = !tried.value.contains(a);
    _selected = a;
    _assembleT = 0;
    switch (a) {
      case Artifact.skeleton:
        _mode = CreatureRenderMode.wireframe;
        if (firstTime) _engine.say(PrologueBeats.onSkeleton, delayMs: PrologueBeats.artifactReactMs);
      case Artifact.photo:
        _mode = CreatureRenderMode.photo;
        if (firstTime) _engine.say(PrologueBeats.onPhoto, delayMs: PrologueBeats.artifactReactMs);
      case Artifact.torn:
        _mode = CreatureRenderMode.broken;
        if (firstTime) _engine.say(PrologueBeats.onTorn, delayMs: PrologueBeats.artifactReactMs);
      case Artifact.genome:
        break; // handled above
    }
    if (!firstTime) _engine.reportCounterproductive(); // socket fires (no line)
    tried.value = {...tried.value, a};
    notifyListeners();
  }

  void _commitRebuild() {
    _terminal = true;
    _selected = Artifact.genome;
    phase.value = RCPhase.rebuilt;
    _genome = _snapshot ?? _genome; // restore the IDENTICAL creature
    _mode = CreatureRenderMode.live;
    _rebuilding = true;
    _rebuildT = reducedMotion ? 1 : 0;
    onRebuild?.call();
    _engine.reportDiscovery(); // "There. That's what it took." (surprised)
    _engine.playAfter(delayMs: PrologueBeats.rebuildToAfterMs); // after (celebrating) + fires card
    notifyListeners();
  }

  void _onAfterCommitted(BeatConfig beat) {
    switch (beat.id) {
      case 'explore':
        canAdvance.value = true; // continue affordance appears (PRD §6 exit)
      case 'reveal':
        showFact.value = true; // the inline 2-metres-of-DNA fact
        canAdvance.value = true;
      case 'bringBack':
        phase.value = RCPhase.closing; // the card overlay is already up
      default:
        break;
    }
  }

  void onCardCollected() {
    showCardEarn.value = false;
    notifyListeners();
  }

  // ── The frame tick (seconds) ───────────────────────────────────────────────
  void tick(double dt) {
    if (dt <= 0) return;
    _clock += dt;

    // Extinction dissolve → hand to the tray.
    if (phase.value == RCPhase.extinction && !reducedMotion) {
      _extinctionT = math.min(1, _extinctionT + dt / RC.extinctionSeconds);
      if (_extinctionT >= 1) _enterSelecting();
    }

    // The one orchestrated rebuild splash.
    if (_rebuilding && !reducedMotion) {
      _rebuildT = math.min(1, _rebuildT + dt / RC.rebuildSeconds);
      if (_rebuildT >= 1) _rebuilding = false;
    }

    // Wireframe / photo / broken entrance.
    if (_assembleT < 1) _assembleT = math.min(1, _assembleT + dt / RC.assembleSeconds);

    // Trait-change pulse decay.
    if (_flashT > 0) _flashT = math.max(0, _flashT - dt / RC.traitFlashSeconds);

    // Idle nudge — Beat 0.1 only, before the kid engages (PRD §11).
    if (phase.value == RCPhase.explore && !_discovered) {
      _idleMs += dt * 1000;
      if (_idleMs >= RC.idleThresholdMs) {
        _idleMs = 0;
        _engine.reportIdle(); // engine gates cooldown + single escalation
      }
    } else {
      _idleMs = 0;
    }

    _engine.update(dt * 1000); // scheduled after-lines / reactions
    notifyListeners();
  }

  @override
  void dispose() {
    botLine.dispose();
    phase.dispose();
    canAdvance.dispose();
    peekOpen.dispose();
    showFact.dispose();
    trayReady.dispose();
    showCardEarn.dispose();
    tried.dispose();
    super.dispose();
  }
}
