// Top bar: back chevron, phase-driven title, and a slim progress strip that
// honestly reflects how many of the 9 commands are placed (arranging) or proven
// correct (running). No baked text — all Flutter (PRD §2).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/code_satellite_tuning.dart';
import '../state/code_satellite_state.dart';

class MissionHeader extends StatelessWidget {
  const MissionHeader({super.key, required this.state, required this.onBack});

  final CodeSatelliteState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            PressableScale(
              onTap: onBack,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        if (_showProgress) ...[
          const SizedBox(height: 10),
          _progress(),
        ],
      ],
    );
  }

  // Progress bar only while building — during the run the bottom strip already
  // shows "Step N / 9", and we want maximum stage space.
  bool get _showProgress => state.phase == Activity10Phase.arranging;

  Widget _progress() {
    final total = state.slots.length;
    final done = state.phase == Activity10Phase.arranging
        ? state.filledCount
        : state.correctSteps.length;
    final accent = state.phase == Activity10Phase.failed ? CSColors.orange : CSColors.cyan;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$done / $total',
            style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w800)),
      ],
    );
  }

  String get _title {
    switch (state.phase) {
      case Activity10Phase.storyIntro:
        return 'How does a satellite know what to do?';
      case Activity10Phase.missionBrief:
        return 'Mission Brief';
      case Activity10Phase.arranging:
        return 'Build the command sequence';
      case Activity10Phase.running:
        return ''; // keep only the back button during the run for more space
      case Activity10Phase.failed:
        return "Why didn't that work? Let's debug it!";
      case Activity10Phase.success:
        return 'Mission Complete!';
    }
  }
}
