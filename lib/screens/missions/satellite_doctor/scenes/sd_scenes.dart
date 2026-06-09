// The three scene overlays routed by SceneGroup: intro, mission (the main
// gameplay UI with its per-step lower panel), and final completion. Each sits
// over the permanent Flame stage (transparent middle band lets it show through).

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import '../models/satellite_doctor_mission.dart';
import '../state/satellite_doctor_controller.dart';
import '../widgets/sd_apply.dart';
import '../widgets/sd_panels.dart';
import '../widgets/sd_ui.dart';
import '../../../../utils/s3_assets.dart';

// ── Intro ──────────────────────────────────────────────────────────────────────
// Clean, Earth-Detective-style intro: EPISODE label + big title + subtitle at the
// TOP over the hero background, MediBot + speech bubble + Start button at the
// bottom. (No baked text — all Flutter.)
class IntroScene extends StatelessWidget {
  const IntroScene({
    super.key,
    required this.onStart,
    required this.onBack,
    required this.voicePlaying,
  });
  final VoidCallback onStart;
  final VoidCallback onBack;

  /// True while Orbit speaks — the Start CTA stays dim + tap-blocked until the
  /// brief finishes (cleared by completion/safety/missing-asset, never stuck).
  final ValueListenable<bool> voicePlaying;

  static const _titleGold = Color(0xFFF3E2A6);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // solid base behind everything (fills the dark gap above the image)
        const Positioned.fill(child: ColoredBox(color: SDColors.bg)),
        // hero background — fitWidth (not cover) and pushed DOWN so it starts
        // below the title block, with clean dark space at the top.
        Positioned(
          top: 132,
          left: 0,
          right: 0,
          child: netImageWidget(
            SD.flutter(SD.introBg),
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        // top scrim so the title is legible over the bright satellite/sun
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0xCC050A14), Colors.transparent],
            ),
          ),
        ),
        // bottom scrim so the bubble + CTA stay legible over the Earth
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xF2050A14)],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              // top bar: back + sound
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
                    _RoundBtn(icon: Icons.volume_up_rounded, onTap: onBack),
                  ],
                ),
              ),
              // (EPISODE label removed — padding keeps the title in place)
              const SizedBox(height: 23),
              // title + subtitle
              Column(
                children: [
                  Text(
                    'SATELLITE DOCTOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _titleGold,
                      fontSize: 34,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fix the fault and keep the\nsatellite alive!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              // Orbit's greeting bubble
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: MediBotBubble(
                  pose: SD.botPointing,
                  text:
                      'Hi! I’m Orbit. I’m seeing health alerts on our satellite — can you help me check each system and repair it?',
                ),
              ),
              const SizedBox(height: 16),
              // Start button — disabled (dim + IgnorePointer) while Orbit speaks
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
                child: ValueListenableBuilder<bool>(
                  valueListenable: voicePlaying,
                  builder: (context, speaking, _) => IgnorePointer(
                    ignoring: speaking,
                    child: AnimatedOpacity(
                      opacity: speaking ? 0.45 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: _StartMissionButton(onTap: onStart),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Round translucent icon button (top-bar back / sound).
class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SDPressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SDColors.panel.withValues(alpha: 0.6),
          border: Border.all(color: SDColors.stroke),
        ),
        child: Icon(icon, color: SDColors.cyan, size: 22),
      ),
    );
  }
}

/// The pill Start Mission button (gold gradient, rocket icon).
class _StartMissionButton extends StatelessWidget {
  const _StartMissionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SDPressable(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFC83D), Color(0xFFFF9A2E)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFB02E).withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: -2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.rocket_launch_rounded, color: Color(0xFF3A1E00), size: 22),
            SizedBox(width: 10),
            Text('Start Mission',
                style: TextStyle(
                    color: Color(0xFF3A1E00),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Mission ────────────────────────────────────────────────────────────────────
class MissionScene extends StatelessWidget {
  const MissionScene({super.key, required this.controller, required this.onBack});
  final SatelliteDoctorController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final repaired = c.step == MissionStep.repaired;
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                // compact header: small back btn · progress · small menu btn
                Row(
                  children: [
                    _MiniIconBtn(icon: Icons.chevron_left, onTap: onBack),
                    Expanded(
                      child: MissionProgress(
                          current: c.missionNumber, total: c.missionCount),
                    ),
                    _MiniIconBtn(icon: Icons.menu, onTap: onBack),
                  ],
                ),
                const SizedBox(height: 10),
                StatusChipRow(chips: c.chips()),
                // transparent band — the Flame satellite stage shows through here.
                // Tapping the satellite during the alert starts the inspection
                // (PRD §15: "child taps the faulty part" → scanner appears).
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: c.step == MissionStep.alert ? c.beginInspect : null,
                    child: Center(
                      child: c.step == MissionStep.alert
                          ? const _TapToInspectHint()
                          : const SizedBox.expand(),
                    ),
                  ),
                ),
                // the per-step bot bubble + lower panel are hidden once the
                // mission is repaired (the success popup takes over).
                if (!repaired) ...[
                  MediBotBubble(pose: _pose(c), text: _botText(c)),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOut,
                    child: KeyedSubtree(
                      key: ValueKey(c.step),
                      child: _lowerPanel(c),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // centered success popup over a scrim
        if (repaired)
          SuccessPopup(
            mission: c.mission,
            isLast: c.missionNumber >= c.missionCount,
            onNext: c.nextMission,
          ),
      ],
    );
  }

  Widget _lowerPanel(SatelliteDoctorController c) {
    switch (c.step) {
      case MissionStep.alert:
        return AlertCard(mission: c.mission, onInspect: c.beginInspect);
      case MissionStep.inspect:
        return DiagnosticClues(mission: c.mission, onChoose: c.finishInspect);
      case MissionStep.chooseRepair:
        return RepairCards(
          mission: c.mission,
          selectedId: c.selectedRepairId,
          wrongId: c.wrongOptionId,
          wrongToken: c.wrongToken,
          onPick: c.chooseRepair,
        );
      case MissionStep.applyRepair:
        return ApplyPanel(controller: c);
      case MissionStep.repaired:
        // handled by the centered SuccessPopup overlay, not the lower panel
        return const SizedBox.shrink();
    }
  }

  String _pose(SatelliteDoctorController c) {
    switch (c.step) {
      case MissionStep.alert:
        return SD.botWorried;
      case MissionStep.inspect:
        return SD.botThinking;
      case MissionStep.chooseRepair:
        return c.wrongOptionId != null ? SD.botPointing : SD.botThinking;
      case MissionStep.applyRepair:
        return SD.botPointing;
      case MissionStep.repaired:
        return SD.botHappy;
    }
  }

  String _botText(SatelliteDoctorController c) {
    final m = c.mission;
    switch (c.step) {
      case MissionStep.alert:
        return m.botIntro;
      case MissionStep.inspect:
        return m.inspectHint;
      case MissionStep.chooseRepair:
        return c.wrongOptionId != null ? m.wrongHint : m.chooseHint;
      case MissionStep.applyRepair:
        return c.applyLocked ? m.fixAppliedLine : m.applyInstruction;
      case MissionStep.repaired:
        return m.successMessage;
    }
  }
}

/// Small square icon button for the compact mission header.
class _MiniIconBtn extends StatelessWidget {
  const _MiniIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SDPressable(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: glassPanel(radius: 11),
        child: Icon(icon, color: SDColors.cyan, size: 20),
      ),
    );
  }
}

/// A gentle "tap the satellite" hint shown during the alert step, near the
/// bottom of the stage band so it doesn't cover the satellite.
class _TapToInspectHint extends StatefulWidget {
  const _TapToInspectHint();

  @override
  State<_TapToInspectHint> createState() => _TapToInspectHintState();
}

class _TapToInspectHintState extends State<_TapToInspectHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.78),
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: SDColors.panel.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SDColors.cyan.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.touch_app, color: SDColors.cyan, size: 16),
              SizedBox(width: 6),
              Text('Tap the satellite to inspect',
                  style: TextStyle(
                      color: SDColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Final completion ────────────────────────────────────────────────────────────
// A centered completion CARD (same clean style as the mid-mission SuccessPopup):
// big final medal at the top, MISSION COMPLETE, the closing message, then
// Replay / Done. No giant burst halo.
class FinalScene extends StatefulWidget {
  const FinalScene({super.key, required this.onReplay, required this.onExit});
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  State<FinalScene> createState() => _FinalSceneState();
}

class _FinalSceneState extends State<FinalScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: Container(
        color: Colors.black.withValues(alpha: 0.66),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: ScaleTransition(
          scale: Tween(begin: 0.72, end: 1.0).animate(pop),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14233A), Color(0xFF0C1526)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: SDColors.green.withValues(alpha: 0.55), width: 1.6),
              boxShadow: [
                BoxShadow(color: SDColors.green.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: -6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // big final medal with a soft gold glow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: SDColors.yellow.withValues(alpha: 0.38), blurRadius: 40, spreadRadius: 2),
                    ],
                  ),
                  child: netImageWidget(
                    SD.flutter(SD.finalMedal),
                    width: 150,
                    height: 150,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.military_tech, color: SDColors.yellow, size: 130),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'MISSION COMPLETE',
                  style: TextStyle(
                      color: SDColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We did it! Every system is healthy again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: SDColors.text, fontSize: 14, height: 1.3, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Now you know the secret: engineers don’t just build satellites — we keep them alive from Earth.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SDColors.textMuted, fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: SDCta(
                    label: 'Done',
                    icon: Icons.check,
                    colors: const [SDColors.purple, SDColors.blue],
                    onTap: widget.onExit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
