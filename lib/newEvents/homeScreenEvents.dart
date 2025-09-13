import 'package:eureka_app/apis/logEventsApi.dart';

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

// ==================== COMPREHENSIVE ANALYTICS EVENTS ====================

// ==================== 1. SCREEN-LEVEL EVENTS ====================

void logHomeScreenLoaded({
  required int totalLessons,
  required int totalChapters,
  required List<String> availableSubjects,
  required int loadTimeMs,
}) {
  try {
    logEvent(
      eventName: "home_screen_loaded",
      screenName: "HomeScreenV2",
      eventType: "screen_event",
      eventDetails: {
        "totalLessons": totalLessons,
        "totalChapters": totalChapters,
        "availableSubjects": availableSubjects,
        "loadTimeMs": loadTimeMs,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logHomeScreenError({
  required String errorType,
  required String errorMessage,
  required String failedOperation,
}) {
  try {
    logEvent(
      eventName: "home_screen_error",
      screenName: "HomeScreenV2",
      eventType: "error",
      eventDetails: {
        "errorType": errorType,
        "errorMessage": errorMessage,
        "failedOperation": failedOperation,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logHomeScreenRefresh({
  required String triggerSource,
}) {
  try {
    logEvent(
      eventName: "home_screen_refresh",
      screenName: "HomeScreenV2",
      eventType: "user_action",
      eventDetails: {
        "triggerSource": triggerSource,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 2. SEARCH FUNCTIONALITY EVENTS ====================

void logSearchQueryEntered({
  required String query,
  required int chaptersFound,
  required int topicsFound,
  required int conceptsFound,
  required int queryLength,
  required int searchTimeMs,
}) {
  try {
    logEvent(
      eventName: "search_query_entered",
      screenName: "HomeScreenV2",
      eventType: "search",
      eventDetails: {
        "query": query,
        "chaptersFound": chaptersFound,
        "topicsFound": topicsFound,
        "conceptsFound": conceptsFound,
        "queryLength": queryLength,
        "searchTimeMs": searchTimeMs,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logSearchResultClicked({
  required String resultType,
  required String itemName,
  required String itemId,
  required String subject,
  required int resultPosition,
  required String searchQuery,
}) {
  try {
    logEvent(
      eventName: "search_result_clicked",
      screenName: "HomeScreenV2",
      eventType: "button_click",
      eventDetails: {
        "resultType": resultType,
        "itemName": itemName,
        "itemId": itemId,
        "subject": subject,
        "resultPosition": resultPosition,
        "searchQuery": searchQuery,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logSearchCancelled({
  required String searchQuery,
  required int timeSpentMs,
  required bool hadResults,
}) {
  try {
    logEvent(
      eventName: "search_cancelled",
      screenName: "HomeScreenV2",
      eventType: "user_action",
      eventDetails: {
        "searchQuery": searchQuery,
        "timeSpentMs": timeSpentMs,
        "hadResults": hadResults,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logSearchNoResults({
  required String query,
  required int queryLength,
}) {
  try {
    logEvent(
      eventName: "search_no_results",
      screenName: "HomeScreenV2",
      eventType: "search",
      eventDetails: {
        "query": query,
        "queryLength": queryLength,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 3. NAVIGATION & OVERLAY EVENTS ====================

void logViewAllOverlayOpened({
  required String sectionType,
  required int totalItems,
}) {
  try {
    logEvent(
      eventName: "view_all_overlay_opened",
      screenName: "HomeScreenV2",
      eventType: "navigation",
      eventDetails: {
        "sectionType": sectionType,
        "totalItems": totalItems,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logViewAllOverlayClosed({
  required String sectionType,
  required int timeSpentMs,
  required bool itemSelected,
}) {
  try {
    logEvent(
      eventName: "view_all_overlay_closed",
      screenName: "HomeScreenV2",
      eventType: "navigation",
      eventDetails: {
        "sectionType": sectionType,
        "timeSpentMs": timeSpentMs,
        "itemSelected": itemSelected,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logSubjectChaptersOpened({
  required String subjectName,
  required String subjectId,
  required int totalChapters,
}) {
  try {
    logEvent(
      eventName: "subject_chapters_opened",
      screenName: "HomeScreenV2",
      eventType: "navigation",
      eventDetails: {
        "subjectName": subjectName,
        "subjectId": subjectId,
        "totalChapters": totalChapters,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logChapterOverlayOpened({
  required String chapterName,
  required String subject,
  required String chapterId,
  required int totalLessons,
  required int completedLessons,
}) {
  try {
    logEvent(
      eventName: "chapter_overlay_opened",
      screenName: "HomeScreenV2",
      eventType: "navigation",
      eventDetails: {
        "chapterName": chapterName,
        "subject": subject,
        "chapterId": chapterId,
        "totalLessons": totalLessons,
        "completedLessons": completedLessons,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 4. FILTER & SORTING EVENTS ====================

void logSubjectFilterApplied({
  required String sectionType,
  required String selectedSubject,
  required String previousFilter,
  required int filteredItemCount,
}) {
  try {
    logEvent(
      eventName: "subject_filter_applied",
      screenName: "HomeScreenV2",
      eventType: "filter",
      eventDetails: {
        "sectionType": sectionType,
        "selectedSubject": selectedSubject,
        "previousFilter": previousFilter,
        "filteredItemCount": filteredItemCount,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logFilterCleared({
  required String sectionType,
  required String previousFilter,
  required int totalItemCount,
}) {
  try {
    logEvent(
      eventName: "filter_cleared",
      screenName: "HomeScreenV2",
      eventType: "filter",
      eventDetails: {
        "sectionType": sectionType,
        "previousFilter": previousFilter,
        "totalItemCount": totalItemCount,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 5. CONTENT INTERACTION EVENTS ====================

void logLessonViewed({
  required String lessonId,
  required String lessonName,
  required String sectionType,
  required String subject,
  required String chapter,
  required double currentProgress,
  required int estimatedMinutes,
}) {
  try {
    logEvent(
      eventName: "lesson_viewed",
      screenName: "HomeScreenV2",
      eventType: "content_view",
      eventDetails: {
        "lessonId": lessonId,
        "lessonName": lessonName,
        "sectionType": sectionType,
        "subject": subject,
        "chapter": chapter,
        "currentProgress": currentProgress,
        "estimatedMinutes": estimatedMinutes,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logLessonProgressUpdated({
  required String lessonId,
  required double oldProgress,
  required double newProgress,
  required int checkpointsCompleted,
  required int totalCheckpoints,
  required bool isCompleted,
}) {
  try {
    logEvent(
      eventName: "lesson_progress_updated",
      screenName: "HomeScreenV2",
      eventType: "progress",
      eventDetails: {
        "lessonId": lessonId,
        "oldProgress": oldProgress,
        "newProgress": newProgress,
        "checkpointsCompleted": checkpointsCompleted,
        "totalCheckpoints": totalCheckpoints,
        "isCompleted": isCompleted,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logLessonCompleted({
  required String lessonId,
  required int timeSpentMs,
  required int checkpointsCompleted,
  required String subject,
  required String chapter,
  required String completionSource,
}) {
  try {
    logEvent(
      eventName: "lesson_completed",
      screenName: "HomeScreenV2",
      eventType: "achievement",
      eventDetails: {
        "lessonId": lessonId,
        "timeSpentMs": timeSpentMs,
        "checkpointsCompleted": checkpointsCompleted,
        "subject": subject,
        "chapter": chapter,
        "completionSource": completionSource,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
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
  try {
    logEvent(
      eventName: "chapter_viewed",
      screenName: "HomeScreenV2",
      eventType: "content_view",
      eventDetails: {
        "chapterId": chapterId,
        "chapterName": chapterName,
        "subject": subject,
        "totalLessons": totalLessons,
        "completedLessons": completedLessons,
        "inProgressLessons": inProgressLessons,
        "completionPercentage": completionPercentage,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logChapterProgressViewed({
  required String chapterId,
  required double completionPercentage,
  required String viewContext,
}) {
  try {
    logEvent(
      eventName: "chapter_progress_viewed",
      screenName: "HomeScreenV2",
      eventType: "content_view",
      eventDetails: {
        "chapterId": chapterId,
        "completionPercentage": completionPercentage,
        "viewContext": viewContext,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 6. USER ENGAGEMENT EVENTS ====================

void logSectionViewed({
  required String sectionName,
  required int itemCount,
  required bool isEmpty,
  required int scrollPosition,
}) {
  try {
    logEvent(
      eventName: "section_viewed",
      screenName: "HomeScreenV2",
      eventType: "content_view",
      eventDetails: {
        "sectionName": sectionName,
        "itemCount": itemCount,
        "isEmpty": isEmpty,
        "scrollPosition": scrollPosition,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logSectionScrolled({
  required String sectionName,
  required int scrollDirection,
  required int scrollPosition,
}) {
  try {
    logEvent(
      eventName: "section_scrolled",
      screenName: "HomeScreenV2",
      eventType: "scroll",
      eventDetails: {
        "sectionName": sectionName,
        "scrollDirection": scrollDirection,
        "scrollPosition": scrollPosition,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logEmptySectionShown({
  required String sectionName,
  required String emptyReason,
}) {
  try {
    logEvent(
      eventName: "empty_section_shown",
      screenName: "HomeScreenV2",
      eventType: "content_view",
      eventDetails: {
        "sectionName": sectionName,
        "emptyReason": emptyReason,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 7. APP UPDATE EVENTS ====================

void logUpdatePromptShown({
  required String currentVersion,
  required String latestVersion,
  required bool isForced,
  required String platform,
  required List<String> updateNotes,
}) {
  try {
    logEvent(
      eventName: "update_prompt_shown",
      screenName: "HomeScreenV2",
      eventType: "system_event",
      eventDetails: {
        "currentVersion": currentVersion,
        "latestVersion": latestVersion,
        "isForced": isForced,
        "platform": platform,
        "updateNotes": updateNotes,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logUpdateAccepted({
  required String currentVersion,
  required String latestVersion,
  required bool wasForced,
}) {
  try {
    logEvent(
      eventName: "update_accepted",
      screenName: "HomeScreenV2",
      eventType: "button_click",
      eventDetails: {
        "currentVersion": currentVersion,
        "latestVersion": latestVersion,
        "wasForced": wasForced,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logUpdateDismissed({
  required String currentVersion,
  required String latestVersion,
  required bool wasForced,
}) {
  try {
    logEvent(
      eventName: "update_dismissed",
      screenName: "HomeScreenV2",
      eventType: "button_click",
      eventDetails: {
        "currentVersion": currentVersion,
        "latestVersion": latestVersion,
        "wasForced": wasForced,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logUpdateCheckFailed({
  required String error,
  required String currentVersion,
}) {
  try {
    logEvent(
      eventName: "update_check_failed",
      screenName: "HomeScreenV2",
      eventType: "error",
      eventDetails: {
        "error": error,
        "currentVersion": currentVersion,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 8. PERFORMANCE & ERROR EVENTS ====================

void logAPICallStarted({
  required String apiName,
  required Map<String, dynamic> parameters,
}) {
  try {
    logEvent(
      eventName: "api_call_started",
      screenName: "HomeScreenV2",
      eventType: "api",
      eventDetails: {
        "apiName": apiName,
        "parameters": parameters,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logAPICallCompleted({
  required String apiName,
  required int durationMs,
  required bool success,
  int? responseSize,
  String? errorMessage,
}) {
  try {
    logEvent(
      eventName: "api_call_completed",
      screenName: "HomeScreenV2",
      eventType: "api",
      eventDetails: {
        "apiName": apiName,
        "durationMs": durationMs,
        "success": success,
        "responseSize": responseSize,
        "errorMessage": errorMessage,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logDataCacheHit({
  required String dataType,
  required String cacheKey,
  required int cacheAgeMs,
}) {
  try {
    logEvent(
      eventName: "data_cache_hit",
      screenName: "HomeScreenV2",
      eventType: "performance",
      eventDetails: {
        "dataType": dataType,
        "cacheKey": cacheKey,
        "cacheAgeMs": cacheAgeMs,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logDataCacheMiss({
  required String dataType,
  required String cacheKey,
  required String missReason,
}) {
  try {
    logEvent(
      eventName: "data_cache_miss",
      screenName: "HomeScreenV2",
      eventType: "performance",
      eventDetails: {
        "dataType": dataType,
        "cacheKey": cacheKey,
        "missReason": missReason,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logNavigationError({
  required String fromScreen,
  required String toScreen,
  required String error,
  required Map<String, dynamic> navigationParams,
}) {
  try {
    logEvent(
      eventName: "navigation_error",
      screenName: "HomeScreenV2",
      eventType: "error",
      eventDetails: {
        "fromScreen": fromScreen,
        "toScreen": toScreen,
        "error": error,
        "navigationParams": navigationParams,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logDataParsingError({
  required String dataType,
  required String error,
  required String apiEndpoint,
  Map<String, dynamic>? rawData,
}) {
  try {
    logEvent(
      eventName: "data_parsing_error",
      screenName: "HomeScreenV2",
      eventType: "error",
      eventDetails: {
        "dataType": dataType,
        "error": error,
        "apiEndpoint": apiEndpoint,
        "rawData": rawData,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 9. USER PREFERENCE EVENTS ====================

void logDefaultSubjectSet({
  required String subjectName,
  required String subjectId,
  required String reason,
  required List<String> availableSubjects,
}) {
  try {
    logEvent(
      eventName: "default_subject_set",
      screenName: "HomeScreenV2",
      eventType: "system_event",
      eventDetails: {
        "subjectName": subjectName,
        "subjectId": subjectId,
        "reason": reason,
        "availableSubjects": availableSubjects,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logSubjectSwitched({
  required String fromSubject,
  required String toSubject,
  required String switchContext,
}) {
  try {
    logEvent(
      eventName: "subject_switched",
      screenName: "HomeScreenV2",
      eventType: "user_action",
      eventDetails: {
        "fromSubject": fromSubject,
        "toSubject": toSubject,
        "switchContext": switchContext,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 10. SESSION EVENTS ====================

void logSessionDuration({
  required int timeSpentMs,
  required int lessonsViewed,
  required int chaptersViewed,
  required int searchesPerformed,
  required List<String> sectionsVisited,
}) {
  try {
    logEvent(
      eventName: "session_duration",
      screenName: "HomeScreenV2",
      eventType: "session",
      eventDetails: {
        "timeSpentMs": timeSpentMs,
        "lessonsViewed": lessonsViewed,
        "chaptersViewed": chaptersViewed,
        "searchesPerformed": searchesPerformed,
        "sectionsVisited": sectionsVisited,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logUserInactivity({
  required int inactiveTimeMs,
  required String lastAction,
  required String currentSection,
}) {
  try {
    logEvent(
      eventName: "user_inactivity",
      screenName: "HomeScreenV2",
      eventType: "session",
      eventDetails: {
        "inactiveTimeMs": inactiveTimeMs,
        "lastAction": lastAction,
        "currentSection": currentSection,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

// ==================== 11. RECOMMENDATION EVENTS ====================

void logRecommendationShown({
  required String lessonId,
  required String lessonName,
  String? recommendationReason,
  double? priorityScore,
  required int positionInList,
  required String subject,
}) {
  try {
    logEvent(
      eventName: "recommendation_shown",
      screenName: "HomeScreenV2",
      eventType: "recommendation",
      eventDetails: {
        "lessonId": lessonId,
        "lessonName": lessonName,
        "recommendationReason": recommendationReason,
        "priorityScore": priorityScore,
        "positionInList": positionInList,
        "subject": subject,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logRecommendationIgnored({
  required String lessonId,
  required int timeVisibleMs,
  required int positionInList,
  required String subject,
}) {
  try {
    logEvent(
      eventName: "recommendation_ignored",
      screenName: "HomeScreenV2",
      eventType: "recommendation",
      eventDetails: {
        "lessonId": lessonId,
        "timeVisibleMs": timeVisibleMs,
        "positionInList": positionInList,
        "subject": subject,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}

void logParentRecommendationViewed({
  required String lessonId,
  required String lessonName,
  required String subject,
  required int positionInList,
}) {
  try {
    logEvent(
      eventName: "parent_recommendation_viewed",
      screenName: "HomeScreenV2",
      eventType: "recommendation",
      eventDetails: {
        "lessonId": lessonId,
        "lessonName": lessonName,
        "subject": subject,
        "positionInList": positionInList,
      },
    );
  } catch (e) {
    print('Analytics logging failed: $e');
  }
}
