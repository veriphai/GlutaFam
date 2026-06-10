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
import 'collectible_card_view.dart';
import 'collectible_models.dart';
import 'collectible_store.dart';

class CollectibleEarnOverlay extends StatefulWidget {
  const CollectibleEarnOverlay({
    super.key,
    required this.card,
    required this.onDone,
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

  /// Called after the kid adds the card to their deck (persisted by then).
  final VoidCallback onDone;

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

  Future<void> _addToDeck() async {
    if (_added) return;
    _added = true;
    HapticFeedback.selectionClick();
    await CollectibleStore.add(widget.card.id);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Image-art cards are square + include their own glow margin, so give them a
    // bit more width and a square height; painted cards stay 5:7.
    final hasImage = widget.card.hasImageFaces;
    final cardW = (media.size.width * (hasImage ? 0.9 : 0.78)).clamp(240.0, hasImage ? 400.0 : 350.0);
    final cardH = hasImage ? cardW : cardW * 7 / 5;
    final accent = widget.card.section.accent;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Near-opaque scrim so the busy crank scene can't bleed through.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    const Color(0xFF10183A).withValues(alpha: 0.97),
                    const Color(0xFF05070F).withValues(alpha: 0.99),
                  ],
                ),
              ),
            ),
          ),
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
                      // Voltix + tailed message box (top).
                      AnimatedOpacity(
                        opacity: settled ? 1 : 0,
                        duration: const Duration(milliseconds: 320),
                        child: _VoltixMessage(
                            eyebrow: widget.eyebrow,
                            brag: widget.brag,
                            mascot: widget.mascot,
                            showMascot: widget.showMascot),
                      ),
                      // Card + glow-burst, centred in the remaining space.
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: cardW * 1.7,
                                height: cardH + 24,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(
                                      opacity: (1 - burst) * 0.9,
                                      child: Container(
                                        width: cardW * (0.7 + burst * 1.1),
                                        height: cardW * (0.7 + burst * 1.1),
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
                                          width: cardW,
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
                        ),
                      ),
                      // "Add to your deck" — pinned at the bottom.
                      AnimatedOpacity(
                        opacity: settled ? 1 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: _addButton(),
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

  Widget _addButton() {
    return PressableScale(
      onTap: _addToDeck,
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
            Text('Add to your deck',
                style: CareerText.cta.copyWith(color: CareerColors.onLight, fontSize: 14.5)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: CareerColors.onLight),
          ],
        ),
      ),
    );
  }
}

/// Voltix (celebrating) + a tailed speech bubble — the same message-box language
/// as the activity. The "NEW CARD" eyebrow + brag line live inside the bubble.
class _VoltixMessage extends StatelessWidget {
  const _VoltixMessage({required this.eyebrow, required this.brag, this.mascot, this.showMascot = true});

  final String eyebrow;
  final String brag;
  final Widget? mascot;
  final bool showMascot;

  @override
  Widget build(BuildContext context) {
    // No-mascot: a plain centred banner (no avatar, no speech tail).
    if (!showMascot) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1E3C).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CareerColors.gold.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              eyebrow,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: const Color(0xFFFFD970),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              brag,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Floaty(
          amplitude: 3,
          child: mascot ??
              Image.asset(
                'assets/images/voltix/voltix_celebrating.png',
                height: 92,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 56),
              ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: CustomPaint(
            painter: _TailBubblePainter(
              fill: const Color(0xFF0E1E3C).withValues(alpha: 0.95),
              border: CareerColors.gold.withValues(alpha: 0.7),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 11, 14, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: const Color(0xFFFFD970),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    brag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark + gold speech bubble with a left tail pointing at Voltix — one
/// continuous outline (tail folded into the left edge) so the border has no seam.
class _TailBubblePainter extends CustomPainter {
  _TailBubblePainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  static const double _tail = 12;
  static const double _tailHalf = 9;
  static const double _r = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h * 0.5;
    final p = Path()
      ..moveTo(_tail + _r, 0)
      ..lineTo(w - _r, 0)
      ..arcToPoint(Offset(w, _r), radius: const Radius.circular(_r))
      ..lineTo(w, h - _r)
      ..arcToPoint(Offset(w - _r, h), radius: const Radius.circular(_r))
      ..lineTo(_tail + _r, h)
      ..arcToPoint(Offset(_tail, h - _r), radius: const Radius.circular(_r))
      ..lineTo(_tail, cy + _tailHalf)
      ..lineTo(0, cy)
      ..lineTo(_tail, cy - _tailHalf)
      ..lineTo(_tail, _r)
      ..arcToPoint(Offset(_tail + _r, 0), radius: const Radius.circular(_r))
      ..close();
    canvas.drawShadow(p, Colors.black.withValues(alpha: 0.5), 5, false);
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_TailBubblePainter old) => old.fill != fill || old.border != border;
}
