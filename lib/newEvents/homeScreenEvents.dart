import 'package:eureka_app/apis/logEventsApi.dart';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:eureka_app/utils/appHelperService.dart';

void logHomeScreenView() {
  logEvent(
    eventName: "home_sv",
    screenName: "HomeScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logConceptClicked(String conceptId) {
  logEvent(
    eventName: "home_concept_clicked",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

void logConceptStart(String conceptId) {
  logEvent(
    eventName: "home_concept_clicked",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

void logSubjectSelectionButtonClick() {
  logEvent(
    eventName: "subject_selection_clicked",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logSubjectSelected(String subject) {
  logEvent(
    eventName: "subject_selected",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {"subject": subject},
  );
}

void logStreakButtonClick() {
  logEvent(
    eventName: "streak_clicked",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logShopButtonClick() {
  logEvent(
    eventName: "shop_clicked",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logLifelinesButtonClick() {
  logEvent(
    eventName: "lifelines_clicked",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logTopicButtonClick(String topicId) {
  logEvent(
      eventName: "topic_clicked",
      screenName: "HomeScreen",
      eventType: "button_click",
      eventDetails: {"topicId": topicId});
}

void logChapterSelectionButtonClick() {
  logEvent(
    eventName: "chapter_selection_clicked",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logChapterSelected(String chapterId) {
  logEvent(
    eventName: "chapter_selected",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId},
  );
}

void logSubjectSelectedFromChaptersList(String subject) {
  logEvent(
    eventName: "subject_selected_from_chapters_list",
    screenName: "HomeScreen",
    eventType: "button_click",
    eventDetails: {"subject": subject},
  );
}

void logSearchOpened() {
  logEvent(
    eventName: "home_search_opened",
    screenName: "HomeScreenV2",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logViewAllClicked(String sectionName) {
  logEvent(
    eventName: "home_view_all_clicked",
    screenName: "HomeScreenV2",
    eventType: "button_click",
    eventDetails: {"section": sectionName},
  );
}

void logSubjectFilterClicked(String filter) {
  logEvent(
    eventName: "home_subject_filter_clicked",
    screenName: "HomeScreenV2",
    eventType: "button_click",
    eventDetails: {"filter": filter},
  );
}

void logLessonResumed(String conceptId) {
  logEvent(
    eventName: "home_lesson_resumed",
    screenName: "HomeScreenV2",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

// Helper function to safely log events with error handling
Future<void> _safeLogEvent({
  required String eventName,
  required String screenName,
  required String eventType,
  required Map<String, dynamic> eventDetails,
}) async {
  try {
    // Auto-include common parameters
    final Map<String, dynamic> enhancedDetails = {
      ...eventDetails,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'screenName': 'HomeScreenV2',
      'platform': Platform.isAndroid ? 'android' : 'ios',
    };

    // Add app version if available
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      enhancedDetails['appVersion'] = packageInfo.version;
    } catch (e) {
      enhancedDetails['appVersion'] = 'unknown';
    }

    // Add user ID if available
    try {
      final profile = await getCachedProfile();
      if (profile != null && profile['id'] != null) {
        enhancedDetails['userId'] = profile['id'];
      }
    } catch (e) {
      // User ID not available
    }

    await logEvent(
      eventName: eventName,
      screenName: screenName,
      eventType: eventType,
      eventDetails: enhancedDetails,
    );
  } catch (e) {
    print('Logging failed for $eventName: $e');
  }
}

// =============================================================================
// 1. SCREEN-LEVEL EVENTS
// =============================================================================

void logHomeScreenLoaded({
  required int totalLessons,
  required int totalChapters,
  required List<String> availableSubjects,
  required int loadTimeMs,
}) {
  _safeLogEvent(
    eventName: "home_screen_loaded",
    screenName: "HomeScreenV2",
    eventType: "screen_lifecycle",
    eventDetails: {
      'totalLessons': totalLessons,
      'totalChapters': totalChapters,
      'availableSubjects': availableSubjects,
      'loadTimeMs': loadTimeMs,
    },
  );
}

void logHomeScreenError({
  required String errorType,
  required String errorMessage,
  required String failedOperation,
}) {
  _safeLogEvent(
    eventName: "home_screen_error",
    screenName: "HomeScreenV2",
    eventType: "error",
    eventDetails: {
      'errorType': errorType,
      'errorMessage': errorMessage,
      'failedOperation': failedOperation,
    },
  );
}

void logHomeScreenRefresh({
  required String triggerSource,
}) {
  _safeLogEvent(
    eventName: "home_screen_refresh",
    screenName: "HomeScreenV2",
    eventType: "user_action",
    eventDetails: {
      'triggerSource': triggerSource,
    },
  );
}

// =============================================================================
// 2. SEARCH FUNCTIONALITY EVENTS
// =============================================================================

void logSearchQueryEntered({
  required String query,
  required int chaptersFound,
  required int topicsFound,
  required int conceptsFound,
  required int queryLength,
  required int searchTimeMs,
}) {
  _safeLogEvent(
    eventName: "search_query_entered",
    screenName: "HomeScreenV2",
    eventType: "search",
    eventDetails: {
      'query': query,
      'chaptersFound': chaptersFound,
      'topicsFound': topicsFound,
      'conceptsFound': conceptsFound,
      'queryLength': queryLength,
      'searchTimeMs': searchTimeMs,
    },
  );
}

void logSearchResultClicked({
  required String resultType,
  required String itemName,
  required String itemId,
  required String subject,
  required int resultPosition,
  required String searchQuery,
}) {
  _safeLogEvent(
    eventName: "search_result_clicked",
    screenName: "HomeScreenV2",
    eventType: "button_click",
    eventDetails: {
      'resultType': resultType,
      'itemName': itemName,
      'itemId': itemId,
      'subject': subject,
      'resultPosition': resultPosition,
      'searchQuery': searchQuery,
    },
  );
}

void logSearchCancelled({
  required String searchQuery,
  required int timeSpentMs,
  required bool hadResults,
}) {
  _safeLogEvent(
    eventName: "search_cancelled",
    screenName: "HomeScreenV2",
    eventType: "user_action",
    eventDetails: {
      'searchQuery': searchQuery,
      'timeSpentMs': timeSpentMs,
      'hadResults': hadResults,
    },
  );
}

void logSearchNoResults({
  required String query,
  required int queryLength,
}) {
  _safeLogEvent(
    eventName: "search_no_results",
    screenName: "HomeScreenV2",
    eventType: "search",
    eventDetails: {
      'query': query,
      'queryLength': queryLength,
    },
  );
}

// =============================================================================
// 3. NAVIGATION & OVERLAY EVENTS
// =============================================================================

void logViewAllOverlayOpened({
  required String sectionType,
  required int totalItems,
}) {
  _safeLogEvent(
    eventName: "view_all_overlay_opened",
    screenName: "HomeScreenV2",
    eventType: "navigation",
    eventDetails: {
      'sectionType': sectionType,
      'totalItems': totalItems,
    },
  );
}

void logViewAllOverlayClosed({
  required String sectionType,
  required int timeSpentMs,
  required bool itemSelected,
}) {
  _safeLogEvent(
    eventName: "view_all_overlay_closed",
    screenName: "HomeScreenV2",
    eventType: "navigation",
    eventDetails: {
      'sectionType': sectionType,
      'timeSpentMs': timeSpentMs,
      'itemSelected': itemSelected,
    },
  );
}

void logSubjectChaptersOpened({
  required String subjectName,
  required String subjectId,
  required int totalChapters,
}) {
  _safeLogEvent(
    eventName: "subject_chapters_opened",
    screenName: "HomeScreenV2",
    eventType: "navigation",
    eventDetails: {
      'subjectName': subjectName,
      'subjectId': subjectId,
      'totalChapters': totalChapters,
    },
  );
}

void logChapterOverlayOpened({
  required String chapterName,
  required String subject,
  required String chapterId,
  required int totalLessons,
  required int completedLessons,
}) {
  _safeLogEvent(
    eventName: "chapter_overlay_opened",
    screenName: "HomeScreenV2",
    eventType: "navigation",
    eventDetails: {
      'chapterName': chapterName,
      'subject': subject,
      'chapterId': chapterId,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
    },
  );
}

// =============================================================================
// 4. FILTER & SORTING EVENTS
// =============================================================================

void logSubjectFilterApplied({
  required String sectionType,
  required String selectedSubject,
  required String previousFilter,
  required int filteredItemCount,
}) {
  _safeLogEvent(
    eventName: "subject_filter_applied",
    screenName: "HomeScreenV2",
    eventType: "user_action",
    eventDetails: {
      'sectionType': sectionType,
      'selectedSubject': selectedSubject,
      'previousFilter': previousFilter,
      'filteredItemCount': filteredItemCount,
    },
  );
}

void logFilterCleared({
  required String sectionType,
  required String previousFilter,
  required int totalItemCount,
}) {
  _safeLogEvent(
    eventName: "filter_cleared",
    screenName: "HomeScreenV2",
    eventType: "user_action",
    eventDetails: {
      'sectionType': sectionType,
      'previousFilter': previousFilter,
      'totalItemCount': totalItemCount,
    },
  );
}

// =============================================================================
// 5. CONTENT INTERACTION EVENTS
// =============================================================================

void logLessonViewed({
  required String lessonId,
  required String lessonName,
  required String sectionType,
  required String subject,
  required String chapter,
  required double currentProgress,
  required int estimatedMinutes,
}) {
  _safeLogEvent(
    eventName: "lesson_viewed",
    screenName: "HomeScreenV2",
    eventType: "content_view",
    eventDetails: {
      'lessonId': lessonId,
      'lessonName': lessonName,
      'sectionType': sectionType,
      'subject': subject,
      'chapter': chapter,
      'currentProgress': currentProgress,
      'estimatedMinutes': estimatedMinutes,
    },
  );
}

void logLessonProgressUpdated({
  required String lessonId,
  required double oldProgress,
  required double newProgress,
  required int checkpointsCompleted,
  required int totalCheckpoints,
  required bool isCompleted,
}) {
  _safeLogEvent(
    eventName: "lesson_progress_updated",
    screenName: "HomeScreenV2",
    eventType: "progress_update",
    eventDetails: {
      'lessonId': lessonId,
      'oldProgress': oldProgress,
      'newProgress': newProgress,
      'checkpointsCompleted': checkpointsCompleted,
      'totalCheckpoints': totalCheckpoints,
      'isCompleted': isCompleted,
    },
  );
}

void logLessonCompleted({
  required String lessonId,
  required int timeSpentMs,
  required int checkpointsCompleted,
  required String subject,
  required String chapter,
  required String completionSource,
}) {
  _safeLogEvent(
    eventName: "lesson_completed",
    screenName: "HomeScreenV2",
    eventType: "achievement",
    eventDetails: {
      'lessonId': lessonId,
      'timeSpentMs': timeSpentMs,
      'checkpointsCompleted': checkpointsCompleted,
      'subject': subject,
      'chapter': chapter,
      'completionSource': completionSource,
    },
  );
}

void logChapterViewed({
  required String chapterId,
  required String chapterName,
  required String subject,
  required int totalLessons,
  required int completedLessons,
  required int inProgressLessons,
  required double completionPercentage,
}) {
  _safeLogEvent(
    eventName: "chapter_viewed",
    screenName: "HomeScreenV2",
    eventType: "content_view",
    eventDetails: {
      'chapterId': chapterId,
      'chapterName': chapterName,
      'subject': subject,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'inProgressLessons': inProgressLessons,
      'completionPercentage': completionPercentage,
    },
  );
}

void logChapterProgressViewed({
  required String chapterId,
  required double completionPercentage,
  required String viewContext,
}) {
  _safeLogEvent(
    eventName: "chapter_progress_viewed",
    screenName: "HomeScreenV2",
    eventType: "content_view",
    eventDetails: {
      'chapterId': chapterId,
      'completionPercentage': completionPercentage,
      'viewContext': viewContext,
    },
  );
}

// =============================================================================
// 6. USER ENGAGEMENT EVENTS
// =============================================================================

void logSectionViewed({
  required String sectionName,
  required int itemCount,
  required bool isEmpty,
  required int scrollPosition,
}) {
  _safeLogEvent(
    eventName: "section_viewed",
    screenName: "HomeScreenV2",
    eventType: "content_view",
    eventDetails: {
      'sectionName': sectionName,
      'itemCount': itemCount,
      'isEmpty': isEmpty,
      'scrollPosition': scrollPosition,
    },
  );
}

void logSectionScrolled({
  required String sectionName,
  required int scrollDirection,
  required int scrollPosition,
}) {
  _safeLogEvent(
    eventName: "section_scrolled",
    screenName: "HomeScreenV2",
    eventType: "user_action",
    eventDetails: {
      'sectionName': sectionName,
      'scrollDirection': scrollDirection,
      'scrollPosition': scrollPosition,
    },
  );
}

void logEmptySectionShown({
  required String sectionName,
  required String emptyReason,
}) {
  _safeLogEvent(
    eventName: "empty_section_shown",
    screenName: "HomeScreenV2",
    eventType: "content_view",
    eventDetails: {
      'sectionName': sectionName,
      'emptyReason': emptyReason,
    },
  );
}

// =============================================================================
// 7. APP UPDATE EVENTS
// =============================================================================

void logUpdatePromptShown({
  required String currentVersion,
  required String latestVersion,
  required bool isForced,
  required String platform,
  required List<String> updateNotes,
}) {
  _safeLogEvent(
    eventName: "update_prompt_shown",
    screenName: "HomeScreenV2",
    eventType: "system_prompt",
    eventDetails: {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'isForced': isForced,
      'platform': platform,
      'updateNotes': updateNotes,
    },
  );
}

void logUpdateAccepted({
  required String currentVersion,
  required String latestVersion,
  required bool wasForced,
}) {
  _safeLogEvent(
    eventName: "update_accepted",
    screenName: "HomeScreenV2",
    eventType: "button_click",
    eventDetails: {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'wasForced': wasForced,
    },
  );
}

void logUpdateDismissed({
  required String currentVersion,
  required String latestVersion,
  required bool wasForced,
}) {
  _safeLogEvent(
    eventName: "update_dismissed",
    screenName: "HomeScreenV2",
    eventType: "button_click",
    eventDetails: {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'wasForced': wasForced,
    },
  );
}

void logUpdateCheckFailed({
  required String error,
  required String currentVersion,
}) {
  _safeLogEvent(
    eventName: "update_check_failed",
    screenName: "HomeScreenV2",
    eventType: "error",
    eventDetails: {
      'error': error,
      'currentVersion': currentVersion,
    },
  );
}

// =============================================================================
// 8. PERFORMANCE & ERROR EVENTS
// =============================================================================

void logAPICallStarted({
  required String apiName,
  required Map<String, dynamic> parameters,
}) {
  _safeLogEvent(
    eventName: "api_call_started",
    screenName: "HomeScreenV2",
    eventType: "api_call",
    eventDetails: {
      'apiName': apiName,
      'parameters': parameters,
    },
  );
}

void logAPICallCompleted({
  required String apiName,
  required int durationMs,
  required bool success,
  int? responseSize,
  String? errorMessage,
}) {
  _safeLogEvent(
    eventName: "api_call_completed",
    screenName: "HomeScreenV2",
    eventType: "api_call",
    eventDetails: {
      'apiName': apiName,
      'durationMs': durationMs,
      'success': success,
      'responseSize': responseSize,
      'errorMessage': errorMessage,
    },
  );
}

void logDataCacheHit({
  required String dataType,
  required String cacheKey,
  required int cacheAgeMs,
}) {
  _safeLogEvent(
    eventName: "data_cache_hit",
    screenName: "HomeScreenV2",
    eventType: "cache_event",
    eventDetails: {
      'dataType': dataType,
      'cacheKey': cacheKey,
      'cacheAgeMs': cacheAgeMs,
    },
  );
}

void logDataCacheMiss({
  required String dataType,
  required String cacheKey,
  required String missReason,
}) {
  _safeLogEvent(
    eventName: "data_cache_miss",
    screenName: "HomeScreenV2",
    eventType: "cache_event",
    eventDetails: {
      'dataType': dataType,
      'cacheKey': cacheKey,
      'missReason': missReason,
    },
  );
}

void logNavigationError({
  required String fromScreen,
  required String toScreen,
  required String error,
  required Map<String, dynamic> navigationParams,
}) {
  _safeLogEvent(
    eventName: "navigation_error",
    screenName: "HomeScreenV2",
    eventType: "error",
    eventDetails: {
      'fromScreen': fromScreen,
      'toScreen': toScreen,
      'error': error,
      'navigationParams': navigationParams,
    },
  );
}

void logDataParsingError({
  required String dataType,
  required String error,
  required String apiEndpoint,
  Map<String, dynamic>? rawData,
}) {
  _safeLogEvent(
    eventName: "data_parsing_error",
    screenName: "HomeScreenV2",
    eventType: "error",
    eventDetails: {
      'dataType': dataType,
      'error': error,
      'apiEndpoint': apiEndpoint,
      'hasRawData': rawData != null,
    },
  );
}

// =============================================================================
// 9. USER PREFERENCE EVENTS
// =============================================================================

void logDefaultSubjectSet({
  required String subjectName,
  required String subjectId,
  required String reason,
  required List<String> availableSubjects,
}) {
  _safeLogEvent(
    eventName: "default_subject_set",
    screenName: "HomeScreenV2",
    eventType: "system_action",
    eventDetails: {
      'subjectName': subjectName,
      'subjectId': subjectId,
      'reason': reason,
      'availableSubjects': availableSubjects,
    },
  );
}

void logSubjectSwitched({
  required String fromSubject,
  required String toSubject,
  required String switchContext,
}) {
  _safeLogEvent(
    eventName: "subject_switched",
    screenName: "HomeScreenV2",
    eventType: "user_action",
    eventDetails: {
      'fromSubject': fromSubject,
      'toSubject': toSubject,
      'switchContext': switchContext,
    },
  );
}

// =============================================================================
// 10. SESSION EVENTS
// =============================================================================

void logSessionDuration({
  required int timeSpentMs,
  required int lessonsViewed,
  required int chaptersViewed,
  required int searchesPerformed,
  required List<String> sectionsVisited,
}) {
  _safeLogEvent(
    eventName: "session_duration",
    screenName: "HomeScreenV2",
    eventType: "session_tracking",
    eventDetails: {
      'timeSpentMs': timeSpentMs,
      'lessonsViewed': lessonsViewed,
      'chaptersViewed': chaptersViewed,
      'searchesPerformed': searchesPerformed,
      'sectionsVisited': sectionsVisited,
    },
  );
}

void logUserInactivity({
  required int inactiveTimeMs,
  required String lastAction,
  required String currentSection,
}) {
  _safeLogEvent(
    eventName: "user_inactivity",
    screenName: "HomeScreenV2",
    eventType: "session_tracking",
    eventDetails: {
      'inactiveTimeMs': inactiveTimeMs,
      'lastAction': lastAction,
      'currentSection': currentSection,
    },
  );
}

// =============================================================================
// 11. RECOMMENDATION EVENTS
// =============================================================================

void logRecommendationShown({
  required String lessonId,
  required String lessonName,
  String? recommendationReason,
  double? priorityScore,
  required int positionInList,
  required String subject,
}) {
  _safeLogEvent(
    eventName: "recommendation_shown",
    screenName: "HomeScreenV2",
    eventType: "content_view",
    eventDetails: {
      'lessonId': lessonId,
      'lessonName': lessonName,
      'recommendationReason': recommendationReason,
      'priorityScore': priorityScore,
      'positionInList': positionInList,
      'subject': subject,
    },
  );
}

void logRecommendationIgnored({
  required String lessonId,
  required int timeVisibleMs,
  required int positionInList,
  required String subject,
}) {
  _safeLogEvent(
    eventName: "recommendation_ignored",
    screenName: "HomeScreenV2",
    eventType: "user_behavior",
    eventDetails: {
      'lessonId': lessonId,
      'timeVisibleMs': timeVisibleMs,
      'positionInList': positionInList,
      'subject': subject,
    },
  );
}

void logParentRecommendationViewed({
  required String lessonId,
  required String lessonName,
  required String subject,
  required int positionInList,
}) {
  _safeLogEvent(
    eventName: "parent_recommendation_viewed",
    screenName: "HomeScreenV2",
    eventType: "content_view",
    eventDetails: {
      'lessonId': lessonId,
      'lessonName': lessonName,
      'subject': subject,
      'positionInList': positionInList,
    },
  );
}
