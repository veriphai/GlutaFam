// Full-screen success celebration: reward badge (sprite) behind Flutter text, the
// mission-complete line and the educational wrap-up. A single full-width CONTINUE
// button is pinned to the bottom.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/signal_tuning.dart';
import '../state/signal_rescue_state.dart';
import '../../../../utils/s3_assets.dart';
import 'helper_card.dart';

class MissionSuccessOverlay extends StatelessWidget {
  const MissionSuccessOverlay({super.key, required this.onDone, this.continueEnabled = true});

  final VoidCallback onDone;

  /// Listen-before-skip: stays dim + tap-blocked until Orbit's success chain
  /// (clips 22→23→24) finishes, so kids hear the teaching recap.
  final bool continueEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC050B1C),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RevealOnLoad(
                        child: netImageWidget(SR.flutter(SR.successBadge), height: 132, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 14),
                      RevealOnLoad(
                        delay: const Duration(milliseconds: 90),
                        child: Text('Mission Complete!',
                            textAlign: TextAlign.center,
                            style: CareerText.heroTitle.copyWith(color: CareerColors.green)),
                      ),
                      const SizedBox(height: 10),
                      RevealOnLoad(
                        delay: const Duration(milliseconds: 160),
                        child: Text(SRTune.successLine,
                            textAlign: TextAlign.center,
                            style: CareerText.body.copyWith(color: Colors.white, fontSize: 13, height: 1.35)),
                      ),
                      const SizedBox(height: 14),
                      // Orbit delivers the wrap-up himself — same mascot + tailed
                      // message bubble used everywhere else.
                      const RevealOnLoad(
                        delay: Duration(milliseconds: 220),
                        child: HelperCard(
                          mood: MascotMood.celebrate,
                          message: SRTune.wrapUpLine,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Continue — pinned to the bottom, full width; gated on the voice
            // chain (dim + IgnorePointer, never dim-only).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: IgnorePointer(
                ignoring: !continueEnabled,
                child: AnimatedOpacity(
                  opacity: continueEnabled ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: PressableScale(
                    onTap: onDone,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF34D17E), Color(0xFF17A95C)]),
                        borderRadius: BorderRadius.circular(CareerRadii.pill),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF17A95C)
                                  .withValues(alpha: continueEnabled ? 0.5 : 0.15),
                              blurRadius: 16),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('CONTINUE', style: CareerText.cta.copyWith(color: Colors.white, fontSize: 15)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
