// Shared CTA widgets: the press-and-HOLD button (intro "Start Final Mission"
// + Stage-8 "Hold to Upload" — PRD §11.3, §19.5), and the standard glowing
// pill CTA. Disabled = dim + IgnorePointer (playbook rule), and the hold
// button reports progress so callers can drive uploads off it.

import 'package:flutter/material.dart';

import '../config/scc_theme.dart';

/// Press-and-hold CTA: fills with cyan light over [holdDuration]; calls
/// [onProgress] each tick and [onComplete] when filled. Releasing early
/// rewinds (and reports the rewind through [onProgress]/[onCancelled]).
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.label,
    required this.onComplete,
    this.onProgress,
    this.onCancelled,
    this.holdDuration = const Duration(milliseconds: 1700),
    this.enabled = true,
    this.icon,
    this.fillColor = SccColors.cyan,
  });

  final String label;
  final VoidCallback onComplete;
  final ValueChanged<double>? onProgress;
  final VoidCallback? onCancelled;
  final Duration holdDuration;
  final bool enabled;
  final IconData? icon;
  final Color fillColor;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  );
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    // Report progress only while actively holding — a rewind after release
    // must not look like renewed progress to the caller.
    _hold.addListener(() {
      if (_hold.status == AnimationStatus.forward) {
        widget.onProgress?.call(_hold.value);
      }
    });
    _hold.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (_completed) return;
    _hold.forward();
  }

  void _up([Object? _]) {
    if (_completed || _hold.status != AnimationStatus.forward) return;
    _hold.reverse();
    widget.onCancelled?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: widget.enabled ? 1 : 0.45,
        child: GestureDetector(
          onTapDown: _down,
          onTapUp: _up,
          onTapCancel: _up,
          child: AnimatedBuilder(
            animation: _hold,
            builder: (context, _) {
              final p = _hold.value;
              return Container(
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29),
                  color: SccColors.panelNavy,
                  border: Border.all(
                    color: widget.fillColor.withValues(alpha: 0.45 + 0.55 * p),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.fillColor.withValues(alpha: 0.18 + 0.4 * p),
                      blurRadius: 14 + 14 * p,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // cyan fill rising with hold progress
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: p,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.fillColor.withValues(alpha: 0.30),
                                  widget.fillColor.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: SccColors.white, size: 22),
                              const SizedBox(width: 8),
                            ],
                            Text(widget.label, style: SccText.cta),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Standard glowing pill CTA. Disabled = dim + IgnorePointer.
class SccCta extends StatelessWidget {
  const SccCta({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.color = SccColors.success,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.55)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: color, width: 1.4),
              boxShadow: enabled
                  ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: SccColors.white, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(label, style: SccText.cta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
