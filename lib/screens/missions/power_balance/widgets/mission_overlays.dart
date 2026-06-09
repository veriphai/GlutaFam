// Full-screen overlays: the Scene-0 intro start page (PRD §12 Scene 0), the
// success state (PRD Scene 7), and the kind failure state (PRD Scene 8). Each
// fades over the live stage; the Flame game plays confetti/star-burst behind the
// success panel.

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/power_balance_tuning.dart';
import 'pb_palette.dart';
import '../../../../utils/s3_assets.dart';

class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label, required this.icon, required this.colors, required this.onTap});
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.4),
          boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.55), blurRadius: 18)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: CareerText.cta.copyWith(color: Colors.white, fontSize: 15.5)),
          ],
        ),
      ),
    );
  }
}

/// Scene 0 — emotional, premium mission start.
class IntroOverlay extends StatelessWidget {
  const IntroOverlay({
    super.key,
    required this.onStart,
    required this.onBack,
    required this.introLine,
    required this.startEnabled,
    this.soundOn = true,
    this.onToggleSound,
  });

  final VoidCallback onStart;
  final VoidCallback onBack;
  final bool soundOn;
  final VoidCallback? onToggleSound;

  /// Which welcome line Orbit is on — owned by the screen so the bubble stays
  /// in sync with the voice clips (advance on completion; timer when muted).
  final ValueListenable<int> introLine;

  /// Listen-before-skip gate: Start stays dim + tap-blocked until Orbit has
  /// finished the last welcome line (or its reading time when muted).
  final ValueListenable<bool> startEnabled;

  // warm gold title that complements the orange sun flare in the background art
  static const _titleGold = Color(0xFFF4E3A8);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // full-screen story background (satellite + battery-critical badge +
        // cyclone on Earth are baked into the art).
        netImageWidget(
          PB.flutter(PB.introBg),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: PBPalette.deepSpace),
        ),
        // legibility scrims: dark at the top (title) + bottom (mascot + CTA).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3040A18), Color(0x00000000), Color(0x00000000), Color(0xF2020509)],
              stops: [0.0, 0.18, 0.50, 1.0],
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
                    _circleBtn(Icons.arrow_back_rounded, onBack),
                    const Spacer(),
                    _circleBtn(soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        onToggleSound ?? () {}),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              RevealOnLoad(
                child: Column(
                  children: [
                    Text(
                      PBTune.introTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: CareerText.heroTitle.copyWith(
                        fontSize: 34,
                        height: 1.0,
                        letterSpacing: 1.5,
                        color: _titleGold,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(PBTune.introSubtitle,
                        textAlign: TextAlign.center,
                        style: CareerText.body.copyWith(fontSize: 13, color: Colors.white)),
                  ],
                ),
              ),
              const Spacer(), // the background art shows through here
              // mascot + speech bubble
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Floaty(
                      amplitude: 4,
                      child: pbImage(PB.flutter(PB.orbitWelcoming), width: 116, height: 150),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _OrbitBubble(line: introLine),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _startButton(),
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

  Widget _startButton() => ValueListenableBuilder<bool>(
        valueListenable: startEnabled,
        builder: (context, enabled, _) => IgnorePointer(
          // dim alone is a UX trap — actually block taps until Orbit finishes
          ignoring: !enabled,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: enabled ? 1.0 : 0.45,
            child: PressableScale(
              onTap: onStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                decoration: BoxDecoration(
                  gradient: CareerGradients.gold,
                  borderRadius: BorderRadius.circular(CareerRadii.pill),
                  boxShadow: [
                    if (enabled)
                      BoxShadow(
                          color: CareerColors.gold.withValues(alpha: 0.5),
                          blurRadius: 22,
                          offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch_rounded,
                        size: 18, color: CareerColors.onLight),
                    const SizedBox(width: 8),
                    Text('Start Mission',
                        style: CareerText.cta.copyWith(
                            color: CareerColors.onLight,
                            fontSize: 14.5,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// Orbit's intro bubble — shows the welcome line the screen says we're on
/// (advanced by voice completion, or a reading-time timer when muted), with a
/// soft fade + resize between lines.
class _OrbitBubble extends StatelessWidget {
  const _OrbitBubble({required this.line});

  final ValueListenable<int> line;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: line,
      builder: (context, i, _) => CustomPaint(
        painter: _IntroBubblePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 15, 12),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                PBTune.introLines[i % PBTune.introLines.length],
                key: ValueKey(i),
                style: CareerText.body.copyWith(
                    color: CareerColors.onLight,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A cream speech bubble with a tail on the left pointing toward the mascot.
class _IntroBubblePainter extends CustomPainter {
  static const _fill = Color(0xFFF2ECDA);
  static const _tail = 11.0;
  static const _radius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.5;
    final body = RRect.fromLTRBR(_tail, 0, size.width, size.height, const Radius.circular(_radius));
    final path = Path()..addRRect(body);
    path
      ..moveTo(_tail, cy - 11)
      ..lineTo(0, cy)
      ..lineTo(_tail, cy + 11)
      ..close();
    canvas.drawShadow(path, Colors.black, 5, false);
    canvas.drawPath(path, Paint()..color = _fill);
  }

  @override
  bool shouldRepaint(_IntroBubblePainter oldDelegate) => false;
}

/// Scene 7 — success.
class SuccessOverlay extends StatelessWidget {
  const SuccessOverlay({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PBPalette.deepSpace.withValues(alpha: 0.66),
      child: SafeArea(
        child: Center(
          child: RevealOnLoad(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xF00C2A1E), Color(0xF0081226)],
                ),
                borderRadius: BorderRadius.circular(CareerRadii.card),
                border: Border.all(color: PBPalette.successGreen.withValues(alpha: 0.7), width: 1.6),
                boxShadow: [BoxShadow(color: PBPalette.successGreen.withValues(alpha: 0.4), blurRadius: 26)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  pbImage(PB.flutter(PB.missionCompleteBadge), width: 130, height: 130),
                  const SizedBox(height: 6),
                  Text('MISSION SUCCESS',
                      style: CareerText.heroTitle.copyWith(
                          color: PBPalette.successGreen, fontSize: 22, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Text(PBTune.successLine,
                      textAlign: TextAlign.center,
                      style: CareerText.body.copyWith(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(PBTune.success2,
                      textAlign: TextAlign.center,
                      style: CareerText.body.copyWith(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(PBTune.success3,
                      textAlign: TextAlign.center,
                      style: CareerText.body.copyWith(
                          color: PBPalette.successGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 22),
                  _CtaPill(
                    label: 'Continue',
                    icon: Icons.check_rounded,
                    colors: const [Color(0xFF34D17E), Color(0xFF17A95C)],
                    onTap: onDone,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scene 8 — kind failure (no harsh tone, PRD §20).
class FailureOverlay extends StatelessWidget {
  const FailureOverlay({super.key, required this.onRetry, required this.onExit});
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PBPalette.deepSpace.withValues(alpha: 0.8),
      child: SafeArea(
        child: Center(
          child: RevealOnLoad(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xF0241024), Color(0xF0081226)],
                ),
                borderRadius: BorderRadius.circular(CareerRadii.card),
                border: Border.all(color: PBPalette.warningRed.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [BoxShadow(color: PBPalette.warningRed.withValues(alpha: 0.3), blurRadius: 24)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  pbImage(PB.flutter(PB.missionFailedBadge), width: 120, height: 120),
                  const SizedBox(height: 8),
                  Text('OUT OF POWER',
                      style: CareerText.heroTitle.copyWith(
                          color: PBPalette.warningRed, fontSize: 20)),
                  const SizedBox(height: 12),
                  Text(PBTune.failureLine,
                      textAlign: TextAlign.center,
                      style: CareerText.body.copyWith(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(PBTune.failureHint,
                      textAlign: TextAlign.center,
                      style: CareerText.body.copyWith(color: CareerColors.textSecondary, fontSize: 11.5)),
                  const SizedBox(height: 14),
                  pbImage(PB.flutter(PB.retryBadge), width: 60, height: 60),
                  const SizedBox(height: 12),
                  _CtaPill(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    colors: const [Color(0xFF3D8BFF), Color(0xFF2270FF)],
                    onTap: onRetry,
                  ),
                  const SizedBox(height: 10),
                  PressableScale(
                    onTap: onExit,
                    child: Text('Exit mission',
                        style: CareerText.body.copyWith(
                            color: CareerColors.textMuted, fontSize: 12, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
