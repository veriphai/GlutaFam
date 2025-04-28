import 'package:eureka_app/apis/logEventsApi.dart';

void logQuestsScreenView() {
  logEvent(
    eventName: "quests_sv",
    screenName: "QuestsScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logFriendAddedToQuest(String friendId) {
  logEvent(
    eventName: "friend_added_for_quest",
    screenName: "QuestsScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logFriendNudged(String friendId) {
  logEvent(
    eventName: "friend_nudged",
    screenName: "QuestsScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}
