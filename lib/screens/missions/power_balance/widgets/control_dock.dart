// Control dock (PRD §10.3) — Solar Align, Camera, Antenna, Thruster. Each button
// swaps its active/inactive sprite, dims when not usable in the current phase,
// and pulses a highlight ring when the tutorial is asking for it (controlHint).
// Portrait translation of the mock's right-edge control cluster.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../models/power_balance_models.dart';
import '../state/power_balance_controller.dart';
import '../state/power_balance_state.dart';
import 'pb_palette.dart';

class ControlDock extends StatelessWidget {
  const ControlDock({super.key, required this.controller, required this.state});

  final PowerBalanceController controller;
  final PowerBalanceState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          label: 'SOLAR',
          // the pack's solar sprites are mislabeled — the "inactive" file is the
          // bright/colourful one, the "active" file is a dull grey panel.
          activeIcon: PB.iconSolarInactive,
          active: state.solarAlign == SolarAlignState.aligned,
          enabled: controller.controlEnabled(ControlHint.solar),
          highlight: state.controlHint == ControlHint.solar,
          accent: PBPalette.solarGold,
          onTap: controller.tapSolar,
        ),
        _ControlButton(
          label: 'CAMERA',
          activeIcon: PB.iconCameraActive,
          active: state.cameraOn,
          enabled: controller.controlEnabled(ControlHint.camera) || state.cameraOn,
          // locked (dimmed + 🔒) while the battery is low, but still tappable so
          // a tap surfaces the "charge first" message.
          locked: state.cameraLocked && !state.cameraOn,
          highlight: state.controlHint == ControlHint.camera,
          accent: PBPalette.skyBlue,
          onTap: controller.toggleCamera,
        ),
        _ControlButton(
          label: 'ANTENNA',
          activeIcon: PB.iconAntennaActive,
          active: state.antennaOn,
          enabled: controller.controlEnabled(ControlHint.antenna) || state.antennaOn,
          highlight: state.controlHint == ControlHint.antenna,
          accent: PBPalette.electricBlue,
          onTap: controller.toggleAntenna,
        ),
        _ControlButton(
          label: 'THRUSTER',
          activeIcon: PB.iconThrusterActive,
          active: false,
          enabled: controller.controlEnabled(ControlHint.none),
          highlight: false,
          accent: PBPalette.warningRed,
          onTap: controller.tapThruster,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.activeIcon,
    required this.active,
    required this.enabled,
    required this.highlight,
    required this.accent,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final String activeIcon;
  final bool active;
  final bool enabled;
  final bool highlight;
  final Color accent;
  final VoidCallback onTap;

  /// Dimmed + a 🔒 badge, but STILL tappable (the tap surfaces a "why" message).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final ringColor = locked
        ? PBPalette.warningRed
        : (active ? accent : (highlight ? accent : PBPalette.panelBorder));
    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      // dims when truly-locked (crisis intro / mid-capture) OR power-locked;
      // otherwise every button stays fully visible so the child decides.
      opacity: (enabled && !locked) ? 1 : 0.55,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PBPalette.panelFill,
              border: Border.all(
                  color: ringColor.withValues(alpha: active || highlight ? 0.9 : 0.6),
                  width: active || highlight ? 2.2 : 1.4),
              boxShadow: active || highlight
                  ? [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: 1)]
                  : null,
            ),
            padding: const EdgeInsets.all(5),
            // always the COLOURED icon — the inactive sprites are desaturated
            // (grey), which read as "broken". On/off is shown by the ring + glow.
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                pbImage(PB.flutter(activeIcon)),
                if (locked)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PBPalette.warningRed,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: CareerText.label.copyWith(
                  fontSize: 7.5,
                  color: active || highlight ? accent : Colors.white60,
                  letterSpacing: 0.6)),
        ],
      ),
    );

    final tappable = PressableScale(
      onTap: enabled ? onTap : () {},
      child: button,
    );
    // a gentle pulse draws the eye to the control the tutorial wants
    return highlight ? Floaty(amplitude: 3, child: tappable) : tappable;
  }
}
