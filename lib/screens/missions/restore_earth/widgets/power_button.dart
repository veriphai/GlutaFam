// A single power button (PRD §12.3 states). Glassy coloured tile with the power
// icon + label. States: idle / pressed (bounce) / selected (border glow + lift,
// others dim) / hintPulse (correct button breathes) / wrongShake (one-shot
// horizontal shake when this power fired wrong).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../home/career/careerTheme.dart';
import '../config/powers.dart';
import '../../../../utils/s3_assets.dart';

class PowerButton extends StatefulWidget {
  const PowerButton({
    super.key,
    required this.def,
    required this.selected,
    required this.dimmed,
    required this.hintPulse,
    required this.enabled,
    required this.wrongShakeToken,
    required this.onTap,
  });

  final PowerDef def;
  final bool selected;
  final bool dimmed; // another power is selected
  final bool hintPulse; // correct-power nudge
  final bool enabled;
  final int wrongShakeToken; // bump → shake
  final VoidCallback onTap;

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with TickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..repeat(reverse: true);
  bool _pressed = false;

  @override
  void didUpdateWidget(PowerButton old) {
    super.didUpdateWidget(old);
    if (widget.wrongShakeToken != old.wrongShakeToken) {
      _shake.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.def.buttonColor;
    return AnimatedBuilder(
      animation: Listenable.merge([_shake, _pulse]),
      builder: (context, _) {
        final shakeX = math.sin(_shake.value * math.pi * 5) * (1 - _shake.value) * 6;
        final pulseScale = widget.hintPulse ? 1 + 0.05 * _pulse.value : 1.0;
        final scale = (_pressed ? 0.96 : 1.0) * (widget.selected ? 1.03 : 1.0) * pulseScale;
        return Transform.translate(
          offset: Offset(shakeX, widget.selected ? -3 : 0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(opacity: widget.dimmed ? 0.72 : 1.0, child: _tile(c)),
          ),
        );
      },
    );
  }

  Widget _tile(Color c) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap();
            }
          : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(c, Colors.white, 0.28)!, c, Color.lerp(c, Colors.black, 0.34)!],
            stops: const [0.0, 0.45, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.selected ? Colors.white : Colors.white.withValues(alpha: 0.28),
            width: widget.selected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: widget.selected || widget.hintPulse ? 0.65 : 0.35),
              blurRadius: widget.selected || widget.hintPulse ? 22 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glossy top sheen.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 26,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Glassy icon badge.
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.08)],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: netImageWidget(widget.def.iconAsset, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.def.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CareerText.cta.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
