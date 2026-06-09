// Mission progress strip (PRD §10.3): "Mission N / 5" + five segment bars.
// Completed = green, current = pulsing cyan, upcoming = dim.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';

class MissionProgress extends StatefulWidget {
  const MissionProgress({
    super.key,
    required this.total,
    required this.completed,
    required this.currentIndex,
  });

  final int total;
  final int completed;
  final int currentIndex;

  @override
  State<MissionProgress> createState() => _MissionProgressState();
}

class _MissionProgressState extends State<MissionProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('MISSION ',
              style: CareerText.label
                  .copyWith(fontSize: 9.5, letterSpacing: 1.4, color: CareerColors.textSecondary)),
          Text('${math.min(widget.currentIndex + 1, widget.total)} / ${widget.total}',
              style: CareerText.statValue.copyWith(fontSize: 12, color: CareerColors.cyan)),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final pulse = 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
                return Row(
                  children: List.generate(widget.total, (i) {
                    final done = i < widget.completed;
                    final current = i == widget.currentIndex && !done;
                    final color = done
                        ? CareerColors.green
                        : current
                            ? Color.lerp(CareerColors.cyan.withValues(alpha: 0.4),
                                CareerColors.cyan, pulse)!
                            : CareerColors.glassBorder;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i == widget.total - 1 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: (done || current)
                              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                              : null,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
