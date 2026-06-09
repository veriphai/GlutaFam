// Signal-strength meter: four climbing bars whose colour + count reflect the
// SignalState, with a Flutter text label (accessibility — never colour alone).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/signal_rescue_state.dart';

class SignalMeter extends StatelessWidget {
  const SignalMeter({super.key, required this.signal, required this.strength});

  final SignalState signal;
  final double strength; // 0..1

  static const _labels = {
    SignalState.noSignal: 'NO SIGNAL',
    SignalState.weak: 'WEAK SIGNAL',
    SignalState.strong: 'STRONG SIGNAL',
    SignalState.locked: 'DATA LOCKED',
  };

  Color get _color => switch (signal) {
        SignalState.noSignal => const Color(0xFFFF4D4D),
        SignalState.weak => const Color(0xFFFFC43D),
        SignalState.strong => const Color(0xFF49E06B),
        SignalState.locked => const Color(0xFF35B6FF),
      };

  int get _activeBars => switch (signal) {
        SignalState.noSignal => strength > 0.05 ? 1 : 0,
        SignalState.weak => 2,
        SignalState.strong => 3,
        SignalState.locked => 4,
      };

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // four climbing bars
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 6,
                height: 9.0 + i * 5,
                decoration: BoxDecoration(
                  color: i < _activeBars ? _color : CareerColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: i < _activeBars
                      ? [BoxShadow(color: _color.withValues(alpha: 0.7), blurRadius: 5)]
                      : null,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(_labels[signal]!,
              style: CareerText.label.copyWith(color: _color, fontSize: 9.5)),
        ],
      ),
    );
  }
}
