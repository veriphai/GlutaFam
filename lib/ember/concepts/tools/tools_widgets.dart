// Ember — concepts/tools/tools_widgets.dart
//
// Tools-specific interact CHROME (Flutter) for the Knapping mini-game — PHASE-2
// redesign. The interaction itself now happens ON the Flame stage (drag a stone
// onto the core, drag ON the rendered core to strike, drag the shaft onto the
// blade to haft); this file is therefore reduced to TWO things, per the quality
// bar's "chrome shrinks to ONE EmberCaption + only non-physical controls":
//
//   1. [KnappingInteractView] — a tiny [BuildSafeChangeNotifier] the scene pushes
//      live sim state into (phase / material / a one-line guidance caption / the
//      failure flag). It uses [safeNotify] because the scene syncs it from inside
//      Flame's update() (which overlaps Flutter's build phase).
//   2. [KnappingStageOverlay] — a FULL-SCREEN, transparent gesture surface that
//      maps finger drags straight onto the scene's on-stage props (one finger
//      drives one hero variable, the prop answers that frame), with ONE bottom
//      [EmberCaption] (bold <=5-word imperative + soft meaning-line, the concept
//      NAMED LAST) and — only when an attempt has failed — a single Retry button.
//
// KILLED (was the old "read a card then tap a button" chrome): the 2x2 stone-card
// picker, the separate strike aim-PAD widget, the flake %-meter, the phase-title
// checklist, and the wall of hint prose. The aim-pad's angle/force math + its live
// green/amber/red good-window verdict now live ON the core in knapping_scene.dart.
//
// Self-contained: reads the same [EmberPalette]/[EmberUi] tonal language as the
// rest of the module (zero app coupling); no new pub package.

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../../ui/ember_theme.dart';
import '../../ui/widgets/ember_caption.dart';
import '../build_safe_notifier.dart';
import 'knapping_sim.dart';
import 'strike_resolver.dart';

/// A small observable view-model the scene pushes the sim's live state into; the
/// full-screen overlay listens and rebuilds its caption + retry affordance. NOT
/// world state — pure presentation.
///
/// It carries the caption in the two-register form the [EmberCaption] expects: a
/// bold IMPERATIVE (what to DO this frame), a soft MEANING line (the lesson), and
/// the CONCEPT named last (the reward word). The scene composes these per phase /
/// outcome so the kid is never reading a paragraph — just one calm line.
class KnappingInteractView extends BuildSafeChangeNotifier {
  KnappingPhase _phase = KnappingPhase.chooseStone;
  StoneMaterial? _material;
  bool _failed = false;

  // The current caption (two registers + concept-last). Defaults to the opening
  // "drag a stone" imperative so there's a line the instant the beat opens.
  String _imperative = 'Drag a stone to the core';
  String _meaning = 'Only hard, glassy stone holds an';
  String _concept = 'edge';
  EmberCaptionTone _tone = EmberCaptionTone.neutral;

  KnappingPhase get phase => _phase;
  StoneMaterial? get material => _material;
  bool get failed => _failed;
  String get imperative => _imperative;
  String get meaning => _meaning;
  String get concept => _concept;
  EmberCaptionTone get tone => _tone;

  /// Push the sim's current phase/material in, plus an optional explicit caption
  /// (imperative + meaning + concept) and the failure flag. When no caption is
  /// supplied the phase's default guidance line is used so the caption always
  /// matches what the finger should do next.
  void sync(
    KnappingSim sim, {
    String? imperative,
    String? meaning,
    String? concept,
    EmberCaptionTone? tone,
    bool? failed,
  }) {
    _phase = sim.phase;
    _material = sim.material;
    if (failed != null) _failed = failed;
    if (imperative != null) {
      _imperative = imperative;
      _meaning = meaning ?? '';
      _concept = concept ?? '';
      _tone = tone ?? EmberCaptionTone.neutral;
    } else {
      _applyPhaseDefault();
    }
    safeNotify();
  }

  /// The default guidance caption for the current phase (used when the scene
  /// doesn't override it with an outcome-specific line).
  void _applyPhaseDefault() {
    if (_failed) return; // a failure caption stays until retry clears it.
    switch (_phase) {
      case KnappingPhase.chooseStone:
        _imperative = 'Drag a stone to the core';
        _meaning = 'Only hard, glassy stone holds an';
        _concept = 'edge';
        _tone = EmberCaptionTone.neutral;
      case KnappingPhase.strike:
        _imperative = 'Pull back, aim the GREEN';
        _meaning = 'A glancing blow flakes a sharp';
        _concept = 'edge';
        _tone = EmberCaptionTone.neutral;
      case KnappingPhase.haft:
        _imperative = 'Drag the shaft onto the blade';
        _meaning = 'Lashing a point to a shaft makes a';
        _concept = 'spear';
        _tone = EmberCaptionTone.neutral;
      case KnappingPhase.finished:
        _imperative = 'Sharp!';
        _meaning = 'A made edge does what hands';
        _concept = "can't";
        _tone = EmberCaptionTone.win;
    }
  }

  void reset() {
    _phase = KnappingPhase.chooseStone;
    _material = null;
    _failed = false;
    _applyPhaseDefault();
    safeNotify();
  }
}

/// The full-screen interact chrome: a transparent full-area gesture surface (its
/// drags are forwarded into the scene, which maps them onto the on-stage core),
/// the bottom [EmberCaption], and a single Retry button shown only on a failure.
///
/// The gesture surface owns the WHOLE screen (world pan/zoom is disabled during an
/// activity), so a finger anywhere drives the on-stage prop — but the picker /
/// strike are spatial (the kid drags the stone they SEE), so we report the raw
/// local position + lifecycle and let the scene resolve which prop is grabbed.
class KnappingStageOverlay extends StatelessWidget {
  const KnappingStageOverlay({
    super.key,
    required this.view,
    required this.palette,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onSkipHaft,
    required this.onRetry,
  });

  final KnappingInteractView view;
  final EmberPalette palette;

  /// Drag lifecycle in SCREEN-LOCAL px. Because the activity camera frames the
  /// stage at screen-centre, zoom 1.0 (anchor centre), a screen-local point maps
  /// 1:1 onto a stage/world point — so the scene treats these as stage coords.
  final void Function(Offset local) onDragStart;
  final void Function(Offset local) onDragUpdate;
  final void Function(Offset local) onDragEnd;

  /// The lone non-physical CHOICE control: during the haft phase the kid may
  /// finish the blade as-is instead of dragging the shaft on (hafting is optional).
  final VoidCallback onSkipHaft;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: view,
      builder: (BuildContext context, _) {
        return Stack(
          children: <Widget>[
            // The transparent full-area drag surface — the input happens ON the
            // prop: the scene maps these drags onto the candidate stones / core /
            // shaft directly. opaque hit-test so drags anywhere are captured.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (DragStartDetails d) =>
                    onDragStart(d.localPosition),
                onPanUpdate: (DragUpdateDetails d) =>
                    onDragUpdate(d.localPosition),
                onPanEnd: (_) => onDragEnd(Offset.zero),
                // A tap is treated as a tiny drag at that point (accessible
                // fallback): start + immediately end so the scene can resolve a
                // grab + a gentle default action there.
                onTapDown: (TapDownDetails d) => onDragStart(d.localPosition),
                onTapUp: (TapUpDetails d) => onDragEnd(d.localPosition),
              ),
            ),

            // The single caption + (on failure) one retry control, bottom-anchored.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EmberUi.gapL,
                    vertical: EmberUi.gap,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      EmberCaption(
                        imperative: view.imperative,
                        meaning: view.meaning,
                        concept: view.concept,
                        tone: view.tone,
                        palette: palette,
                        reservedHeight: 88,
                        // Over the knapping stage; keep the line legible through
                        // the fade-out -> swap -> fade-in dip.
                        scrim: true,
                      ),
                      if (view.failed) ...<Widget>[
                        const SizedBox(height: EmberUi.gapS),
                        _RetryButton(palette: palette, onRetry: onRetry),
                      ] else if (view.phase == KnappingPhase.haft) ...<Widget>[
                        const SizedBox(height: EmberUi.gapS),
                        _SkipHaftButton(palette: palette, onSkip: onSkipHaft),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The lone non-physical control: re-arm a fresh attempt after a teaching failure.
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.palette, required this.onRetry});

  final EmberPalette palette;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.replay),
        label: const Text('Try again'),
        style: FilledButton.styleFrom(
          backgroundColor: palette.ember,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}

/// A quiet text affordance shown only in the haft phase: finish as a hand blade
/// without hafting (a non-physical CHOICE, not a physical act — the kid still
/// makes the spear by DRAGGING the shaft on if they want reach).
class _SkipHaftButton extends StatelessWidget {
  const _SkipHaftButton({required this.palette, required this.onSkip});

  final EmberPalette palette;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onSkip,
      style: TextButton.styleFrom(foregroundColor: palette.inkSoft),
      child: const Text('Finish as a blade'),
    );
  }
}
