// The 0.3 "bring it back" tray — a single horizontal row of large tappable
// artifacts in the thumb zone (PRD §10). Order-independent; selecting bones or
// the photo is an inert OPTIONAL discovery — NEVER a quiz, NEVER "wrong"
// feedback (criterion 3). The genome is the goal, but no card is styled as "the
// right answer" beyond a quiet life-green identity.
//
// Tier-4: custom-drawn glyphs (ribcage / polaroid / helix / torn helix) for a
// cohesive, designed look instead of mismatched Material icons.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/creature_tuning.dart';
import '../state/recipe_creature_controller.dart';

class ArtifactTray extends StatelessWidget {
  const ArtifactTray({super.key, required this.controller, this.includeTorn = true});
  final RecipeCreatureController controller;
  final bool includeTorn;

  @override
  Widget build(BuildContext context) {
    final items = <_Spec>[
      const _Spec(Artifact.skeleton, 'Bones'),
      const _Spec(Artifact.photo, 'Photo'),
      const _Spec(Artifact.genome, 'Genome'),
      if (includeTorn) const _Spec(Artifact.torn, 'Torn recipe'),
    ];
    return ValueListenableBuilder<Set<Artifact>>(
      valueListenable: controller.tried,
      builder: (context, tried, _) {
        return Row(
          children: [
            for (final it in items) ...[
              Expanded(
                child: _Card(
                  spec: it,
                  triedAlready: tried.contains(it.artifact),
                  onTap: () => controller.selectArtifact(it.artifact),
                ),
              ),
              if (it != items.last) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _Spec {
  const _Spec(this.artifact, this.label);
  final Artifact artifact;
  final String label;
}

class _Card extends StatelessWidget {
  const _Card({required this.spec, required this.triedAlready, required this.onTap});
  final _Spec spec;
  final bool triedAlready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGenome = spec.artifact == Artifact.genome;
    final accent = isGenome ? RC.lifeGreen : Colors.white;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 112,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isGenome
                ? [const Color(0xFF12301F), const Color(0xFF0C1A24)]
                : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: isGenome ? 0.55 : 0.14)),
          boxShadow: isGenome
              ? [BoxShadow(color: RC.lifeGreen.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(
                painter: _ArtifactGlyph(spec.artifact, accent.withValues(alpha: isGenome ? 1 : 0.82)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              spec.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 5),
            Opacity(
              opacity: triedAlready ? 1 : 0,
              child: Icon(Icons.check_circle_rounded, size: 13, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crisp, consistent-weight glyphs per artifact (drawn, not Material icons).
class _ArtifactGlyph extends CustomPainter {
  _ArtifactGlyph(this.artifact, this.color);
  final Artifact artifact;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    switch (artifact) {
      case Artifact.skeleton:
        _ribcage(canvas, p, cx, cy, w, h);
      case Artifact.photo:
        _polaroid(canvas, p, cx, cy, w, h);
      case Artifact.genome:
        _helix(canvas, p, cx, h, false);
      case Artifact.torn:
        _helix(canvas, p, cx, h, true);
    }
  }

  void _ribcage(Canvas canvas, Paint p, double cx, double cy, double w, double h) {
    // spine + 3 rib pairs curving out.
    canvas.drawLine(Offset(cx, cy - h * 0.34), Offset(cx, cy + h * 0.34), p);
    for (var i = 0; i < 3; i++) {
      final y = cy - h * 0.22 + i * h * 0.22;
      for (final s in [-1.0, 1.0]) {
        final path = Path()
          ..moveTo(cx, y)
          ..quadraticBezierTo(cx + s * w * 0.32, y + h * 0.02, cx + s * w * 0.26, y + h * 0.14);
        canvas.drawPath(path, p);
      }
    }
    // skull-ish dot on top.
    canvas.drawCircle(Offset(cx, cy - h * 0.4), w * 0.05, p..style = PaintingStyle.stroke);
  }

  void _polaroid(Canvas canvas, Paint p, double cx, double cy, double w, double h) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - h * 0.02), width: w * 0.62, height: h * 0.62),
      const Radius.circular(3),
    );
    canvas.drawRRect(frame, p);
    // thick bottom border (polaroid) + a sun + horizon inside.
    final inner = Rect.fromLTWH(cx - w * 0.28, cy - h * 0.30, w * 0.56, h * 0.40);
    canvas.drawCircle(Offset(inner.right - w * 0.12, inner.top + h * 0.10), w * 0.06, p);
    canvas.drawLine(Offset(inner.left, inner.bottom), Offset(inner.right, inner.bottom - h * 0.04), p);
  }

  void _helix(Canvas canvas, Paint p, double cx, double h, bool torn) {
    final amp = h * 0.16;
    final top = h * 0.14, bot = h * 0.86;
    for (final dir in [1.0, -1.0]) {
      final path = Path();
      var started = false;
      for (var i = 0; i <= 24; i++) {
        final f = i / 24;
        final y = top + (bot - top) * f;
        // torn → a jagged gap in the middle third.
        if (torn && f > 0.42 && f < 0.58) {
          started = false;
          continue;
        }
        final x = cx + dir * math.sin(f * 2.4 * math.pi) * amp;
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, p);
    }
    // rungs.
    for (var i = 1; i <= 5; i++) {
      final f = i / 6;
      if (torn && f > 0.40 && f < 0.60) continue;
      final y = top + (bot - top) * f;
      final x = math.sin(f * 2.4 * math.pi) * amp;
      canvas.drawLine(Offset(cx - x, y), Offset(cx + x, y), p..strokeWidth = 1.4);
    }
    p.strokeWidth = 2;
    if (torn) {
      // a small red tear flash at the gap.
      canvas.drawLine(Offset(cx - amp * 0.6, h * 0.46), Offset(cx + amp * 0.6, h * 0.54),
          Paint()..color = const Color(0xFFE2557A)..strokeWidth = 1.6..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_ArtifactGlyph old) => old.artifact != artifact || old.color != color;
}
