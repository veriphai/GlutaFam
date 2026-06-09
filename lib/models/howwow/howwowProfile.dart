// Typed mirror of HowwowProfile + nested DTOs returned by the howwow auth
// + profile endpoints. Lifted directly from the API revamp plan (§3.1).

/// Profile payload embedded in {@link LoginResponse} (and returned by the
/// upcoming `GET /howwow/profile`). The client routes post-login by reading
/// `phoneVerified` — if false (Google/Apple first sign-in), the user is sent
/// to the PhoneCollectionScreen.
class HowwowProfile {
  const HowwowProfile({
    this.userTrackingId,
    this.firstName,
    this.lastName,
    this.displayName,
    this.emailId,
    this.phoneNumber,
    this.phoneVerified = false,
    this.avatar,
    this.signInProvider,
    this.sourceApp,
    this.newUser = false,
    this.ageGroup,
    this.interests = const [],
    this.stats,
    this.career,
    this.notifications,
  });

  final String? userTrackingId;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? emailId;
  final String? phoneNumber;
  final bool phoneVerified;
  final HowwowAvatar? avatar;
  final String? signInProvider; // "google.com" | "apple.com" | "phone"
  final String? sourceApp;      // "howwow" | "tuto" | ...
  final bool newUser;

  /// Onboarding answers — "under-11" | "11-13" | "14-16" | "17-plus".
  final String? ageGroup;

  /// Onboarding interest ids (see kOnboardingInterests in onboardingFlow.dart).
  final List<String> interests;

  final HowwowStats? stats;
  final HowwowCareer? career;
  final HowwowNotifications? notifications;

  factory HowwowProfile.fromJson(Map<String, dynamic> j) => HowwowProfile(
        userTrackingId: j['userTrackingId'] as String?,
        firstName: j['firstName'] as String?,
        lastName: j['lastName'] as String?,
        displayName: j['displayName'] as String?,
        emailId: j['emailId'] as String?,
        phoneNumber: j['phoneNumber'] as String?,
        phoneVerified: j['phoneVerified'] == true,
        avatar: _mapOrNull(j['avatar'], HowwowAvatar.fromJson),
        signInProvider: j['signInProvider'] as String?,
        sourceApp: j['sourceApp'] as String?,
        newUser: j['newUser'] == true,
        ageGroup: j['ageGroup'] as String?,
        interests:
            (j['interests'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        stats: _mapOrNull(j['stats'], HowwowStats.fromJson),
        career: _mapOrNull(j['career'], HowwowCareer.fromJson),
        notifications: _mapOrNull(j['notifications'], HowwowNotifications.fromJson),
      );
}

class HowwowAvatar {
  const HowwowAvatar({this.kind, this.presetId, this.imageUrl});

  final String? kind;       // "preset" | "image"
  final String? presetId;
  final String? imageUrl;

  factory HowwowAvatar.fromJson(Map<String, dynamic> j) => HowwowAvatar(
        kind: j['kind'] as String?,
        presetId: j['presetId'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );
}

class HowwowStats {
  const HowwowStats({this.xp = 0, this.badges = 0, this.streakDays = 0});

  final int xp;
  final int badges;
  final int streakDays;

  factory HowwowStats.fromJson(Map<String, dynamic> j) => HowwowStats(
        xp: _int(j['xp']),
        badges: _int(j['badges']),
        streakDays: _int(j['streakDays']),
      );
}

/// One step inside a lesson — a video, image or playable activity. The
/// frontend `openLesson(...)` runner walks this list in order, pushing one
/// screen per resource.
class HowwowLessonResource {
  const HowwowLessonResource({
    required this.type,
    this.url,
    this.activityId,
    this.durationSeconds,
    this.caption,
  });

  /// "video" | "image" | "activity"
  final String type;

  /// For video/image resources. The runner detects an `http*` prefix to
  /// decide between {@code VideoPlayerController.networkUrl} (S3) and
  /// {@code .asset(...)} (bundled assets).
  final String? url;

  /// Registry key for {@code "activity"} resources — looked up in
  /// {@code activityRegistry.dart} to find the Widget.
  final String? activityId;

  /// Optional auto-advance timer for {@code "image"} resources. {@code null}
  /// means "tap to advance".
  final int? durationSeconds;

  /// Optional caption / overlay text.
  final String? caption;

  factory HowwowLessonResource.fromJson(Map<String, dynamic> j) =>
      HowwowLessonResource(
        type: j['type']?.toString() ?? '',
        url: j['url'] as String?,
        activityId: j['activityId'] as String?,
        durationSeconds: j['durationSeconds'] is num
            ? (j['durationSeconds'] as num).toInt()
            : null,
        caption: j['caption'] as String?,
      );
}

/// Hero "Continue Career Mission" card payload — what shows up on the home
/// page when a user has a lesson in progress (or is being recommended their
/// first one).
class HowwowCurrentLesson {
  const HowwowCurrentLesson({
    this.lessonId,
    this.professionId,
    this.worldId,
    this.lessonNumber = 0,
    this.title,
    this.skills = const [],
    this.resources = const [],
    this.completedCount = 0,
    this.totalCount = 0,
    this.lastCompletedResourceIndex = -1,
    this.startedAt,
  });

  final String? lessonId;
  final String? professionId;
  final String? worldId;
  final int lessonNumber;
  final String? title;
  final List<String> skills;
  final List<HowwowLessonResource> resources;

  /// Number of lessons the user has completed in this profession —
  /// drives the "X / Y Missions" pill on the home Continue card.
  final int completedCount;

  /// Total lessons in this profession.
  final int totalCount;

  /// Highest resource index completed inside THIS lesson, or `-1`
  /// when nothing is done yet — same semantics as the field on
  /// `HowwowDetailLesson`. Lets the home card say
  /// "Resume — step 2 of 3" without a detail round trip.
  /// Absent until the backend ships the resource-start spec
  /// (docs/howwow-resource-start-spec.md); defaults keep old payloads
  /// rendering exactly as before.
  final int lastCompletedResourceIndex;

  /// ISO-8601 timestamp of the user's FIRST entry into this lesson, or
  /// null when the lesson was never opened. Set by the
  /// POST /lessons/{id}/resources/{idx}/start write — this is what
  /// distinguishes "opened but nothing completed yet" from "untouched".
  final String? startedAt;

  /// True when the user has been inside this lesson at all — drives
  /// "Start" vs "Continue" copy. Derived so it works as soon as EITHER
  /// signal exists (startedAt needs the new backend; a completed
  /// resource works today).
  bool get started => startedAt != null || lastCompletedResourceIndex >= 0;

  /// Index of the resource the user is on (= next to play). Always the
  /// derivation `lastCompleted + 1` clamped to the list — the server
  /// enforces monotonic completion so this never disagrees with a
  /// stored "current" pointer.
  int get nextResourceIndex => resources.isEmpty
      ? 0
      : (lastCompletedResourceIndex + 1).clamp(0, resources.length - 1);

  factory HowwowCurrentLesson.fromJson(Map<String, dynamic> j) => HowwowCurrentLesson(
        lessonId: j['lessonId'] as String?,
        professionId: j['professionId'] as String?,
        worldId: j['worldId'] as String?,
        lessonNumber: _int(j['lessonNumber']),
        title: j['title'] as String?,
        skills: (j['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        resources: (j['resources'] as List?)
                ?.whereType<Map>()
                .map((e) => HowwowLessonResource.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        completedCount: _int(j['completedCount']),
        totalCount: _int(j['totalCount']),
        lastCompletedResourceIndex: j['lastCompletedResourceIndex'] is num
            ? (j['lastCompletedResourceIndex'] as num).toInt()
            : -1,
        startedAt: j['startedAt'] as String?,
      );
}

class HowwowPassport {
  const HowwowPassport({
    this.jobsExplored = 0,
    this.badgesEarned = 0,
    this.toolsCollected = 0,
  });

  final int jobsExplored;
  final int badgesEarned;
  final int toolsCollected;

  factory HowwowPassport.fromJson(Map<String, dynamic> j) => HowwowPassport(
        jobsExplored: _int(j['jobsExplored']),
        badgesEarned: _int(j['badgesEarned']),
        toolsCollected: _int(j['toolsCollected']),
      );
}

class HowwowCareer {
  const HowwowCareer({this.currentLesson, this.passport});

  final HowwowCurrentLesson? currentLesson;
  final HowwowPassport? passport;

  factory HowwowCareer.fromJson(Map<String, dynamic> j) => HowwowCareer(
        currentLesson: _mapOrNull(j['currentLesson'], HowwowCurrentLesson.fromJson),
        passport: _mapOrNull(j['passport'], HowwowPassport.fromJson),
      );
}

class HowwowNotifications {
  const HowwowNotifications({this.unreadCount = 0});

  final int unreadCount;

  factory HowwowNotifications.fromJson(Map<String, dynamic> j) => HowwowNotifications(
        unreadCount: _int(j['unreadCount']),
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
