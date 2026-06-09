// The 9-step command sequence as a horizontal scrolling timeline (mockup 2):
// numbered slots connected by arrows. Guided learning — slots fill strictly
// left-to-right: placed slots lock green, the next slot glows as the active drop
// target (the only one that accepts), and future slots are dimmed/locked. A
// wrong drop flashes the active slot red (driven by state.wrongSlotIndex).
// During the run, the executing step highlights and auto-scrolls into view.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/code_satellite_tuning.dart';
import '../models/satellite_command.dart';
import '../state/code_satellite_controller.dart';
import '../state/code_satellite_state.dart';
import 'command_block.dart';

class CommandTimeline extends StatefulWidget {
  const CommandTimeline({
    super.key,
    required this.state,
    required this.controller,
    this.activeSlotKey,
  });

  final CodeSatelliteState state;
  final CodeSatelliteController controller;

  /// Attached to the active arranging slot so the scene can locate it for the
  /// fly-in animation.
  final GlobalKey? activeSlotKey;

  @override
  State<CommandTimeline> createState() => _CommandTimelineState();
}

class _CommandTimelineState extends State<CommandTimeline>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  static const _cardW = 96.0;
  static const _cardH = 108.0;
  static const _arrowW = 26.0;

  // One-shot "snap" pop on the slot a block just landed in (so a correct tap
  // visibly + tactilely registers, even though the tray card disappears).
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  int _poppedIndex = -1;

  int? _focus(CodeSatelliteState s) =>
      s.activeStepIndex ?? s.failedStepIndex ?? s.activeSlotIndex;

  @override
  void didUpdateWidget(CommandTimeline old) {
    super.didUpdateWidget(old);
    final active = _focus(widget.state);
    if (active != null && active != _focus(old.state)) {
      _scrollTo(active);
    }
    // A new block was just placed → pop that slot.
    final f = widget.state.filledCount;
    if (f > old.state.filledCount &&
        widget.state.phase == Activity10Phase.arranging &&
        f > 0) {
      _poppedIndex = f - 1;
      _pop.forward(from: 0);
    }
  }

  Widget _withPop(int index, Widget child) {
    if (index != _poppedIndex) return child;
    return AnimatedBuilder(
      animation: _pop,
      child: child,
      builder: (_, c) =>
          Transform.scale(scale: 1 + 0.28 * math.sin(math.pi * _pop.value), child: c),
    );
  }

  void _scrollTo(int index) {
    if (!_scroll.hasClients) return;
    final target = index * (_cardW + _arrowW) - 120;
    _scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pop.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return SizedBox(
      height: _cardH + 8,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: s.slots.length * 2 - 1,
        itemBuilder: (context, i) {
          if (i.isOdd) return _arrow();
          final slotIndex = i ~/ 2;
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _slot(slotIndex),
          );
        },
      ),
    );
  }

  Widget _arrow() => SizedBox(
        width: _arrowW,
        height: _cardH,
        child: Center(
          child: Icon(Icons.chevron_right_rounded,
              size: 22, color: CSColors.cyan.withValues(alpha: 0.55)),
        ),
      );

  Widget _slot(int index) {
    final s = widget.state;
    final command = s.slots[index];
    final isFailed = s.failedStepIndex == index;
    final isWrong = s.wrongSlotIndex == index;
    final isCorrect = s.correctSteps.contains(index);
    final isRunActive = s.activeStepIndex == index;
    final activeSlot = s.activeSlotIndex; // arranging target (or null)
    final isTarget = activeSlot == index;
    final isFuture = activeSlot != null && index > activeSlot;

    // The active arranging slot glows as the target; a wrong tap flashes it red.
    // (Placement happens by tapping the matching tray block.)
    if (isTarget) {
      return KeyedSubtree(
        key: widget.activeSlotKey,
        child: Semantics(
          label: 'Step ${index + 1}: next command goes here. Tap the matching block below.',
          child: CommandCard(
            command: null,
            style: isWrong ? CommandCardStyle.error : CommandCardStyle.active,
            stepNumber: index + 1,
            width: _cardW,
            height: _cardH,
          ),
        ),
      );
    }

    // Future locked slots are dimmed and inert.
    if (isFuture) {
      return Opacity(
        opacity: 0.32,
        child: CommandCard(
          command: null,
          style: CommandCardStyle.ghost,
          stepNumber: index + 1,
          width: _cardW,
          height: _cardH,
        ),
      );
    }

    // Placed / running slots (no dragging — guided flow locks them in).
    CommandCardStyle style;
    if (isFailed || isWrong) {
      style = CommandCardStyle.error;
    } else if (isRunActive) {
      style = CommandCardStyle.active;
    } else if (isCorrect || command != null) {
      style = CommandCardStyle.correct;
    } else {
      style = CommandCardStyle.ghost;
    }
    return Semantics(
      label: command == null
          ? 'Step ${index + 1}, empty.'
          : 'Step ${index + 1}: ${command.label}',
      child: _withPop(
        index,
        CommandCard(
          command: command,
          style: style,
          stepNumber: index + 1,
          width: _cardW,
          height: _cardH,
        ),
      ),
    );
  }
}
