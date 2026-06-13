// Data models + Satellite Engineer seed for the profession detail screen.
//
// Backed by static seed data today so the screen can render the moment a
// user taps a profession card on the home page. When backend support lands
// (`GET /howwow/career/professions/{id}`), these same types accept a
// `fromApi(...)` factory just like Profession/CareerWorld in
// careerModels.dart — the widgets are decoupled from the source.

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../../../models/howwow/howwowCareer.dart' as api;
import '../../../models/howwow/howwowProfile.dart' as api;
import 'careerModels.dart' show iconForKey, parseHexColor, parseGradient;
import 'careerTheme.dart';

/// DEV TOGGLE — set true to ignore the server's lock chain and make every
/// episode tappable (e.g. to spot-check a mid-chain episode's videos
/// without completing the ones before it). Gated on [kDebugMode] at the
/// use site, so a `true` left behind can never unlock release builds.
const bool kDevUnlockAllLessons = false;

/// One full profession + season + lesson chain + rewards.
class ProfessionDetail {
  const ProfessionDetail({
    required this.professionId,
    required this.name,
    required this.world,
    required this.worldEmoji,
    required this.accentColor,
    required this.seriesLabel,
    required this.seasonTitle,
    required this.tagline,
    required this.heroGradient,
    required this.lessons,
    required this.rewards,
    required this.certificate,
    this.heroAsset,
    this.footerHint = 'New episode unlocked when you complete the current one!',
  });

  final String professionId;
  final String name;
  final String world;
  final String worldEmoji;
  final Color accentColor;
  final String seriesLabel;     // e.g. "CAREER SERIES"
  final String seasonTitle;     // e.g. "Season 1: Space Helpers"
  final String tagline;         // one-line "what this career is about"
  final List<Color> heroGradient;
  final String? heroAsset;      // optional full-bleed illustration on the hero card
  final List<Lesson> lessons;
  final List<RewardBadge> rewards;
  final Certificate certificate;
  final String footerHint;

  int get total => lessons.length;
  int get completed => lessons.where((e) => e.isCompleted).length;
  double get progress => total == 0 ? 0 : completed / total;

  /// First lesson that isn't completed — drives the "Start / Continue"
  /// CTAs and the "Next Episode" card.
  Lesson? get nextLesson {
    for (final e in lessons) {
      if (!e.isCompleted) return e;
    }
    return null;
  }

  /// Build the UI type from the `/career/professions/{id}/detail` response.
  /// Reward badges and certificate are also mapped from the wire shape;
  /// when those fields are absent (e.g. older backend) the corresponding
  /// section silently empties.
  factory ProfessionDetail.fromApi(api.HowwowProfessionDetail d) {
    final accent = parseHexColor(d.accentColor) ?? CareerColors.purple;
    return ProfessionDetail(
      professionId: d.professionId,
      name: d.name,
      world: d.worldName ?? '',
      worldEmoji: d.worldEmoji ?? '🌍',
      accentColor: accent,
      seriesLabel: d.seriesLabel ?? 'CAREER SERIES',
      seasonTitle: d.seasonTitle ?? '',
      tagline: d.tagline ?? '',
      heroGradient: parseGradient(d.heroGradient),
      heroAsset: d.heroImageUrl,
      lessons: d.lessons.map((m) => Lesson.fromApi(m, defaultAccent: accent)).toList(),
      rewards: d.rewards
          .map((r) => RewardBadge(
                name: r.name,
                icon: iconForKey(r.iconKey),
                color: parseHexColor(r.color) ?? accent,
                imageAsset: r.imageUrl,
                earned: r.earned,
              ))
          .toList(),
      certificate: Certificate(
        title: d.certificate?.title ?? 'Certificate',
        requirementLine: d.certificate?.requirementLine ?? 'Complete all episodes to earn',
        imageAsset: d.certificate?.imageUrl,
      ),
      footerHint: d.footerHint ?? 'New episode unlocked when you complete the current one!',
    );
  }
}

class Lesson {
  const Lesson({
    required this.number,
    required this.title,
    required this.shortDescription,
    this.lessonId,
    this.longDescription,
    this.discoverHook,
    this.rewardName,
    this.rewardImageUrl,
    this.thumbnailIcon = Icons.public_rounded,
    this.thumbnailAsset,
    this.thumbnailColor,
    this.isCompleted = false,
    this.isLocked = true,
    this.resources = const [],
    this.lastCompletedResourceIndex = -1,
    this.startedOnServer = false,
    this.tag,
  });

  /// Backend lesson id (e.g. {@code "satellite_engineer_m1"}) — required by
  /// the lesson runner to POST resource-completion writes. Null on the
  /// static seed Lessons (Satellite Engineer mock); the runner just
  /// skips the progress writes in that case.
  final String? lessonId;

  /// 1-based lesson index displayed on the timeline.
  final int number;
  final String title;
  /// One-liner under the title in the timeline rows.
  final String shortDescription;
  /// Longer copy shown only inside the "Next Episode" card.
  final String? longDescription;
  /// "You'll discover…" hook shown inside the "Next Episode" card.
  final String? discoverHook;
  /// "Reward" label shown inside the "Next Episode" card.
  final String? rewardName;

  /// Absolute URL of the badge artwork for this lesson, rendered inside
  /// the hex on the "Next Episode" reward + on each timeline row.
  /// Null → render the icon hex (using [thumbnailIcon]) as today.
  final String? rewardImageUrl;

  /// Used as a fallback when [thumbnailAsset] is null or fails to load.
  final IconData thumbnailIcon;
  /// Square illustration shown to the left of the title in timeline rows
  /// and inside the "Next Episode" card.
  final String? thumbnailAsset;
  final Color? thumbnailColor;
  final bool isCompleted;
  /// Locked rows show a lock icon and ignore taps.
  final bool isLocked;

  /// Ordered list of resources (video/image/activity) the lesson runner
  /// walks through when the user taps "Start Episode".
  final List<api.HowwowLessonResource> resources;

  /// Highest resource index already completed; {@code -1} when nothing
  /// is done yet. The launcher passes {@code lastCompletedResourceIndex + 1}
  /// as the runner's {@code startFromIndex} so the user resumes at the
  /// next unfinished resource instead of restarting from the intro.
  final int lastCompletedResourceIndex;

  /// Server saw a resource-start write for this lesson (the user opened
  /// it, even if nothing completed). Mirrors
  /// `HowwowDetailLesson.started`; false on static seed Lessons.
  final bool startedOnServer;

  /// Optional short badge shown on the timeline row (e.g. "LONGEST" to flag
  /// the heaviest episode). Null → no badge. Seed-only today.
  final String? tag;

  bool get isCurrent => !isCompleted && !isLocked;

  /// True when the user has started this lesson but not yet finished it
  /// — drives copy like "Resume" instead of "Start" on the CTA. Either
  /// signal counts: a completed resource (works today) or a server-side
  /// start write ("opened the intro, backed out" — needs the backend from
  /// docs/howwow-resource-start-spec.md).
  bool get isPartiallyStarted =>
      !isCompleted && (lastCompletedResourceIndex >= 0 || startedOnServer);

  /// Build the UI type from the `/career/professions/{id}/detail` lesson
  /// DTO. `defaultAccent` is used to colour the thumbnail when the wire
  /// payload doesn't carry one.
  factory Lesson.fromApi(api.HowwowDetailLesson m,
      {required Color defaultAccent}) {
    return Lesson(
      lessonId: m.lessonId,
      number: m.lessonNumber,
      title: m.title,
      shortDescription: m.description ?? '',
      longDescription: m.descriptionLong,
      discoverHook: m.discoverHook,
      rewardName: m.rewardName,
      rewardImageUrl: m.rewardImageUrl,
      thumbnailIcon: iconForKey(m.thumbnailIconKey),
      // Episode art URL rides the existing thumbnailAsset slot —
      // _SquareThumbnail picks NetworkImage vs AssetImage by prefix.
      thumbnailAsset: m.thumbnailImageUrl,
      thumbnailColor: defaultAccent,
      isCompleted: m.completed,
      // Honour the server's lock state — the backend computes
      // "lesson N unlocked iff N-1 in completedLessonIds". The dev toggle
      // (debug builds only) overrides it for episode spot-checks.
      //
      // BUT an episode with NO resources (content not built yet, e.g.
      // electricity Ep3) stays LOCKED no matter what — finishing the prior
      // episode must never open an empty one, and the dev unlock can't reach
      // it either (nothing to spot-check). Because it can't be completed,
      // this also stalls the unlock chain at the first content-less episode,
      // keeping every later episode locked too.
      isLocked: m.resources.isEmpty
          ? true
          : (kDebugMode && kDevUnlockAllLessons)
              ? false
              : m.locked,
      resources: m.resources,
      lastCompletedResourceIndex: m.lastCompletedResourceIndex,
      startedOnServer: m.started,
      tag: m.tag,
    );
  }
}

class RewardBadge {
  const RewardBadge({
    required this.name,
    required this.icon,
    required this.color,
    this.imageAsset,
    this.earned = false,
  });

  final String name;
  final IconData icon;
  final Color color;
  final String? imageAsset;
  final bool earned;
}

class Certificate {
  const Certificate({
    required this.title,
    this.requirementLine = 'Complete all episodes to earn',
    this.imageAsset,
  });

  final String title;
  final String requirementLine;
  final String? imageAsset;
}

// ── Satellite Engineer seed (matches the mock 1:1) ─────────────────

const ProfessionDetail kSatelliteEngineerDetail = ProfessionDetail(
  professionId: 'satellite_engineer',
  name: 'Satellite Engineer',
  world: 'Space World',
  worldEmoji: '🪐',
  accentColor: CareerColors.purple,
  seriesLabel: 'CAREER SERIES',
  seasonTitle: 'Season 1: Space Helpers',
  tagline: 'Build machines that help people on Earth every day.',
  heroGradient: [Color(0xFF3A2C7A), Color(0xFF1A2566)],
  heroAsset: 'assets/images/satellite_engineer.png',
  // Mirrors the seeded backend catalog (titles/copy updated 2026-06-07,
  // episodes 4↔5 swapped: choose before build). Fallback-only — no
  // resources wired, so tapping rows in demo mode shows the "not
  // available yet" snackbar, same as before.
  lessons: [
    Lesson(
      number: 1,
      title: 'The Day the World Went Blind',
      shortDescription:
          'Discover the invisible satellites powering everyday life.',
      longDescription:
          'Maps fail, weather alerts vanish, and signals go dark. Spot the space helpers Earth secretly depends on.',
      discoverHook: 'How satellites quietly help us every day.',
      rewardName: 'Junior Satellite Engineer',
      thumbnailIcon: Icons.satellite_alt_rounded,
      thumbnailColor: CareerColors.purple,
      isCompleted: false,
      isLocked: false,
    ),
    Lesson(
      number: 2,
      title: 'Why Put a Machine in Space?',
      shortDescription: 'Find out why satellites need a view from space.',
      thumbnailIcon: Icons.cloud_rounded,
      thumbnailColor: CareerColors.cyan,
    ),
    Lesson(
      number: 3,
      title: 'The Great Falling Trick',
      shortDescription: 'Unlock the secret of how satellites stay in orbit.',
      thumbnailIcon: Icons.public_rounded,
      thumbnailColor: CareerColors.gold,
    ),
    Lesson(
      number: 4,
      title: 'Choose the Right Satellite',
      shortDescription: 'Pick the perfect satellite for every mission.',
      thumbnailIcon: Icons.satellite_alt_rounded,
      thumbnailColor: CareerColors.blue,
    ),
    Lesson(
      number: 5,
      title: 'Build the Space Helper',
      shortDescription:
          'Assemble a satellite built to see, think, and survive.',
      thumbnailIcon: Icons.engineering_rounded,
      thumbnailColor: CareerColors.green,
    ),
    Lesson(
      number: 6,
      title: 'Keep the Satellite Alive',
      shortDescription:
          'Manage power when there are no plug points in space.',
      thumbnailIcon: Icons.battery_charging_full_rounded,
      thumbnailColor: CareerColors.pink,
    ),
    Lesson(
      number: 7,
      title: 'Talk to Earth',
      shortDescription:
          'Send important satellite data back to Mission Control.',
      thumbnailIcon: Icons.settings_input_antenna_rounded,
      thumbnailColor: CareerColors.blue,
    ),
    Lesson(
      number: 8,
      title: 'Earth Detective',
      shortDescription: 'Use satellite images to solve real-world mysteries.',
      thumbnailIcon: Icons.travel_explore_rounded,
      thumbnailColor: CareerColors.orange,
    ),
    Lesson(
      number: 9,
      title: 'Satellite Doctor',
      shortDescription:
          'Diagnose and fix your satellite before the mission fails.',
      thumbnailIcon: Icons.healing_rounded,
      thumbnailColor: CareerColors.green,
    ),
    Lesson(
      number: 10,
      title: 'Program the Satellite',
      shortDescription:
          'Give your satellite the perfect step-by-step mission plan.',
      thumbnailIcon: Icons.smart_toy_rounded,
      thumbnailColor: CareerColors.cyan,
    ),
    Lesson(
      number: 11,
      title: 'Save the Coastal City',
      shortDescription:
          'Use every satellite skill to stop a cyclone disaster.',
      thumbnailIcon: Icons.thunderstorm_rounded,
      thumbnailColor: CareerColors.pink,
    ),
  ],
  rewards: [
    RewardBadge(
      name: 'Orbit Rookie',
      icon: Icons.satellite_alt_rounded,
      color: CareerColors.purple,
    ),
    RewardBadge(
      name: 'Space View',
      icon: Icons.visibility_rounded,
      color: CareerColors.cyan,
    ),
    RewardBadge(
      name: 'Orbit Master',
      icon: Icons.public_rounded,
      color: CareerColors.gold,
    ),
    RewardBadge(
      name: 'Signal Scout',
      icon: Icons.settings_input_antenna_rounded,
      color: CareerColors.blue,
    ),
    RewardBadge(
      name: 'Junior Engineer',
      icon: Icons.engineering_rounded,
      color: CareerColors.green,
    ),
  ],
  certificate: Certificate(
    title: 'Junior Satellite Engineer Certificate',
  ),
);
