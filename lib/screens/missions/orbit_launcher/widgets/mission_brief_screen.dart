// Activity 3 start screen — the mission-control "window" brief (mock-matched):
// EPISODE 3 / ORBIT LAUNCHER title, robot + boy characters in the bottom
// corners, a speech bubble, and a big yellow START MISSION button. A full-bleed
// Flutter overlay shown only in the missionBrief scene; START fades it out and
// reveals the launchpad.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../../../../utils/s3_assets.dart';

class MissionBriefScreen extends StatelessWidget {
  const MissionBriefScreen({
    super.key,
    required this.onStart,
    required this.onBack,
    required this.muted,
    required this.onToggleMute,
    this.startEnabled = true,
  });

  final VoidCallback onStart;
  final VoidCallback onBack;
  final bool muted;
  final VoidCallback onToggleMute;

  /// False while Orbit is speaking the intro line — Start waits for it.
  final bool startEnabled;

  static const _bubbleText =
      'Ever wonder why satellites don’t fall back to Earth? Let’s launch a rocket and find out!';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            netImageWidget(
              OL.flutter(OL.bgMissionWindow),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF05102A)),
            ),
            // bottom darkening for character/button legibility
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                  ),
                ),
              ),
            ),
            // characters in the bottom corners (behind the bubble/button)
            Positioned(
              left: c.maxWidth * 0.01,
              bottom: h * 0.115,
              child: netImageWidget(OL.flutter(OL.robotPointing),
                  height: h * 0.155, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
            Positioned(
              right: c.maxWidth * 0.02,
              bottom: h * 0.115,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: netImageWidget(OL.flutter(OL.mcHappy),
                    height: h * 0.16, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _circleBtn(Icons.arrow_back_rounded, onBack),
                        const Spacer(),
                        _circleBtn(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, onToggleMute),
                      ],
                    ),
                    // (EPISODE 3 tag removed — keep its vertical space so the
                    // title stays at the same height: 8 + ~17 line + 2 ≈ 27)
                    const SizedBox(height: 30),
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFFFE16B), Color(0xFFFFB020)],
                      ).createShader(r),
                      child: Text('ORBIT LAUNCHER',
                          textAlign: TextAlign.center,
                          style: CareerText.heroTitle.copyWith(
                              fontSize: 40, color: Colors.white, letterSpacing: 0.5, height: 1.0)),
                    ),
                    const SizedBox(height: 8),
                    Text('How do rockets send satellites into orbit?',
                        textAlign: TextAlign.center,
                        style: CareerText.body.copyWith(
                            color: Colors.white, fontSize: 17, height: 1.25, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _speechBubble(),
                    const SizedBox(height: 16),
                    _startButton(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => PressableScale(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: const Color(0xCC10306B),
            border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      );

  // A chat bubble the robot (bottom-left) is "speaking" — body + a tail on the
  // bottom edge pointing down-left toward the mascot.
  Widget _speechBubble() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: CustomPaint(
            painter: _BubblePainter(),
            child: Padding(
              // extra left padding leaves room for the tail pointing at the robot
              padding: const EdgeInsets.fromLTRB(26, 13, 16, 13),
              child: Text(_bubbleText,
                  style: CareerText.body.copyWith(
                      color: const Color(0xFF1A2A52), fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3)),
            ),
          ),
        ),
      );

  Widget _startButton() => PressableScale(
        onTap: startEnabled ? onStart : null,
        pressedScale: 0.97,
        child: AnimatedOpacity(
          opacity: startEnabled ? 1 : 0.45,
          duration: const Duration(milliseconds: 250),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFD24A), Color(0xFFFFA91C)]),
            borderRadius: BorderRadius.circular(CareerRadii.pill),
            boxShadow: [BoxShadow(color: const Color(0xFFFFB020).withValues(alpha: 0.6), blurRadius: 22, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.rocket_launch_rounded, size: 24, color: Color(0xFF2A1A00)),
              const SizedBox(width: 10),
              Text('Start Mission',
                  style: CareerText.cta.copyWith(
                      color: const Color(0xFF2A1A00), fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          ),
        ),
      );
}

/// Cream chat bubble with a soft shadow and a tail on the LEFT edge pointing
/// left toward the robot mascot (the speaker, up-left of the bubble).
class _BubblePainter extends CustomPainter {
  static const _fill = Color(0xFFFBF3DD);
  static const _tailW = 13.0; // how far the tail pokes left
  static const _tailSpan = 22.0; // vertical span of the tail base
  static const _radius = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(_tailW, 0, size.width - _tailW, size.height),
      const Radius.circular(_radius),
    );
    // tail near the upper-left, tip pointing left (and slightly up) at the robot
    final tailY = size.height * 0.34;
    final tail = Path()
      ..moveTo(_tailW, tailY - _tailSpan * 0.35)
      ..lineTo(0, tailY - _tailSpan * 0.5) // tip
      ..lineTo(_tailW, tailY + _tailSpan * 0.55)
      ..close();

    final path = Path()
      ..addRRect(body)
      ..addPath(tail, Offset.zero);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.45), 6, false);
    canvas.drawPath(path, Paint()..color = _fill);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => false;
}
