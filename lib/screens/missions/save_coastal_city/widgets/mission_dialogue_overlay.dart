// Bottom dialogue area (PRD §9.2): Orbit mascot on the left + a speech bubble
// with a tail pointing at the speaker (playbook: a plain rounded box reads as
// "text on screen", not the mascot talking). Text swaps with the playbook's
// sequential fade-out → swap → fade-in (NOT AnimatedSwitcher's cross-fade,
// which shows both lines at once).
//
// Tap the bubble to advance queued lines (PRD §9.2 "tap to continue only when
// needed" — taps no-op once the instruction line persists).

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_dialogue.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';

class MissionDialogueOverlay extends StatelessWidget {
  const MissionDialogueOverlay({super.key, required this.controller});

  final MissionStageController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.state;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.advanceDialogue,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Orbit, pose mapped to the situation (PRD §22.3).
              SizedBox(
                width: 74,
                height: 74,
                child: _OrbitSprite(face: s.face),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _TailedBubble(
                  child: _SequentialText(
                    token: s.dialogueToken,
                    text: s.dialogueText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrbitSprite extends StatelessWidget {
  const _OrbitSprite({required this.face});
  final OrbitFace face;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: sccImage(
        SCC.flutter(face.sprite),
        key: ValueKey(face),
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Rounded bubble + triangular tail pointing left at Orbit, soft shadow.
class _TailedBubble extends StatelessWidget {
  const _TailedBubble({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.fromLTRB(22, 12, 14, 12),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  static const tailW = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(tailW, 0, size.width - tailW, size.height),
      const Radius.circular(16),
    );
    final tail = Path()
      ..moveTo(tailW + 2, size.height * 0.62 - 9)
      ..lineTo(0, size.height * 0.62 + 2)
      ..lineTo(tailW + 2, size.height * 0.62 + 11)
      ..close();
    final fill = Paint()..color = SccColors.panelFill;
    final border = Paint()
      ..color = SccColors.panelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawShadow(
        Path()..addRRect(body), Colors.black.withValues(alpha: 0.6), 6, true);
    canvas.drawRRect(body, fill);
    canvas.drawPath(tail, fill);
    canvas.drawRRect(body, border);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}

/// Fade out → swap text → fade in, keyed off the dialogue token.
class _SequentialText extends StatefulWidget {
  const _SequentialText({required this.token, required this.text});
  final int token;
  final String text;

  @override
  State<_SequentialText> createState() => _SequentialTextState();
}

class _SequentialTextState extends State<_SequentialText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
    value: 1,
  );
  late String _shown = widget.text;
  int _shownToken = -1;

  @override
  void initState() {
    super.initState();
    _shownToken = widget.token;
  }

  @override
  void didUpdateWidget(covariant _SequentialText old) {
    super.didUpdateWidget(old);
    if (widget.token != _shownToken) {
      _shownToken = widget.token;
      _fade.reverse().then((_) {
        if (!mounted) return;
        setState(() => _shown = widget.text);
        _fade.forward();
      });
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Text(_shown, style: SccText.dialogue),
    );
  }
}
