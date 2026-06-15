// Ember — concepts/fire/fire_widgets.dart
//
// Fire-specific interact CHROME (Flutter) — rebuilt for DIRECT, ON-STAGE, SAME-
// FRAME manipulation. There are NO panels, cards, %-meters, phase-title checklist,
// prose hint bar, or blow/cover buttons any more. Instead this is ONE full-screen,
// TRANSPARENT gesture surface laid over the Flame stage (the host mounts it
// Positioned.fill; world pan/zoom is off during an activity) plus ONE EmberCaption
// + a retry CTA. The finger acts directly ON the props in the Flame stage:
//
//   * TINDER  — DRAG the grass tuft into the fireboard notch (drag progress 0..1
//     = how seated it is). Dry seats with a click; damp drips + refuses.
//   * HEAT    — TURN the CRANK WHEEL (like the Hand-Crank Lamp). This surface is a
//     RAW [Listener] (not a GestureDetector — no pan threshold), so it forwards
//     the finger's down/move/up straight to the scene the instant they happen; the
//     SCENE owns the crank physics (angle delta around the wheel centre -> true
//     rad/s, with a sample-timeout hold). The instant the finger lifts, velocity
//     -> 0 and the heat bleeds NOW.
//   * AIR     — an upward SWIPE over the ember (swipe length = puff strength); a
//     short DRAG of a stone lid onto the ember caps its air.
//
// All gesture geometry is computed against PROP ANCHORS the scene pushes into the
// view each frame (crank-wheel centre / ember centre / lid rest, in screen px), so
// the gestures map onto the on-canvas props — the control IS the value. The widget
// reports CONTINUOUS channels back through callbacks the scene forwards into the
// sim as SimInputs; the props answer that frame.
//
// The view is a tiny [FireInteractView] (BuildSafeChangeNotifier + safeNotify):
// the scene syncs it from inside Flame's update (which overlaps the Flutter build
// phase), so a raw notifyListeners would fire setState during build. Self-
// contained: reads the same [EmberPalette]/[EmberUi] as the rest of the module.

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../../ui/ember_theme.dart';
import '../../ui/widgets/ember_caption.dart';
import '../build_safe_notifier.dart';
import 'make_fire_sim.dart';

/// A small observable view-model the scene pushes the sim's live state + the
/// on-screen prop anchors into; the gesture overlay + caption listen and rebuild.
/// NOT world state — pure presentation.
class FireInteractView extends BuildSafeChangeNotifier {
  MakeFirePhase _phase = MakeFirePhase.gatherTinder;
  double _heat = 0.0;
  double _ember = 0.0;
  double _flame = 0.0;
  double _tinderSeated = 0.0;
  bool _failed = false;
  String _failHint = '';

  MakeFirePhase get phase => _phase;
  double get heat => _heat;
  double get ember => _ember;
  double get flame => _flame;
  double get tinderSeated => _tinderSeated;
  bool get failed => _failed;
  String get failHint => _failHint;

  // ---- Prop anchors in SCREEN px (pushed by the scene each frame) ----------
  // The gesture surface maps finger drags against these so the input lands ON
  // the Flame props. Defaults are harmless until the first sync.
  Offset _spindlePivot = const Offset(0, 0);
  Offset _emberCenter = const Offset(0, 0);
  Offset _lidRest = const Offset(0, 0);
  Offset _tinderStart = const Offset(0, 0);
  double _stageScale = 1.0;

  Offset get spindlePivot => _spindlePivot;
  Offset get emberCenter => _emberCenter;
  Offset get lidRest => _lidRest;
  Offset get tinderStart => _tinderStart;

  /// Logical-px -> screen-px factor (so swipe-length thresholds scale with the
  /// device). The scene resolves this from game.size / canvas size.
  double get stageScale => _stageScale;

  /// Push the sim's current live state in (called each tick / event by scene).
  void sync(MakeFireSim sim, {bool? failed, String? failHint}) {
    _phase = sim.phase;
    _heat = sim.heat;
    _ember = sim.ember;
    _flame = sim.flame;
    _tinderSeated = sim.tinderSeated;
    if (failed != null) _failed = failed;
    if (failHint != null) _failHint = failHint;
    safeNotify();
  }

  /// Push the live screen-space anchors of the on-stage props.
  void syncAnchors({
    required Offset spindlePivot,
    required Offset emberCenter,
    required Offset lidRest,
    required Offset tinderStart,
    required double stageScale,
  }) {
    _spindlePivot = spindlePivot;
    _emberCenter = emberCenter;
    _lidRest = lidRest;
    _tinderStart = tinderStart;
    _stageScale = stageScale;
    safeNotify();
  }

  void reset() {
    _phase = MakeFirePhase.gatherTinder;
    _heat = 0.0;
    _ember = 0.0;
    _flame = 0.0;
    _tinderSeated = 0.0;
    _failed = false;
    _failHint = '';
    safeNotify();
  }
}

/// The full-screen, transparent gesture overlay for Make Fire. It owns the whole
/// screen (mounted Positioned.fill by the host) and lays a single gesture surface
/// that maps finger drags onto the Flame props via the view's prop anchors, plus
/// ONE bottom [EmberCaption] and a retry CTA on failure. NO panels / buttons /
/// meters.
class FireInteractOverlay extends StatefulWidget {
  const FireInteractOverlay({
    super.key,
    required this.view,
    required this.palette,
    required this.onSeatTinder,
    required this.onCrankDown,
    required this.onCrankMove,
    required this.onCrankUp,
    required this.onPuff,
    required this.onCover,
    required this.onRetry,
  });

  final FireInteractView view;
  final EmberPalette palette;

  /// dry == true seats dry tinder; false drips damp (the FUEL lesson). [seat] is
  /// the live 0..1 drag progress toward the notch.
  final void Function(bool dry, double seat) onSeatTinder;

  /// The finger grabbed the crank wheel (raw pointer-down) at screen-space pos.
  final void Function(Offset local) onCrankDown;

  /// The finger swept the crank wheel (raw pointer-move) to screen-space pos. The
  /// scene integrates these into a true angular velocity in update(dt).
  final void Function(Offset local) onCrankMove;

  /// The finger lifted off the crank wheel (raw pointer-up/cancel).
  final VoidCallback onCrankUp;

  /// An upward-swipe frame: puff [strength] (0..1, the swipe length).
  final void Function(double strength) onPuff;

  /// A stone-lid drag landed on the ember: cut its air.
  final VoidCallback onCover;

  final VoidCallback onRetry;

  @override
  State<FireInteractOverlay> createState() => _FireInteractOverlayState();
}

/// Which prop the active drag is driving (chosen at pan-start by proximity).
enum _Grab { none, tinder, spindle, lid }

class _FireInteractOverlayState extends State<FireInteractOverlay> {
  _Grab _grab = _Grab.none;

  // ---- TINDER drag state ---------------------------------------------------
  /// Whether the player picked the DAMP tuft this drag (vs the dry one).
  bool _dampPick = false;

  // ---- AIR swipe state -----------------------------------------------------
  /// Where the upward swipe began (to measure its length on release / drag).
  Offset _swipeStart = Offset.zero;
  double _lastPuffTick = 0.0;

  // ---- Raw pointer routing (CrankSurface pattern) --------------------------
  // A raw Listener has no pan threshold, so we get the finger DOWN the instant it
  // touches (vital for the crank: a held-still finger must read as "down but not
  // spinning", and a continuous turn must register from the first pixel). At down
  // we pick which prop the gesture drives by the live phase (+ lid proximity).

  void _onPointerDown(PointerDownEvent e) {
    if (widget.view.failed) return;
    final Offset p = e.localPosition;
    final FireInteractView v = widget.view;
    switch (v.phase) {
      case MakeFirePhase.gatherTinder:
        _grab = _Grab.tinder;
        // Left half of the tinder row = dry, right half = damp (the two tufts).
        _dampPick = p.dx > MediaQuery.of(context).size.width / 2;
        widget.onSeatTinder(!_dampPick, 0.0);
      case MakeFirePhase.buildHeat:
        _grab = _Grab.spindle; // the crank-wheel grab channel
        widget.onCrankDown(p);
      case MakeFirePhase.catchEmber:
      case MakeFirePhase.giveAir:
        final double dLid = (p - v.lidRest).distance;
        if (dLid < 60 * v.stageScale) {
          _grab = _Grab.lid;
        } else {
          _grab = _Grab.spindle; // reuse as the "swipe" grab channel
          _swipeStart = p;
        }
      case MakeFirePhase.ignited:
        _grab = _Grab.none;
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (widget.view.failed) return;
    final Offset p = e.localPosition;
    final FireInteractView v = widget.view;
    switch (_grab) {
      case _Grab.tinder:
        _updateTinder(p);
      case _Grab.spindle:
        if (v.phase == MakeFirePhase.buildHeat) {
          widget.onCrankMove(p); // the scene integrates this into rad/s
        } else {
          _updateSwipe(p);
        }
      case _Grab.lid:
        _updateLid(p);
      case _Grab.none:
        break;
    }
  }

  void _onPointerUp() {
    final FireInteractView v = widget.view;
    if (_grab == _Grab.spindle && v.phase == MakeFirePhase.buildHeat) {
      // Finger lifted -> velocity HARD-drops to 0 this frame; heat bleeds NOW.
      widget.onCrankUp();
    }
    _grab = _Grab.none;
  }

  // ---- TINDER: drag the tuft toward the notch (0..1 seat). -----------------
  void _updateTinder(Offset p) {
    final FireInteractView v = widget.view;
    // Seat = how far the finger has travelled ALONG the start->notch axis (the
    // spindle pivot sits at the notch), so only progress toward the notch counts.
    final Offset axis = v.spindlePivot - v.tinderStart;
    final double total = axis.distance;
    if (total < 1) return;
    final Offset rel = p - v.tinderStart;
    final double along = (rel.dx * axis.dx + rel.dy * axis.dy) / total; // dot/|a|
    final double seat = (along / total).clamp(0.0, 1.0);
    widget.onSeatTinder(!_dampPick, seat);
  }

  // ---- AIR: upward swipe over the ember -> puff strength. ------------------
  void _updateSwipe(Offset p) {
    // Only UPWARD travel counts (a puff blows up into the flame). Length is
    // normalized by ~28% of the screen height so a clear flick reads as strength
    // ~1. We emit the strength in felt CHUNKS (not per-pixel) so the flame leans +
    // brightens in a few clear steps as the breath rises — same-frame, but without
    // flooding the sim/particles. Each completed stroke resets so a continuous
    // hand-driven bellows registers stroke after stroke.
    final double up = (_swipeStart.dy - p.dy);
    if (up <= 0) return;
    final double span = MediaQuery.of(context).size.height * 0.28;
    final double reached = (up / span).clamp(0.0, 1.0);
    final double delta = reached - _lastPuffTick;
    if (delta < 0.2 && reached < 0.98) return; // chunk the breath
    _lastPuffTick = reached;
    widget.onPuff(delta);
    if (reached >= 0.98) {
      _swipeStart = p;
      _lastPuffTick = 0.0;
    }
  }

  // ---- AIR fail: drag the stone lid onto the ember. -----------------------
  void _updateLid(Offset p) {
    final FireInteractView v = widget.view;
    final double dEmber = (p - v.emberCenter).distance;
    if (dEmber < 26 * v.stageScale) {
      _grab = _Grab.none; // one-shot
      widget.onCover();
    }
  }

  // ---- The single bold imperative + soft meaning, concept named LAST. ------
  ({String imperative, String meaning, String concept, EmberCaptionTone tone})
      _caption() {
    final FireInteractView v = widget.view;
    if (v.failed) {
      return (
        imperative: 'Try again',
        meaning: v.failHint,
        concept: '',
        tone: EmberCaptionTone.warn,
      );
    }
    switch (v.phase) {
      case MakeFirePhase.gatherTinder:
        return (
          imperative: 'Drag the tinder in',
          meaning: 'Fire needs something dry to burn —',
          concept: 'fuel',
          tone: EmberCaptionTone.neutral,
        );
      case MakeFirePhase.buildHeat:
        return (
          imperative: 'Spin the drill',
          meaning: 'Friction rubs the wood hot — stop and it cools.',
          concept: 'heat',
          tone: EmberCaptionTone.neutral,
        );
      case MakeFirePhase.catchEmber:
      case MakeFirePhase.giveAir:
        return (
          imperative: 'Swipe up to breathe',
          meaning: 'A flame breathes —',
          concept: 'air',
          tone: EmberCaptionTone.neutral,
        );
      case MakeFirePhase.ignited:
        return (
          imperative: 'Fire!',
          meaning: 'Fuel, heat, and air at once —',
          concept: 'The Fire Triangle',
          tone: EmberCaptionTone.win,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.view,
      builder: (BuildContext context, _) {
        final cap = _caption();
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The transparent full-area gesture surface — a RAW [Listener] (like
            // the Hand-Crank Lamp's CrankSurface), NOT a GestureDetector: no pan
            // threshold, so the finger DOWN/MOVE/UP register the instant they
            // happen (a held-still crank reads "down but not spinning"; a turn
            // counts from the first pixel). opaque hit-test so it always receives
            // pointers over the whole stage (the props are painted underneath).
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: (_) => _onPointerUp(),
                onPointerCancel: (_) => _onPointerUp(),
                child: const SizedBox.expand(),
              ),
            ),
            // The single caption + retry, anchored at the bottom.
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: EmberUi.gapL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      EmberCaption(
                        imperative: cap.imperative,
                        meaning: cap.meaning,
                        concept: cap.concept,
                        palette: widget.palette,
                        tone: cap.tone,
                        // Over the warm fire stage; keep the line legible through
                        // the fade-out -> swap -> fade-in dip.
                        scrim: true,
                      ),
                      if (widget.view.failed)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: EmberUi.gapL),
                          child: _RetryButton(
                            palette: widget.palette,
                            onRetry: widget.onRetry,
                          ),
                        ),
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

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.palette, required this.onRetry});

  final EmberPalette palette;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.replay),
      label: const Text('Try again'),
      style: FilledButton.styleFrom(
        backgroundColor: palette.ember,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}
