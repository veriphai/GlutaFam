// Ember — concepts/shelter/shelter_widgets.dart
//
// Shelter interact CHROME (Flutter) — PHASE-2 redesign. The card-then-button panel
// is GONE. This is now a FULL-SCREEN, TRANSPARENT gesture surface that maps finger
// drags straight onto the on-stage Flame props (the "input happens ON the prop"
// quality bar), plus the ONE EmberCaption channel and a retry CTA. Everything the
// finger does drives one hero variable and the PROP answers that frame:
//   * SITE     — TAP a candidate spot on the iso ground to stand the build there.
//                Each spot's risk is FELT on the stage (a low spot has a water-line
//                haze); the tap commits it.
//   * MATERIAL — DRAG a material chip UP onto the riser; while you hold it the WALL
//                RISES course by course at that material's pace (hide snaps up,
//                timber climbs) — release at the top to commit (the felt tradeoff).
//   * ASSEMBLE — SNAP-BUILD: drag the one lit part (Frame -> Cover -> Anchor ->
//                Smoke-hole) from the tray onto its pulsing ghost slot; it auto-
//                snaps within a generous radius (selectionClick + the stage's slide+
//                scale+fade settle + a bespoke deployment). A wrong drop bounces
//                back with a kind nudge (no destroyed progress).
//   * TEST     — the storm plays out ON the Flame stage (driving rain, gusts,
//                lightning, strain, collapse-vs-cozy). The overlay just names the
//                tension in the caption and pulses light haptics on the gusts +
//                verdict — numbers are never the feedback channel; the WORLD is.
//
// The surface reads the SHARED [ShelterStageLayout] fractions so its hit-tests line
// up with the stage's props WITHOUT coupling. It is driven by a tiny
// [ShelterInteractView] (a BuildSafeChangeNotifier the scene syncs from Flame's
// update() — DEFECT B FIX: uses safeNotify to never setState during build).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../art/ember_palette.dart';
import '../../ui/ember_theme.dart';
import '../../ui/widgets/ember_caption.dart';
import '../build_safe_notifier.dart';
import 'raise_shelter_sim.dart';

/// One offered site the player can pick from (laid out on the iso ground). [risk]
/// drives the FELT water-line haze the stage paints, and the verdict at the test.
class SiteOption {
  const SiteOption({
    required this.id,
    required this.label,
    required this.blurb,
    required this.risk,
    required this.icon,
  });

  final String id;
  final String label;
  final String blurb;

  /// 0..1 flood risk — at/above the activity threshold it floods at the test.
  final double risk;
  final IconData icon;
}

/// A small observable view-model the scene pushes the sim's live state into; the
/// full-screen surface listens and rebuilds. NOT world state — pure presentation.
///
/// DEFECT B FIX: extends [BuildSafeChangeNotifier] + uses [safeNotify] because the
/// scene syncs this from inside Flame's update (which overlaps the Flutter build
/// phase), so a raw notifyListeners fired setState during build.
class ShelterInteractView extends BuildSafeChangeNotifier {
  RaisePhase _phase = RaisePhase.chooseSite;
  double _siteRisk = 0.0;
  String _siteId = '';
  bool _siteChosen = false;
  ShelterMaterial _material = ShelterMaterial.hideTent;
  bool _materialChosen = false;
  double _wallRise = 0.0;
  bool _hasFrame = false;
  bool _hasCover = false;
  bool _hasAnchor = false;
  bool _hasSmokeHole = false;
  AssembleStep? _currentStep = AssembleStep.frame;
  double _nudge = 0.0;
  double _testProgress = 0.0;
  String _hint = '';
  bool _failed = false;

  // Storm telemetry mirrored from the sim (presentation-only).
  StormVerdict? _verdict;
  double _gust = 0.0;
  double _strain = 0.0;
  double _failProgress = 0.0;

  RaisePhase get phase => _phase;
  double get siteRisk => _siteRisk;
  String get siteId => _siteId;
  bool get siteChosen => _siteChosen;
  ShelterMaterial get material => _material;
  bool get materialChosen => _materialChosen;
  double get wallRise => _wallRise;
  bool get hasFrame => _hasFrame;
  bool get hasCover => _hasCover;
  bool get hasAnchor => _hasAnchor;
  bool get hasSmokeHole => _hasSmokeHole;
  AssembleStep? get currentStep => _currentStep;
  double get nudge => _nudge;
  bool get canRunTest => _hasFrame && _hasCover;
  bool get fullyAssembled =>
      _hasFrame && _hasCover && _hasAnchor && _hasSmokeHole;
  double get testProgress => _testProgress;
  String get hint => _hint;
  bool get failed => _failed;

  StormVerdict? get verdict => _verdict;
  double get gust => _gust;
  double get strain => _strain;
  double get failProgress => _failProgress;

  /// How many assemble parts are placed (0..4).
  int get stepsDone =>
      (_hasFrame ? 1 : 0) +
      (_hasCover ? 1 : 0) +
      (_hasAnchor ? 1 : 0) +
      (_hasSmokeHole ? 1 : 0);

  /// Push the sim's current state in (called each tick / on event by the scene).
  void sync(RaiseShelterSim sim, {String? hint, bool? failed}) {
    _phase = sim.phase;
    _siteRisk = sim.siteRisk;
    _siteId = sim.siteId;
    _siteChosen = sim.siteChosen;
    _material = sim.material;
    _materialChosen = sim.materialChosen;
    _wallRise = sim.wallRise;
    _hasFrame = sim.hasFrame;
    _hasCover = sim.hasCover;
    _hasAnchor = sim.hasAnchor;
    _hasSmokeHole = sim.hasSmokeHole;
    _currentStep = sim.currentStep;
    _nudge = sim.nudge;
    _testProgress = sim.testProgress;
    _verdict = sim.verdict;
    _gust = sim.gust;
    _strain = sim.strain;
    _failProgress = sim.failProgress;
    if (hint != null) _hint = hint;
    if (failed != null) _failed = failed;
    safeNotify();
  }

  void reset() {
    _phase = RaisePhase.chooseSite;
    _siteRisk = 0.0;
    _siteId = '';
    _siteChosen = false;
    _material = ShelterMaterial.hideTent;
    _materialChosen = false;
    _wallRise = 0.0;
    _hasFrame = false;
    _hasCover = false;
    _hasAnchor = false;
    _hasSmokeHole = false;
    _currentStep = AssembleStep.frame;
    _nudge = 0.0;
    _testProgress = 0.0;
    _verdict = null;
    _gust = 0.0;
    _strain = 0.0;
    _failProgress = 0.0;
    _failed = false;
    _hint = '';
    safeNotify();
  }
}

/// The full-screen interact surface: a transparent gesture layer mapping drags onto
/// the on-stage props, with ONE bottom EmberCaption + (on failure) a retry CTA.
///
/// It owns its whole-screen layout (the host guarantees Positioned.fill + disabled
/// world pan/zoom). Inputs are routed back into the sim via the scene callbacks.
class ShelterInteractPanel extends StatefulWidget {
  const ShelterInteractPanel({
    super.key,
    required this.view,
    required this.palette,
    required this.sites,
    required this.onChooseSite,
    required this.onMaterialDrag,
    required this.onAssembleStep,
    required this.onRunTest,
    required this.onRetry,
    this.floodRiskThreshold = 0.4,
  });

  final ShelterInteractView view;
  final EmberPalette palette;

  /// The three offered sites (high/safe, mid, low/river).
  final List<SiteOption> sites;

  /// Tap-to-choose a site spot.
  final void Function(SiteOption site) onChooseSite;

  /// Drag a material in: ([material], dragging?) — dragging true while held, false
  /// on release. While dragging the wall rises; release at the top commits.
  final void Function(ShelterMaterial material, bool dragging) onMaterialDrag;

  /// Snap a part onto its slot (the LEGO drop).
  final void Function(AssembleStep step) onAssembleStep;

  /// Run the storm test (auto-fired once all parts are placed; see below).
  final VoidCallback onRunTest;
  final VoidCallback onRetry;
  final double floodRiskThreshold;

  @override
  State<ShelterInteractPanel> createState() => _ShelterInteractPanelState();
}

class _ShelterInteractPanelState extends State<ShelterInteractPanel> {
  // ---- Active drag bookkeeping (presentation-only) -----------------------
  /// The material chip being dragged (null when not dragging one).
  ShelterMaterial? _dragMaterial;

  /// The assemble part being dragged + its live finger position (local px).
  AssembleStep? _dragPart;
  Offset? _dragPos;

  // ---- Storm haptic bookkeeping ------------------------------------------
  bool _gustBuzzed = false;
  bool _verdictBuzzed = false;
  bool _testFired = false;

  /// The last laid-out full-screen size (from the LayoutBuilder), used to resolve
  /// the shared fractional slot geometry for the snap hit-test without poking at
  /// the render tree mid-gesture.
  Size _lastSize = Size.zero;

  void _stormHaptics(ShelterInteractView v) {
    if (v.gust > 0.78 && !_gustBuzzed) {
      _gustBuzzed = true;
      HapticFeedback.lightImpact();
    } else if (v.gust < 0.5) {
      _gustBuzzed = false;
    }
    if (v.testProgress >= 0.999 && !_verdictBuzzed) {
      _verdictBuzzed = true;
      v.verdict == StormVerdict.holds
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.view,
      builder: (BuildContext context, _) {
        final ShelterInteractView v = widget.view;

        // Auto-advance into the storm the moment all four parts are placed (the
        // build IS complete; no "face the storm" button). Fire once.
        if (v.phase == RaisePhase.assemble && v.fullyAssembled && !_testFired) {
          _testFired = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onRunTest();
          });
        }
        if (v.phase == RaisePhase.chooseSite ||
            v.phase == RaisePhase.chooseMaterial) {
          _testFired = false;
        }
        if (v.phase == RaisePhase.test) _stormHaptics(v);

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Size size = Size(c.maxWidth, c.maxHeight);
            _lastSize = size;
            return Stack(
              children: <Widget>[
                // The whole-screen drag/tap surface (transparent — the props live
                // on the Flame stage beneath).
                Positioned.fill(
                  child: _GestureSurface(
                    view: v,
                    palette: widget.palette,
                    size: size,
                    sites: widget.sites,
                    floodRiskThreshold: widget.floodRiskThreshold,
                    dragMaterial: _dragMaterial,
                    dragPart: _dragPart,
                    dragPos: _dragPos,
                    onTapSite: _handleTapSite,
                    onMaterialDragStart: _handleMaterialStart,
                    onMaterialDragUpdate: (Offset p) =>
                        setState(() => _dragPos = p),
                    onMaterialDragEnd: _handleMaterialEnd,
                    onPartDragStart: _handlePartStart,
                    onPartDragUpdate: (Offset p) =>
                        setState(() => _dragPos = p),
                    onPartDragEnd: _handlePartEnd,
                  ),
                ),

                // The single caption channel + retry, bottom-anchored.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: EmberUi.gap, vertical: EmberUi.gapS),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _caption(v),
                          if (v.failed) ...<Widget>[
                            const SizedBox(height: EmberUi.gapS),
                            _RetryButton(
                                palette: widget.palette,
                                onRetry: () {
                                  setState(() {
                                    _dragMaterial = null;
                                    _dragPart = null;
                                    _dragPos = null;
                                    _testFired = false;
                                    _gustBuzzed = false;
                                    _verdictBuzzed = false;
                                  });
                                  widget.onRetry();
                                }),
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
      },
    );
  }

  // ---- The caption: ONE bold imperative + soft meaning, concept named LAST ----
  Widget _caption(ShelterInteractView v) {
    final EmberPalette p = widget.palette;
    String imperative;
    String meaning = '';
    String concept = '';
    EmberCaptionTone tone = EmberCaptionTone.neutral;

    if (v.failed) {
      imperative = 'Try again';
      meaning = v.hint;
      tone = EmberCaptionTone.warn;
    } else {
      switch (v.phase) {
        case RaisePhase.chooseSite:
          imperative = 'Read the ground';
          meaning = 'Build where water cannot reach —';
          concept = 'site';
        case RaisePhase.chooseMaterial:
          imperative = v.wallRise > 0.02 ? 'Hold — keep raising' : 'Raise the walls';
          meaning = 'Strong takes longer to build —';
          concept = 'tradeoff';
        case RaisePhase.assemble:
          final (String imp, String mean, String con) = _assembleCaption(v);
          imperative = imp;
          meaning = mean;
          concept = con;
        case RaisePhase.test:
          imperative = v.gust > 0.7 ? 'A gust lashes in' : 'Brace the storm';
          meaning = 'A frame sheds the storm —';
          concept = 'shelter';
        case RaisePhase.stood:
          imperative = 'It holds!';
          meaning = 'Warm and dry through the night —';
          concept = 'home';
          tone = EmberCaptionTone.win;
      }
    }

    return EmberCaption(
      imperative: imperative,
      meaning: meaning,
      concept: concept,
      palette: p,
      tone: tone,
      reservedHeight: 88,
      // Over the warm activity background; keep the line legible through the fade.
      scrim: true,
    );
  }

  (String, String, String) _assembleCaption(ShelterInteractView v) {
    return switch (v.currentStep) {
      AssembleStep.frame => ('Raise the frame', 'Poles carry the load —', 'frame'),
      AssembleStep.cover => ('Drape the cover', 'Hides keep out the cold —', 'cover'),
      AssembleStep.anchor =>
        ('Anchor it down', 'Weight stops the wind taking it —', 'anchor'),
      AssembleStep.smokeHole =>
        ('Cut the smoke hole', 'Let the hearth breathe —', 'air'),
      null => ('Stand it up', 'Now face the storm —', 'shelter'),
    };
  }

  // ---- Site tap ----------------------------------------------------------
  void _handleTapSite(SiteOption site) {
    HapticFeedback.selectionClick();
    widget.onChooseSite(site);
  }

  // ---- Material drag (raise the walls) -----------------------------------
  void _handleMaterialStart(ShelterMaterial m, Offset p) {
    setState(() {
      _dragMaterial = m;
      _dragPos = p;
    });
    widget.onMaterialDrag(m, true);
  }

  void _handleMaterialEnd() {
    final ShelterMaterial? m = _dragMaterial;
    if (m != null) widget.onMaterialDrag(m, false); // released — stop rising.
    setState(() {
      _dragMaterial = null;
      _dragPos = null;
    });
  }

  // ---- Part drag (snap-build) --------------------------------------------
  void _handlePartStart(AssembleStep step, Offset p) {
    setState(() {
      _dragPart = step;
      _dragPos = p;
    });
  }

  void _handlePartEnd() {
    final AssembleStep? step = _dragPart;
    final Offset? pos = _dragPos;
    setState(() {
      _dragPart = null;
      _dragPos = null;
    });
    if (step == null || pos == null) return;
    // Snap if the drop landed within the generous radius of the part's ghost slot.
    final Size size = _lastSize;
    if (size.isEmpty) return;
    final ({double x, double y}) slot = ShelterStageLayout.slotFor(step);
    final Offset slotPx = Offset(slot.x * size.width, slot.y * size.height);
    final double r = ShelterStageLayout.snapRadiusFrac * size.width;
    if ((pos - slotPx).distance <= r) {
      HapticFeedback.selectionClick();
      widget.onAssembleStep(step);
    } else {
      // Missed the slot — a kind bounce (the part just returns to the tray; the
      // stage pulses the ghost slot). No event, no destroyed progress.
      HapticFeedback.lightImpact();
    }
  }
}

/// The transparent full-screen gesture surface. It hit-tests finger drags against
/// the SHARED [ShelterStageLayout] fractions (so it lines up with the on-stage
/// props), routes them to the callbacks, and paints only the LIGHTEST drag-follow
/// affordances (a faint chip under the finger) — the real props are on the Flame
/// stage. Phase decides which gestures are live.
class _GestureSurface extends StatelessWidget {
  const _GestureSurface({
    required this.view,
    required this.palette,
    required this.size,
    required this.sites,
    required this.floodRiskThreshold,
    required this.dragMaterial,
    required this.dragPart,
    required this.dragPos,
    required this.onTapSite,
    required this.onMaterialDragStart,
    required this.onMaterialDragUpdate,
    required this.onMaterialDragEnd,
    required this.onPartDragStart,
    required this.onPartDragUpdate,
    required this.onPartDragEnd,
  });

  final ShelterInteractView view;
  final EmberPalette palette;
  final Size size;
  final List<SiteOption> sites;
  final double floodRiskThreshold;

  final ShelterMaterial? dragMaterial;
  final AssembleStep? dragPart;
  final Offset? dragPos;

  final void Function(SiteOption site) onTapSite;
  final void Function(ShelterMaterial m, Offset p) onMaterialDragStart;
  final void Function(Offset p) onMaterialDragUpdate;
  final VoidCallback onMaterialDragEnd;
  final void Function(AssembleStep step, Offset p) onPartDragStart;
  final void Function(Offset p) onPartDragUpdate;
  final VoidCallback onPartDragEnd;

  Offset _frac(({double x, double y}) f) =>
      Offset(f.x * size.width, f.y * size.height);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _onPanEnd(),
      child: Stack(
        children: <Widget>[
          // Phase affordances (light, non-physical hints layered over the stage).
          if (view.phase == RaisePhase.chooseSite) ..._siteHaloes(),
          if (view.phase == RaisePhase.chooseMaterial) ..._materialChips(),
          if (view.phase == RaisePhase.assemble) _partTray(),
          // The drag-follow ghost under the finger.
          if (dragPos != null && (dragMaterial != null || dragPart != null))
            _dragGhost(),
        ],
      ),
    );
  }

  // ---- SITE: tap one of the candidate spots ------------------------------
  List<Widget> _siteHaloes() {
    return <Widget>[
      for (final SiteOption s in sites)
        if (ShelterStageLayout.siteSpots.containsKey(s.id))
          _SiteHalo(
            center: _frac(ShelterStageLayout.siteSpots[s.id]!),
            risky: s.risk >= floodRiskThreshold,
            label: s.label,
            palette: palette,
          ),
    ];
  }

  void _onTapDown(TapDownDetails d) {
    if (view.phase != RaisePhase.chooseSite) return;
    final double r = ShelterStageLayout.siteTapRadiusFrac * size.width;
    SiteOption? best;
    double bestD = double.infinity;
    for (final SiteOption s in sites) {
      final ({double x, double y})? f = ShelterStageLayout.siteSpots[s.id];
      if (f == null) continue;
      final double dist = (d.localPosition - _frac(f)).distance;
      if (dist < bestD && dist <= r) {
        bestD = dist;
        best = s;
      }
    }
    if (best != null) onTapSite(best);
  }

  // ---- MATERIAL: drag a chip up to raise the walls -----------------------
  List<Widget> _materialChips() {
    return <Widget>[
      for (final MapEntry<String, ({double x, double y})> e
          in ShelterStageLayout.materialSpots.entries)
        _MaterialChip(
          center: _frac(e.value),
          material: e.key == 'hut' ? ShelterMaterial.hut : ShelterMaterial.hideTent,
          palette: palette,
          dimmed: dragMaterial != null &&
              dragMaterial!.name != e.key,
        ),
    ];
  }

  // ---- ASSEMBLE: the tray with the single lit, draggable part ------------
  Widget _partTray() {
    final AssembleStep? step = view.currentStep;
    if (step == null) return const SizedBox.shrink();
    final Offset c = _frac(ShelterStageLayout.trayAnchor);
    final bool nudging = view.nudge > 0.05;
    return Positioned(
      left: c.dx - 40,
      top: c.dy - 40,
      child: IgnorePointer(
        child: _PartChip(
          step: step,
          palette: palette,
          // Hide the resting chip while it's being dragged (the ghost follows).
          visible: dragPart == null,
          nudge: nudging,
        ),
      ),
    );
  }

  // ---- The drag-follow ghost (faint chip under the finger) ---------------
  Widget _dragGhost() {
    final Offset p = dragPos!;
    final Widget chip = dragPart != null
        ? _PartChip(step: dragPart!, palette: palette, visible: true)
        : _MaterialGlyph(
            material: dragMaterial!, palette: palette, size: 56);
    return Positioned(
      left: p.dx - 30,
      top: p.dy - 30,
      child: IgnorePointer(
        child: Opacity(opacity: 0.85, child: SizedBox(width: 60, child: chip)),
      ),
    );
  }

  // ---- Pan routing -------------------------------------------------------
  void _onPanStart(DragStartDetails d) {
    final Offset p = d.localPosition;
    if (view.phase == RaisePhase.chooseMaterial) {
      // Grab whichever material chip the finger started on (nearest within reach).
      final double r = 0.16 * size.width;
      ShelterMaterial? pick;
      double bestD = double.infinity;
      for (final MapEntry<String, ({double x, double y})> e
          in ShelterStageLayout.materialSpots.entries) {
        final double dist = (p - _frac(e.value)).distance;
        if (dist < bestD && dist <= r) {
          bestD = dist;
          pick = e.key == 'hut'
              ? ShelterMaterial.hut
              : ShelterMaterial.hideTent;
        }
      }
      if (pick != null) onMaterialDragStart(pick, p);
      return;
    }
    if (view.phase == RaisePhase.assemble) {
      final AssembleStep? step = view.currentStep;
      if (step == null) return;
      // Only the current lit part is grabbable — start a drag if the finger began
      // near the tray (generous) OR anywhere (the only part is the current one).
      onPartDragStart(step, p);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (dragMaterial != null) {
      onMaterialDragUpdate(d.localPosition);
    } else if (dragPart != null) {
      onPartDragUpdate(d.localPosition);
    }
  }

  void _onPanEnd() {
    if (dragMaterial != null) {
      onMaterialDragEnd();
    } else if (dragPart != null) {
      onPartDragEnd();
    }
  }
}

/// A faint pulsing halo over a candidate SITE spot (the non-physical "tap here"
/// affordance; the felt risk read itself lives on the Flame stage as the haze).
class _SiteHalo extends StatelessWidget {
  const _SiteHalo({
    required this.center,
    required this.risky,
    required this.label,
    required this.palette,
  });

  final Offset center;
  final bool risky;
  final String label;
  final EmberPalette palette;

  @override
  Widget build(BuildContext context) {
    final Color c = risky ? palette.warning : palette.success;
    return Positioned(
      left: center.dx - 54,
      top: center.dy - 54,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 108,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(54),
                border: Border.all(color: c.withValues(alpha: 0.7), width: 2),
                color: c.withValues(alpha: 0.10),
              ),
              child: Icon(risky ? Icons.water_drop : Icons.terrain,
                  color: c, size: 24),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(EmberUi.radiusS),
                border: Border.all(color: c.withValues(alpha: 0.5)),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A draggable MATERIAL chip (hide vs hut) resting in the bottom band.
class _MaterialChip extends StatelessWidget {
  const _MaterialChip({
    required this.center,
    required this.material,
    required this.palette,
    required this.dimmed,
  });

  final Offset center;
  final ShelterMaterial material;
  final EmberPalette palette;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final bool hut = material == ShelterMaterial.hut;
    return Positioned(
      left: center.dx - 52,
      top: center.dy - 52,
      child: IgnorePointer(
        child: Opacity(
          opacity: dimmed ? 0.35 : 1.0,
          child: Container(
            width: 104,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: EmberUi.panel(palette, raised: true),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _MaterialGlyph(material: material, palette: palette, size: 44),
                const SizedBox(height: 4),
                Text(hut ? 'Timber hut' : 'Hide tent',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.ink)),
                Text(hut ? 'slow · strong' : 'fast · light',
                    style:
                        TextStyle(fontSize: 10, color: palette.inkSoft)),
                const SizedBox(height: 2),
                Icon(Icons.north, size: 14, color: palette.ember),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny volumetric-ish glyph for a material (a tent triangle vs a timber block).
class _MaterialGlyph extends StatelessWidget {
  const _MaterialGlyph({
    required this.material,
    required this.palette,
    this.size = 44,
  });

  final ShelterMaterial material;
  final EmberPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MaterialGlyphPainter(material: material, palette: palette),
      ),
    );
  }
}

class _MaterialGlyphPainter extends CustomPainter {
  _MaterialGlyphPainter({required this.material, required this.palette});

  final ShelterMaterial material;
  final EmberPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (material == ShelterMaterial.hideTent) {
      final Path tent = Path()
        ..moveTo(w * 0.5, h * 0.12)
        ..lineTo(w * 0.88, h * 0.86)
        ..lineTo(w * 0.12, h * 0.86)
        ..close();
      canvas.drawPath(tent, Paint()..color = palette.hide);
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.5, h * 0.12)
          ..lineTo(w * 0.88, h * 0.86)
          ..lineTo(w * 0.5, h * 0.86)
          ..close(),
        Paint()..color = palette.hideDark,
      );
      canvas.drawPath(
        tent,
        Paint()
          ..color = palette.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      // A stacked timber block (two logs).
      for (int i = 0; i < 2; i++) {
        final Rect r = Rect.fromLTWH(
            w * 0.16, h * (0.30 + i * 0.28), w * 0.68, h * 0.22);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[palette.wood, palette.woodDark],
            ).createShader(r),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..color = palette.outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MaterialGlyphPainter old) =>
      old.material != material;
}

/// A draggable ASSEMBLE part chip (frame / cover / anchor / smoke hole). Only the
/// current step is ever shown as a chip; a wrong-drop nudge pulses it.
class _PartChip extends StatelessWidget {
  const _PartChip({
    required this.step,
    required this.palette,
    required this.visible,
    this.nudge = false,
  });

  final AssembleStep step;
  final EmberPalette palette;
  final bool visible;
  final bool nudge;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 80, height: 80);
    final (IconData icon, String label) = switch (step) {
      AssembleStep.frame => (Icons.architecture, 'Frame'),
      AssembleStep.cover => (Icons.roofing, 'Cover'),
      AssembleStep.anchor => (Icons.anchor, 'Anchor'),
      AssembleStep.smokeHole => (Icons.air, 'Smoke'),
    };
    final Color accent = nudge ? palette.warning : palette.ember;
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: EmberUi.panel(palette, raised: true).copyWith(
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: accent, size: 30),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: palette.ink)),
        ],
      ),
    );
  }
}

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
