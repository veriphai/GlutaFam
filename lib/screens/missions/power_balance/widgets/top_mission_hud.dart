// Top mission HUD (PRD §10.1) — title bar, battery pill with state icon, the
// Images/Data objective counters, and an optional zone badge. Pure Flutter,
// reads the immutable state. Portrait translation of the mock's top strip.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/power_balance_tuning.dart';
import '../models/power_balance_models.dart';
import '../state/power_balance_state.dart';
import 'pb_palette.dart';

class TopMissionHud extends StatelessWidget {
  const TopMissionHud(
      {super.key, required this.state, required this.onBack, this.onImagesTap});

  final PowerBalanceState state;
  final VoidCallback onBack;

  /// Tapping the IMAGES counter opens the captured-images gallery (when any).
  final VoidCallback? onImagesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // title row
        Row(
          children: [
            PressableScale(
              onTap: onBack,
              child: GlassSurface(
                radius: 12,
                padding: const EdgeInsets.all(7),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 18, color: CareerColors.textPrimary),
              ),
            ),
            const SizedBox(width: 10),
            // Title only on the (pre-start) intro; once playing it's removed so
            // the stage stays clean — just the back button, battery + zone badge.
            if (state.isPlaying)
              const Spacer()
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EPISODE 6',
                        style: CareerText.label.copyWith(
                            color: PBPalette.skyBlue, fontSize: 8, letterSpacing: 1.4)),
                    Text('Keep the Satellite Alive',
                        style: CareerText.greeting.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            ZoneBadge(zone: state.currentZone, shown: state.isPlaying),
          ],
        ),
        const SizedBox(height: 10),
        // battery + counters row
        Row(
          children: [
            BatteryPill(state: state),
            const Spacer(),
            ObjectiveCounters(state: state, onImagesTap: onImagesTap),
          ],
        ),
      ],
    );
  }
}

class BatteryPill extends StatelessWidget {
  const BatteryPill({super.key, required this.state});

  final PowerBalanceState state;

  String get _icon {
    if (state.phase == MissionPhase.failure || state.batteryPercent <= 0) return PB.batEmpty;
    if (state.isCharging) return PB.batCharging;
    final b = state.batteryPercent;
    if (b >= 80) return PB.batFull;
    if (b >= 50) return PB.batHigh;
    if (b >= 25) return PB.batMedium;
    if (b >= 10) return PB.batLow;
    return PB.batCritical;
  }

  Color get _accent {
    if (state.isCharging) return PBPalette.solarGold;
    if (state.batteryPercent <= PBTune.criticalThreshold) return PBPalette.warningRed;
    if (state.batteryPercent <= PBTune.lowThreshold) return PBPalette.solarGold;
    return PBPalette.successGreen;
  }

  @override
  Widget build(BuildContext context) {
    final pct = state.batteryPercent.round();
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
      decoration: BoxDecoration(
        color: PBPalette.panelFill,
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(color: _accent.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pbImage(PB.flutter(_icon), width: 30, height: 30),
          const SizedBox(width: 6),
          // animated number so battery changes read as smooth (PRD §17) — omitting
          // `begin` lets it tween from the previously-rendered value to the new one.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: pct.toDouble()),
            duration: const Duration(milliseconds: 300),
            builder: (_, v, __) => Text('${v.round()}%',
                style: CareerText.statValue.copyWith(color: _accent, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class ObjectiveCounters extends StatelessWidget {
  const ObjectiveCounters({super.key, required this.state, this.onImagesTap});

  final PowerBalanceState state;
  final VoidCallback? onImagesTap;

  @override
  Widget build(BuildContext context) {
    final canView = onImagesTap != null && state.imagesCaptured > 0;
    final images = _counter(
        Icons.photo_camera_rounded, 'IMAGES', state.imagesCaptured, PBPalette.skyBlue,
        viewable: canView);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // tap to open the gallery once at least one image exists
        canView ? PressableScale(onTap: onImagesTap, child: images) : images,
        const SizedBox(height: 6),
        _counter(Icons.wifi_tethering_rounded, 'DATA', state.dataSent, PBPalette.electricBlue),
      ],
    );
  }

  Widget _counter(IconData icon, String label, int value, Color accent, {bool viewable = false}) {
    final done = value >= PBTune.imagesNeeded;
    final tint = done ? PBPalette.successGreen : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: PBPalette.panelFill,
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(color: tint.withValues(alpha: viewable ? 0.85 : 0.5), width: viewable ? 1.5 : 1.2),
        boxShadow: viewable
            ? [BoxShadow(color: tint.withValues(alpha: 0.4), blurRadius: 10)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 5),
          Text(label, style: CareerText.label.copyWith(fontSize: 8, color: Colors.white70)),
          const SizedBox(width: 6),
          Text('$value/${PBTune.imagesNeeded}',
              style: CareerText.statValue.copyWith(fontSize: 12.5, color: tint)),
          if (viewable) ...[
            const SizedBox(width: 4),
            Icon(Icons.visibility_rounded, size: 12, color: tint),
          ],
        ],
      ),
    );
  }
}

class ZoneBadge extends StatelessWidget {
  const ZoneBadge({super.key, required this.zone, required this.shown});

  final OrbitZone zone;
  final bool shown;

  Color get _c => switch (zone) {
        OrbitZone.sunlight => PBPalette.solarGold,
        OrbitZone.cycloneTarget => PBPalette.skyBlue,
        OrbitZone.groundStationRange => PBPalette.electricBlue,
        OrbitZone.shadow => const Color(0xFF6C7BDC),
      };

  IconData get _icon => switch (zone) {
        OrbitZone.sunlight => Icons.wb_sunny_rounded,
        OrbitZone.cycloneTarget => Icons.cyclone_rounded,
        OrbitZone.groundStationRange => Icons.settings_input_antenna_rounded,
        OrbitZone.shadow => Icons.nightlight_round,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          border: Border.all(color: _c.withValues(alpha: 0.6), width: 1.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 12, color: _c),
            const SizedBox(width: 4),
            Text(zone.label, style: CareerText.label.copyWith(fontSize: 7.5, color: _c)),
          ],
        ),
      ),
    );
  }
}
