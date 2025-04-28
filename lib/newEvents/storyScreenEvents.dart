import 'package:eureka_app/apis/logEventsApi.dart';

void logStoryScreenView(String conceptId) {
  logEvent(
    eventName: "story_sv",
    screenName: "StoryScreen",
    eventType: "screen_view",
    eventDetails: {"conceptId": conceptId},
  );
}

void logHandRaiseButtonClick(String conceptId) {
  logEvent(
    eventName: "hand_raise_clicked",
    screenName: "StoryScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

void logDoubtAsked(String conceptId) {
  logEvent(
    eventName: "doubt_asked",
    screenName: "StoryScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}
