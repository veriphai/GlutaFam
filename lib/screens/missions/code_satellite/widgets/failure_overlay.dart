// "Mission Paused" debug card (mockup 2). Appears over the play scene when a
// step fails validation. Encouraging, never shaming (PRD §11): the reason +
// "That's okay — let's fix the order!" + Orbit in debug pose + Reorder CTA.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import 'cta_button.dart';
import '../../../../utils/s3_assets.dart';

class FailureOverlay extends StatelessWidget {
  const FailureOverlay({super.key, required this.message, required this.onReorder});

  final String message;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: RevealOnLoad(
          offsetY: 30,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A1726), Color(0xFF1A1330)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: CSColors.orange.withValues(alpha: 0.8), width: 1.6),
                    boxShadow: [BoxShadow(color: CSColors.orange.withValues(alpha: 0.3), blurRadius: 22)],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CSColors.orange.withValues(alpha: 0.2),
                                    border: Border.all(color: CSColors.orange, width: 1.6),
                                  ),
                                  child: const Icon(Icons.warning_amber_rounded,
                                      size: 20, color: CSColors.orange),
                                ),
                                const SizedBox(width: 10),
                                const Text('Mission Paused',
                                    style: TextStyle(
                                        color: CSColors.orange,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(message,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15, height: 1.3, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Text("That's okay. Engineers do this too — they debug by finding the step that went wrong and fixing the order.",
                                style: TextStyle(
                                    color: CSColors.teal, fontSize: 13.5, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Floaty(
                        amplitude: 4,
                        child: netImageWidget(CS.flutter(CS.orbitDebug),
                            width: 78, height: 78, fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CtaButton(
                  label: 'Reorder Commands',
                  icon: Icons.refresh_rounded,
                  onTap: onReorder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
