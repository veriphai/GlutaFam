// Power / Signal / Stability meters. Each animates smoothly to its current
// value whenever the controller updates after a part is installed.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../state/build_satellite_controller.dart';

class StatusMeters extends StatelessWidget {
  const StatusMeters({super.key, required this.controller});

  final BuildSatelliteController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return Row(
      children: [
        Expanded(child: _Meter(label: 'Power', value: s.powerLevel, color: CareerColors.blue, icon: Icons.bolt_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _Meter(label: 'Signal', value: s.signalLevel, color: CareerColors.cyan, icon: Icons.wifi_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _Meter(label: 'Stability', value: s.stabilityLevel, color: CareerColors.green, icon: Icons.shield_rounded)),
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value, required this.color, required this.icon});

  final String label;
  final double value; // 0..100
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: CareerText.statLabel.copyWith(color: CareerColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('${v.round()}%',
                style: CareerText.statValue.copyWith(fontSize: 11, color: color)),
          ),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 7,
            color: Colors.white.withValues(alpha: 0.12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (value / 100).clamp(0, 1)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, Color.lerp(color, Colors.white, 0.35)!],
                      ),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
