// Shared UI kit for Satellite Doctor: palette, pressable, CTA button, glass panel,
// top bar, mission progress, status chip row, and the MediBot speech bubble.
// Self-contained palette (SDColors) so the module doesn't couple to the exact
// careerTheme API. All TEXT is Flutter-rendered (PRD hard rule).

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import '../models/satellite_doctor_mission.dart';
import '../state/satellite_doctor_controller.dart';
import '../../../../utils/s3_assets.dart';

class SDColors {
  SDColors._();
  static const bg = Color(0xFF0A0E1A);
  static const panel = Color(0xFF131B30);
  static const panelHi = Color(0xFF1B2746);
  static const stroke = Color(0x553FC9FF);
  static const cyan = Color(0xFF3FC9FF);
  static const blue = Color(0xFF2E6BFF);
  static const green = Color(0xFF35E0A1);
  static const yellow = Color(0xFFFFC53D);
  static const orange = Color(0xFFFF8A3D);
  static const red = Color(0xFFFF5A5A);
  static const purple = Color(0xFF9B7BFF);
  static const text = Color(0xFFEAF2FF);
  static const textMuted = Color(0xFF9DB2D0);
}

/// Tap-scale wrapper (immediate, kid-friendly).
class SDPressable extends StatefulWidget {
  const SDPressable({super.key, required this.child, this.onTap, this.enabled = true});
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<SDPressable> createState() => _SDPressableState();
}

class _SDPressableState extends State<SDPressable> {
  double _s = 1;
  void _set(double v) => setState(() => _s = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _set(0.94) : null,
      onTapUp: widget.enabled ? (_) => _set(1) : null,
      onTapCancel: widget.enabled ? () => _set(1) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _s,
        duration: const Duration(milliseconds: 90),
        child: Opacity(opacity: widget.enabled ? 1 : 0.5, child: widget.child),
      ),
    );
  }
}

BoxDecoration glassPanel({Color? border, double radius = 20, Color? fill}) =>
    BoxDecoration(
      color: fill ?? SDColors.panel.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? SDColors.stroke, width: 1.4),
      boxShadow: [
        BoxShadow(
          color: (border ?? SDColors.cyan).withValues(alpha: 0.16),
          blurRadius: 22,
          spreadRadius: -4,
        ),
      ],
    );

/// Premium card shell: dark vertical gradient, a glowing accent top strip, a
/// tinted glow border, and a soft corner sheen. The signature panel look for
/// Satellite Doctor (alert / clues / apply panels).
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    required this.accent,
    this.danger,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });
  final Widget child;
  final Color accent;
  final Color? danger;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final glow = danger ?? accent;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.28), blurRadius: 30, spreadRadius: -8, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF18253D), Color(0xFF0C1422)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    accent.withValues(alpha: 0.0),
                    accent,
                    accent.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accent.withValues(alpha: 0.12),
                    accent.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: glow.withValues(alpha: 0.45), width: 1.4),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// A small accent-tinted pill label (e.g. "SYSTEM ALERT", "CHOOSE A REPAIR").
class SectionPill extends StatelessWidget {
  const SectionPill({super.key, required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2)),
        ],
      ),
    );
  }
}

/// Frosted wrapper for panels that sit over the live stage.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.border, this.radius = 20, this.padding});
  final Widget child;
  final Color? border;
  final double radius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: glassPanel(border: border, radius: radius),
          child: child,
        ),
      ),
    );
  }
}

class SDCta extends StatelessWidget {
  const SDCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    // deep-blue default so the button stays legible over the bright Earth
    this.colors = const [Color(0xFF2E6BFF), Color(0xFF123A8C)],
    this.enabled = true,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final List<Color> colors;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final top = colors.first;
    final bottom = colors.last;
    return SDPressable(
      enabled: enabled,
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // layered glow: a wide soft halo in the button's hue
          boxShadow: [
            BoxShadow(color: bottom.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: -6, offset: const Offset(0, 8)),
            BoxShadow(color: top.withValues(alpha: 0.30), blurRadius: 10, spreadRadius: -4),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // base gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(top, Colors.white, 0.18)!,
                        top,
                        bottom,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // glossy top sheen
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 26,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ),
              // crisp inner border
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
                  ),
                ),
              ),
              // content
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: bottom.withValues(alpha: 0.8), blurRadius: 6, offset: const Offset(0, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Mission X of 7" + progress dots.
class MissionProgress extends StatelessWidget {
  const MissionProgress({super.key, required this.current, required this.total});
  final int current; // 1-based
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Mission $current of $total',
          style: const TextStyle(
            color: SDColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final done = i < current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current - 1 ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: done ? SDColors.cyan : SDColors.panelHi,
                borderRadius: BorderRadius.circular(4),
                boxShadow: done
                    ? [BoxShadow(color: SDColors.cyan.withValues(alpha: 0.6), blurRadius: 8)]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Row of status chips.
class StatusChipRow extends StatelessWidget {
  const StatusChipRow({super.key, required this.chips});
  final List<ChipView> chips;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final c in chips)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _Chip(c),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.c);
  final ChipView c;

  String get _icon {
    switch (c.kind) {
      case ChipKind.power:
        return SD.chipPower;
      case ChipKind.signal:
        return SD.chipSignal;
      case ChipKind.temperature:
        return SD.chipTemperature;
      case ChipKind.orbit:
        return SD.chipOrbit;
      case ChipKind.camera:
        return SD.chipCamera;
      case ChipKind.solar:
        return SD.chipSolar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final warn = c.status == ChipStatus.warning;
    final col = warn ? SDColors.orange : SDColors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: glassPanel(border: col.withValues(alpha: 0.5), radius: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              netImageWidget(
                SD.flutter(_icon),
                width: 14,
                height: 14,
                errorBuilder: (_, __, ___) => Icon(Icons.bolt, size: 14, color: col),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  c.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SDColors.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            c.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// MediBot pose + speech bubble. The bubble body + a left-pointing tail are
/// drawn as ONE shape (CustomPaint) so the tail joins the rounded box cleanly
/// and points at the bot — reads as the bot talking, not just text on screen.
class MediBotBubble extends StatelessWidget {
  const MediBotBubble({super.key, required this.pose, required this.text});
  final String pose; // SD.bot*
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        netImageWidget(
          SD.flutter(pose),
          width: 78,
          height: 78,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.smart_toy, color: SDColors.cyan, size: 62),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: CustomPaint(
            painter: _SpeechBubblePainter(),
            child: Padding(
              // left padding clears the tail; the rest is the body inset
              padding: const EdgeInsets.fromLTRB(22, 12, 16, 12),
              child: Text(
                text,
                style: const TextStyle(
                  color: SDColors.text,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded speech bubble with an integrated triangular tail on the left edge
/// (points at the mascot). Drawn as one filled+stroked path.
class _SpeechBubblePainter extends CustomPainter {
  static const double _tail = 11; // tail width
  static const double _r = 16; // corner radius

  @override
  void paint(Canvas canvas, Size size) {
    final bodyLeft = _tail;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, 0, size.width - bodyLeft, size.height),
      const Radius.circular(_r),
    );
    final tailCy = size.height * 0.5;
    final bodyPath = Path()..addRRect(body);
    // overlap the tail a few px INTO the body so the union has no inner seam
    final tail = Path()
      ..moveTo(bodyLeft + 4, tailCy - 9)
      ..lineTo(0, tailCy)
      ..lineTo(bodyLeft + 4, tailCy + 9)
      ..close();
    // ONE merged silhouette → the stroke only traces the outer edge (no divider
    // line where the tail meets the body).
    final path = Path.combine(PathOperation.union, bodyPath, tail);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5), 4, false);
    canvas.drawPath(path, Paint()..color = SDColors.panel.withValues(alpha: 0.96));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = SDColors.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
