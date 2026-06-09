// Mission Goal screen — Orbit (the bot) sits at the bottom and delivers two
// messages in sequence (the goal, then what orbit is) as chat bubbles, the same
// bottom-mascot style used in the other activities. Tap to advance; on the last
// message the LET'S LAUNCH button appears.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import 'orbit_button.dart';
import '../../../../utils/s3_assets.dart';

class MissionGoalPanel extends StatefulWidget {
  const MissionGoalPanel({
    super.key,
    required this.onLaunch,
    this.onAdvance,
    this.enabled = true,
  });

  final VoidCallback onLaunch;

  /// Called when the panel advances to the next message (used to play the
  /// matching voice-over line).
  final VoidCallback? onAdvance;

  /// False while Orbit is narrating — advancing/launching waits for the line.
  final bool enabled;

  @override
  State<MissionGoalPanel> createState() => _MissionGoalPanelState();
}

class _MissionGoalPanelState extends State<MissionGoalPanel> {
  static const _messages = [
    'Our goal is to place the satellite into orbit.',
    'Do you know what an orbit is? Orbit is a repeating curved path around Earth. '
        'Gravity keeps pulling the satellite into that curve.',
  ];

  int _i = 0;
  bool get _last => _i == _messages.length - 1;

  void _advance() {
    if (_last) return;
    setState(() => _i++);
    widget.onAdvance?.call();
  }

  @override
  Widget build(BuildContext context) {
    // The whole message area (bot + bubble + hint) advances on tap.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (_last || !widget.enabled) ? null : _advance,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  netImageWidget(OL.flutter(OL.orbitBotHappy),
                      height: 96, errorBuilder: (_, __, ___) => const SizedBox(width: 64)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _bubble(key: ValueKey(_i)),
                    ),
                  ),
                ],
              ),
              if (!_last)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AnimatedOpacity(
                    opacity: widget.enabled ? 1 : 0.35,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0A1838),
                        borderRadius: BorderRadius.circular(CareerRadii.pill),
                        border: Border.all(color: CareerColors.gold.withValues(alpha: 0.7), width: 1.5),
                      ),
                      child: Text('Tap to continue  ›',
                          style: CareerText.cta.copyWith(
                              color: CareerColors.gold, fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_last) ...[
          const SizedBox(height: 12),
          OrbitButton(
            label: 'Let’s Launch',
            colors: const [Color(0xFF34D17E), Color(0xFF17A95C)],
            leadingIcon: Icons.rocket_launch_rounded,
            onTap: widget.onLaunch,
            enabled: widget.enabled,
          ),
        ],
        const SizedBox(height: 10), // lift the content up off the bottom edge
      ],
    );
  }

  Widget _bubble({required Key key}) => CustomPaint(
        key: key,
        painter: _GoalBubblePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
          child: Text(
            _messages[_i],
            style: CareerText.body.copyWith(
                color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3),
          ),
        ),
      );
}

/// Navy-glass chat bubble with a cyan border and a tail pointing left at Orbit.
/// Body + tail are merged into a single UNION outline, so the border traces only
/// the outer edge — no internal seam where the tail meets the body.
class _GoalBubblePainter extends CustomPainter {
  static const _fill = Color(0xF20A1838);
  static const _border = CareerColors.cyan;
  static const _tailW = 13.0;
  static const _tailSpan = 22.0;
  static const _radius = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(_tailW, 0, size.width - _tailW, size.height),
        const Radius.circular(_radius),
      ));
    final tailY = size.height * 0.55;
    final tail = Path()
      ..moveTo(_tailW + 1, tailY - _tailSpan * 0.5)
      ..lineTo(0, tailY)
      ..lineTo(_tailW + 1, tailY + _tailSpan * 0.5)
      ..close();
    final merged = Path.combine(PathOperation.union, body, tail);

    canvas.drawShadow(merged, Colors.black.withValues(alpha: 0.5), 8, false);
    canvas.drawPath(merged, Paint()..color = _fill);
    canvas.drawPath(
        merged,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _border.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_GoalBubblePainter oldDelegate) => false;
}
