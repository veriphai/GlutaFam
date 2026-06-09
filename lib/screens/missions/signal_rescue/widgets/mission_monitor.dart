// Mission Control monitor — a Flutter glass panel (matches the design board; all
// text is Flutter). Two modes:
//   • COMPACT (default): a slim status strip — just "MISSION CONTROL … <status>"
//     — so the Earth + ground station stay visible during play.
//   • EXPANDED (while receiving): the full screen, showing static → a bottom-up
//     reveal of the cyclone image with a scan line at the reveal edge.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../state/signal_rescue_state.dart';
import '../../../../utils/s3_assets.dart';

class MissionMonitor extends StatelessWidget {
  const MissionMonitor({super.key, required this.state, this.expanded = false});

  final SignalRescueState state;
  final bool expanded;

  ({String text, Color color, IconData? icon}) get _status {
    switch (state.phase) {
      case MissionPhase.dataLocked:
        return (text: 'DATA LOCKED', color: const Color(0xFF35B6FF), icon: Icons.lock_rounded);
      case MissionPhase.transmitting:
        return (text: 'RECEIVING… ${(state.transmissionProgress * 100).round()}%',
            color: const Color(0xFF35B6FF), icon: Icons.cloud_download_rounded);
      case MissionPhase.success:
        return (text: 'TRANSMISSION COMPLETE', color: const Color(0xFF49E06B), icon: Icons.check_circle_rounded);
      default:
        return (text: 'NO SIGNAL YET', color: const Color(0xFF7E8AC0), icon: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1730).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.color.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [BoxShadow(color: s.color.withValues(alpha: 0.22), blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MISSION CONTROL',
                  style: CareerText.label.copyWith(color: CareerColors.cyan, fontSize: 9.5)),
              const Spacer(),
              if (s.icon != null) Icon(s.icon, size: 14, color: s.color),
              const SizedBox(width: 5),
              Text(s.text, style: CareerText.label.copyWith(color: s.color, fontSize: 9.5)),
            ],
          ),
          // The screen only renders when expanded (while receiving). AnimatedSize
          // in the shell makes the panel grow/shrink smoothly.
          if (expanded) ...[
            const SizedBox(height: 7),
            _Screen(state: state),
          ],
        ],
      ),
    );
  }
}

class _Screen extends StatelessWidget {
  const _Screen({required this.state});

  final SignalRescueState state;

  @override
  Widget build(BuildContext context) {
    final reveal = state.monitorRevealProgress.clamp(0.0, 1.0);
    final showImage = reveal > 0.001;
    final color = state.phase == MissionPhase.success
        ? const Color(0xFF49E06B)
        : const Color(0xFF35B6FF);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: (1 - reveal).clamp(0.0, 1.0),
              child: netImageWidget(SR.flutter(SR.monitorStatic), fit: BoxFit.cover),
            ),
            if (showImage)
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: reveal,
                  widthFactor: 1,
                  child: netImageWidget(SR.flutter(SR.cycloneFull), fit: BoxFit.cover),
                ),
              ),
            if (showImage && reveal < 0.999)
              Align(
                alignment: Alignment(0, 1 - reveal * 2),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 8)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
