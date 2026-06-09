// MagicalField — the howwow magic-box logo at the centre with two
// clockwise orbits of curiosity glyphs around it. Used as the brand
// centrepiece on multiple surfaces in the auth flow:
//
//   • WowFirstHowNextScreen — the brand-statement bridge after Welcome.
//   • HowwowLoginScreen     — the auth provider picker.
//
// Sharing one widget keeps the visual identity continuous (same icon
// set, same rotation cadence, same halo) — the only difference between
// surfaces is the size, which is parameterised.
//
// Sizing model — pass `size` (the outer SizedBox bounds) and `logoSize`
// (the central magic-box illustration). Inner radius, outer radius, and
// icon base sizes all scale proportionally from `size` using ratios
// taken from the original wow-first design (size 340).

import 'dart:math' as math;

import 'package:flutter/material.dart';

class MagicalField extends StatefulWidget {
  const MagicalField({
    super.key,
    this.size = 340.0,
    this.logoSize = 120.0,
  });

  final double size;
  final double logoSize;

  @override
  State<MagicalField> createState() => _MagicalFieldState();
}

class _MagicalFieldState extends State<MagicalField>
    with TickerProviderStateMixin {
  // Two independent controllers — one per ring. Each completes EXACTLY
  // one full revolution per cycle (controller.value 0 → 1 maps to angle
  // 0 → 2π), so `cos(angle)` at the loop boundary equals `cos(0)` and
  // `.repeat()` is visually a no-op.
  late final AnimationController _innerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();
  late final AnimationController _outerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
  )..repeat();

  // Reference dimensions at size = 340. Everything else derives.
  static const _refSize = 340.0;
  static const _refInnerRadius = 95.0;
  static const _refOuterRadius = 145.0;
  static const _refInnerMinSize = 28.0;
  static const _refOuterMinSize = 24.0;
  static const _refInnerJitter = 14.0;
  static const _refOuterJitter = 12.0;

  static const _step = math.pi / 3; // 60°

  /// Inner orbit — base angles 0°, 60°, 120°, 180°, 240°, 300°.
  static const _innerGlyphs = ['🚀', '🛰', '🔭', '🌌', '🤖', '💡'];

  /// Outer orbit — base angles offset by 30° (π/6) so the rings
  /// interleave as they rotate past each other.
  static const _outerGlyphs = ['🧬', '⚙️', '🔬', '🧪', '🪐', '🌍'];
  static const _outerPhase = math.pi / 6; // 30°

  late final List<double> _innerSizes;
  late final List<double> _outerSizes;

  @override
  void initState() {
    super.initState();
    // Fixed seed → same constellation every build / hot reload. Per-
    // icon size = (minSize + rng × jitter) × scale, so the minimum
    // matches the previous uniform size at the reference scale and
    // shrinks proportionally on smaller fields.
    final scale = widget.size / _refSize;
    final rng = math.Random(0xC0FFEE);
    _innerSizes = List.generate(
      _innerGlyphs.length,
      (_) => (_refInnerMinSize + rng.nextDouble() * _refInnerJitter) * scale,
    );
    _outerSizes = List.generate(
      _outerGlyphs.length,
      (_) => (_refOuterMinSize + rng.nextDouble() * _refOuterJitter) * scale,
    );
  }

  @override
  void dispose() {
    _innerCtrl.dispose();
    _outerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.size / _refSize;
    final innerRadius = _refInnerRadius * scale;
    final outerRadius = _refOuterRadius * scale;
    return AnimatedBuilder(
      animation: Listenable.merge([_innerCtrl, _outerCtrl]),
      builder: (context, _) {
        // Both rings rotate CLOCKWISE; each controller's value 0 → 1
        // maps to exactly one revolution so the .repeat() wrap is
        // seamless.
        final innerOffset = _innerCtrl.value * 2 * math.pi;
        final outerOffset = _outerCtrl.value * 2 * math.pi;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < _outerGlyphs.length; i++)
                _ringIcon(
                  glyph: _outerGlyphs[i],
                  baseAngle: _outerPhase + i * _step,
                  radius: outerRadius,
                  size: _outerSizes[i],
                  angleOffset: outerOffset,
                ),
              for (int i = 0; i < _innerGlyphs.length; i++)
                _ringIcon(
                  glyph: _innerGlyphs[i],
                  baseAngle: i * _step,
                  radius: innerRadius,
                  size: _innerSizes[i],
                  angleOffset: innerOffset,
                ),
              MagicBox(size: widget.logoSize),
            ],
          ),
        );
      },
    );
  }

  /// Place a single glyph on a ring of [radius], offset from its base
  /// angle by [angleOffset]. Uses (cos, sin) with the 12 o'clock origin
  /// (so baseAngle 0 sits directly above the centre, going clockwise
  /// for positive angles).
  Widget _ringIcon({
    required String glyph,
    required double baseAngle,
    required double radius,
    required double size,
    required double angleOffset,
  }) {
    final angle = baseAngle + angleOffset;
    final dx = radius * math.cos(angle - math.pi / 2);
    final dy = radius * math.sin(angle - math.pi / 2);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Text(
        glyph,
        style: TextStyle(fontSize: size, height: 1.0),
      ),
    );
  }
}

/// The central magic-box illustration with a pulsing radial halo behind.
/// The brand logo IS the magic box (open chest with rocket / planet /
/// gear / book / lightbulb / stars bursting out), so we render it as
/// the centrepiece on a transparent backdrop. The halo is gold-core
/// fading through purple to transparent — glows against the cosmic
/// indigo backdrop without needing its own frame.
class MagicBox extends StatefulWidget {
  const MagicBox({super.key, this.size = 120.0});
  final double size;

  @override
  State<MagicBox> createState() => _MagicBoxState();
}

class _MagicBoxState extends State<MagicBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size + 64,
      height: size + 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_pulse.value);
              final halo = 0.32 + t * 0.18; // 0.32 → 0.50
              return Container(
                width: size + 60,
                height: size + 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFC83D).withValues(alpha: halo),
                      const Color(0xFF7C4DFF).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              );
            },
          ),
          Image.asset(
            'assets/howwow-logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ],
      ),
    );
  }
}
