// The earn moment — ONE orchestrated hero animation (per the spec): the card
// scales up from a point with a soft radial glow-burst, settles with a slight
// overshoot, a medium haptic fires, and an "Add to your deck" CTA appears at the
// bottom. Voltix accompanies in voltix_celebrating with a proper tailed message
// box (the same speech-bubble language as the activity). ~1.2–1.8s, satisfying,
// not a slot machine. Reduced motion → a simple scale-and-fade.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/career/careerCommon.dart';
import '../home/career/careerTheme.dart';
import '../missions/episode_board/activity_background.dart';
import 'collectible_card_view.dart';
import 'collectible_models.dart';
import 'collectible_store.dart';

class CollectibleEarnOverlay extends StatefulWidget {
  const CollectibleEarnOverlay({
    super.key,
    required this.card,
    required this.onDone,
    this.onReplay,
    this.eyebrow = 'NEW CARD',
    this.brag = 'Whoa — your first card. A real law of the universe.',
    this.mascot,
    this.showMascot = true,
  });

  final CollectibleCard card;

  /// The mono eyebrow + the one-line brag the companion says in the bubble (his
  /// `cardEarnLine` for this beat). Defaults to the Prologue/Card-01 copy.
  final String eyebrow;
  final String brag;

  /// The companion shown beside the bubble. Null → the default Voltix sprite;
  /// other modules (de-extinction → Helix) pass their own avatar.
  final Widget? mascot;

  /// When false, the card-earn message shows NO companion avatar (just a plain
  /// centred banner) — for activities with no mascot (e.g. Trace It Back).
  final bool showMascot;

  /// Called when the kid taps the primary button (card persisted to the deck by
  /// then). For lesson activities this pops the activity → the runner advances
  /// to the next beat. The collectible screen is the LAST screen.
  final VoidCallback onDone;

  /// When non-null, a "Replay" button appears ABOVE the primary button and the
  /// primary is labelled "Continue" (instead of "Add to your deck"). Tapping
  /// Replay persists the card, then redoes the activity from scratch.
  final VoidCallback? onReplay;

  @override
  State<CollectibleEarnOverlay> createState() => _CollectibleEarnOverlayState();
}

class _CollectibleEarnOverlayState extends State<CollectibleEarnOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  bool _hapticFired = false;
  bool _added = false;

  bool get _reduced => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _entry.addListener(() {
      if (!_hapticFired && _entry.value >= 0.55) {
        _hapticFired = true;
        HapticFeedback.mediumImpact();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  /// Persist the earned card to the deck (idempotent). Both Continue and Replay
  /// do this first, so the card is always saved once the kid leaves this screen.
  Future<void> _persist() async {
    if (_added) return;
    _added = true;
    await CollectibleStore.add(widget.card.id);
  }

  Future<void> _continue() async {
    HapticFeedback.selectionClick();
    await _persist();
    widget.onDone();
  }

  Future<void> _replay() async {
    HapticFeedback.selectionClick();
    await _persist();
    widget.onReplay?.call();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final hasImage = widget.card.hasImageFaces;
    final avail = media.size.width - 32; // content width inside the 16px padding
    // WIDTH budget for the card. Image-art cards are SQUARE + carry their own glow
    // margin, so let them fill almost the whole width (the old 400 cap left big
    // side gaps on wide screens). The FINAL size is fit to the available height in
    // the LayoutBuilder below, so the square card grows as large as fits without
    // pushing the brag/buttons off-screen. Painted cards keep their 5:7 sizing.
    final cardW = hasImage
        ? (avail * 0.98).clamp(260.0, 640.0)
        : (media.size.width * 0.78).clamp(240.0, 350.0);
    final accent = widget.card.section.accent;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // The shared dossier background (same as the activities), shown at FULL —
          // the art is already dark by design, so NO scrim/tint over it. Opaque, so
          // it also hides the busy activity scene behind.
          const Positioned.fill(child: ActivityDossierBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AnimatedBuilder(
                animation: _entry,
                builder: (context, _) {
                  final e = _reduced
                      ? 1.0
                      : Curves.easeOutBack.transform(_entry.value.clamp(0.0, 1.0));
                  final burst = Curves.easeOut.transform(_entry.value.clamp(0.0, 1.0));
                  final settled = _entry.value > 0.85 || _reduced;
                  return Column(
                    children: [
                      // Card + glow-burst, sized to FILL the free space: a square
                      // image card fits to the smaller of the width budget and the
                      // column's available height (reserving room for the flip hint),
                      // so it's as large as fits — no more big side gaps.
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            // Image cards are PORTRAIT (kImageCardAspect): width w, height
                            // w / aspect. Fill the free space — bounded by the width budget
                            // OR the column height (reserve for the flip hint + box pad),
                            // whichever binds — so it's as large as fits.
                            final hRoom = c.maxHeight - 66;
                            final double w;
                            if (hasImage) {
                              final byHeight = hRoom * kImageCardAspect; // width keeping height ≤ hRoom
                              w = (cardW < byHeight ? cardW : byHeight).clamp(260.0, double.infinity);
                            } else {
                              w = cardW;
                            }
                            final h = hasImage ? w / kImageCardAspect : w * 7 / 5;
                            final glowBox = (w * 1.4).clamp(w, avail); // never wider than the screen
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: glowBox,
                                    height: h + 24,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Opacity(
                                          opacity: (1 - burst) * 0.9,
                                          child: Container(
                                            width: w * (0.7 + burst * 1.1),
                                            height: w * (0.7 + burst * 1.1),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  _glowColor(accent).withValues(alpha: 0.6),
                                                  _glowColor(accent).withValues(alpha: 0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Opacity(
                                          opacity: _reduced ? _entry.value : burst,
                                          child: Transform.scale(
                                            scale: _reduced ? (0.9 + 0.1 * _entry.value) : e,
                                            child: CollectibleCardView(
                                              card: widget.card,
                                              width: w,
                                              interactive: settled,
                                              tossOnEnter: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  AnimatedOpacity(
                                    opacity: settled ? 1 : 0,
                                    duration: const Duration(milliseconds: 280),
                                    child: _flipHint(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Replay (above) + Continue / Add-to-deck — pinned bottom.
                      AnimatedOpacity(
                        opacity: settled ? 1 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: _bottomButtons(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _glowColor(Color accent) =>
      widget.card.section.isPrismatic ? const Color(0xFFBFCBEA) : accent;

  Widget _flipHint() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app_rounded, size: 14, color: Colors.white.withValues(alpha: 0.55)),
        const SizedBox(width: 5),
        Text(
          'Tap the card to flip it',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _bottomButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Replay sits ABOVE Continue — secondary, so it never competes with the
        // primary action. Only shown when the host wired a replay handler.
        if (widget.onReplay != null) ...[
          _replayButton(),
          const SizedBox(height: 10),
        ],
        _continueButton(),
      ],
    );
  }

  Widget _continueButton() {
    // "Continue" in the new lesson flow (Replay wired); "Add to your deck" in
    // the legacy single-button flow (satellite / CER), so those are untouched.
    final label = widget.onReplay != null ? 'Continue' : 'Add to your deck';
    return PressableScale(
      onTap: _continue,
      child: Container(
        height: 54,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // Calm gold — restrained, not neon (spec §3).
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5C451), Color(0xFFD9A43B)],
          ),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: CareerText.cta.copyWith(color: CareerColors.onLight, fontSize: 14.5)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: CareerColors.onLight),
          ],
        ),
      ),
    );
  }

  Widget _replayButton() {
    return PressableScale(
      onTap: _replay,
      child: Container(
        height: 50,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 19, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 7),
            Text('Replay',
                style: CareerText.cta.copyWith(
                    color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
