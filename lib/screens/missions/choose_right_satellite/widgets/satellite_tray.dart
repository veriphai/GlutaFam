// The bottom satellite tray (PRD §10.6): four draggable "deployable units",
// not answer options. Built from the SatelliteType enum so nothing is hardcoded
// per card. Uses an IMMEDIATE Draggable (never LongPress — wrong for a kids'
// mobile UI, per the playbook); one active drag at a time is enforced upstream
// by `enabled`. The drag feedback is the satellite scaled up with a trail,
// centred under the finger.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../models/satellite_type.dart';
import '../../../../utils/s3_assets.dart';

const List<SatelliteType> _trayOrder = [
  SatelliteType.navigation,
  SatelliteType.weather,
  SatelliteType.communication,
  SatelliteType.earthObservation,
];

class SatelliteTray extends StatelessWidget {
  const SatelliteTray({
    super.key,
    required this.activeDragType,
    required this.pulseHintType,
    required this.canDrag,
    required this.onDragStart,
    required this.onDragEnd,
    required this.introRevealT,
  });

  final SatelliteType? activeDragType;
  final SatelliteType? pulseHintType;
  final bool Function(SatelliteType type) canDrag;
  final void Function(SatelliteType type) onDragStart;
  final VoidCallback onDragEnd;

  /// 0..1 stagger reveal used on the intro (each card glows in).
  final double introRevealT;

  @override
  Widget build(BuildContext context) {
    // Self-bounded height: each tray card's inner Column uses an Expanded for
    // the satellite image, so the Row MUST have a bounded height or RenderFlex
    // throws. Bounding it here means no caller (intro vs play) can break it.
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: SizedBox(
        height: 96,
        child: Row(
          children: [
            for (var i = 0; i < _trayOrder.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == _trayOrder.length - 1 ? 0 : 8),
                  child: _TrayCard(
                    type: _trayOrder[i],
                    enabled: canDrag(_trayOrder[i]),
                    dimmed: activeDragType != null && activeDragType != _trayOrder[i],
                    isHint: pulseHintType == _trayOrder[i],
                    reveal: ((introRevealT * _trayOrder.length) - i).clamp(0.0, 1.0),
                    onDragStart: () => onDragStart(_trayOrder[i]),
                    onDragEnd: onDragEnd,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrayCard extends StatefulWidget {
  const _TrayCard({
    required this.type,
    required this.enabled,
    required this.dimmed,
    required this.isHint,
    required this.reveal,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final SatelliteType type;
  final bool enabled;
  final bool dimmed;
  final bool isHint;
  final double reveal;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  @override
  State<_TrayCard> createState() => _TrayCardState();
}

class _TrayCardState extends State<_TrayCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reveal = Curves.easeOutCubic.transform(widget.reveal.clamp(0, 1));
    final card = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final hintGlow = widget.isHint ? _pulse.value : 0.0;
        return _frame(hintGlow, child!);
      },
      child: _content(),
    );

    final reveal2 = Opacity(
      opacity: reveal,
      child: Transform.translate(offset: Offset(0, (1 - reveal) * 14), child: card),
    );

    if (!widget.enabled) {
      return Opacity(opacity: widget.dimmed ? 0.4 : 0.7, child: reveal2);
    }

    return Floaty(
      amplitude: 3,
      period: const Duration(milliseconds: 2600),
      phase: widget.type.index.toDouble(),
      child: Draggable<SatelliteType>(
        data: widget.type,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: widget.onDragStart,
        onDragEnd: (_) => widget.onDragEnd(),
        onDraggableCanceled: (_, __) => widget.onDragEnd(),
        feedback: _feedback(),
        childWhenDragging: Opacity(opacity: 0.25, child: reveal2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: widget.dimmed ? 0.45 : 1,
          child: reveal2,
        ),
      ),
    );
  }

  Widget _frame(double hintGlow, Widget child) {
    final accent = widget.type.accent;
    final borderColor = Color.lerp(CareerColors.glassBorder, accent, 0.35 + 0.65 * hintGlow)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x3315335E), Color(0x22091428)],
        ),
        border: Border.all(color: borderColor, width: 1.4 + 1.2 * hintGlow),
        boxShadow: hintGlow > 0.02
            ? [BoxShadow(color: accent.withValues(alpha: 0.5 * hintGlow), blurRadius: 16, spreadRadius: 1)]
            : null,
      ),
      child: child,
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(child: netImageWidget(widget.type.sprite, fit: BoxFit.contain)),
          const SizedBox(height: 4),
          Text(
            widget.type.label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: CareerText.label.copyWith(
                fontSize: 8.5, height: 1.05, letterSpacing: 0.4, color: CareerColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _feedback() {
    const size = 118.0;
    return Transform.translate(
      offset: const Offset(-size / 2, -size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Drag trail behind the lifted satellite.
            Transform.translate(
              offset: const Offset(-14, 18),
              child: Opacity(
                opacity: 0.7,
                child: Transform.rotate(
                  angle: -math.pi / 5,
                  child: netImageWidget(CrsAssets.dragTrail, width: size * 0.9, fit: BoxFit.contain),
                ),
              ),
            ),
            netImageWidget(widget.type.sprite, width: size * 0.86, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
