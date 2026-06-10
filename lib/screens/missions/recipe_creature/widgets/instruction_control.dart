// InstructionControl — the reusable instruction-slider primitive (PRD §5), Tier-4
// premium pass. One control binds to one Genome field; dragging changes only that
// trait, live (criterion 1). Each row: a gene glyph + label + a refined glowing
// track + a value chip (or the 0.2 "peek" affordance on the colour row).
// Immediate drag (never long-press) per the kids'-mobile rule.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/creature_tuning.dart';
import '../config/genome.dart';

class InstructionControl extends StatelessWidget {
  const InstructionControl({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.showPeek = false,
    this.onPeek,
  });

  final GeneField field;
  final double value; // 0..1
  final ValueChanged<double> onChanged;
  final bool showPeek;
  final VoidCallback? onPeek;

  bool get _isColour => field == GeneField.colour;

  IconData get _icon {
    switch (field) {
      case GeneField.size:
        return Icons.zoom_out_map_rounded;
      case GeneField.limbs:
        return Icons.directions_walk_rounded;
      case GeneField.colour:
        return Icons.palette_rounded;
      case GeneField.pattern:
        return Icons.grain_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hue = value * 360;
    final swatch = HSVColor.fromAHSV(1, hue, 0.62, 0.98).toColor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_icon, size: 17, color: Colors.white.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              field.label,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, cns) {
                final w = cns.maxWidth;
                void set(double x) => onChanged((x / w).clamp(0.0, 1.0));
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => set(d.localPosition.dx),
                  onHorizontalDragStart: (d) => set(d.localPosition.dx),
                  onHorizontalDragUpdate: (d) => set(d.localPosition.dx),
                  child: SizedBox(
                    height: 36,
                    child: CustomPaint(painter: _TrackPainter(value: value, colour: _isColour)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: showPeek
                ? _PeekButton(onTap: onPeek)
                : _isColour
                    ? _Swatch(color: swatch)
                    : _ValueChip(value: value),
          ),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        '${(value * 100).round()}',
        style: GoogleFonts.ibmPlexMono(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
        ),
      ),
    );
  }
}

class _PeekButton extends StatelessWidget {
  const _PeekButton({this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RC.lifeAmber.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: RC.lifeAmber.withValues(alpha: 0.65)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_rounded, size: 13, color: RC.lifeAmber),
            const SizedBox(width: 3),
            Text('Peek',
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 9, fontWeight: FontWeight.w700, color: RC.lifeAmber)),
          ],
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.value, required this.colour});
  final double value;
  final bool colour;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const railH = 8.0;
    final railRect = Rect.fromLTWH(0, cy - railH / 2, size.width, railH);
    final rail = RRect.fromRectAndRadius(railRect, const Radius.circular(railH));

    // Recessed rail.
    canvas.drawRRect(rail, Paint()..color = const Color(0xFF0A1020));
    canvas.drawRRect(rail, Paint()..color = Colors.white.withValues(alpha: 0.05));

    if (colour) {
      canvas.drawRRect(
        rail,
        Paint()
          ..shader = SweepGradient(
            colors: [for (var i = 0; i <= 6; i++) HSVColor.fromAHSV(1, i * 60.0, 0.62, 0.98).toColor()],
          ).createShader(railRect),
      );
    } else {
      final fillRect = Rect.fromLTWH(0, cy - railH / 2, size.width * value, railH);
      final fill = RRect.fromRectAndRadius(fillRect, const Radius.circular(railH));
      final grad = const LinearGradient(colors: [RC.lifeGreen, RC.lifeAmber]).createShader(railRect);
      // soft glow under the fill.
      canvas.drawRRect(fill, Paint()
        ..shader = grad
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawRRect(fill, Paint()..shader = grad);
    }
    // bottom highlight hairline.
    canvas.drawLine(Offset(2, cy + railH / 2 - 0.5), Offset(size.width - 2, cy + railH / 2 - 0.5),
        Paint()..color = Colors.white.withValues(alpha: 0.06)..strokeWidth = 1);

    // Thumb.
    final tx = (size.width * value).clamp(12.0, size.width - 12.0);
    final tc = colour ? HSVColor.fromAHSV(1, value * 360, 0.62, 0.98).toColor() : Colors.white;
    canvas.drawCircle(Offset(tx, cy), 14, Paint()
      ..color = tc.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(Offset(tx, cy), 11, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(tx, cy), 8, Paint()..color = tc);
    canvas.drawCircle(Offset(tx - 2.4, cy - 2.4), 2.4, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.value != value || old.colour != colour;
}
