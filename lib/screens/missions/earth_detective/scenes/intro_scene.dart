// Scene 0 — Activity launch / Mission Control (storyboard frame 1, PRD §19).
// Mission-control window background (its own Earth in view), a satellite beaming
// a scan cone down to Earth, the bright robo mascot welcoming the child, and the
// "Start Mission" CTA.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/missions.dart';
import '../state/earth_detective_controller.dart';
import '../widgets/ed_cta_button.dart';
import '../../../../utils/s3_assets.dart';

const _titleGold = Color(0xFFF3E2A6);

class IntroScene extends StatelessWidget {
  const IntroScene({super.key, required this.controller, required this.onHome});

  final EarthDetectiveController controller;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Mission-control window background (Earth + console).
        netImageWidget(edFlutter(EdAssets.bgMissionControl), fit: BoxFit.cover, alignment: Alignment.topCenter),
        // Bottom legibility scrim for the mascot + CTA.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Color(0x00081B3F), Color(0xCC061226)],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // header: back + sound
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(
                  children: [
                    _circleBtn(Icons.arrow_back_rounded, onHome),
                    const Spacer(),
                    _circleBtn(
                      controller.state.soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      controller.toggleSound,
                    ),
                  ],
                ),
              ),
              // extra top padding standing in for the removed EPISODE 8 label
              const SizedBox(height: 26),
              RevealOnLoad(
                child: Column(
                  children: [
                    Text(
                      EdCopy.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: CareerText.heroTitle.copyWith(
                        fontSize: 40,
                        height: 1.0,
                        letterSpacing: 1.5,
                        color: _titleGold,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(EdCopy.introQuestion,
                        textAlign: TextAlign.center,
                        style: CareerText.body.copyWith(fontSize: 15.5, color: Colors.white)),
                  ],
                ),
              ),
              // middle area: satellite beaming to the Earth in the background
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _IntroBeamPainter())),
                    Positioned(
                      top: 6,
                      right: 22,
                      child: Floaty(
                        amplitude: 8,
                        child: netImageWidget(edFlutter(EdAssets.satelliteTiny), width: 78, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
              // mascot + speech bubble
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Floaty(
                      amplitude: 4,
                      child: netImageWidget(edFlutter(EdAssets.mascotWelcoming),
                          height: 150, fit: BoxFit.contain),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        // voice-paced by the controller's monologue driver;
                        // instant swap (no cross-fade) so text never collides
                        // with the line being spoken
                        child: _bubble(controller.state.helperMessage ?? EdCopy.introLines.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              EdCtaButton(
                label: EdCopy.startCta,
                icon: Icons.rocket_launch_rounded,
                enabled: !controller.state.voicePlaying,
                onTap: controller.startMission,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => PressableScale(
        onTap: onTap,
        child: GlassSurface(
          radius: 14,
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: CareerColors.textPrimary),
        ),
      );

  Widget _bubble(String text) => CustomPaint(
        painter: _BubblePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 15, 12),
          child: Text(text,
              style: CareerText.body.copyWith(
                  color: CareerColors.onLight, fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600)),
        ),
      );
}

/// A cream speech bubble with a tail on the left pointing toward the mascot.
class _BubblePainter extends CustomPainter {
  static const _fill = Color(0xFFF2ECDA);
  static const _tail = 11.0;
  static const _radius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.5;
    final body = RRect.fromLTRBR(_tail, 0, size.width, size.height, const Radius.circular(_radius));
    final path = Path()..addRRect(body);
    // left-pointing tail, vertically centred on the mascot
    path
      ..moveTo(_tail, cy - 11)
      ..lineTo(0, cy)
      ..lineTo(_tail, cy + 11)
      ..close();
    canvas.drawShadow(path, Colors.black, 5, false);
    canvas.drawPath(path, Paint()..color = _fill);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => false;
}

/// A cyan scan cone from the satellite (top-right) down to the Earth in the
/// background image. Positions are fractions of the middle area.
class _IntroBeamPainter extends CustomPainter {
  static const _cyan = Color(0xFF35C6FF);

  @override
  void paint(Canvas canvas, Size size) {
    final emit = Offset(size.width * 0.80, size.height * 0.06);
    final target = Offset(size.width * 0.46, size.height * 0.30); // land on Earth, not the console
    final d = target - emit;
    final len = d.distance;
    if (len < 1) return;
    final ux = d.dx / len, uy = d.dy / len;
    final px = -uy, py = ux;
    final half = size.width * 0.14;

    final l = Offset(target.dx + px * half, target.dy + py * half);
    final r = Offset(target.dx - px * half, target.dy - py * half);
    final cone = Path()
      ..moveTo(emit.dx, emit.dy)
      ..lineTo(l.dx, l.dy)
      ..lineTo(r.dx, r.dy)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = ui.Gradient.linear(
          emit,
          target,
          [_cyan.withValues(alpha: 0.45), _cyan.withValues(alpha: 0.16), _cyan.withValues(alpha: 0.0)],
          [0.0, 0.65, 1.0],
        ),
    );
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = _cyan.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(emit, l, edge);
    canvas.drawLine(emit, r, edge);
    canvas.drawCircle(emit, 4, Paint()..color = _cyan);
  }

  @override
  bool shouldRepaint(_IntroBeamPainter oldDelegate) => false;
}
