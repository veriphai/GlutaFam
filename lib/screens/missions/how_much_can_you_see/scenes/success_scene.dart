// Scene 9 — Correct Answer Success (PRD §13).
//
// Plays a capture sequence BEFORE the win overlay (refs: earth_detective's
// satellite→cyclone light cone `_renderBeam(locked)`, and code_satellite's
// captured-image thumbnail):
//   1. the satellite fires a widening CONE OF LIGHT onto the cyclone,
//   2. a CAMERA FLASH captures it,
//   3. the captured photo POPS into a framed panel at centre,
//   4. the panel ZOOMS OUT and flies to the top as a thumbnail,
//   5. THEN the green check + "EARTH VIEW MASTERED!" badge + Mission Control +
//      CONTINUE reveal.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/scene_copy.dart';
import '../state/how_much_controller.dart';
import '../state/how_much_state.dart';
import '../widgets/cta_button.dart';
import '../widgets/orbit_message.dart';
import '../../../../utils/s3_assets.dart';

double _ramp(double v, double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

class SuccessScene extends StatefulWidget {
  const SuccessScene({
    super.key,
    required this.controller,
    required this.onExit,
    required this.onSound,
  });

  final HowMuchController controller;
  /// CONTINUE leaves the activity directly (bridge + teaser are bypassed).
  final VoidCallback onExit;
  final void Function(String assetFile) onSound;

  @override
  State<SuccessScene> createState() => _SuccessSceneState();
}

class _SuccessSceneState extends State<SuccessScene> with SingleTickerProviderStateMixin {
  late final AnimationController _seq =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
  bool _captured = false;
  bool _showOutcome = false;

  @override
  void initState() {
    super.initState();
    _seq.addListener(_onTick);
    _seq.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        widget.onSound(HMSounds.correct);
        HapticFeedback.mediumImpact();
        setState(() => _showOutcome = true);
        // Orbit speaks the success line as his bubble appears (clip 13).
        widget.controller.onSuccessOutcomeShown();
      }
    });
    _seq.forward();
  }

  // Fire the shutter once, mid-sequence.
  void _onTick() {
    if (!_captured && _seq.value >= 0.43) {
      _captured = true;
      widget.onSound(HMSounds.tap);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _seq.removeListener(_onTick);
    _seq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        netImageWidget(HM.flutter(HM.bgOceanCyclone), fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x3307162F), Color(0xDD07162F)],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth, h = c.maxHeight;
              final satCenter = Offset(w * 0.64, h * 0.15);
              const satH = 116.0;
              final satEmit = satCenter + const Offset(0, satH * 0.34);
              final cyclone = Offset(w * 0.48, h * 0.47);
              final panelBig = Offset(w * 0.5, h * 0.44);
              final panelTop = Offset(w * 0.27, h * 0.13);
              final bigW = w * 0.54;

              return Stack(
                children: [
                  // 1+2: the cone of light + capture flash (animated).
                  AnimatedBuilder(
                    animation: _seq,
                    builder: (_, __) {
                      final v = _seq.value;
                      final coneP = Curves.easeOut.transform(_ramp(v, 0.06, 0.30));
                      final coneO = 1 - _ramp(v, 0.50, 0.66);
                      final flash = (1 - ((v - 0.45).abs() / 0.06)).clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ConePainter(
                                emit: satEmit,
                                target: cyclone,
                                progress: coneP,
                                opacity: coneO,
                              ),
                            ),
                          ),
                          // camera-shutter white veil
                          if (flash > 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: ColoredBox(
                                    color: Colors.white.withValues(alpha: 0.55 * flash)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Satellite (the cone source), floating.
                  Positioned(
                    left: satCenter.dx - satH / 2,
                    top: satCenter.dy - satH / 2,
                    child: Floaty(child: netImageWidget(HM.flutter(HM.satelliteIcon), height: satH)),
                  ),

                  // 3+4: captured photo panel — pops at centre, then flies to top.
                  AnimatedBuilder(
                    animation: _seq,
                    builder: (_, __) {
                      final v = _seq.value;
                      final appear = _ramp(v, 0.45, 0.62);
                      if (appear <= 0) return const SizedBox.shrink();
                      final toTop = Curves.easeInOut.transform(_ramp(v, 0.78, 0.96));
                      // position: cyclone → centre → top
                      final mid = Offset.lerp(cyclone, panelBig, Curves.easeOut.transform(appear))!;
                      final pos = Offset.lerp(mid, panelTop, toTop)!;
                      // scale: grow (overshoot) then shrink toward thumbnail
                      final grow = Curves.easeOutBack.transform(appear);
                      final scale = (0.15 + 0.85 * grow) * (1 - 0.58 * toTop);
                      final opacity = _ramp(v, 0.45, 0.53);
                      return Positioned(
                        left: pos.dx - bigW / 2,
                        top: pos.dy - bigW / 2,
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: _CapturedPanel(side: bigW),
                          ),
                        ),
                      );
                    },
                  ),

                  // 5: the win outcome (revealed after the sequence).
                  if (_showOutcome) ..._outcome(w, h),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _outcome(double w, double h) {
    return [
      // Green check + sparkles, centred.
      Positioned(
        left: 0,
        right: 0,
        top: h * 0.40,
        child: Center(
          child: SizedBox(
            width: 240,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0, end: 1),
                  builder: (_, v, __) => Opacity(
                    opacity: (1 - (v - 0.6).clamp(0, 0.4) / 0.4).clamp(0.0, 1.0),
                    child: Transform.scale(
                        scale: 0.8 + 0.5 * v,
                        child: netImageWidget(HM.flutter(HM.sparkles), width: 230)),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  tween: Tween(begin: 0, end: 1),
                  builder: (_, v, __) =>
                      Transform.scale(scale: v, child: netImageWidget(HM.flutter(HM.checkmark), width: 110)),
                ),
              ],
            ),
          ),
        ),
      ),
      // Badge + Mission Control + CONTINUE at the bottom.
      Positioned(
        left: 18,
        right: 18,
        bottom: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RevealOnLoad(child: _MasteredBadge()),
            const SizedBox(height: 12),
            const RevealOnLoad(
              delay: Duration(milliseconds: 120),
              child: OrbitMessage(
                mood: MascotMood.thumbsUp,
                message: SceneCopy.successMissionControl,
              ),
            ),
            const SizedBox(height: 12),
            RevealOnLoad(
              delay: const Duration(milliseconds: 240),
              child: CtaButton(
                label: SceneCopy.cont,
                // Listen-before-skip: CONTINUE lights up when the success line
                // finishes (safety timer in the shell un-gates if audio fails).
                enabled: !widget.controller.state.voicePlaying,
                onTap: () {
                  widget.controller.finishAndAdvance();
                  widget.onExit();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ];
  }
}

/// A widening cone of light from the satellite onto the cyclone (additive),
/// with a glowing elliptical footprint at the base. Adapted from earth_detective
/// `_renderBeam(locked)`.
class _ConePainter extends CustomPainter {
  _ConePainter({
    required this.emit,
    required this.target,
    required this.progress,
    required this.opacity,
  });

  final Offset emit;
  final Offset target;
  final double progress; // 0..1 cone extension
  final double opacity; // overall fade

  static const _cyan = Color(0xFF7CE0FF);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || progress <= 0) return;
    final tip = Offset.lerp(emit, target, progress)!;
    final d = tip - emit;
    final len = d.distance;
    if (len < 1) return;
    final ux = d.dx / len, uy = d.dy / len;
    final px = -uy, py = ux; // perpendicular unit

    final apexH = size.width * 0.012;
    final baseH = size.width * 0.27 * progress;
    final cone = Path()
      ..moveTo(emit.dx + px * apexH, emit.dy + py * apexH)
      ..lineTo(tip.dx + px * baseH, tip.dy + py * baseH)
      ..lineTo(tip.dx - px * baseH, tip.dy - py * baseH)
      ..lineTo(emit.dx - px * apexH, emit.dy - py * apexH)
      ..close();

    canvas.drawPath(
      cone,
      Paint()
        ..color = _cyan.withValues(alpha: 0.16 * opacity)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(cone, Paint()..color = _cyan.withValues(alpha: 0.20 * opacity)..blendMode = BlendMode.plus);

    // bright core line down the axis
    canvas.drawLine(
      emit,
      tip,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * opacity)
        ..strokeWidth = 2
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // glowing footprint ellipse over the cyclone
    if (progress > 0.5) {
      final fp = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final el = Rect.fromCenter(center: tip, width: baseH * 2.3, height: baseH * 1.15);
      canvas.drawOval(
        el,
        Paint()
          ..color = _cyan.withValues(alpha: 0.20 * opacity * fp)
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawOval(
        el,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _cyan.withValues(alpha: 0.5 * opacity * fp)
          ..blendMode = BlendMode.plus,
      );
    }

    // emitter dot at the satellite
    canvas.drawCircle(emit, size.width * 0.012,
        Paint()..color = _cyan.withValues(alpha: opacity)..blendMode = BlendMode.plus);
  }

  @override
  bool shouldRepaint(covariant _ConePainter old) =>
      old.progress != progress || old.opacity != opacity || old.emit != emit || old.target != target;
}

/// The captured cyclone photo in a HUD frame (cyan border + corner brackets).
class _CapturedPanel extends StatelessWidget {
  const _CapturedPanel({required this.side});
  final double side;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: side,
      height: side,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1430),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.8), width: 2),
        boxShadow: [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.45), blurRadius: 18)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: netImageWidget(HM.flutter(HM.bgOceanCyclone), fit: BoxFit.cover, alignment: Alignment.center),
          ),
          // corner brackets
          Positioned.fill(child: CustomPaint(painter: _BracketsPainter())),
          // label
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text('STORM CAPTURED',
                    style: CareerText.label.copyWith(
                        color: CareerColors.cyan, fontSize: 8.5, letterSpacing: 0.8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = CareerColors.cyan.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final len = size.width * 0.16;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * len, 0), p);
      canvas.drawLine(o, o.translate(0, dy * len), p);
    }
    const m = 3.0;
    corner(Offset(m, m), 1, 1);
    corner(Offset(size.width - m, m), -1, 1);
    corner(Offset(m, size.height - m), 1, -1);
    corner(Offset(size.width - m, size.height - m), -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MasteredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: CareerGradients.gold,
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        boxShadow: [BoxShadow(color: CareerColors.gold.withValues(alpha: 0.5), blurRadius: 16)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFF6B4A00), size: 20),
          const SizedBox(width: 8),
          Text(SceneCopy.earthViewMastered,
              style: CareerText.label.copyWith(color: const Color(0xFF4A3300), fontSize: 12, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
