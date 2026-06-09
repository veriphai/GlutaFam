// Central catalog of howwow analytics event names.
//
// Every event fired anywhere in the codebase must reference a constant in
// this file. Two reasons:
//   • A typo in `'lessons_started'` (extra `s`) silently fragments the
//     analytics. Constants make typos a compile error.
//   • The catalog itself documents the events we collect — a single grep
//     answers "what telemetry do we have?".
//
// Naming convention: snake_case, past tense for actions
// (`profession_tapped`, not `tap_profession`). Camp = the subject; verb
// describes what happened.

class HowwowEvents {
  HowwowEvents._();

  // ── app lifecycle ──────────────────────────────────────────────────
  static const String appOpened = 'app_opened';
  static const String appBackgrounded = 'app_backgrounded';
  static const String screenViewed = 'screen_viewed';

  // ── app update prompt (appUpdateCheck.dart) ───────────────────────
  static const String updatePromptShown = 'update_prompt_shown';
  static const String updateAccepted = 'update_accepted';
  static const String updateDismissed = 'update_dismissed';
  static const String updateCheckFailed = 'update_check_failed';

  // ── auth ──────────────────────────────────────────────────────────
  static const String loginAttempted = 'login_attempted';
  static const String loginSucceeded = 'login_succeeded';
  static const String loginFailed = 'login_failed';
  static const String logout = 'logout';
  static const String phoneCollectionSubmitted = 'phone_collection_submitted';

  // ── new-user onboarding funnel ────────────────────────────────────
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingStepCompleted = 'onboarding_step_completed';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String onboardingSubmitFailed = 'onboarding_submit_failed';
  static const String onboardingSkipped = 'onboarding_skipped';

  // ── career exploration ────────────────────────────────────────────
  static const String continueMissionCardTapped = 'continue_mission_card_tapped';
  static const String professionTapped = 'profession_tapped';
  static const String worldTapped = 'world_tapped';
  static const String dailyChallengeTapped = 'daily_challenge_tapped';
  static const String careerPassportTapped = 'career_passport_tapped';
  static const String lockedProfessionTap = 'locked_profession_tap';
  static const String lockedWorldTap = 'locked_world_tap';
  static const String viewAllJobsTapped = 'view_all_jobs_tapped';
  static const String viewAllWorldsTapped = 'view_all_worlds_tapped';
  static const String allJobsFilterTapped = 'all_jobs_filter_tapped';

  // ── lessons ───────────────────────────────────────────────────────
  static const String lessonCardTapped = 'lesson_card_tapped';
  static const String lockedLessonTap = 'locked_lesson_tap';
  static const String lessonStarted = 'lesson_started';
  static const String lessonResumed = 'lesson_resumed';
  static const String lessonCompleted = 'lesson_completed';
  static const String lessonAbandoned = 'lesson_abandoned';
  static const String resourceStarted = 'resource_started';
  static const String resourceSkipped = 'resource_skipped';
  // Leave-confirm modal (leaveLessonDialog.dart) — shown on system back
  // inside a video/activity resource. kept_going vs left maps retention
  // impact of the prompt; left is always followed by lesson_abandoned.
  static const String lessonLeavePromptShown = 'lesson_leave_prompt_shown';
  static const String lessonLeavePromptKeptGoing = 'lesson_leave_prompt_kept_going';
  static const String lessonLeavePromptLeft = 'lesson_leave_prompt_left';

  // ── deeplinks / notifications ─────────────────────────────────────
  /// Fired the moment HowwowDeeplinkRouter accepts a URL (push tap,
  /// app_links cold-start, app_links foreground stream). Carries the
  /// full URL, the optional backend-generated `deeplink_id`, the
  /// `source` ("push" | "external" | ...), and the `target_type`
  /// ("home" | "world" | "career" | "lesson"). Always immediate so
  /// we capture intent even if downstream navigation bails.
  static const String notificationTapped = 'notification_tapped';
}
