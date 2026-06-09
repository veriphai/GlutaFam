// Bottom result card. Covers the straight-up failure (GOT IT → tilt unlock) and
// the five mission outcomes (TRY AGAIN on fails / AWESOME on orbit). Copy is
// verbatim from the PRD V2 copy deck (§16).

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../state/orbit_launcher_controller.dart';
import '../state/orbit_launcher_state.dart';
import 'orbit_button.dart';

class _CardSpec {
  final List<Color> card; // outcome ACCENT gradient (badge / border / glow)
  final List<Color> button;
  final IconData icon; // outcome badge glyph
  final String headline;
  final String message;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback action;
  const _CardSpec({
    required this.card,
    required this.button,
    required this.icon,
    required this.headline,
    required this.message,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.action,
  });
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.controller, this.onOrbitFinish});

  final OrbitLauncherController controller;

  /// What "Orbit Locked → AWESOME!" does. Defaults to entering the bridge
  /// screen; the shell currently passes an exit callback because the bridge
  /// (next-activity) screen is temporarily disabled.
  final VoidCallback? onOrbitFinish;

  static const _red = [Color(0xFFE0573D), Color(0xFFB22F1E)];
  static const _redBtn = [Color(0xFFFF6A4D), Color(0xFFD63B27)];
  static const _orange = [Color(0xFFF0A92B), Color(0xFFCF7E12)];
  static const _orangeBtn = [Color(0xFFFFC247), Color(0xFFE6951C)];
  static const _redOrange = [Color(0xFFE0653A), Color(0xFFC23E1E)];
  static const _redOrangeBtn = [Color(0xFFFF7A4D), Color(0xFFE04A27)];
  static const _purple = [Color(0xFF8A4BE0), Color(0xFF5E2BAE)];
  static const _purpleBtn = [Color(0xFFA467F0), Color(0xFF6E34C9)];
  static const _amber = [Color(0xFFE0A52A), Color(0xFFBE7E12)];
  static const _amberBtn = [Color(0xFFFFCE4A), Color(0xFFEFA21C)];
  static const _green = [Color(0xFF1E9E6E), Color(0xFF137C57)];
  static const _greenBtn = [Color(0xFF34D17E), Color(0xFF17A95C)];

  _CardSpec? _spec() {
    switch (controller.state.scene) {
      case OrbitActivityState.straightLaunchFailed:
        return _CardSpec(
          card: _red,
          button: _redBtn,
          icon: Icons.south_rounded,
          headline: 'Oops! It fell back.',
          message: 'We need more than going up.',
          buttonLabel: 'Got it',
          buttonIcon: Icons.arrow_forward_rounded,
          action: controller.gotIt,
        );
      case OrbitActivityState.notEnoughPower:
        return _CardSpec(
          card: _red,
          button: _redBtn,
          icon: Icons.bolt_rounded,
          headline: 'Not Enough Power!',
          message: 'Increase launch power.',
          buttonLabel: 'Try Again',
          buttonIcon: Icons.refresh_rounded,
          action: controller.tryAgain,
        );
      case OrbitActivityState.tooStraight:
        return _CardSpec(
          card: _orange,
          button: _orangeBtn,
          icon: Icons.north_rounded,
          headline: 'Too Straight!',
          message: 'Add more tilt.',
          buttonLabel: 'Try Again',
          buttonIcon: Icons.refresh_rounded,
          action: controller.tryAgain,
        );
      case OrbitActivityState.tooMuchTilt:
        return _CardSpec(
          card: _redOrange,
          button: _redOrangeBtn,
          icon: Icons.rotate_right_rounded,
          headline: 'Too Much Tilt!',
          message: 'Use a little less tilt.',
          buttonLabel: 'Try Again',
          buttonIcon: Icons.refresh_rounded,
          action: controller.tryAgain,
        );
      case OrbitActivityState.tooFast:
        return _CardSpec(
          card: _purple,
          button: _purpleBtn,
          icon: Icons.speed_rounded,
          headline: 'Too Fast!',
          message: 'Reduce power or tilt.',
          buttonLabel: 'Try Again',
          buttonIcon: Icons.refresh_rounded,
          action: controller.tryAgain,
        );
      case OrbitActivityState.almost:
        return _CardSpec(
          card: _amber,
          button: _amberBtn,
          icon: Icons.adjust_rounded,
          headline: 'Almost Orbit!',
          message: 'Make a small adjustment.',
          buttonLabel: 'Try Again',
          buttonIcon: Icons.refresh_rounded,
          action: controller.tryAgain,
        );
      case OrbitActivityState.orbitLocked:
        return _CardSpec(
          card: _green,
          button: _greenBtn,
          icon: Icons.check_circle_rounded,
          headline: 'Orbit Locked!',
          message: 'Gravity keeps pulling it into the curve.',
          buttonLabel: 'Awesome!',
          buttonIcon: Icons.arrow_forward_rounded,
          action: onOrbitFinish ?? controller.awesome,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec();
    if (spec == null) return const SizedBox.shrink();
    final accent = spec.card.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        // premium dark glass (matches the activity's panels) with a coloured
        // outcome accent: hairline border + soft outer glow + inner sheen
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF7142450), Color(0xF7091632)],
        ),
        borderRadius: BorderRadius.circular(CareerRadii.card),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.32), blurRadius: 26, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // outcome badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight, colors: spec.card),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 16)],
            ),
            child: Icon(spec.icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(spec.headline,
              textAlign: TextAlign.center,
              style: CareerText.heroTitle.copyWith(fontSize: 21, color: Colors.white, letterSpacing: 0.2)),
          const SizedBox(height: 5),
          Text(spec.message,
              textAlign: TextAlign.center,
              style: CareerText.body.copyWith(
                  color: CareerColors.textSecondary, fontSize: 13, height: 1.3, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          OrbitButton(
            label: spec.buttonLabel,
            colors: spec.button,
            leadingIcon: spec.buttonIcon == Icons.refresh_rounded ? spec.buttonIcon : null,
            trailingIcon: spec.buttonIcon == Icons.arrow_forward_rounded ? spec.buttonIcon : null,
            onTap: spec.action,
            pulse: false,
            fontSize: 16,
            // wait for Orbit to finish explaining before moving on
            enabled: !controller.state.voicePlaying,
          ),
        ],
      ),
    );
  }
}
