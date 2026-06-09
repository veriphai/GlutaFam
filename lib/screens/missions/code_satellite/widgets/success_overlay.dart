// Mission Success screen (PRD §12). Full-screen overlay, top→bottom:
//   big Satellite Coder badge (centered, standalone) → Mission Success card →
//   Orbit's VOICED closing thread (clips 57, 58, card-59, 60) spoken through
//   ONE swapping bubble (hidden while clip 59 narrates the card) → Continue.
// Listen-before-skip: Continue stays dimmed + tap-blocked until the final clip
// finishes (muted users advance on the thread's reading fallback).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../config/orbit_voice.dart';
import 'cta_button.dart';
import 'orbit_voice_thread.dart';
import 'voiced_bubble.dart';
import '../../../../utils/s3_assets.dart';

class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay> {
  late final OrbitVoiceThread _thread = OrbitVoiceThread(clips: kClipsSuccess);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _thread.start();
      });
    });
  }

  @override
  void dispose() {
    _thread.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1533), Color(0xFF070C20)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Big badge, centered, standalone (outside the card).
                        Floaty(
                        amplitude: 7,
                        child: netImageWidget(
                          CS.flutter(CS.badgeSatelliteCoder),
                          width: 276,
                          height: 276,
                          fit: BoxFit.contain,
                        ),
                      ),
                        const SizedBox(height: 20),
                        _successCard(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Orbit's closing thread — ONE swapping bubble (the Mission
              // Success card itself is read, not narrated).
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  netImageWidget(CS.flutter(CS.orbitSuccessJump),
                      width: 82, height: 82, fit: BoxFit.contain),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VoicedBubble(
                      index: _thread.current,
                      lines: const [
                        'You did it! You built a real command sequence.',
                        'Our satellite followed your plan, captured the cyclone image, and sent it to Mission Control.',
                        'See? A good satellite engineer thinks carefully about order. One smart sequence can make the whole mission work.',
                      ],
                      accents: const [CSColors.teal, CSColors.cyan, CSColors.teal],
                      fromRight: false,
                      maxWidth: 2000,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Listen-before-skip: lights up when the final clip ends.
              ValueListenableBuilder<bool>(
                valueListenable: _thread.done,
                builder: (context, done, _) => CtaButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  enabled: done,
                  onTap: widget.onContinue,
                  colors: const [Color(0xFF36C5F0), Color(0xFF2D6FF7)],
                  dark: false,
                  height: 56,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E2C3A), Color(0xFF0E1B3A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CSColors.teal.withValues(alpha: 0.7), width: 1.6),
        boxShadow: [BoxShadow(color: CSColors.teal.withValues(alpha: 0.28), blurRadius: 22)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 16, color: CSColors.yellow),
              const SizedBox(width: 5),
              Text('MISSION SUCCESS',
                  style: TextStyle(
                      color: CSColors.teal, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Mission Success!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text(
            'You programmed the satellite correctly. The cyclone warning image reached Mission Control. That warning can help people prepare.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFD7E2FF), fontSize: 13.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
