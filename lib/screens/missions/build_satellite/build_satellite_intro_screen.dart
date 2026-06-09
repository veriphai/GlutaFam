// Cover-art intro SCENE (no audio plumbing here). Lives as a Widget the
// gameplay screen swaps in/out via AnimatedSwitcher — one BGM player owns
// the whole activity lifetime so the bed doesn't restart between intro and
// gameplay. Tapping Start Mission calls [onStart]; audio is started AND
// stopped by the gameplay screen.
//
// The `BuildSatelliteIntroScreen` alias is kept so existing route imports
// (lesson runner, activities registry) keep compiling. It just renders the
// gameplay screen, which shows this intro scene first.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import 'build_satellite_screen.dart';
import '../../../utils/s3_assets.dart';

/// Back-compat shim — the route that used to push this now pushes the
/// gameplay screen, which renders the intro scene as its first phase.
class BuildSatelliteIntroScreen extends StatelessWidget {
  const BuildSatelliteIntroScreen({super.key});

  @override
  Widget build(BuildContext context) => const BuildSatelliteScreen();
}

/// Pure layout for the cover-art intro. Hosted by the gameplay screen via
/// AnimatedSwitcher. `onStart` flips the screen's `_introVisible` flag —
/// the screen does NOT navigate, so the BGM player keeps playing.
class BuildSatelliteIntroScene extends StatelessWidget {
  const BuildSatelliteIntroScene({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Stack(
        children: [
          // Hero art shown un-cropped (BoxFit.contain).
          Positioned.fill(
            child: Image(
              image: netImage('assets/images/build_satellite/intro_background.png'),
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          // Top + bottom soft darkening so both ends are legible.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC02040E),
                      Color(0x6602040E),
                      Color(0x00000000),
                      Color(0x6602040E),
                      Color(0xEE02040E),
                    ],
                    stops: [0.0, 0.18, 0.5, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    children: [
                      PressableScale(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: GlassSurface(
                          radius: 14,
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 20, color: CareerColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Build Your Satellite',
                              style: CareerText.heroTitle.copyWith(fontSize: 36),
                              textAlign: TextAlign.center)
                          .animate()
                          .fadeIn(duration: 480.ms, delay: 140.ms),
                      const SizedBox(height: 10),
                      Text(
                        'Assemble all seven systems — power, signal, brain, eyes and more — and bring your first satellite to life.',
                        style: CareerText.body.copyWith(
                            color: CareerColors.textSecondary,
                            fontSize: 16,
                            height: 1.4),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 480.ms, delay: 220.ms),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OrbitInvite()
                          .animate()
                          .fadeIn(duration: 480.ms, delay: 320.ms)
                          .slideY(
                              begin: 0.2,
                              end: 0,
                              duration: 480.ms,
                              curve: Curves.easeOutCubic),
                      const SizedBox(height: 18),
                      _StartButton(onTap: onStart)
                          .animate()
                          .fadeIn(duration: 480.ms, delay: 420.ms)
                          .scaleXY(
                              begin: 0.92,
                              end: 1.0,
                              duration: 480.ms,
                              curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitInvite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Floaty(
          amplitude: 5,
          child: netImageWidget(
            'assets/images/build_satellite/mascot/orbit_welcoming.png',
            height: 96,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: CustomPaint(
            painter: const _BubblePainter(accent: CareerColors.cyan),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 16, 14),
              child: Text(
                'Ready to build your first satellite?',
                style: CareerText.body.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.32,
                    fontWeight: FontWeight.w600),
                maxLines: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.accent});
  final Color accent;

  static const double _tail = 13;
  static const double _radius = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(RRect.fromLTRBR(
          _tail, 0, size.width, size.height, const Radius.circular(_radius)));
    final cy = size.height * 0.5;
    final tri = Path()
      ..moveTo(_tail + 0.5, cy - 12)
      ..lineTo(0, cy)
      ..lineTo(_tail + 0.5, cy + 12)
      ..close();
    final shape = Path.combine(PathOperation.union, body, tri);

    canvas.drawPath(
      shape,
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE60B2147), Color(0xE6081226)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.accent != accent;
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [CareerColors.cyan, CareerColors.purple],
          ),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(
                color: CareerColors.blue.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start Mission',
                style: CareerText.cta.copyWith(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
