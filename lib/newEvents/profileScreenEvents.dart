import 'package:eureka_app/apis/logEventsApi.dart';

void logProfileScreenView() {
  logEvent(
    eventName: "profile_sv",
    screenName: "ProfileScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logShareProfileClicked() {
  logEvent(
    eventName: "share_profile",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logClassSelectionClicked() {
  logEvent(
    eventName: "class_selection_clicked",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logClassUpdated(int standard, String stream) {
  logEvent(
    eventName: "class_updated",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {"standard": standard, "stream": stream},
  );
}

void logAddFriendsClicked() {
  logEvent(
    eventName: "add_friends_clicked",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logViewAllAchievementsClicked() {
  logEvent(
    eventName: "view_all_achievements_clicked",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logAchievementClicked(String achievementId) {
  logEvent(
    eventName: "achievement_clicked",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {"achievementId": achievementId},
  );
}

void logViewFriendsClicked() {
  logEvent(
    eventName: "view_friiends",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logFriendAddedFromSuggestions(String friendId) {
  logEvent(
    eventName: "friend_added_from_suggestions",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {"friendId": friendId},
  );
}

void logCollectionItemClicked(String collectionItemId) {
  logEvent(
    eventName: "collection_item_clicked",
    screenName: "ProfileScreen",
    eventType: "button_click",
    eventDetails: {"collectionItemId": collectionItemId},
  );
}
