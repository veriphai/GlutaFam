// The cyclone-challenge options (PRD §12, §20). Four cards in a 2x2 grid;
// Satellite is correct. Wrong choices get a card-specific limitation line.

import 'asset_paths.dart';

enum ChallengeOptionId { tower, drone, airplane, satellite }

class ChallengeOption {
  const ChallengeOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.wrongFeedback,
    this.wrongVoiceClip = 0,
  });

  final ChallengeOptionId id;
  final String label;
  /// HM object-icon key (03_objects) shown inside a Flutter-drawn card — the
  /// same crisp icons used in the Scene 1 hologram, so every card looks uniform.
  final String icon;
  /// Shown when this (wrong) option is picked. Unused for the correct option.
  final String wrongFeedback;
  /// Orbit voice clip for the wrong-feedback line (0 = none / correct option).
  final int wrongVoiceClip;
}

const ChallengeOptionId kCorrectChallengeOption = ChallengeOptionId.satellite;

/// 2x2 grid order (PRD §6 styleboard / mockup): Tower, Drone / Airplane, Satellite.
const List<ChallengeOption> kChallengeOptions = [
  ChallengeOption(
    id: ChallengeOptionId.tower,
    label: 'Tower',
    icon: HM.towerIcon,
    wrongFeedback: 'Hmm, not the tower. See how small its view is? That ocean storm is way too far away.',
    wrongVoiceClip: 9,
  ),
  ChallengeOption(
    id: ChallengeOptionId.drone,
    label: 'Drone',
    icon: HM.droneIcon,
    wrongFeedback: 'The drone is helpful nearby, but this cyclone is huge. The drone can’t cover that much ocean for long.',
    wrongVoiceClip: 10,
  ),
  ChallengeOption(
    id: ChallengeOptionId.airplane,
    label: 'Airplane',
    icon: HM.airplaneIcon,
    wrongFeedback: 'The airplane sees a lot, but it has to land. We need something that can keep watching from far above.',
    wrongVoiceClip: 11,
  ),
  ChallengeOption(
    id: ChallengeOptionId.satellite,
    label: 'Satellite',
    icon: HM.satelliteIcon,
    wrongFeedback: '', // correct
  ),
];

ChallengeOption challengeOption(ChallengeOptionId id) =>
    kChallengeOptions.firstWhere((o) => o.id == id);
