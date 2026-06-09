// Top mission chrome: title row + the 8-node horizontal progress rail +
// the "warning readiness" narrative chip (PRD §8, §23.3). Node states:
// locked (dim) / active (amber pulse, PRD colour coding) / complete (green ✓).

import 'package:flutter/material.dart';

import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_state.dart';

class MissionTopBar extends StatelessWidget {
  const MissionTopBar({
    super.key,
    required this.state,
    required this.onExit,
    this.onToggleSound,
    this.railLit = true,
  });

  final MissionState state;
  final VoidCallback onExit;
  final VoidCallback? onToggleSound;
  /// Intro shows the rail unpowered until the hold completes.
  final bool railLit;

  @override
  Widget build(BuildContext context) {
    final info = kStageInfo[state.stage];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _RoundIconButton(icon: Icons.close_rounded, onTap: onExit),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The mission title only headlines the intro; stage screens
                  // lead with their own stage title.
                  if (state.stage == MissionStage.intro)
                    Text('SAVE THE COASTAL CITY', style: SccText.missionTitle)
                  else if (info != null)
                    Text(info.title,
                        style: SccText.stageTitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            if (onToggleSound != null) ...[
              _RoundIconButton(
                icon: state.soundOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                onTap: onToggleSound!,
              ),
              const SizedBox(width: 8),
            ],
            _ReadinessChip(readiness: state.readiness),
          ],
        ),
        const SizedBox(height: 10),
        MissionProgressRail(state: state, lit: railLit),
      ],
    );
  }
}

class MissionProgressRail extends StatelessWidget {
  const MissionProgressRail({super.key, required this.state, this.lit = true});

  final MissionState state;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < kPlayableStages.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: _connectorColor(i),
              ),
            ),
          _RailNode(
            index: i,
            stage: kPlayableStages[i],
            state: state,
            lit: lit,
          ),
        ],
      ],
    );
  }

  Color _connectorColor(int i) {
    final prev = kPlayableStages[i - 1];
    if (!lit) return SccColors.panelBorder;
    return state.completed.contains(prev)
        ? SccColors.success.withValues(alpha: 0.7)
        : SccColors.panelBorder;
  }
}

class _RailNode extends StatefulWidget {
  const _RailNode(
      {required this.index, required this.stage, required this.state, required this.lit});

  final int index;
  final MissionStage stage;
  final MissionState state;
  final bool lit;

  @override
  State<_RailNode> createState() => _RailNodeState();
}

class _RailNodeState extends State<_RailNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.state.completed.contains(widget.stage);
    final active = widget.lit && widget.state.stage == widget.stage && !done;
    final color = !widget.lit
        ? SccColors.textMuted.withValues(alpha: 0.5)
        : done
            ? SccColors.success
            : active
                ? SccColors.warningAmber
                : SccColors.textMuted;

    Widget node = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SccColors.panelNavy,
        border: Border.all(color: color, width: 1.6),
        boxShadow: active || done
            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
            : null,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded, size: 15, color: SccColors.success)
            : Text('${widget.index + 1}',
                style: SccText.chip.copyWith(color: color, fontSize: 11)),
      ),
    );

    if (active) {
      node = ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.08).animate(
            CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: node,
      );
    }
    // Power-up cascade: each node reaches full brightness a beat after the
    // previous one when the rail lights (intro hold complete — PRD §11.4).
    node = AnimatedOpacity(
      duration: Duration(milliseconds: 220 + widget.index * 170),
      curve: Curves.easeIn,
      opacity: widget.lit ? 1 : 0.45,
      child: node,
    );
    return Tooltip(
      message: kStageInfo[widget.stage]?.railLabel ?? '',
      child: node,
    );
  }
}

class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({required this.readiness});
  final int readiness;

  @override
  Widget build(BuildContext context) {
    final hot = readiness >= 100;
    final color = hot ? SccColors.success : SccColors.warningAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SccColors.panelFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('WARNING', style: SccText.label.copyWith(fontSize: 8.5, color: color)),
          Text('$readiness%',
              style: SccText.meterValue.copyWith(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SccColors.panelFill,
          border: Border.all(color: SccColors.panelBorder),
        ),
        child: Icon(icon, size: 20, color: SccColors.textSecondary),
      ),
    );
  }
}
