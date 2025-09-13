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
