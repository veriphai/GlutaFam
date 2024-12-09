import 'package:eureka_app/apis/logEventsApi.dart';

void logChapterListingScreenView(int selectedClass) {
  logEvent(
    eventName: "chapter_listing_sv",
    screenName: "ChapterListingScreen",
    eventType: "screen_view",
    eventDetails: {"selectedStandard": selectedClass},
  );
}

void logClassChangeEvent(int selectedClass) {
  logEvent(
    eventName: "chapter_listing_class_change_panel",
    screenName: "ChapterListingScreen",
    eventType: "button_click",
    eventDetails: {"selectedStandard": selectedClass},
  );
}

void logSelectedClassChangedEvent(int newClass) {
  logEvent(
    eventName: "chapter_listing_selected_class_changed",
    screenName: "ChapterListingScreen",
    eventType: "button_click",
    eventDetails: {"selectedStandard": newClass},
  );
}

void logReferralButtonClick(int selectedClass) {
  logEvent(
    eventName: "chapter_listing_referral",
    screenName: "ChapterListingScreen",
    eventType: "button_click",
    eventDetails: {"selectedStandard": selectedClass},
  );
}

//source : Just for You / Episode Carousal
void logShareButtonClick(String topicId, String source) {
  logEvent(
    eventName: "chapter_listing_share",
    screenName: "ChapterListingScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId, "source": source},
  );
}

void logBookmarkButtonClick(String topicId, String source) {
  logEvent(
    eventName: "chapter_listing_bookmark",
    screenName: "ChapterListingScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId, "source": source},
  );
}

void logEpisodeCardClick(String topicId, String source) {
  logEvent(
    eventName: "chapter_listing_episodes_click",
    screenName: "ChapterListingScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId, "source": source},
  );
}

void logChapterClick(String chapterId) {
  logEvent(
    eventName: "chapter_listing_chapter_click",
    screenName: "ChapterListingScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId},
  );
}
