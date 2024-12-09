import 'package:eureka_app/apis/logEventsApi.dart';

void logMiniPlayerTrigger(
    String topicId, bool audioPlaying, int audioDuration) {
  logEvent(
    eventName: "mini_player_trigger",
    screenName: "MiniPlayer",
    eventType: "screen_view",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration
    },
  );
}

void logMiniPlayerClick(String topicId, bool audioPlaying, int audioDuration) {
  logEvent(
    eventName: "mini_player_click",
    screenName: "MiniPlayer",
    eventType: "screen_view",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration
    },
  );
}

void logMiniPlayerPauseButtonClick(
    String topicId, bool audioPlaying, int audioDuration) {
  logEvent(
    eventName: "mini_player_pause_button_click",
    screenName: "MiniPlayer",
    eventType: "button_click",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration
    },
  );
}

void logMiniPlayerPlayButtonClick(
    String topicId, bool audioPlaying, int audioDuration) {
  logEvent(
    eventName: "mini_player_play_button_click",
    screenName: "MiniPlayer",
    eventType: "button_click",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration
    },
  );
}

void logMiniPlayerCloseButtonClick(
    String topicId, bool audioPlaying, int audioDuration) {
  logEvent(
    eventName: "mini_player_close_button_click",
    screenName: "MiniPlayer",
    eventType: "button_click",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration
    },
  );
}
