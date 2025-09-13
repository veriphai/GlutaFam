# HomeScreenV2 Analytics Implementation Guide

## Overview

This document outlines all the analytics events that need to be implemented in the HomeScreenV2 and its components for comprehensive user behavior tracking.

## Implementation Guidelines

### Auto-included Parameters

All events should automatically include these common parameters:

```dart
userId: userProfile?['id'],
timestamp: DateTime.now().millisecondsSinceEpoch,
screenName: 'HomeScreenV2',
appVersion: currentAppVersion,
platform: Platform.isAndroid ? 'android' : 'ios',
```

### Error Handling

Wrap each logging call to prevent crashes:

```dart
try {
  logEventName(parameters);
} catch (e) {
  print('Logging failed: $e');
}
```

### Performance Considerations

- For high-frequency events (scrolling), consider throttling or batching
- Use async logging to avoid blocking UI
- Add feature flags to enable/disable logging in different environments

---

## 1. Screen-Level Events

### Screen Lifecycle

```dart
logHomeScreenLoaded({
  required int totalLessons,
  required int totalChapters,
  required List<String> availableSubjects,
  required int loadTimeMs,
});
```

**Where to add:** In `_initializeData()` method, after all data is loaded successfully

```dart
logHomeScreenError({
  required String errorType, // 'api_failure', 'network_error', 'parsing_error'
  required String errorMessage,
  required String failedOperation, // 'fetch_profile', 'fetch_lessons', etc.
});
```

**Where to add:** In catch blocks of all API methods (`_fetchProfile()`, `_fetchRecommendedLessons()`, etc.)

```dart
logHomeScreenRefresh({
  required String triggerSource, // 'pull_to_refresh', 'retry_button', 'auto_refresh'
});
```

**Where to add:** If implementing pull-to-refresh functionality

---

## 2. Search Functionality Events

### Search Interactions

```dart
logSearchQueryEntered({
  required String query,
  required int chaptersFound,
  required int topicsFound,
  required int conceptsFound,
  required int queryLength,
  required int searchTimeMs,
});
```

**Where to add:** In `_performSearch()` method, after search results are calculated

```dart
logSearchResultClicked({
  required String resultType, // 'chapter', 'topic', 'concept'
  required String itemName,
  required String itemId,
  required String subject,
  required int resultPosition, // position in search results (1-based)
  required String searchQuery,
});
```

**Where to add:** In `SearchOverlay` widget when user taps on search results

```dart
logSearchCancelled({
  required String searchQuery,
  required int timeSpentMs,
  required bool hadResults,
});
```

**Where to add:** In `_closeSearch()` method

```dart
logSearchNoResults({
  required String query,
  required int queryLength,
});
```

**Where to add:** In `_performSearch()` when all result arrays are empty

---

## 3. Navigation & Overlay Events

### Overlay Interactions

```dart
logViewAllOverlayOpened({
  required String sectionType, // 'continue', 'recommended', 'parents', 'continue_chapters'
  required int totalItems,
});
```

**Where to add:** In each "View all" button's onAction callback

```dart
logViewAllOverlayClosed({
  required String sectionType,
  required int timeSpentMs,
  required bool itemSelected,
});
```

**Where to add:** In `ViewAllOverlay` widget's onClose callback

```dart
logSubjectChaptersOpened({
  required String subjectName,
  required String subjectId,
  required int totalChapters,
});
```

**Where to add:** In `SubjectsSection` widget's onSubjectTap callback

```dart
logChapterOverlayOpened({
  required String chapterName,
  required String subject,
  required String chapterId,
  required int totalLessons,
  required int completedLessons,
});
```

**Where to add:** When setting `_chapterView` state variable

---

## 4. Filter & Sorting Events

### Filter Usage

```dart
logSubjectFilterApplied({
  required String sectionType, // 'continue', 'recommended', 'parents', 'continue_chapters'
  required String selectedSubject,
  required String previousFilter,
  required int filteredItemCount,
});
```

**Where to add:** In `SubjectFilterBar` widget's onChanged callback

```dart
logFilterCleared({
  required String sectionType,
  required String previousFilter,
  required int totalItemCount,
});
```

**Where to add:** In `SubjectFilterBar` when "all" is selected

---

## 5. Content Interaction Events

### Lesson Interactions

```dart
logLessonViewed({
  required String lessonId,
  required String lessonName,
  required String sectionType, // 'continue', 'recommended', 'parents'
  required String subject,
  required String chapter,
  required double currentProgress,
  required int estimatedMinutes,
});
```

**Where to add:** In `LessonList` widget when lesson cards are built/displayed

```dart
logLessonProgressUpdated({
  required String lessonId,
  required double oldProgress,
  required double newProgress,
  required int checkpointsCompleted,
  required int totalCheckpoints,
  required bool isCompleted,
});
```

**Where to add:** In `_updateLessonProgress()` method

```dart
logLessonCompleted({
  required String lessonId,
  required int timeSpentMs,
  required int checkpointsCompleted,
  required String subject,
  required String chapter,
  required String completionSource, // 'home_screen', 'search_result'
});
```

**Where to add:** In `_updateLessonProgress()` when `isCompleted` is true

### Chapter Interactions

```dart
logChapterViewed({
  required String chapterId,
  required String chapterName,
  required String subject,
  required int totalLessons,
  required int completedLessons,
  required int inProgressLessons,
  required double completionPercentage,
});
```

**Where to add:** In `ChapterList` widget when chapter cards are built/displayed

```dart
logChapterProgressViewed({
  required String chapterId,
  required double completionPercentage,
  required String viewContext, // 'home_list', 'view_all_overlay', 'subject_overlay'
});
```

**Where to add:** In chapter tap handlers across different contexts

---

## 6. User Engagement Events

### Section Engagement

```dart
logSectionViewed({
  required String sectionName, // 'subjects', 'continue_chapters', 'continue_learning', 'recommended', 'parents'
  required int itemCount,
  required bool isEmpty,
  required int scrollPosition,
});
```

**Where to add:** In `_buildMainContent()` when each section is rendered

```dart
logSectionScrolled({
  required String sectionName,
  required int scrollDirection, // 1 for down, -1 for up
  required int scrollPosition,
});
```

**Where to add:** In `SingleChildScrollView`'s scroll listener (if implemented)

```dart
logEmptySectionShown({
  required String sectionName,
  required String emptyReason, // 'no_data', 'all_completed', 'filter_no_results'
});
```

**Where to add:** In section builders when checking for empty lists

---

## 7. App Update Events

### Update Flow

```dart
logUpdatePromptShown({
  required String currentVersion,
  required String latestVersion,
  required bool isForced,
  required String platform, // 'android', 'ios'
  required List<String> updateNotes,
});
```

**Where to add:** In `showUpdateSheet()` method

```dart
logUpdateAccepted({
  required String currentVersion,
  required String latestVersion,
  required bool wasForced,
});
```

**Where to add:** In "UPDATE NOW" button's onPressed callback

```dart
logUpdateDismissed({
  required String currentVersion,
  required String latestVersion,
  required bool wasForced,
});
```

**Where to add:** In "MAYBE LATER" button's onPressed callback

```dart
logUpdateCheckFailed({
  required String error,
  required String currentVersion,
});
```

**Where to add:** In `checkForAppUpdate()` catch block

---

## 8. Performance & Error Events

### API Performance

```dart
logAPICallStarted({
  required String apiName, // 'fetchProfile', 'fetchRecommendedLessons', etc.
  required Map<String, dynamic> parameters,
});
```

**Where to add:** At the beginning of each API method

```dart
logAPICallCompleted({
  required String apiName,
  required int durationMs,
  required bool success,
  required int? responseSize,
  required String? errorMessage,
});
```

**Where to add:** At the end of each API method (both success and failure cases)

```dart
logDataCacheHit({
  required String dataType, // 'profile', 'chapters', 'books'
  required String cacheKey,
  required int cacheAgeMs,
});
```

**Where to add:** In cache utility methods when cached data is returned

```dart
logDataCacheMiss({
  required String dataType,
  required String cacheKey,
  required String missReason, // 'expired', 'not_found', 'invalid'
});
```

**Where to add:** In cache utility methods when fresh API call is needed

### Error Tracking

```dart
logNavigationError({
  required String fromScreen,
  required String toScreen,
  required String error,
  required Map<String, dynamic> navigationParams,
});
```

**Where to add:** In navigation try-catch blocks

```dart
logDataParsingError({
  required String dataType,
  required String error,
  required String apiEndpoint,
  required Map<String, dynamic>? rawData,
});
```

**Where to add:** When parsing API responses fails

---

## 9. User Preference Events

### Subject Selection

```dart
logDefaultSubjectSet({
  required String subjectName,
  required String subjectId,
  required String reason, // 'first_time', 'science_preferred', 'fallback_first'
  required List<String> availableSubjects,
});
```

**Where to add:** In `_fetchSubjectsAndChapters()` when setting default subject

```dart
logSubjectSwitched({
  required String fromSubject,
  required String toSubject,
  required String switchContext, // 'subject_grid', 'filter_bar', 'search_result'
});
```

**Where to add:** When user changes subject selection

---

## 10. Session Events

### Session Tracking

```dart
logSessionDuration({
  required int timeSpentMs,
  required int lessonsViewed,
  required int chaptersViewed,
  required int searchesPerformed,
  required List<String> sectionsVisited,
});
```

**Where to add:** In `dispose()` method or when user leaves screen

```dart
logUserInactivity({
  required int inactiveTimeMs,
  required String lastAction,
  required String currentSection,
});
```

**Where to add:** If implementing inactivity detection

---

## 11. Recommendation Events

### Recommendation Interactions

```dart
logRecommendationShown({
  required String lessonId,
  required String lessonName,
  required String? recommendationReason,
  required double? priorityScore,
  required int positionInList,
  required String subject,
});
```

**Where to add:** In `_buildUIData()` when building recommended lessons list

```dart
logRecommendationIgnored({
  required String lessonId,
  required int timeVisibleMs,
  required int positionInList,
  required String subject,
});
```

**Where to add:** If implementing viewport tracking for recommendations

```dart
logParentRecommendationViewed({
  required String lessonId,
  required String lessonName,
  required String subject,
  required int positionInList,
});
```

**Where to add:** In `_buildFromParentsSection()` when parent recommendations are shown

---

## Implementation Priority

### High Priority (Implement First)

1. User interactions (taps, navigation)
2. Content engagement (lessons started/completed)
3. Search functionality
4. Error tracking

### Medium Priority

1. Performance metrics
2. Filter usage
3. Section engagement
4. Update flow events

### Low Priority

1. Session tracking
2. Recommendation analytics
3. Scroll behavior
4. Cache performance

---

## Testing Checklist

- [ ] All events fire correctly in development
- [ ] Parameters are properly formatted
- [ ] No crashes when logging fails
- [ ] Events are batched appropriately for performance
- [ ] Privacy compliance (no sensitive data logged)
- [ ] Feature flags work correctly
- [ ] Analytics dashboard receives events properly

---

## Notes for Developer

1. **Event Naming:** Use consistent naming convention (camelCase for function names)
2. **Parameter Validation:** Validate required parameters before logging
3. **Async Logging:** Make logging calls non-blocking
4. **Debug Mode:** Add debug prints for event verification during development
5. **Documentation:** Update this document if you add new events or modify existing ones

## Questions?

If you have questions about any specific event or implementation detail, please refer back to the HomeScreenV2.dart file and this documentation, or reach out for clarification.
