// The collectible card itself — a 5:7 flippable specimen. Front = the trophy
// (motif, names, the law); back = the reward for flipping (tie-back + reach +
// recurring-idea link). Layered for physical depth: guilloché frame → gold
// hairline → body → inset panels, with a subtle current-sheen on top.
//
// Tap to flip (3D rotateY; the back is pre-mirrored). Reduced motion is
// honoured: the ambient sheen/drift stops and the flip becomes a crossfade.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'collectible_models.dart';
import 'collectible_painters.dart';

const Color _ink800 = Color(0xFF161D3A); // card body
const Color _paperMist = Color(0xFFE8ECF7); // body text
const Color _gold = Color(0xFFF5C451);
const Color _goldBright = Color(0xFFFFD970);

class CollectibleCardView extends StatefulWidget {
  const CollectibleCardView({
    super.key,
    required this.card,
    required this.width,
    this.interactive = true,
    this.animate = true,
  });

  final CollectibleCard card;
  final double width;
  final bool interactive; // tap to flip
  final bool animate; // ambient sheen + prismatic drift

  @override
  State<CollectibleCardView> createState() => _CollectibleCardViewState();
}

class _CollectibleCardViewState extends State<CollectibleCardView>
    with TickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 7));

  bool get _reducedMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate && !_reducedMotion && !_drift.isAnimating) {
      _drift.repeat();
    } else if ((!widget.animate || _reducedMotion) && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _drift.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (!widget.interactive) return;
    if (_flip.value < 0.5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 7 / 5;
    final radius = w * 0.06;
    final band = w * 0.066;

    return GestureDetector(
      onTap: _toggleFlip,
      child: SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flip, _drift]),
          builder: (context, _) {
            final phase = _drift.value * 2 * math.pi;
            final angle = _flip.value * math.pi;
            final showBack = angle > math.pi / 2;

            Widget face = showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _Face(
                      card: widget.card,
                      size: Size(w, h),
                      radius: radius,
                      band: band,
                      phase: phase,
                      sheen: widget.animate && !_reducedMotion ? _drift.value : null,
                      front: false,
                    ),
                  )
                : _Face(
                    card: widget.card,
                    size: Size(w, h),
                    radius: radius,
                    band: band,
                    phase: phase,
                    sheen: widget.animate && !_reducedMotion ? _drift.value : null,
                    front: true,
                  );

            // Reduced motion → crossfade instead of a 3D flip.
            if (_reducedMotion) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(key: ValueKey(showBack), child: face),
              );
            }
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: face,
            );
          },
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.card,
    required this.size,
    required this.radius,
    required this.band,
    required this.phase,
    required this.sheen,
    required this.front,
  });

  final CollectibleCard card;
  final Size size;
  final double radius;
  final double band;
  final double phase;
  final double? sheen; // 0..1 sweep progress, null = no sheen
  final bool front;

  @override
  Widget build(BuildContext context) {
    final accent = card.section.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          const BoxShadow(color: Color(0xCC05070F), blurRadius: 10, offset: Offset(0, 6)),
          BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 14)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Card stock — body gradient + top inner highlight.
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A2348), _ink800],
                  ),
                ),
              ),
            ),
            // The signature guilloché frame + gold hairline.
            Positioned.fill(
              child: CustomPaint(
                painter: GuillocheFramePainter(
                  section: card.section,
                  radius: radius,
                  band: band,
                  phase: phase,
                ),
              ),
            ),
            // Content inside the frame band.
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(band + size.width * 0.02),
                child: front ? _front(accent) : _back(accent),
              ),
            ),
            // Current-flow sheen across the whole face.
            if (sheen != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SheenPainter(sheen!)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── FRONT ────────────────────────────────────────────────────────────
  Widget _front(Color accent) {
    final w = size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Art window (~upper 45%) — the motif on a raised panel.
        Expanded(
          flex: 45,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0E1430),
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: CustomPaint(
              painter: EnergyLoopPainter(section: card.section, phase: phase),
            ),
          ),
        ),
        SizedBox(height: w * 0.035),
        // Nameplate.
        Text(
          card.cardName,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: w * 0.105,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          maxLines: 2,
        ),
        SizedBox(height: w * 0.012),
        Text(
          card.realName,
          style: GoogleFonts.ibmPlexMono(
            fontSize: w * 0.039,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.6,
            color: _gold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: w * 0.04),
        // The law (headline) + kicker.
        Text(
          card.law,
          style: GoogleFonts.plusJakartaSans(
            fontSize: w * 0.058,
            fontWeight: FontWeight.w700,
            height: 1.18,
            color: _paperMist,
          ),
        ),
        SizedBox(height: w * 0.014),
        Text(
          card.kicker,
          style: GoogleFonts.plusJakartaSans(
            fontSize: w * 0.044,
            fontWeight: FontWeight.w500,
            color: _paperMist.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        _footer(accent),
      ],
    );
  }

  Widget _footer(Color accent) {
    final w = size.width;
    final monoStyle = GoogleFonts.ibmPlexMono(
      fontSize: w * 0.034,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      color: _paperMist.withValues(alpha: 0.8),
    );
    return Row(
      children: [
        Text(card.section.label, style: monoStyle),
        SizedBox(width: w * 0.025),
        Text(card.numberLabel, style: monoStyle.copyWith(color: _gold)),
        const Spacer(),
        _rarityPip(card.rarity),
        SizedBox(width: w * 0.025),
        Icon(card.section.icon, size: w * 0.052, color: accent.withValues(alpha: 0.9)),
      ],
    );
  }

  Widget _rarityPip(CardRarity rarity) {
    final w = size.width;
    final s = w * 0.05;
    // Foundational = a filled prismatic diamond (the crown); core = a hollow pip.
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: _RarityPipPainter(rarity)),
    );
  }

  // ── BACK ─────────────────────────────────────────────────────────────
  Widget _back(Color accent) {
    final w = size.width;
    return Stack(
      children: [
        // Faint circuit watermark.
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(painter: EnergyLoopPainter(section: card.section, phase: phase)),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.realName,
              style: GoogleFonts.ibmPlexMono(
                fontSize: w * 0.036,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: _gold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: w * 0.045),
            Text(
              card.tieBack,
              style: GoogleFonts.plusJakartaSans(
                fontSize: w * 0.05,
                fontWeight: FontWeight.w600,
                height: 1.34,
                color: _paperMist,
              ),
            ),
            SizedBox(height: w * 0.045),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            SizedBox(height: w * 0.045),
            Text(
              card.reach,
              style: GoogleFonts.plusJakartaSans(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w500,
                height: 1.34,
                color: _paperMist.withValues(alpha: 0.82),
              ),
            ),
            const Spacer(),
            if (card.linkedCardName != null) _linkBadge(card.linkedCardName!, accent),
            SizedBox(height: w * 0.02),
            // Small Voltix mark.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.bolt_rounded, size: w * 0.05, color: _goldBright.withValues(alpha: 0.8)),
                SizedBox(width: w * 0.01),
                Text(
                  'VOLTIX',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: w * 0.03,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: _goldBright.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _linkBadge(String linkedName, Color accent) {
    final w = size.width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.018),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: w * 0.045, color: accent),
          SizedBox(width: w * 0.018),
          Flexible(
            child: Text(
              'Linked · $linkedName',
              style: GoogleFonts.ibmPlexMono(
                fontSize: w * 0.032,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: _paperMist,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal current-flow sheen — a soft white band that sweeps across once per
/// [progress] cycle. Low opacity (premium = subtle).
class _SheenPainter extends CustomPainter {
  _SheenPainter(this.progress);
  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep from off-left to off-right across the diagonal.
    final span = size.width * 1.8;
    final x = -size.width * 0.4 + progress * span;
    final rect = Rect.fromLTWH(x - size.width * 0.18, -size.height * 0.2,
        size.width * 0.36, size.height * 1.4);
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = const LinearGradient(
        colors: [Color(0x00FFFFFF), Color(0x22FFFFFF), Color(0x00FFFFFF)],
      ).createShader(rect);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.35);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.progress != progress;
}

class _RarityPipPainter extends CustomPainter {
  _RarityPipPainter(this.rarity);
  final CardRarity rarity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final diamond = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    if (rarity == CardRarity.foundational) {
      canvas.drawPath(
        diamond,
        Paint()..shader = prismaticShader(Offset.zero & size, opacity: 1),
      );
      canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.8),
      );
    } else {
      canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _gold,
      );
    }
  }

  @override
  bool shouldRepaint(_RarityPipPainter old) => old.rarity != rarity;
}
