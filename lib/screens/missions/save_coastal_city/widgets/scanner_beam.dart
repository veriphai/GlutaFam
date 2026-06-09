// Procedural Stage-1 scanner beam ("photocopier sweep" design) — replaces the
// fx_cyan_scan_beam sprite. Anatomy, outside-in:
//
//   • one-sided trailing VEIL — a translucent wash behind the direction of
//     travel (the "just-scanned area is still energized" photocopier cue)
//   • BLOOM — two widening soft glows around the core
//   • white-hot CORE line — the actual "laser"
//   • ruler TICKS + emitter END-CAPS — instrument character
//   • travelling HIGHLIGHT + subtle flicker — energy flowing along the line
//   • contact RIPPLE + colour tint — the beam reacts when it crosses a row,
//     lerping from cyan toward that satellite's glow colour
//
// All driven by one looping clock passed to the painter as `repaint` (no
// setState per frame); a short energy controller eases idle ↔ scanning
// brightness; a one-shot controller fires the ripple on contactToken bumps.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScannerBeam extends StatefulWidget {
  const ScannerBeam({
    super.key,
    required this.scanning,
    required this.tint,
    required this.movingUp,
    required this.contactToken,
    this.height = 90,
  });

  /// Finger is down — full energy. Otherwise the beam idles, dim + breathing.
  final bool scanning;

  /// Colour of the satellite row currently under the beam (or cyan).
  final Color tint;

  /// Travel direction — the veil trails on the opposite side.
  final bool movingUp;

  /// Bump when the beam crosses onto a new row → contact ripple.
  final int contactToken;

  final double height;

  @override
  State<ScannerBeam> createState() => _ScannerBeamState();
}

class _ScannerBeamState extends State<ScannerBeam>
    with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  late final AnimationController _energy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: widget.scanning ? 1 : 0,
  );

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1, // start spent — no ripple until first contact
  );

  @override
  void didUpdateWidget(covariant ScannerBeam old) {
    super.didUpdateWidget(old);
    if (widget.scanning != old.scanning) {
      widget.scanning ? _energy.forward() : _energy.reverse();
    }
    if (widget.contactToken != old.contactToken) {
      _ripple.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _energy.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _BeamPainter(
          clock: _clock,
          energy: _energy,
          ripple: _ripple,
          tint: widget.tint,
          movingUp: widget.movingUp,
        ),
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  _BeamPainter({
    required this.clock,
    required this.energy,
    required this.ripple,
    required this.tint,
    required this.movingUp,
  }) : super(repaint: Listenable.merge([clock, energy, ripple]));

  final Animation<double> clock;
  final Animation<double> energy;
  final Animation<double> ripple;
  final Color tint;
  final bool movingUp;

  static const _inset = 30.0; // beam line stops short of the emitter caps

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final t = clock.value;
    // idle 45% energy, scanning 100%, plus a gentle organic flicker
    final flicker =
        0.92 + 0.08 * (math.sin(t * 13 * math.pi) + math.sin(t * 7 * math.pi)) / 2;
    final e = (0.45 + 0.55 * energy.value) * flicker;

    final core = Color.lerp(tint, Colors.white, 0.72)!;
    final x0 = _inset, x1 = size.width - _inset;
    final a = Offset(x0, midY), b = Offset(x1, midY);

    // ── trailing veil (opposite the direction of travel) ────────────────
    final veilRect = movingUp
        ? Rect.fromLTRB(x0, midY, x1, size.height)
        : Rect.fromLTRB(x0, 0, x1, midY);
    canvas.drawRect(
      veilRect,
      Paint()
        ..shader = LinearGradient(
          begin: movingUp ? Alignment.topCenter : Alignment.bottomCenter,
          end: movingUp ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            tint.withValues(alpha: 0.16 * e),
            tint.withValues(alpha: 0.0),
          ],
        ).createShader(veilRect),
    );

    // ── bloom + core ─────────────────────────────────────────────────────
    void line(double width, double alpha, double blur, [Color? c]) {
      final p = Paint()
        ..color = (c ?? tint).withValues(alpha: alpha * e)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawLine(a, b, p);
    }

    line(16, 0.20, 14);
    line(7, 0.38, 5);
    line(2.4, 0.95, 0, core);

    // ── ruler ticks (above the line) ─────────────────────────────────────
    final tickPaint = Paint()
      ..color = tint.withValues(alpha: 0.30 * e)
      ..strokeWidth = 1.2;
    for (var x = x0 + 14; x < x1 - 14; x += 28) {
      canvas.drawLine(Offset(x, midY - 7), Offset(x, midY - 12), tickPaint);
    }

    // ── travelling highlight (energy flowing along the line) ─────────────
    final hx = x0 + (x1 - x0) * t;
    const hw = 34.0;
    final hRect = Rect.fromLTRB(hx - hw, midY - 3, hx + hw, midY + 3);
    canvas.drawLine(
      Offset(math.max(x0, hx - hw), midY),
      Offset(math.min(x1, hx + hw), midY),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.85 * e),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(hRect)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // ── emitter end-caps (inward chevrons + glow node) ───────────────────
    for (final (cx, dir) in [(x0 - 12, 1.0), (x1 + 12, -1.0)]) {
      final cap = Path()
        ..moveTo(cx, midY - 9)
        ..lineTo(cx + 9 * dir, midY)
        ..lineTo(cx, midY + 9)
        ..close();
      canvas.drawPath(
        cap,
        Paint()
          ..color = tint.withValues(alpha: 0.85 * e)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.2),
      );
      canvas.drawCircle(
        Offset(cx + 11 * dir, midY),
        2.6,
        Paint()
          ..color = core.withValues(alpha: 0.9 * e)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // ── contact ripple (one-shot on row crossing) ────────────────────────
    final r = ripple.value;
    if (r < 1) {
      final cx = size.width / 2;
      canvas.drawCircle(
        Offset(cx, midY),
        10 + 42 * Curves.easeOut.transform(r),
        Paint()
          ..color = tint.withValues(alpha: (1 - r) * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) =>
      old.tint != tint || old.movingUp != movingUp;
}
