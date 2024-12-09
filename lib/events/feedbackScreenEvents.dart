import 'package:eureka_app/apis/logEventsApi.dart';

void logFeedbackScreenView(String topicId) {
  logEvent(
    eventName: "feedback_sv",
    screenName: "FeedbackScreen",
    eventType: "screen_view",
    eventDetails: {"topicId": topicId},
  );
}

void logStarSelection(String topicId, int starRating) {
  logEvent(
    eventName: "feedback_star_selection",
    screenName: "FeedbackScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId, "star_rating": starRating},
  );
}

void logFeedbackCheckboxClick(String topicId, String checkboxOption) {
  logEvent(
    eventName: "feedback_checkbox",
    screenName: "FeedbackScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId, "feedbackOption": checkboxOption},
  );
}

void logFeedbackContinueWithQna(String topicId) {
  logEvent(
    eventName: "feedback_book_end_qna",
    screenName: "FeedbackScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId},
  );
}

void logFeedbackEndLessonClick(String topicId) {
  logEvent(
    eventName: "feedback_end_lesson",
    screenName: "FeedbackScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId},
  );
}
