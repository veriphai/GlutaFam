// Ember — activity/activity_phase_overlay.dart
//
// The shared FLUTTER chrome that frames the 5-beat arc on top of the Flame
// [ActivityScene]. It listens to the [BeatController] and renders, per beat:
//   * setup    — LIGHT framing: the Elder briefly, ONE caption (the prompt as a
//                bold imperative + the myth as the soft meaning-line), a single
//                "Let's find out" CTA that begins the interaction;
//   * interact — the Flame stage owns the screen; the leaf's own
//                buildInteractOverlay is mounted FULL-SCREEN (Positioned.fill) over
//                it so the leaf can lay a transparent full-area gesture surface that
//                drives its on-stage props directly, plus its own bottom
//                EmberCaption + small controls — or, if the leaf has none, a thin
//                bottom hint caption + retry;
//   * discover — LIGHT: the "ohh!" caption + a Show Me Why CTA;
//   * itClicks — LIGHT: the science as ONE caption (concept named last) + Continue;
//   * apply    — the success flourish (stars) + the unlock summary + Done.
//
// PHILOSOPHY (Phase-1 rework): KILL the walls of Elder prose + phase-title
// checklists. Every non-interact beat is now a brief Elder, ONE EmberCaption line,
// and ONE call-to-action — the same disciplined caption channel the Phase-2
// activity redesigns will drive from inside the interact beat. The declarative
// contract fields (SetupCopy / ClickCopy) are UNCHANGED — they are simply mapped
// into the two-register caption form here.
//
// It is DATA-DRIVEN from [EmberActivity] (SetupCopy / ClickCopy / SuccessCriteria
// / unlocks) so every leaf gets the same polished framing for free. It NEVER
// touches the world — completion is reported by the scene's finishWithResult,
// which the host wires; this overlay only advances beats + calls scene.finish().

import 'package:flutter/material.dart';

import '../art/ember_palette.dart';
import '../contracts/codex_entry.dart';
import '../core/enums.dart';
import '../ui/ember_theme.dart';
import '../ui/widgets/ember_button.dart';
import '../ui/widgets/ember_caption.dart';
import 'activity_contract.dart';
import 'activity_scene.dart';
import 'apply_effect.dart';
import 'beat_controller.dart';

/// The Flutter overlay that frames an [ActivityScene]'s 5-beat arc.
class ActivityPhaseOverlay extends StatefulWidget {
  const ActivityPhaseOverlay({
    super.key,
    required this.scene,
    this.palette = EmberPalette.dusk,
  });

  /// The Flame scene this overlay frames (its controller + activity are read).
  final ActivityScene scene;
  final EmberPalette palette;

  @override
  State<ActivityPhaseOverlay> createState() => _ActivityPhaseOverlayState();
}

class _ActivityPhaseOverlayState extends State<ActivityPhaseOverlay> {
  BeatController get _c => widget.scene.controller;
  EmberActivity get _a => widget.scene.activity;
  EmberPalette get _p => widget.palette;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onBeat);
  }

  @override
  void dispose() {
    _c.removeListener(_onBeat);
    super.dispose();
  }

  void _onBeat() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // During the interact beat the Flame stage owns the screen; show only the
    // leaf's own chrome (or a thin hint caption). Every other beat shows a LIGHT
    // framing card — a brief Elder, one caption, one CTA.
    return switch (_c.beat) {
      ActivityBeat.setup => _scrim(child: _setupCard()),
      ActivityBeat.interact => _interactBeat(context),
      ActivityBeat.discover => _scrim(child: _discoverCard()),
      ActivityBeat.itClicks => _scrim(child: _clicksCard()),
      ActivityBeat.apply => _scrim(child: _applyCard()),
    };
  }

  // ===========================================================================
  // Shared chrome
  // ===========================================================================

  Widget _scrim({required Widget child}) {
    // A warm dark-amber -> night gradient (instead of a flat dead grey) so the
    // framing cards sit over the cold-night-by-the-fire mood the Elder describes,
    // letting the warm stage backdrop glow through at the edges.
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              _p.night.withValues(alpha: 0.62),
              Color.lerp(_p.night, _p.emberDeep, 0.35)!.withValues(alpha: 0.52),
              _p.emberDeep.withValues(alpha: 0.40),
            ],
            stops: const <double>[0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EmberUi.gapL),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(EmberUi.gapL),
      decoration: EmberUi.panel(_p, raised: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// A small firelit Elder avatar + an optional one-phrase tag beside it. This is
  /// now the WHOLE Elder presence on a framing beat — a glance, not a speech. The
  /// teaching itself lives in the [EmberCaption] below it.
  Widget _elderBadge(String tag) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            // A warm firelit disc behind the elder silhouette.
            gradient: RadialGradient(
              colors: <Color>[_p.emberBright, _p.ember],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: _p.outline, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _ElderSilhouettePainter(_p.outline),
          ),
        ),
        if (tag.isNotEmpty) ...<Widget>[
          const SizedBox(width: EmberUi.gapS),
          Flexible(
            child: Text(
              tag,
              style: TextStyle(
                color: _p.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The first imperative-sized clause of [text] (<=[maxWords] words), with any
  /// trailing punctuation kept — used to derive a bold caption line from contract
  /// prose without changing the data contract.
  String _shortImperative(String text, {int maxWords = 5}) {
    final String t = text.trim();
    if (t.isEmpty) return '';
    // Take the first sentence.
    final String firstSentence = t.split(RegExp(r'(?<=[.!?])\s')).first.trim();
    final List<String> words = firstSentence.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return firstSentence;
    // Prefer cutting on a CLAUSE boundary (a comma) within reach, so the headline
    // ends on a complete phrase ("Read the ground, raise the walls") rather than
    // a dangling preposition ("Read the ground, raise the…").
    for (int i = maxWords; i >= 2; i--) {
      if (words[i - 1].endsWith(',')) {
        return words.take(i).join(' ').replaceAll(RegExp(r',$'), '');
      }
    }
    return '${words.take(maxWords).join(' ')}…';
  }

  // ===========================================================================
  // Beat: Setup — LIGHT framing
  // ===========================================================================

  Widget _setupCard() {
    final SetupCopy s = _a.setupCopy;
    // The prompt is the imperative (what we're about to do); the myth (or the
    // Elder's framing) is the soft meaning-line. ONE caption, not a wall.
    final String meaning = s.mythLine.isNotEmpty ? s.mythLine : s.elderLine;
    return _card(
      children: <Widget>[
        Center(child: _elderBadge(_a.title.toUpperCase())),
        EmberCaption(
          // Cut on a clause boundary and allow two lines in this roomy card, so a
          // longer prompt WRAPS cleanly instead of ellipsis-clipping mid-phrase.
          imperative: _shortImperative(s.prompt, maxWords: 7),
          meaning: meaning,
          palette: _p,
          reservedHeight: 124,
          imperativeMaxLines: 2,
        ),
        if (s.hintLine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: EmberUi.gap),
            child: Text(
              s.hintLine,
              textAlign: TextAlign.center,
              style: TextStyle(color: _p.inkSoft, fontSize: 12),
            ),
          ),
        EmberButton(
          label: "Let's find out",
          icon: Icons.science_outlined,
          palette: _p,
          expand: true,
          onPressed: () => widget.scene.beginInteract(),
        ),
      ],
    );
  }

  // ===========================================================================
  // Beat: Interact
  // ===========================================================================

  /// During interact: if the leaf supplies bespoke Flutter chrome
  /// (buildInteractOverlay), mount it FULL-SCREEN over the Flame stage so the leaf
  /// can lay a transparent full-area gesture surface that maps finger drags onto
  /// its on-stage Flame props (the Phase-2 "input happens ON the prop" quality
  /// bar) — and, within that same full-area layer, anchor its own bottom
  /// EmberCaption + any small non-physical controls + retry. The leaf OWNS its
  /// layout; the host only guarantees it the whole screen (world pan/zoom is off
  /// during an activity — EmberGame.onScaleUpdate early-returns when inActivity —
  /// so a full-area drag layer never fights the map). Leaves that want the old
  /// bottom card can wrap themselves in Align(bottomCenter) + SafeArea.
  ///
  /// If the leaf supplies nothing, fall back to the thin bottom hint strip for
  /// activities whose interaction lives entirely in the Flame stage's own props.
  Widget _interactBeat(BuildContext context) {
    final Widget? leaf = widget.scene.buildInteractOverlay(context);
    if (leaf == null) return _interactStrip();
    return Positioned.fill(child: leaf);
  }

  /// Fallback interact chrome for leaves with no bespoke overlay: a single caption
  /// surfaces the active failure hint (warn tone), and a retry CTA appears once
  /// the attempt is spent. This is the SAME caption channel as everywhere else.
  Widget _interactStrip() {
    final String? hint = _c.activeHint;
    final bool outOfTries = _c.inputsUsed >= _a.interactionRules.maxInputs &&
        _a.interactionRules.maxInputs > 0;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EmberUi.gap),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EmberUi.gapL,
                  vertical: EmberUi.gapS,
                ),
                decoration: EmberUi.panel(
                  _p,
                  raised: true,
                  fill: _p.surface,
                  border: hint == null ? null : _p.warning,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    EmberCaption(
                      imperative: hint == null
                          ? ''
                          : _shortImperative(hint, maxWords: 6),
                      meaning: hint == null
                          ? ''
                          : (hint.length > 40 ? hint : ''),
                      tone: EmberCaptionTone.warn,
                      palette: _p,
                      reservedHeight: 64,
                    ),
                    if (outOfTries)
                      EmberButton(
                        label: 'Try Again',
                        style: EmberButtonStyle.secondary,
                        palette: _p,
                        onPressed: () => widget.scene.retry(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Beat: Discover — LIGHT framing
  // ===========================================================================

  Widget _discoverCard() {
    final ClickCopy c = _a.clickCopy;
    return _card(
      children: <Widget>[
        Center(
          child: Icon(Icons.auto_awesome, color: _p.ember, size: 30),
        ),
        EmberCaption(
          imperative: 'Ohh!',
          meaning: c.revelation,
          tone: EmberCaptionTone.win,
          palette: _p,
          reservedHeight: 104,
        ),
        EmberButton(
          label: 'Show me why',
          icon: Icons.visibility_outlined,
          palette: _p,
          expand: true,
          onPressed: () => _c.revealClick(),
        ),
      ],
    );
  }

  // ===========================================================================
  // Beat: ItClicks (the science) — LIGHT framing
  // ===========================================================================

  Widget _clicksCard() {
    final ClickCopy c = _a.clickCopy;
    final ModelUpgrade? up = _a.modelUpgrade;
    return _card(
      children: <Widget>[
        Center(
          child: Icon(Icons.menu_book_outlined, color: _p.ember, size: 28),
        ),
        // The science as ONE caption: a short headline imperative + the
        // explanation as the soft meaning-line.
        EmberCaption(
          imperative: 'Here is why',
          meaning: c.science,
          palette: _p,
          reservedHeight: 112,
        ),
        if (up != null) ...<Widget>[
          _beforeAfter(up),
          const SizedBox(height: EmberUi.gap),
        ],
        EmberButton(
          label: 'Use what I learned',
          icon: Icons.check_circle_outline,
          palette: _p,
          expand: true,
          onPressed: () => _c.proceedToApply(),
        ),
      ],
    );
  }

  /// The myth->evidence flip, kept compact (one warn row + one win row).
  Widget _beforeAfter(ModelUpgrade up) {
    return Container(
      padding: const EdgeInsets.all(EmberUi.gap),
      decoration: EmberUi.chip(_p, fill: _p.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _flipRow(Icons.history_toggle_off, up.mythBelief, _p.inkSoft),
          const SizedBox(height: EmberUi.gapS),
          _flipRow(Icons.verified_outlined, up.evidenceBelief, _p.success),
        ],
      ),
    );
  }

  Widget _flipRow(IconData icon, String body, Color tint) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: tint, size: 18),
        const SizedBox(width: EmberUi.gapS),
        Expanded(
          child: Text(
            body,
            style: TextStyle(
              color: _p.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Beat: Apply (success flourish + unlock summary) — KEPT (the reward screen)
  // ===========================================================================

  Widget _applyCard() {
    final ClickCopy c = _a.clickCopy;
    final int stars = _c.qualityStars;
    final List<String> unlockLabels = _unlockLabels();
    return _card(
      children: <Widget>[
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: i < stars ? _p.emberBright : _p.inkSoft,
                    size: 40,
                  ),
                ),
            ],
          ),
        ),
        EmberCaption(
          imperative: _c.succeeded ? 'You did it!' : 'Good try',
          meaning: c.celebrationLine,
          tone: EmberCaptionTone.win,
          palette: _p,
          reservedHeight: 88,
        ),
        if (unlockLabels.isNotEmpty) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(EmberUi.gap),
            decoration: EmberUi.chip(_p, fill: _p.surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Unlocked',
                  style: TextStyle(
                    color: _p.ember,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: EmberUi.gapS),
                for (final String label in unlockLabels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.add_circle_outline,
                            color: _p.success, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: _p.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: EmberUi.gap),
        ],
        EmberButton(
          label: 'Back to my village',
          icon: Icons.home_outlined,
          palette: _p,
          expand: true,
          onPressed: () => widget.scene.finish(),
        ),
      ],
    );
  }

  /// Human-readable labels for the effects this activity grants (apply summary).
  List<String> _unlockLabels() {
    final List<String> out = <String>[];
    for (final ApplyEffect e in _a.unlocks) {
      switch (e) {
        case UnlockPlaceable():
          out.add('Build: ${_placeableLabel(e.type)}');
        case RaisePopulationCap():
          out.add('+${e.by} villagers');
        case GrantResources():
          out.add('Resources granted');
        case EnableActivity():
          out.add('New challenge available');
        case SetKnowledgeFlag():
        case MarkConceptDone():
        case GrantCodexEntry():
        case UpgradeModel():
        case SetWorldFlag():
          break; // not player-facing in this summary.
      }
    }
    if (_a.codexEntryIds.isNotEmpty) {
      out.add('Codex: ${_a.codexEntryIds.length} new ${_a.codexEntryIds.length == 1 ? 'page' : 'pages'}');
    }
    return out;
  }

  String _placeableLabel(PlaceableType t) {
    return switch (t) {
      PlaceableType.hearth => 'Hearth',
      PlaceableType.torch => 'Torch',
      PlaceableType.brazier => 'Brazier',
      PlaceableType.cookingFire => 'Cooking Fire',
      PlaceableType.knappingStation => 'Knapping Station',
      PlaceableType.toolRack => 'Tool Rack',
      PlaceableType.leanTo => 'Lean-to',
      PlaceableType.hideTent => 'Hide Tent',
      PlaceableType.hut => 'Hut',
      PlaceableType.palisade => 'Palisade',
    };
  }
}

/// A simple Stone-Age ELDER silhouette (hooded head + shoulders + a soft beard)
/// painted in [_ink] over the warm firelit avatar disc — a warmer, in-world motif
/// than a generic person glyph. Vector-only, no font/asset dependency.
class _ElderSilhouettePainter extends CustomPainter {
  const _ElderSilhouettePainter(this._ink);

  final Color _ink;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint p = Paint()..color = _ink.withValues(alpha: 0.92);

    // Shoulders / robe (a wide rounded mound rising from the bottom).
    final Path robe = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(w * 0.16, h * 0.66, w * 0.5, h * 0.62)
      ..quadraticBezierTo(w * 0.84, h * 0.66, w * 0.88, h)
      ..close();
    canvas.drawPath(robe, p);

    // Hooded head (a circle tucked under a hood arc).
    canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.17, p);
    final Path hood = Path()
      ..moveTo(w * 0.27, h * 0.46)
      ..quadraticBezierTo(w * 0.5, h * 0.12, w * 0.73, h * 0.46)
      ..quadraticBezierTo(w * 0.5, h * 0.30, w * 0.27, h * 0.46)
      ..close();
    canvas.drawPath(hood, p);

    // A soft beard hint under the chin (a small tapered triangle).
    final Path beard = Path()
      ..moveTo(w * 0.40, h * 0.52)
      ..quadraticBezierTo(w * 0.5, h * 0.70, w * 0.60, h * 0.52)
      ..close();
    canvas.drawPath(beard, p);
  }

  @override
  bool shouldRepaint(covariant _ElderSilhouettePainter oldDelegate) =>
      oldDelegate._ink != _ink;
}
