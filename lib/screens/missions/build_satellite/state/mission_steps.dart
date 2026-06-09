// The 7-step mission script (PRD §8). Each step names the systems being built,
// the parts required, and the guidance copy shown by the mascot + tip card.

import '../config/part_catalog.dart';

class MissionStep {
  final int number; // 1..7
  final String system; // short rail label
  final String title; // tip-card heading
  final String intro; // mascot copy when the step begins
  final String tip; // contextual mission tip
  final List<String> requiredPartIds;

  const MissionStep({
    required this.number,
    required this.system,
    required this.title,
    required this.intro,
    required this.tip,
    required this.requiredPartIds,
  });
}

const String kMissionCompleteMessage =
    'You did it! Your satellite is fully assembled.';

const String kIntroMessage =
    'Mission Control needs your help! Let’s build a real satellite.';

final List<MissionStep> kMissionSteps = [
  MissionStep(
    number: 1,
    system: 'Power',
    title: 'Power System',
    intro: 'First, let’s give your satellite power. Install both solar panels.',
    tip: 'Every part has a job. Start with the solar panels on the sides.',
    requiredPartIds: partsForStep(1).map((p) => p.id).toList(),
  ),
  MissionStep(
    number: 2,
    system: 'Communicate',
    title: 'Communication',
    intro: 'Next, let’s help the satellite talk to Earth. Add the antenna.',
    tip: 'Install the antenna base first, then the dish on top.',
    requiredPartIds: partsForStep(2).map((p) => p.id).toList(),
  ),
  MissionStep(
    number: 3,
    system: 'Vision',
    title: 'Vision System',
    intro: 'Time to give it eyes. Place the camera in the front bay.',
    tip: 'The camera fits into the round bay on the front.',
    requiredPartIds: partsForStep(3).map((p) => p.id).toList(),
  ),
  MissionStep(
    number: 4,
    system: 'Brain',
    title: 'Brain System',
    intro: 'Every satellite needs a brain. Insert the computer core.',
    tip: 'The computer core controls all the other systems.',
    requiredPartIds: partsForStep(4).map((p) => p.id).toList(),
  ),
  MissionStep(
    number: 5,
    system: 'Battery',
    title: 'Energy Storage',
    intro: 'Let’s store some energy. Slot in the battery.',
    tip: 'The battery keeps the satellite running in the dark.',
    requiredPartIds: partsForStep(5).map((p) => p.id).toList(),
  ),
  MissionStep(
    number: 6,
    system: 'Movement',
    title: 'Movement System',
    intro: 'Now it needs to move. Attach the thruster underneath.',
    tip: 'The thruster lets the satellite steer in space.',
    requiredPartIds: partsForStep(6).map((p) => p.id).toList(),
  ),
  MissionStep(
    number: 7,
    system: 'Protection',
    title: 'Protection System',
    intro: 'Last one! Wrap it in the thermal blanket to keep it safe.',
    tip: 'The thermal blanket shields it from extreme heat and cold.',
    requiredPartIds: partsForStep(7).map((p) => p.id).toList(),
  ),
];

const int kTotalSteps = 7;

MissionStep missionStep(int number) =>
    kMissionSteps.firstWhere((s) => s.number == number);
