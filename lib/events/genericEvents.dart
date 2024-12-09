import 'package:eureka_app/apis/logEventsApi.dart';

void logAppLaunchEvent(
    String deviceId, String devicePlatform, String userIp, bool firstLaunch) {
  logEvent(
      eventName: "app_launch",
      screenName: firstLaunch ? "LandingScreen" : "ChapterListingScreen",
      eventType: "app_launch",
      eventDetails: {
        "deviceId": deviceId,
        "devicePlatform": devicePlatform,
        "userIp": userIp,
        "firstLaunch": firstLaunch
      });
}

void logLandingScreenViewEvent(
    String deviceId, String devicePlatform, String userIp) {
  logEvent(
      eventName: "landing_sv",
      screenName: "LandingScreen",
      eventType: "screen_view",
      eventDetails: {
        "deviceId": deviceId,
        "devicePlatform": devicePlatform,
        "userIp": userIp,
      });
}

void logAppCloseEvent(String topicId, bool isAudioPlaying, int audioDuration) {
  logEvent(
    eventName: "app_close_event",
    screenName: "AppClose",
    eventType: "app_close",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": isAudioPlaying,
      "audioDuration": audioDuration
    },
  );
}

void logAppMinimizeEvent(
    String topicId, bool isAudioPlaying, int audioDuration) {
  logEvent(
      eventName: "app_minimize_audio_player_active",
      screenName: "AppMinimize",
      eventType: "app_minimize",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": isAudioPlaying,
        "audioDuration": audioDuration
      });
}

void logAppCloseEventFirstLaunch(
    String deviceId, String devicePlatform, String userIp) {
  logEvent(
      eventName: "app_close_event_first_launch",
      screenName: "AppClose",
      eventType: "app_close",
      eventDetails: {
        "deviceId": deviceId,
        "devicePlatform": devicePlatform,
        "userIp": userIp,
      });
}

void logAppMinimizeEventFirstLaunch(
    String deviceId, String devicePlatform, String userIp) {
  logEvent(
      eventName: "app_minimize",
      screenName: "AppMinimize",
      eventType: "app_minimize",
      eventDetails: {
        "deviceId": deviceId,
        "devicePlatform": devicePlatform,
        "userIp": userIp,
      });
}

void logBackButtonClick(String topicId, bool isAudioPlaying, int audioDuration,
    String sourceScreen) {
  logEvent(
      eventName: "back_button_click",
      screenName: sourceScreen,
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": isAudioPlaying,
        "audioDuration": audioDuration,
        "source": sourceScreen
      });
}


//add event for joined by referral