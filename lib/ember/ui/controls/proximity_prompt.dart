// Ember — ui/controls/proximity_prompt.dart
//
// The floating PROXIMITY PROMPT: a small, tappable pill that hovers over whatever
// interactable the avatar is standing beside (an NPC to talk to, a node to
// gather, a discovery to launch). The world_screen anchors it in screen space
// from the target's world position (via game.worldToScreen) every frame, and taps
// resolve it through the matching seam. It is the walk-up affordance — "you can do
// this here" — and it doubles as the tap-fallback the brief asks for.
//
// Pure presentation: it renders an icon + a short imperative + a soft pulse so the
// kid notices it; it calls back [onTap] and never touches the world. The kind tints
// it (ember for discovery, warm for talk, leaf-green for gather) so the action
// reads at a glance.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../../game/exploration/proximity_resolver.dart';

/// A floating, tappable action pill for a [ProximityTarget].
class ProximityPrompt extends StatefulWidget {
  const ProximityPrompt({
    super.key,
    required this.target,
    required this.palette,
    required this.onTap,
  });

  final ProximityTarget target;
  final EmberPalette palette;
  final VoidCallback onTap;

  @override
  State<ProximityPrompt> createState() => _ProximityPromptState();
}

class _ProximityPromptState extends State<ProximityPrompt>
    with SingleTickerProviderStateMixin {
  // EAGER (initState), not a `late final` lazy initializer: an AnimationController
  // built lazily on FIRST access could be constructed from dispose() (its ctor
  // does a TickerMode ancestor lookup) if this prompt is torn down before it ever
  // built — "Looking up a deactivated widget's ancestor is unsafe". Eager
  // construction means dispose() only ever tears down. (Same hazard class as the
  // VirtualJoystick ticker.)
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = widget.palette;
    final (IconData icon, Color tint) = switch (widget.target.kind) {
      ProximityKind.discovery => (Icons.auto_awesome, p.ember),
      ProximityKind.npc => (Icons.chat_bubble_outline, p.emberBright),
      ProximityKind.resource => (Icons.back_hand_outlined, p.success),
    };

    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double pulse = 0.5 + 0.5 * math.sin(_c.value * math.pi * 2);
        final double lift = 2.0 * pulse;
        return Transform.translate(
          offset: Offset(0, -lift),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tint, width: 2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: tint.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: tint, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.target.label,
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small downward "tail" so the pill reads as pointing at the entity below it.
/// Kept here so world_screen can stack it under the pill if desired (currently the
/// glow + position is enough; exported for future tuning).
class PromptTail extends StatelessWidget {
  const PromptTail({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 8),
      painter: _TailPainter(color),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path tri = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(tri, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
