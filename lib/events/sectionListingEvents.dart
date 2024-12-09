import 'package:eureka_app/apis/logEventsApi.dart';

void logSectionListingScreenView(String chapterId) {
  logEvent(
    eventName: "section_listing_sv",
    screenName: "SectionListingScreen",
    eventType: "screen_view",
    eventDetails: {"chapterId": chapterId},
  );
}

void logChapterShareClick(String chapterId) {
  logEvent(
    eventName: "section_listing_chapter_share",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId},
  );
}

void logChapterBookmark(String chapterId) {
  logEvent(
    eventName: "section_listing_chapter_bookmark",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId},
  );
}

void logGoToBookQnAClick(String chapterId) {
  logEvent(
    eventName: "section_listing_book_end_qna",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId},
  );
}

void logTopicClick(String chapterId, String topicId) {
  logEvent(
    eventName: "section_listing_topic_click",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId, "topicId": topicId},
  );
}

void logTopicBookmarked(String chapterId, String topicId) {
  logEvent(
    eventName: "section_listing_topic_bookmark",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId, "topicId": topicId},
  );
}

void logTopicShared(String chapterId, String topicId) {
  logEvent(
    eventName: "section_listing_topic_share",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId, "topicId": topicId},
  );
}

//check how to add this
void logSimulationScreenView(String chapterId) {
  logEvent(
    eventName: "section_listing_simulation_sv",
    screenName: "SectionListingScreen",
    eventType: "screen_view",
    eventDetails: {"chapterId": chapterId},
  );
}

void logSimulationPlayed(String chapterId, String simulationId) {
  logEvent(
    eventName: "section_listing_simulation_click",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId, "simulationId": simulationId},
  );
}

void logSimulationBookmarked(String chapterId, String simulationId) {
  logEvent(
    eventName: "section_listing_simulation_bookmark",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId, "simulationId": simulationId},
  );
}

void logSimulationShared(String chapterId, String simulationId) {
  logEvent(
    eventName: "section_listing_simulation_share",
    screenName: "SectionListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId, "simulationId": simulationId},
  );
}

//not added yet
void logSimulationPlayScreenView(String chapterId, String simulationId) {
  logEvent(
    eventName: "simulation_play_sv",
    screenName: "SimulationScreen",
    eventType: "screen_view",
    eventDetails: {"chapterId": chapterId, "simulationId": simulationId},
  );
}
