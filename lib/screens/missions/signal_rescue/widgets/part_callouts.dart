// Explain-parts callouts (Phase 1). Flutter labels anchored over the Flame stage
// by factor positions, revealing one part at a time as the controller steps
// through them. Pure Flutter text — no sprite labels.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';

class PartCallouts extends StatelessWidget {
  const PartCallouts({super.key, required this.step});

  /// 0 = antenna, 1 = ground station, 2 = data packets. Earlier ones stay shown.
  final int step;

  // factor anchors over the stage (align coordinates, -1..1)
  static const _items = [
    (label: 'ANTENNA', align: Alignment(-0.05, -0.62), icon: Icons.settings_input_antenna_rounded),
    (label: 'GROUND STATION', align: Alignment(0.0, 0.12), icon: Icons.cell_tower_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < _items.length; i++)
          if (i <= step)
            Align(
              alignment: _items[i].align,
              child: _Chip(label: _items[i].label, icon: _items[i].icon, active: i == step),
            ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, required this.active});

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = active ? CareerColors.cyan : CareerColors.textMuted;
    return AnimatedScale(
      scale: active ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1E3C).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.8), width: 1.4),
          boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 12)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
            Text(label, style: CareerText.label.copyWith(color: c, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
