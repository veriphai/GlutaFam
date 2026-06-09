// Scene 1 — Mission Control Test Intro (PRD §10 Scene 1). Introduces the five
// camera carriers in a big hologram panel — TWO per row (Tower/Mountain,
// Drone/Airplane, then Satellite centred). Each with a Flutter label. CTA →
// BEGIN starts the climb at Ground.
//
// The panel fills the available width AND height of its slot and the tiles flex
// to fill it, so the icons render as large as possible on any phone.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/scene_copy.dart';
import '../state/how_much_controller.dart';
import '../state/how_much_state.dart';
import '../widgets/cta_button.dart';
import '../widgets/orbit_message.dart';
import '../../../../utils/s3_assets.dart';

class _Carrier {
  const _Carrier(this.asset, this.label);
  final String asset;
  final String label;
}

const _tower = _Carrier(HM.towerIcon, 'Tower');
const _mountain = _Carrier(HM.mountainIcon, 'Mountain');
const _drone = _Carrier(HM.droneIcon, 'Drone');
const _airplane = _Carrier(HM.airplaneIcon, 'Airplane');
const _satellite = _Carrier(HM.satelliteIcon, 'Satellite');

class MissionTestScene extends StatelessWidget {
  const MissionTestScene({super.key, required this.controller, required this.onHome});

  final HowMuchController controller;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        netImageWidget(HM.flutter(HM.bgMissionControl), fit: BoxFit.cover),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xBB07162F))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PressableScale(
                    onTap: onHome,
                    child: GlassSurface(
                      radius: 12,
                      padding: const EdgeInsets.all(7),
                      child: const Icon(Icons.home_rounded, size: 18, color: CareerColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Orbit (the bot) at the top, forward-facing, with the question
                // in a speech bubble pointing back to it (shared OrbitMessage).
                const RevealOnLoad(
                  child: OrbitMessage(mood: MascotMood.idle, message: SceneCopy.testMissionControl),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, c) => RevealOnLoad(
                        delay: const Duration(milliseconds: 140),
                        child: _HologramPanel(width: c.maxWidth * 0.9, height: c.maxHeight * 0.9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                RevealOnLoad(
                  delay: const Duration(milliseconds: 240),
                  child: CtaButton(
                    label: SceneCopy.begin,
                    onTap: controller.beginExploration,
                    // Listen-before-act: BEGIN waits for Orbit's line.
                    enabled: !controller.state.voicePlaying,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HologramPanel extends StatelessWidget {
  const _HologramPanel({required this.width, required this.height});
  final double width;
  final double height;

  static const double _pad = 18.0;
  static const double _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final tileW = (width - _pad * 2 - _gap) / 2; // two tiles across

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        image: DecorationImage(image: netImage(HM.flutter(HM.hologramPanel)), fit: BoxFit.fill),
      ),
      child: Column(
        children: [
          Expanded(child: _row(const [_tower, _mountain])),
          const SizedBox(height: _gap),
          Expanded(child: _row(const [_drone, _airplane])),
          const SizedBox(height: _gap),
          // Satellite alone, centred, same width as the others.
          Expanded(
            child: Center(child: SizedBox(width: tileW, child: const _Tile(carrier: _satellite))),
          ),
        ],
      ),
    );
  }

  Widget _row(List<_Carrier> pair) => Row(
        children: [
          Expanded(child: _Tile(carrier: pair[0])),
          const SizedBox(width: _gap),
          Expanded(child: _Tile(carrier: pair[1])),
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.carrier});
  final _Carrier carrier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0x33123A6E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.5), width: 1.6),
        boxShadow: [
          BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.18), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: netImageWidget(HM.flutter(carrier.asset), fit: BoxFit.contain)),
          const SizedBox(height: 6),
          Text(carrier.label,
              style: CareerText.label.copyWith(fontSize: 14, color: Colors.white, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

