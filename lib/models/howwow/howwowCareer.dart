// Typed Dart mirrors for the /howwow/career/* response DTOs. The widget
// tree consumes its existing local UI types (Profession, CareerWorld,
// ContinueMission); these classes are the raw on-the-wire shapes plus
// `.fromApi(...)` adapters live in `careerModels.dart` to convert them.

import 'howwowProfile.dart';

class HowwowWorld {
  const HowwowWorld({
    required this.worldId,
    required this.name,
    this.accentColor,
    this.gradient = const [],
    this.professionCount = 0,
    this.sampleProfessions = const [],
    this.imageUrl,
    this.locked = false,
  });

  final String worldId;
  final String name;
  final String? accentColor;        // hex string e.g. "#7C4DFF"
  final List<String> gradient;       // list of hex stops
  final int professionCount;
  final List<String> sampleProfessions;
  final String? imageUrl;            // asset path or remote URL
  final bool locked;

  factory HowwowWorld.fromJson(Map<String, dynamic> j) => HowwowWorld(
        worldId: j['worldId']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        accentColor: j['accentColor'] as String?,
        gradient: (j['gradient'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        professionCount: _int(j['professionCount']),
        sampleProfessions:
            (j['sampleProfessions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        imageUrl: j['imageUrl'] as String?,
        locked: j['locked'] == true,
      );
}

class HowwowProfession {
  const HowwowProfession({
    required this.professionId,
    required this.name,
    this.worldId,
    this.description,
    this.iconKey,
    this.accentColor,
    this.gradient = const [],
    this.imageUrl,
    this.missionCount = 0,
    this.recommended = false,
    this.locked = false,
  });

  final String professionId;
  final String name;
  final String? worldId;
  final String? description;
  final String? iconKey;             // e.g. "satellite_alt" — client maps to IconData
  final String? accentColor;
  final List<String> gradient;
  final String? imageUrl;
  final int missionCount;
  final bool recommended;
  final bool locked;                 // gameplay gated; the UI decides how to render it

  factory HowwowProfession.fromJson(Map<String, dynamic> j) => HowwowProfession(
        professionId: j['professionId']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        worldId: j['worldId'] as String?,
        description: j['description'] as String?,
        iconKey: j['iconKey'] as String?,
        accentColor: j['accentColor'] as String?,
        gradient: (j['gradient'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        imageUrl: j['imageUrl'] as String?,
        missionCount: _int(j['missionCount']),
        recommended: j['recommended'] == true,
        locked: j['locked'] == true,
      );
}

class HowwowDailyChallenge {
  const HowwowDailyChallenge({
    this.challengeId,
    this.professionId,
    this.professionName,
    this.prompt,
    this.type,
    this.rewardXp = 0,
    this.expiresAtEpochSec = 0,
  });

  final String? challengeId;
  final String? professionId;
  final String? professionName;
  final String? prompt;
  final String? type;                // "quiz" | "drag" | "decision" | ...
  final int rewardXp;
  final int expiresAtEpochSec;

  factory HowwowDailyChallenge.fromJson(Map<String, dynamic> j) => HowwowDailyChallenge(
        challengeId: j['challengeId'] as String?,
        professionId: j['professionId'] as String?,
        professionName: j['professionName'] as String?,
        prompt: j['prompt'] as String?,
        type: j['type'] as String?,
        rewardXp: _int(j['rewardXp']),
        expiresAtEpochSec: _int(j['expiresAtEpochSec']),
      );
}

/// Full `GET /howwow/career/home` payload — everything the home screen needs
/// in one round trip. Sub-models that already exist (HowwowStats, etc.) are
/// reused from {@link howwowProfile.dart}.
class HowwowHomeBundle {
  const HowwowHomeBundle({
    this.stats,
    this.currentLesson,
    this.professions = const [],
    this.worlds = const [],
    this.todaysChallenge,
    this.passport,
    this.notifications,
  });

  final HowwowStats? stats;
  final HowwowCurrentLesson? currentLesson;
  final List<HowwowProfession> professions;
  final List<HowwowWorld> worlds;
  final HowwowDailyChallenge? todaysChallenge;
  final HowwowPassport? passport;
  final HowwowNotifications? notifications;

  factory HowwowHomeBundle.fromJson(Map<String, dynamic> j) => HowwowHomeBundle(
        stats: _mapOrNull(j['stats'], HowwowStats.fromJson),
        currentLesson: _mapOrNull(j['currentLesson'], HowwowCurrentLesson.fromJson),
        professions: (j['professions'] as List?)
                ?.whereType<Map>()
                .map((e) => HowwowProfession.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        worlds: (j['worlds'] as List?)
                ?.whereType<Map>()
                .map((e) => HowwowWorld.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        todaysChallenge: _mapOrNull(j['todaysChallenge'], HowwowDailyChallenge.fromJson),
        passport: _mapOrNull(j['passport'], HowwowPassport.fromJson),
        notifications: _mapOrNull(j['notifications'], HowwowNotifications.fromJson),
      );
}

// ── Profession-detail payload (full /career/professions/{id}/detail) ──

class HowwowDetailLesson {
  const HowwowDetailLesson({
    required this.lessonId,
    required this.lessonNumber,
    required this.title,
    this.description,
    this.descriptionLong,
    this.discoverHook,
    this.rewardName,
    this.rewardImageUrl,
    this.thumbnailIconKey,
    this.thumbnailImageUrl,
    this.skills = const [],
    this.resources = const [],
    this.completed = false,
    this.locked = false,
    this.current = false,
    this.lastCompletedResourceIndex = -1,
    this.startedOnServer = false,
  });

  final String lessonId;
  final int lessonNumber;
  final String title;
  final String? description;
  final String? descriptionLong;
  final String? discoverHook;
  final String? rewardName;

  /// Absolute URL of the badge artwork for this lesson (typically an S3
  /// `activities/<id>/...` key). Null when no art is wired — the client
  /// falls back to drawing an icon-themed hex instead.
  final String? rewardImageUrl;

  final String? thumbnailIconKey;

  /// Absolute URL of the 512x512 square episode illustration (S3
  /// `professions/<id>/episode_thumbnails/...`). Null -> the client renders
  /// the icon hex from [thumbnailIconKey], same as before the art existed.
  final String? thumbnailImageUrl;
  final List<String> skills;
  final List<HowwowLessonResource> resources;
  final bool completed;
  final bool locked;
  final bool current;

  /// Highest resource index the user has completed inside this lesson,
  /// or {@code -1} when nothing is done yet. The runner uses
  /// {@code lastCompletedResourceIndex + 1} as the resume start.
  final int lastCompletedResourceIndex;

  /// Raw wire flag: the server saw a resource-start write for this lesson
  /// (`startedAt` is set on its progress doc). Absent until the backend
  /// ships docs/howwow-resource-start-spec.md. Prefer [started], which
  /// also derives from completions and so works against today's payloads.
  final bool startedOnServer;

  /// True when the user has been inside this lesson at all — opened it
  /// (start write) OR completed at least one resource.
  bool get started => startedOnServer || lastCompletedResourceIndex >= 0;

  factory HowwowDetailLesson.fromJson(Map<String, dynamic> j) => HowwowDetailLesson(
        lessonId: j['lessonId']?.toString() ?? '',
        lessonNumber: _int(j['lessonNumber']),
        title: j['title']?.toString() ?? '',
        description: j['description'] as String?,
        descriptionLong: j['descriptionLong'] as String?,
        discoverHook: j['discoverHook'] as String?,
        rewardName: j['rewardName'] as String?,
        rewardImageUrl: j['rewardImageUrl'] as String?,
        thumbnailIconKey: j['thumbnailIconKey'] as String?,
        thumbnailImageUrl: j['thumbnailImageUrl'] as String?,
        skills: (j['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        resources: (j['resources'] as List?)
                ?.whereType<Map>()
                .map((e) => HowwowLessonResource.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        completed: j['completed'] == true,
        locked: j['locked'] == true,
        current: j['current'] == true,
        lastCompletedResourceIndex: j['lastCompletedResourceIndex'] is num
            ? (j['lastCompletedResourceIndex'] as num).toInt()
            : -1,
        startedOnServer: j['started'] == true,
      );
}

class HowwowRewardBadgeDto {
  const HowwowRewardBadgeDto({
    required this.rewardId,
    required this.name,
    this.iconKey,
    this.color,
    this.imageUrl,
    this.earned = false,
  });

  final String rewardId;
  final String name;
  final String? iconKey;
  final String? color;
  final String? imageUrl;
  final bool earned;

  factory HowwowRewardBadgeDto.fromJson(Map<String, dynamic> j) => HowwowRewardBadgeDto(
        rewardId: j['rewardId']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        iconKey: j['iconKey'] as String?,
        color: j['color'] as String?,
        imageUrl: j['imageUrl'] as String?,
        earned: j['earned'] == true,
      );
}

class HowwowCertificateDto {
  const HowwowCertificateDto({
    required this.title,
    this.requirementLine,
    this.imageUrl,
    this.earned = false,
  });

  final String title;
  final String? requirementLine;
  final String? imageUrl;
  final bool earned;

  factory HowwowCertificateDto.fromJson(Map<String, dynamic> j) => HowwowCertificateDto(
        title: j['title']?.toString() ?? '',
        requirementLine: j['requirementLine'] as String?,
        imageUrl: j['imageUrl'] as String?,
        earned: j['earned'] == true,
      );
}

class HowwowProfessionDetail {
  const HowwowProfessionDetail({
    required this.professionId,
    required this.name,
    this.worldId,
    this.worldName,
    this.worldEmoji,
    this.accentColor,
    this.heroGradient = const [],
    this.heroImageUrl,
    this.seriesLabel,
    this.seasonTitle,
    this.tagline,
    this.locked = false,
    this.completedCount = 0,
    this.totalCount = 0,
    this.lessons = const [],
    this.rewards = const [],
    this.certificate,
    this.footerHint,
  });

  final String professionId;
  final String name;
  final String? worldId;
  final String? worldName;
  final String? worldEmoji;
  final String? accentColor;
  final List<String> heroGradient;
  final String? heroImageUrl;
  final String? seriesLabel;
  final String? seasonTitle;
  final String? tagline;
  final bool locked;
  final int completedCount;
  final int totalCount;
  final List<HowwowDetailLesson> lessons;
  final List<HowwowRewardBadgeDto> rewards;
  final HowwowCertificateDto? certificate;
  final String? footerHint;

  factory HowwowProfessionDetail.fromJson(Map<String, dynamic> j) => HowwowProfessionDetail(
        professionId: j['professionId']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        worldId: j['worldId'] as String?,
        worldName: j['worldName'] as String?,
        worldEmoji: j['worldEmoji'] as String?,
        accentColor: j['accentColor'] as String?,
        heroGradient: (j['heroGradient'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        heroImageUrl: j['heroImageUrl'] as String?,
        seriesLabel: j['seriesLabel'] as String?,
        seasonTitle: j['seasonTitle'] as String?,
        tagline: j['tagline'] as String?,
        locked: j['locked'] == true,
        completedCount: _int(j['completedCount']),
        totalCount: _int(j['totalCount']),
        lessons: (j['lessons'] as List?)
                ?.whereType<Map>()
                .map((e) => HowwowDetailLesson.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        rewards: (j['rewards'] as List?)
                ?.whereType<Map>()
                .map((e) => HowwowRewardBadgeDto.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        certificate: _mapOrNull(j['certificate'], HowwowCertificateDto.fromJson),
        footerHint: j['footerHint'] as String?,
      );
}

// ── small parsing helpers (file-private) ───────────────────────────────

T? _mapOrNull<T>(dynamic value, T Function(Map<String, dynamic>) factory) {
  if (value is Map) {
    return factory(Map<String, dynamic>.from(value));
  }
  return null;
}

int _int(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
