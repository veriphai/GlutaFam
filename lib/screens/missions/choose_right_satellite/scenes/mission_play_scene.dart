// Scenes 2–6 (PRD §16): the active mission loop. One scene reused for all five
// missions (the controller swaps mission data); the dragging / correct / wrong
// sub-states all play here without remounting.
//
// This widget OWNS the animation timing. Four controllers feed plain 0..1
// values into MissionCard; the controller (ChangeNotifier) owns discrete state.
// Transitions are detected by listening to the controller and diffing cached
// values (the house pattern) — never from build().
//
//   correct drop -> resolveDrop() sets phase=resolving
//                -> _snap plays (flash + dock)  [correct SFX + medium haptic]
//                -> on snap done, _effect plays (success effect)
//                -> on effect done, controller.markSolved() -> phase=solved
//   wrong drop   -> resolveDrop() bumps wrongPulseToken
//                -> _wrong plays (soft pulse + card shake) [wrong SFX + haptic]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../home/career/careerTheme.dart';
import '../models/satellite_type.dart';
import '../state/choose_satellite_controller.dart';
import '../state/choose_satellite_state.dart';
import '../widgets/cta_button.dart';
import '../widgets/mascot_helper.dart';
import '../widgets/mission_card.dart';
import '../widgets/mission_header.dart';
import '../widgets/mission_progress.dart';
import '../widgets/satellite_tray.dart';

class MissionPlayScene extends StatefulWidget {
  const MissionPlayScene({
    super.key,
    required this.controller,
    required this.onSound,
    this.onHome,
    this.soundOn = true,
    this.onToggleSound,
  });

  final ChooseSatelliteController controller;
  final void Function(String assetFile) onSound;
  final VoidCallback? onHome;
  final bool soundOn;
  final VoidCallback? onToggleSound;

  @override
  State<MissionPlayScene> createState() => _MissionPlaySceneState();
}

class _MissionPlaySceneState extends State<MissionPlayScene> with TickerProviderStateMixin {
  late final AnimationController _enter =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final AnimationController _snap =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  late final AnimationController _effect =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  late final AnimationController _wrong =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

  int _lastIndex = -1;
  MissionPhase _lastPhase = MissionPhase.idle;
  int _lastWrongToken = 0;

  ChooseSatelliteController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _lastIndex = c.state.currentMissionIndex;
    _lastPhase = c.state.phase;
    _lastWrongToken = c.state.wrongPulseToken;

    // Snap finished -> play the success effect; effect finished -> lock solved.
    _snap.addStatusListener((s) {
      if (s == AnimationStatus.completed) _effect.forward(from: 0);
    });
    _effect.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) c.markSolved();
    });

    c.addListener(_onChange);
    _enter.forward();
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    _enter.dispose();
    _snap.dispose();
    _effect.dispose();
    _wrong.dispose();
    super.dispose();
  }

  void _onChange() {
    final s = c.state;
    if (s.scene != ActivityScene.missionPlay) return;

    // New mission -> reset effects and replay the card entrance.
    if (s.currentMissionIndex != _lastIndex) {
      _lastIndex = s.currentMissionIndex;
      _snap.value = 0;
      _effect.value = 0;
      _wrong.value = 0;
      _enter.forward(from: 0);
    }

    // Correct drop -> begin the snap + success sequence (once).
    if (s.phase != _lastPhase) {
      if (s.phase == MissionPhase.resolving) {
        // Per-mission themed sting (sonar ping / radar sweep / connect chime …),
        // falling back to the generic correct chime.
        widget.onSound(c.mission.successSting ?? 'correct_answer.mp3');
        HapticFeedback.mediumImpact();
        _snap.forward(from: 0);
      }
      _lastPhase = s.phase;
    }

    // Wrong drop -> soft pulse + shake (once per token bump).
    if (s.wrongPulseToken != _lastWrongToken) {
      _lastWrongToken = s.wrongPulseToken;
      widget.onSound('incorrect_answer.mp3'); // CrsSounds.wrongSoft
      HapticFeedback.selectionClick();
      _wrong.forward(from: 0);
    }
  }

  void _onDragStart(SatelliteType type) {
    widget.onSound('jumpSound.mp3'); // CrsSounds.dragPickup
    HapticFeedback.lightImpact();
    c.onDragStart(type);
  }

  @override
  Widget build(BuildContext context) {
    final merged = Listenable.merge([c, _enter, _snap, _effect, _wrong]);
    return SafeArea(
      child: AnimatedBuilder(
        animation: merged,
        builder: (context, _) {
          final s = c.state;
          final mission = c.mission;
          return Column(
            children: [
              MissionHeader(
                onLeading: widget.onHome,
                soundOn: widget.soundOn,
                onToggleSound: widget.onToggleSound,
              ),
              MissionProgress(
                total: c.missionCount,
                completed: s.completedMissionIds.length,
                currentIndex: s.currentMissionIndex,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: DragTarget<SatelliteType>(
                    onWillAcceptWithDetails: (_) => s.trayEnabled,
                    onMove: (_) => c.setHovering(true),
                    onLeave: (_) => c.setHovering(false),
                    onAcceptWithDetails: (d) => c.resolveDrop(d.data),
                    builder: (context, cand, rej) => MissionCard(
                      mission: mission,
                      enterT: _enter.value,
                      snapT: _snap.value,
                      effectT: _effect.value,
                      wrongT: _wrong.value,
                      hovering: s.isHoveringZone,
                      resolving: s.isResolving,
                      solved: s.isSolved,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MascotHelper(mood: c.mascotMood, line: c.currentLine.text, height: 64),
              ),
              const SizedBox(height: 6),
              SizedBox(height: 116, child: _bottomSlot(s)),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomSlot(ChooseSatelliteState s) {
    final isLast = s.currentMissionIndex >= c.missionCount - 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
      ),
      child: s.isSolved
          ? Padding(
              key: const ValueKey('next'),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Align(
                alignment: Alignment.topCenter,
                child: CrsCtaButton(
                  label: isLast ? 'VIEW MISSION LOG' : 'NEXT MISSION',
                  icon: Icons.arrow_forward_rounded,
                  enabled: !s.voicePlaying,
                  gradient: const LinearGradient(colors: [CareerColors.green, Color(0xFF36B36A)]),
                  onTap: c.nextMission,
                ),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('tray'),
              child: SatelliteTray(
                activeDragType: s.activeDragType,
                pulseHintType: s.pulseHintType,
                canDrag: s.canDrag,
                onDragStart: _onDragStart,
                onDragEnd: c.onDragEnd,
                introRevealT: 1.0,
              ),
            ),
    );
  }
}
