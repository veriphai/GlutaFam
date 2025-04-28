import 'package:eureka_app/apis/logEventsApi.dart';

void logLeaderboardScreenView() {
  logEvent(
    eventName: "leaderboard_sv",
    screenName: "LeaderboardScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logLeaderboardResultScreenView() {
  logEvent(
    eventName: "leaderboard_results_sv",
    screenName: "LeaderboardScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logProfileOpened(String userId) {
  logEvent(
    eventName: "leaderboard_profile_sv",
    screenName: "LeaderboardScreen",
    eventType: "buttonClick",
    eventDetails: {"userId": userId},
  );
}
