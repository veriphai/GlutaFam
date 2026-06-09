// Flutter-drawn command card — ONE frame, state-tinted per the styleboard
// palette, with the command's icon cut-out + a Flutter text label. (The baked
// block sprites ship at mismatched sizes, so per the playbook we draw the frame
// here and only use the icon art — every card is pixel-identical bar its icon.)
//
// Used for tray blocks, placed blocks, and the drag feedback. Visual state is
// expressed through border colour + glow + a subtle fill, never colour alone
// (a11y, PRD §19) — active/correct/error also carry an icon badge.

import 'package:flutter/material.dart';

import '../config/code_satellite_tuning.dart';
import '../models/satellite_command.dart';
import '../../../../utils/s3_assets.dart';

enum CommandCardStyle { idle, dragging, active, correct, error, ghost }

class CommandCard extends StatelessWidget {
  const CommandCard({
    super.key,
    required this.command,
    this.style = CommandCardStyle.idle,
    this.stepNumber,
    this.width = 96,
    this.height = 108,
  });

  /// Null renders an empty "drop here" slot (style should be ghost/active).
  final SatelliteCommand? command;
  final CommandCardStyle style;
  final int? stepNumber;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final filled = command != null;

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: filled
                ? [const Color(0xFF15224A), const Color(0xFF0E1633)]
                : [Colors.white.withValues(alpha: 0.04), Colors.white.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: style == CommandCardStyle.ghost ? 0.4 : 0.9),
            width: style == CommandCardStyle.idle ? 1.4 : 2.2,
          ),
          boxShadow: style == CommandCardStyle.idle || style == CommandCardStyle.ghost
              ? null
              : [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: 0.5)],
        ),
        child: filled ? _content(accent) : _emptyContent(accent),
      ),
    );
  }

  Widget _content(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (stepNumber != null) _numberBadge(accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: netImageWidget(command!.iconAsset, fit: BoxFit.contain),
            ),
          ),
          Text(
            command!.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              height: 1.1,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
          ),
          if (style == CommandCardStyle.correct || style == CommandCardStyle.error)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                style == CommandCardStyle.correct ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 15,
                color: accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyContent(Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (stepNumber != null) _numberBadge(accent),
        const SizedBox(height: 6),
        Icon(Icons.touch_app_rounded, size: 22, color: accent.withValues(alpha: 0.8)),
        const SizedBox(height: 4),
        Text(
          'Tap a\nblock',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent.withValues(alpha: 0.85),
            fontSize: 10,
            height: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _numberBadge(Color accent) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.18),
        border: Border.all(color: accent, width: 1.4),
      ),
      child: Text(
        '$stepNumber',
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Color get _accent {
    switch (style) {
      case CommandCardStyle.idle:
      case CommandCardStyle.dragging:
        return CSColors.cyan;
      case CommandCardStyle.active:
        return CSColors.yellow;
      case CommandCardStyle.correct:
        return CSColors.green;
      case CommandCardStyle.error:
        return CSColors.red;
      case CommandCardStyle.ghost:
        return CSColors.blue;
    }
  }
}
