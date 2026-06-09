// Flutter-rendered "Send Data" button. Glows + pulses when the connection is
// locked and ready; dims when not. Tapping while not-ready is NOT blocked at the
// widget level — the controller returns a friendly reason (never punishes), so
// the button always calls onTap.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class SendDataButton extends StatefulWidget {
  const SendDataButton({super.key, required this.ready, required this.onTap});

  final bool ready;
  final VoidCallback onTap;

  @override
  State<SendDataButton> createState() => _SendDataButtonState();
}

class _SendDataButtonState extends State<SendDataButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.ready;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = ready ? (0.35 + 0.45 * _pulse.value) : 0.0;
        return PressableScale(
          onTap: widget.onTap,
          child: Opacity(
            opacity: ready ? 1.0 : 0.55,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ready
                      ? const [Color(0xFF33B5FF), Color(0xFF1C7FE0)]
                      : const [Color(0xFF3A4A6E), Color(0xFF2A3658)],
                ),
                borderRadius: BorderRadius.circular(CareerRadii.pill),
                border: Border.all(color: Colors.white.withValues(alpha: ready ? 0.6 : 0.2), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF33B5FF).withValues(alpha: glow),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SEND DATA',
                      style: CareerText.cta.copyWith(
                          color: Colors.white, fontSize: 15, letterSpacing: 0.5)),
                  const SizedBox(width: 8),
                  const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
