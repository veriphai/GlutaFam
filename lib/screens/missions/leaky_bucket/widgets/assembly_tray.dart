// Parts tray (PRD: snap-build, LEGO-not-jigsaw) — during the build beat it shows
// ALL the machines still to place, each an immediate `Draggable`. The screen wraps
// the scene in a `DragTarget` that calls `controller.placeMachine(kind)` on drop —
// and each machine SNAPS to its own correct slot (no wrong order possible, no
// fail-state). The fun is the building + the power-up reveal, not a permutation.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/leaky_chain_defs.dart';
import '../state/leaky_bucket_controller.dart';

class PartsTray extends StatelessWidget {
  const PartsTray({super.key, required this.controller});
  final LeakyBucketController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final parts = controller.unplacedMachines;
        if (parts.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF0A1126).withValues(alpha: 0.55), const Color(0xFF070C1E).withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Drag the parts into the chain',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _DraggablePart(kind: parts[i]),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggablePart extends StatelessWidget {
  const _DraggablePart({required this.kind});
  final LeakStepKind kind;

  @override
  Widget build(BuildContext context) {
    final card = _PartCard(kind: kind);
    return Draggable<LeakStepKind>(
      data: kind,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(offset: const Offset(-38, -38), child: _PartCard(kind: kind, dragging: true)),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({required this.kind, this.dragging = false});
  final LeakStepKind kind;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final accent = kind.accent;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dragging ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.5),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: dragging ? 0.5 : 0.28), blurRadius: dragging ? 20 : 11, spreadRadius: dragging ? 2 : 0.5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(kind.icon, size: 26, color: accent),
          const SizedBox(height: 5),
          Text(kind.machineName, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}
