// The command tray — a horizontal strip of the unplaced command blocks. The
// child TAPS the correct block; it turns green in place, then flies into the
// active slot (the scene runs the flight). A horizontal swipe still scrolls.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/code_satellite_tuning.dart';
import '../models/satellite_command.dart';
import '../state/code_satellite_state.dart';
import 'command_block.dart';

class CommandTray extends StatelessWidget {
  const CommandTray({
    super.key,
    required this.state,
    required this.onTapCommand,
    required this.keyFor,
    this.selecting,
    this.hidden,
    this.wrong,
    this.wrongPulse,
  });

  final CodeSatelliteState state;
  final void Function(SatelliteCommand) onTapCommand;
  final GlobalKey Function(SatelliteCommand) keyFor;

  /// Command shown green in place (just tapped, about to fly).
  final SatelliteCommand? selecting;

  /// Command hidden because it's currently flying to its slot (keeps layout).
  final SatelliteCommand? hidden;

  /// Command tapped at the wrong time — shown with a red border + shake.
  final SatelliteCommand? wrong;
  final Animation<double>? wrongPulse;

  static const _cardW = 92.0;
  static const _cardH = 104.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _cardH + 22,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: state.tray.isEmpty
          ? _emptyHint()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              itemCount: state.tray.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _trayCard(state.tray[i]),
            ),
    );
  }

  Widget _emptyHint() => Center(
        child: Text(
          'All commands placed — press Run Mission!',
          style: TextStyle(
            color: CSColors.teal,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _trayCard(SatelliteCommand command) {
    final isSelecting = command == selecting;
    final isHidden = command == hidden;
    final isWrong = command == wrong;

    final style = isSelecting
        ? CommandCardStyle.correct
        : isWrong
            ? CommandCardStyle.error
            : CommandCardStyle.idle;

    Widget card = CommandCard(
      command: command,
      style: style,
      width: _cardW,
      height: _cardH,
    );

    // Wrong tap: shrink-and-shake the card while its red border shows.
    if (isWrong && wrongPulse != null) {
      card = AnimatedBuilder(
        animation: wrongPulse!,
        child: card,
        builder: (_, c) {
          final v = wrongPulse!.value; // 0 → 1
          final scale = 1 - 0.12 * math.sin(math.pi * v); // dip to ~0.88 then back
          final dx = 6 * math.sin(v * math.pi * 4) * (1 - v); // decaying shake
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: scale, child: c),
          );
        },
      );
    }

    return Opacity(
      // hide (but keep the layout slot) while this card is flying.
      opacity: isHidden ? 0 : 1,
      child: KeyedSubtree(
        key: keyFor(command),
        child: PressableScale(
          onTap: () => onTapCommand(command),
          child: Semantics(
            label: 'Command block: ${command.label}. Tap to place it in the mission sequence.',
            button: true,
            child: card,
          ),
        ),
      ),
    );
  }
}
