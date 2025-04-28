import 'package:eureka_app/apis/logEventsApi.dart';

void logAchievementScreenView(String achievementId) {
  logEvent(
    eventName: "achievement_sv",
    screenName: "AchievementScreen",
    eventType: "screen_view",
    eventDetails: {"achievementId": achievementId},
  );
}

void logAchievementSharedViaLink(String achievementId) {
  logEvent(
    eventName: "achievement_shared_via_link",
    screenName: "AchievementScreen",
    eventType: "button_click",
    eventDetails: {"achievementId": achievementId},
  );
}

void logAchievementSharedOnFeed(String achievementId) {
  logEvent(
    eventName: "achievement_shared",
    screenName: "AchievementScreen",
    eventType: "button_click",
    eventDetails: {"achievementId": achievementId},
  );
}
