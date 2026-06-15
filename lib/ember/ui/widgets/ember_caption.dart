// Ember — ui/widgets/ember_caption.dart
//
// The shared CAPTION CHANNEL: ONE fixed-height line of guidance that frames every
// activity beat the SAME disciplined way (see the module brief's "Text
// discipline"). It is the single place a scene "speaks" — replacing walls of Elder
// prose, phase-title checklists, and %-bars-as-feedback with one calm line.
//
// THE RULES THIS ENCODES (from the quality bar):
//   * ONE line on screen at a time. Never a paragraph, never a checklist.
//   * Two registers, top to bottom:
//       1. a BOLD <=5-word IMPERATIVE — what to DO right now ("Spin the drill").
//       2. a SOFT meaning-line — the lesson, in plain words ("Friction makes
//          heat"). The concept is NAMED LAST, as a reward, once the player has
//          felt it (pass it as [concept]; it renders as the final, accented word).
//   * FADE-OUT -> swap -> FADE-IN. NEVER a cross-fade: the old line fades fully to
//     nothing, the text swaps while invisible, then the new line fades in. The two
//     lines never overlap mid-air (that reads as a glitch, not a beat change).
//   * FIXED HEIGHT (reserve [reservedHeight], ~96px): the stage above NEVER
//     reflows when the caption changes, so the felt object stays rock-steady.
//   * Silent beats are allowed: pass a null/blank [imperative] and the caption
//     fades to empty while holding its height (a quiet moment, not a layout jump).
//
// disableAnimations-aware: when MediaQuery.disableAnimations is set the swap is
// INSTANT (no fade) — captions are framing, not a same-frame causal update, so
// stilling them is correct. The height reservation is unaffected.
//
// Self-contained presentation: reads the [EmberPalette]/[EmberUi] tonal language
// only; no host-app import, no clock that feeds sim state, no new pub package.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../ember_theme.dart';

/// One disciplined caption line: a bold imperative + a soft meaning-line (concept
/// named last), fade-OUT -> swap -> fade-IN inside a fixed-height slot.
///
/// Drive it declaratively: rebuild it with new [imperative]/[meaning]/[concept]
/// values and it animates the swap itself. Identical content is a no-op (no
/// reflash). Pass a blank [imperative] for a silent beat (it fades to empty).
class EmberCaption extends StatefulWidget {
  const EmberCaption({
    super.key,
    required this.imperative,
    this.meaning = '',
    this.concept = '',
    this.palette = EmberPalette.dusk,
    this.reservedHeight = 96,
    this.tone = EmberCaptionTone.neutral,
    this.fadeMs = 180,
    this.imperativeMaxLines = 1,
    this.scrim = false,
  });

  /// The BOLD top line — what to DO. Keep it <=5 words, imperative. Blank => a
  /// silent caption (fades to empty, keeps height).
  final String imperative;

  /// The SOFT second line — the lesson in plain words. Optional.
  final String meaning;

  /// The concept NAMED LAST, rendered as the accented final word of the
  /// meaning-line (the reward). Optional; only shown when [meaning] is non-blank.
  final String concept;

  final EmberPalette palette;

  /// Reserved slot height so the stage above never reflows (~96px default).
  final double reservedHeight;

  /// Semantic colour of the imperative (e.g. warn on a failure nudge, win on
  /// success). Defaults to the neutral ember accent.
  final EmberCaptionTone tone;

  /// Half-duration of the fade-out / fade-in legs (each leg is [fadeMs]).
  final int fadeMs;

  /// Max lines for the bold IMPERATIVE. Defaults to 1 (the strict on-stage
  /// discipline). CARD beats sitting in a roomy modal pass 2 so a long headline
  /// wraps to a second line instead of ellipsis-clipping mid-phrase.
  final int imperativeMaxLines;

  /// Paint a soft readability scrim behind the line. ON for captions over bright
  /// activity backgrounds (the bottom interact caption), so the line stays legible
  /// even at the bottom of the fade-out -> swap -> fade-in dip. OFF inside cards
  /// (which already sit on an opaque panel).
  final bool scrim;

  @override
  State<EmberCaption> createState() => _EmberCaptionState();
}

/// The accent register of a caption's imperative.
enum EmberCaptionTone { neutral, warn, win }

class _EmberCaptionState extends State<EmberCaption> {
  // The content currently PAINTED (lags the widget props by one fade-out leg, so
  // the swap happens while invisible — never a cross-fade).
  String _shownImperative = '';
  String _shownMeaning = '';
  String _shownConcept = '';
  EmberCaptionTone _shownTone = EmberCaptionTone.neutral;

  double _opacity = 0.0;
  Timer? _swapTimer;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _shownImperative = widget.imperative;
    _shownMeaning = widget.meaning;
    _shownConcept = widget.concept;
    _shownTone = widget.tone;
    // First content (if any) fades in on the next frame.
    _opacity = widget.imperative.trim().isEmpty ? 0.0 : 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void didUpdateWidget(covariant EmberCaption old) {
    super.didUpdateWidget(old);
    final bool changed = old.imperative != widget.imperative ||
        old.meaning != widget.meaning ||
        old.concept != widget.concept ||
        old.tone != widget.tone;
    if (changed) _beginSwap();
  }

  /// FADE-OUT the old line, swap the painted content while invisible, FADE-IN the
  /// new. With reduced motion the content is swapped instantly (no fade legs).
  void _beginSwap() {
    _swapTimer?.cancel();

    if (_reduceMotion) {
      setState(() {
        _adoptIncoming();
        _opacity = _hasContent ? 1.0 : 0.0;
      });
      return;
    }

    // Leg 1: fade the current line fully out.
    setState(() => _opacity = 0.0);
    // Leg 2 (after the fade-out completes): swap content + fade the new line in.
    _swapTimer = Timer(Duration(milliseconds: widget.fadeMs), () {
      if (!mounted) return;
      setState(() {
        _adoptIncoming();
        _opacity = _hasContent ? 1.0 : 0.0;
      });
    });
  }

  void _adoptIncoming() {
    _shownImperative = widget.imperative;
    _shownMeaning = widget.meaning;
    _shownConcept = widget.concept;
    _shownTone = widget.tone;
  }

  bool get _hasContent => _shownImperative.trim().isNotEmpty;

  @override
  void dispose() {
    _swapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = widget.palette;
    final Color accent = switch (_shownTone) {
      EmberCaptionTone.neutral => p.ember,
      EmberCaptionTone.warn => p.warning,
      EmberCaptionTone.win => p.success,
    };

    return SizedBox(
      height: widget.reservedHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // A soft readability scrim behind the line. It does NOT fade with the
          // text swap, so the caption stays legible against bright activity
          // backgrounds THROUGHOUT the fade-out -> swap -> fade-in dip (the swap
          // momentarily drops the text to 0 opacity by design; without this scrim
          // the line reads as near-invisible mid-transition).
          if (widget.scrim)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: <Color>[
                        p.night.withValues(alpha: 0.34),
                        p.night.withValues(alpha: 0.0),
                      ],
                      stops: const <double>[0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration:
                  Duration(milliseconds: _reduceMotion ? 0 : widget.fadeMs),
              curve: Curves.easeOut,
              child: _hasContent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Register 1 — the bold imperative (what to do).
                        Text(
                          _shownImperative,
                          textAlign: TextAlign.center,
                          // On-stage interact captions stay a strict single line;
                          // roomy CARD beats (intro/science/reward) opt into 2 so a
                          // long headline WRAPS instead of clipping mid-phrase.
                          maxLines: widget.imperativeMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (_shownMeaning.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: EmberUi.gapS),
                          // Register 2 — the soft meaning-line, concept named LAST.
                          _meaningLine(p, accent),
                        ],
                      ],
                    )
                  // Silent beat: empty (but the SizedBox still reserves the height).
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// The soft meaning-line. When [concept] is set it is appended as the accented
  /// FINAL word (the reward): `Friction makes heat` with `heat` accented.
  Widget _meaningLine(EmberPalette p, Color accent) {
    final TextStyle soft = TextStyle(
      color: p.inkSoft,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
    if (_shownConcept.trim().isEmpty) {
      return Text(
        _shownMeaning,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: soft,
      );
    }
    return RichText(
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: soft,
        children: <TextSpan>[
          TextSpan(text: '$_shownMeaning '),
          TextSpan(
            text: _shownConcept,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
