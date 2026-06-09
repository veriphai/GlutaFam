// The brain of Satellite Doctor. A ChangeNotifier that owns the mission index,
// the per-mission step machine (alert → inspect → chooseRepair → applyRepair →
// repaired), the status-chip states, wrong-answer retry, and drives the Flame
// stage through the SatelliteStage interface.

import 'package:flutter/foundation.dart';

import '../config/asset_paths.dart';
import '../config/missions.dart';
import '../models/satellite_doctor_mission.dart';
import 'satellite_stage.dart';

enum SceneGroup { intro, mission, complete }

enum ChipStatus { good, warning }

class ChipView {
  final ChipKind kind;
  final String label;
  final String value;
  final ChipStatus status;
  const ChipView(this.kind, this.label, this.value, this.status);
}

class SatelliteDoctorController extends ChangeNotifier {
  SatelliteDoctorController({
    required this.onSound,
    required this.onHaptic,
    required this.onExit,
  });

  final void Function(String assetFile) onSound;
  final VoidCallback onHaptic;
  final VoidCallback onExit;

  SatelliteStage? _stage;
  void attachStage(SatelliteStage stage) => _stage = stage;

  // ── state ──────────────────────────────────────────────────────────────────
  SceneGroup scene = SceneGroup.intro;
  int missionIndex = 0;
  MissionStep step = MissionStep.alert;

  String? selectedRepairId; // currently highlighted card
  String? wrongOptionId; // last wrong pick (for the red/shake state)
  int wrongToken = 0; // bump to fire a one-shot shake
  bool correctChosen = false; // correct repair picked → lock all cards
  double applyProgress = 0; // 0..1 of the apply interaction
  bool applyLocked = false; // interaction finished → fix applied

  final Set<int> repairedMissions = {}; // mission ids completed

  // ── voice (Orbit) ───────────────────────────────────────────────────────────
  // Clip layout in assets/sounds/satellite_doctor/orbit/: 01–02 intro,
  // then 8 clips per mission (alert, inspect, teaching, choose, wrong, apply,
  // fix-applied, success) at the bases below, 59–60 final. The screen plays
  // [voiceClip] whenever [voiceToken] changes, then chains [voiceFollowUp].
  int? voiceClip;
  int? voiceFollowUp;
  int voiceToken = 0;

  static const Map<SatelliteFaultType, int> _voiceBase = {
    SatelliteFaultType.batteryOverheating: 3,
    SatelliteFaultType.signalLost: 11,
    SatelliteFaultType.cameraOffline: 19,
    SatelliteFaultType.solarPanelNotCharging: 27,
    SatelliteFaultType.spaceDebrisNearby: 35,
    SatelliteFaultType.solarPanelStuck: 43,
    SatelliteFaultType.orbitDrifting: 51, // disabled mission; clips reserved
  };

  int get _base => _voiceBase[mission.faultType]!;

  void _speak(int clip, {int? followUp}) {
    voiceClip = clip;
    voiceFollowUp = followUp;
    voiceToken++;
  }

  SatelliteDoctorMission get mission => kMissions[missionIndex];
  int get missionNumber => missionIndex + 1;
  int get missionCount => kMissions.length;

  // ── lifecycle ───────────────────────────────────────────────────────────────
  void onFirstBuild() {
    // Pre-warm the stage with mission 1 visuals behind the intro overlay.
    _whenStageReady(() => _stage?.loadMission(0, kMissions[0].faultType));
  }

  void _whenStageReady(VoidCallback fn, {int tries = 0}) {
    if (_stage?.stageReady ?? false) {
      fn();
    } else if (tries < 80) {
      Future.delayed(const Duration(milliseconds: 50),
          () => _whenStageReady(fn, tries: tries + 1));
    }
  }

  // ── intro → first mission ────────────────────────────────────────────────────
  void startDiagnosis() {
    scene = SceneGroup.mission;
    _enterMission(0);
    notifyListeners();
  }

  void _enterMission(int index) {
    missionIndex = index;
    step = MissionStep.alert;
    selectedRepairId = null;
    wrongOptionId = null;
    correctChosen = false;
    applyProgress = 0;
    applyLocked = false;
    onSound(SDSounds.tap);
    _speak(_base); // alert line
    _whenStageReady(() => _stage?.loadMission(index, kMissions[index].faultType));
  }

  // ── step transitions ─────────────────────────────────────────────────────────

  /// Alert → Inspect.
  void beginInspect() {
    if (step != MissionStep.alert) return;
    step = MissionStep.inspect;
    onHaptic();
    onSound(SDSounds.tap);
    _speak(_base + 1, followUp: _base + 2); // inspect line → teaching beat
    _stage?.enterInspect(mission.faultType);
    notifyListeners();
  }

  /// Inspect → Choose Repair.
  void finishInspect() {
    if (step != MissionStep.inspect) return;
    step = MissionStep.chooseRepair;
    _speak(_base + 3); // choose line
    _stage?.exitInspect();
    notifyListeners();
  }

  /// Tap a repair card.
  void chooseRepair(String optionId) {
    if (step != MissionStep.chooseRepair || correctChosen) return;
    final opt = mission.repairOptions.firstWhere((o) => o.id == optionId);
    selectedRepairId = optionId;
    if (opt.isCorrect) {
      correctChosen = true;
      wrongOptionId = null;
      onHaptic();
      onSound(SDSounds.correct);
      notifyListeners();
      // brief "correct card" beat, then move to apply (+ its instruction line)
      Future.delayed(const Duration(milliseconds: 650), () {
        step = MissionStep.applyRepair;
        applyProgress = 0;
        applyLocked = false;
        _speak(_base + 5); // apply instruction
        _stage?.beginApply(mission.interaction);
        notifyListeners();
      });
    } else {
      wrongOptionId = optionId;
      wrongToken++;
      onSound(SDSounds.wrong);
      _speak(_base + 4); // wrong-pick hint (token bump → replays on repeat)
      notifyListeners();
    }
  }

  /// Live progress from the apply-interaction widget (0..1).
  void setApplyProgress(double t) {
    if (step != MissionStep.applyRepair || applyLocked) return;
    applyProgress = t.clamp(0, 1);
    _stage?.updateApply(mission.interaction, applyProgress);
    if (applyProgress >= 0.999 && !applyLocked) {
      _lockRepair();
    }
    notifyListeners();
  }

  void _lockRepair() {
    applyLocked = true;
    applyProgress = 1;
    onHaptic();
    onSound(SDSounds.correct);
    _speak(_base + 6); // fix-applied line ("Nice, hold it there…")
    _stage?.finishRepair(mission.faultType);
    notifyListeners();
    // VOICE-PACED: the screen calls onVoiceFinished() when the fix-applied
    // clip completes (or its safety timer / mute fallback fires) — never a
    // fixed timer, which would cut the line or leave silence (playbook rule).
  }

  /// Single router for "the current voice line finished" — only the
  /// fix-applied → repaired transition is voice-driven; all other clips no-op.
  void onVoiceFinished() {
    if (step == MissionStep.applyRepair && applyLocked) {
      step = MissionStep.repaired;
      repairedMissions.add(mission.id);
      onSound(SDSounds.complete);
      _speak(_base + 7); // success line
      notifyListeners();
    }
  }

  /// Repaired → next mission, or the final completion screen.
  void nextMission() {
    if (missionIndex + 1 >= kMissions.length) {
      scene = SceneGroup.complete;
      onSound(SDSounds.complete);
      _speak(59, followUp: 60); // "We did it!" → learning wrap-up
      _stage?.celebrateFinal();
      notifyListeners();
      return;
    }
    _enterMission(missionIndex + 1);
    notifyListeners();
  }

  void replay() {
    repairedMissions.clear();
    scene = SceneGroup.mission;
    _enterMission(0);
    notifyListeners();
  }

  // ── status chips ─────────────────────────────────────────────────────────────
  /// The chips shown in the header for the current mission/step.
  List<ChipView> chips() {
    const defaults = <ChipKind, ChipView>{
      ChipKind.power: ChipView(ChipKind.power, 'POWER', '100%', ChipStatus.good),
      ChipKind.signal: ChipView(ChipKind.signal, 'SIGNAL', 'Strong', ChipStatus.good),
      ChipKind.temperature: ChipView(ChipKind.temperature, 'TEMP', '24°C', ChipStatus.good),
      ChipKind.orbit: ChipView(ChipKind.orbit, 'ORBIT', 'Stable', ChipStatus.good),
    };

    final m = mission;
    final fixed = step == MissionStep.repaired || applyLocked;

    // first three are fixed; the fourth slot is contextual (orbit/camera/solar)
    final order = <ChipKind>[ChipKind.power, ChipKind.signal, ChipKind.temperature];
    if (m.warningChip == ChipKind.camera) {
      order.add(ChipKind.camera);
    } else if (m.warningChip == ChipKind.solar) {
      order.add(ChipKind.solar);
    } else {
      order.add(ChipKind.orbit);
    }

    return order.map((kind) {
      if (kind == ChipKind.camera) {
        return ChipView(kind, 'CAMERA', fixed ? m.chipAfterValue : m.chipBeforeValue,
            fixed ? ChipStatus.good : ChipStatus.warning);
      }
      if (kind == ChipKind.solar) {
        return ChipView(kind, 'SOLAR', fixed ? m.chipAfterValue : m.chipBeforeValue,
            fixed ? ChipStatus.good : ChipStatus.warning);
      }
      if (kind == m.warningChip) {
        return ChipView(kind, defaults[kind]!.label,
            fixed ? m.chipAfterValue : m.chipBeforeValue,
            fixed ? ChipStatus.good : ChipStatus.warning);
      }
      return defaults[kind]!;
    }).toList();
  }
}
