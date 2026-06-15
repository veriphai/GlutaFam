// Ember — ui/hud/day_night_indicator.dart
//
// The time-of-day dial: a small circular gauge that sweeps a sun/moon marker
// around the day cycle (phase 0..1), tints toward night, shows a night-warning
// pip when predators prowl, and carries a season chip + day counter. Watches the
// day/night slice of the world so it rebuilds each tick the phase moves. Reads
// state only — no mutation.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../art/ember_palette.dart';
import '../../core/enums.dart';
import '../../data/models/day_night_state.dart';
import '../../state/providers.dart';
import '../../state/world_controller.dart';
import '../ember_theme.dart';

/// The compact day/night dial + season chip.
class DayNightIndicator extends ConsumerWidget {
  const DayNightIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmberPalette p = ref.watch(artProvider).palette;
    final DayNightState dn = ref.watch(
      worldControllerProvider.select((s) => s.dayNight),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: EmberUi.panel(p, raised: true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              painter: _DialPainter(dn: dn, palette: p),
            ),
          ),
          const SizedBox(width: EmberUi.gapS),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Day ${dn.dayCount + 1}',
                style: TextStyle(
                  color: p.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              _seasonChip(dn.season, p),
            ],
          ),
          if (dn.isNight) ...<Widget>[
            const SizedBox(width: EmberUi.gapS),
            _nightWarning(p),
          ],
        ],
      ),
    );
  }

  Widget _seasonChip(Season season, EmberPalette p) {
    final (String label, Color tint) = switch (season) {
      Season.warm => ('Warm', p.warning),
      Season.cold => ('Cold', p.cold),
      Season.wet => ('Wet', p.water),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _nightWarning(EmberPalette p) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.night.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: p.danger, width: 1.5),
      ),
      child: Icon(Icons.nightlight_round, color: p.emberBright, size: 16),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.dn, required this.palette});

  final DayNightState dn;
  final EmberPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 2;

    // Dial face tinted toward night by the darkness factor.
    final Color face = Color.lerp(
      palette.emberBright.withValues(alpha: 0.35),
      palette.night,
      dn.isNight ? 0.6 + 0.4 * dn.darkness : 0.0,
    )!;
    canvas.drawCircle(c, r, Paint()..color = face);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Marker sweeps clockwise: phase 0 = dawn at left (-pi), 0.5 = dusk at right.
    final double angle = -math.pi + dn.phase * 2 * math.pi;
    final Offset marker = Offset(
      c.dx + math.cos(angle) * (r - 6),
      c.dy + math.sin(angle) * (r - 6),
    );
    final Color markerColor = dn.isNight ? palette.spark : palette.emberBright;
    canvas.drawCircle(marker, 5, Paint()..color = markerColor);
    canvas.drawCircle(
      marker,
      5,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.dn != dn || old.palette != palette;
}
