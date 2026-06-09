// The earn moment — ONE orchestrated hero animation (per the spec): the card
// scales up from a point with a soft radial glow-burst, settles with a slight
// overshoot, a medium haptic fires, and "Tap to add to your deck" appears.
// Voltix accompanies in voltix_celebrating (the one place that rare mood earns
// its keep). ~1.2–1.8s, satisfying, not a slot machine. Reduced motion → a
// simple scale-and-fade.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/career/careerCommon.dart';
import '../home/career/careerTheme.dart';
import 'collectible_card_view.dart';
import 'collectible_models.dart';
import 'collectible_store.dart';

class CollectibleEarnOverlay extends StatefulWidget {
  const CollectibleEarnOverlay({super.key, required this.card, required this.onDone});

  final CollectibleCard card;

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
      // Medium haptic at the settle (the "charge lands").
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
    final cardW = (media.size.width * 0.66).clamp(220.0, 300.0);
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
                  colors: [const Color(0xFF10183A).withValues(alpha: 0.96), const Color(0xFF05070F).withValues(alpha: 0.985)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _entry,
              builder: (context, _) {
                final e = _reduced ? 1.0 : Curves.easeOutBack.transform(_entry.value.clamp(0.0, 1.0));
                final burst = Curves.easeOut.transform(_entry.value.clamp(0.0, 1.0));
                final settled = _entry.value > 0.85 || _reduced;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _voltixHeader(settled),
                      SizedBox(height: media.size.height * 0.018),
                      // Card + glow-burst.
                      SizedBox(
                        width: cardW * 1.6,
                        height: cardW * 7 / 5 + 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Radial glow-burst behind the card.
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: media.size.height * 0.01),
                      AnimatedOpacity(
                        opacity: settled ? 1 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: _prompt(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _glowColor(Color accent) =>
      widget.card.section.isPrismatic ? const Color(0xFFBFCBEA) : accent;

  Widget _voltixHeader(bool show) {
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Floaty(
            amplitude: 3,
            child: Image.asset(
              'assets/images/voltix/voltix_celebrating.png',
              height: 78,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEW CARD',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                  color: const Color(0xFFFFD970),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'You earned a law of the universe.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 14, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text(
              'Tap the card to flip it',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        PressableScale(
          onTap: _addToDeck,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: CareerGradients.gold,
              borderRadius: BorderRadius.circular(CareerRadii.pill),
              boxShadow: [
                BoxShadow(
                  color: CareerColors.gold.withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add to your deck',
                    style: CareerText.cta.copyWith(color: CareerColors.onLight)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 19, color: CareerColors.onLight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
