// Scene 1 — How to play (storyboard frame 2). A glass card demoing the scanner:
// a Flutter-drawn translucent target sweeps over a forest satellite image, then
// a green "locked" target shows the success state. Bright pointing robo + Got It.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/missions.dart';
import '../state/earth_detective_controller.dart';
import '../widgets/ed_cta_button.dart';
import '../widgets/ed_top_bar.dart';
import '../../../../utils/s3_assets.dart';

class TutorialScene extends StatefulWidget {
  const TutorialScene({super.key, required this.controller, required this.onHome});

  final EarthDetectiveController controller;
  final VoidCallback onHome;

  @override
  State<TutorialScene> createState() => _TutorialSceneState();
}

class _TutorialSceneState extends State<TutorialScene> with SingleTickerProviderStateMixin {
  late final AnimationController _demo =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              EdTopBar(
                title: EdCopy.tutorialTitle.toUpperCase(),
                onBack: widget.onHome,
                soundOn: widget.controller.state.soundOn,
                onToggleSound: widget.controller.toggleSound,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0A1A38),
                      borderRadius: BorderRadius.circular(CareerRadii.card),
                      border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.55), width: 1.4),
                      boxShadow: [BoxShadow(color: CareerColors.blue.withValues(alpha: 0.3), blurRadius: 20)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(EdCopy.tutorialLine1,
                            textAlign: TextAlign.center,
                            style: CareerText.cardTitle.copyWith(fontSize: 15.5, color: Colors.white, height: 1.3)),
                        const SizedBox(height: 18),
                        // satellite image with a sweeping translucent scanner
                        _ImageFrame(
                          height: 188,
                          child: AnimatedBuilder(
                            animation: _demo,
                            builder: (context, _) {
                              final t = _demo.value;
                              final ax = 0.62 * math.sin(t * 2 * math.pi);
                              final ay = 0.42 * math.sin(t * 4 * math.pi);
                              return Align(
                                alignment: Alignment(ax, ay),
                                child: SizedBox(
                                  width: 86,
                                  height: 86,
                                  child: CustomPaint(painter: _ScanTargetPainter(color: _cyan, phase: t)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(EdCopy.tutorialLine2,
                            textAlign: TextAlign.center,
                            style: CareerText.body.copyWith(fontSize: 14, color: CareerColors.textSecondary)),
                        const SizedBox(height: 18),
                        // locked (green) state
                        _ImageFrame(
                          height: 120,
                          width: 120,
                          child: Center(
                            child: SizedBox(
                              width: 92,
                              height: 92,
                              child: AnimatedBuilder(
                                animation: _demo,
                                builder: (context, _) => CustomPaint(
                                  painter: _ScanTargetPainter(color: _green, phase: _demo.value, locked: true),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(EdCopy.tutorialLine3,
                            textAlign: TextAlign.center,
                            style: CareerText.cardTitle.copyWith(fontSize: 15, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              EdCtaButton(
            label: EdCopy.tutorialCta,
            enabled: !widget.controller.state.voicePlaying,
            onTap: widget.controller.finishTutorial,
          ),
              const SizedBox(height: 22),
            ],
          ),
          // bright robo pointing toward the card
          Positioned(
            left: 28,
            bottom: 70,
            child: Floaty(
              amplitude: 4,
              child: netImageWidget(edFlutter(EdAssets.mascotPointingRight), height: 192, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

const _cyan = Color(0xFF35C6FF);
const _green = Color(0xFF65D65E);

/// A rounded "satellite image" frame showing the forest scene with [child] on top.
class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.height, required this.child, this.width});

  final double height;
  final double? width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            netImageWidget(edFlutter(EdAssets.sceneForestBefore), fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: _cyan.withValues(alpha: 0.35), width: 1.2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// A scanner/target reticle: concentric rings + crosshair, translucent centre so
/// the image shows through. A rotating sweep tick reads as "scanning"; [locked]
/// switches to the steady green confirmation look.
class _ScanTargetPainter extends CustomPainter {
  _ScanTargetPainter({required this.color, required this.phase, this.locked = false});

  final Color color;
  final double phase;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;

    // translucent interior so the satellite image shows through
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: locked ? 0.16 : 0.10));

    // soft outer glow
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // outer ring
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = color);
    // inner ring
    canvas.drawCircle(c, r * 0.5,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = color.withValues(alpha: 0.85));
    // centre dot
    canvas.drawCircle(c, 3.2, Paint()..color = color);

    // crosshair ticks at N/E/S/W
    final tick = Paint()..color = color..strokeWidth = 2.4..strokeCap = StrokeCap.round;
    for (final o in [const Offset(1, 0), const Offset(-1, 0), const Offset(0, 1), const Offset(0, -1)]) {
      canvas.drawLine(c + o * (r - 7), c + o * (r + 4), tick);
    }

    // rotating sweep tick (scanning state only)
    if (!locked) {
      final a = phase * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c, c + dir * (r - 3),
          Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 2..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_ScanTargetPainter old) => old.phase != phase || old.locked != locked || old.color != color;
}
