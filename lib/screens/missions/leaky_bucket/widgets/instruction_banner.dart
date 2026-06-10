// The instruction banner — a short, large-font line at the top: the imperatives
// (Build the Plant, Power It Up) and the de-personified meaning-lines (So Much
// Fuel So Little Light, The 'Lost' Energy Became Heat, …). Set by the engine via
// controller.instruction. Fades-swaps on change; auto-shrinks long meaning-lines
// to fit; collapses to nothing when empty (during the power-up reveal / card).

import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/leaky_bucket_controller.dart';

class InstructionBanner extends StatelessWidget {
  const InstructionBanner({super.key, required this.controller});
  final LeakyBucketController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: controller.instruction,
      builder: (context, text, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
          ),
          child: text.isEmpty
              ? const SizedBox(width: double.infinity, key: ValueKey('none'))
              : Container(
                  key: ValueKey(text),
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 29,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: const Color(0xFFFFFFFF),
                          shadows: [
                            Shadow(color: const Color(0xFFFFC24D).withValues(alpha: 0.45), blurRadius: 18),
                            const Shadow(color: Color(0x8C000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
