import 'package:eureka_app/apis/logEventsApi.dart';

void logMistakeCorrectionScreenView(String conceptId) {
  logEvent(
    eventName: "mistake_correction_sv",
    screenName: "MistakeCorrectionScreen",
    eventType: "screen_view",
    eventDetails: {"conceptId": conceptId},
  );
}

void logMistakeCorrectionStatusPerQuestion(
    String conceptId, String questionId, bool corrected) {
  logEvent(
      eventName: "mistake_correction_status",
      screenName: "MistakeCorrectionScreen",
      eventType: "button_click",
      eventDetails: {
        "conceptId": conceptId,
        "questionId": questionId,
        "mistakeCorrected": corrected
      });
}
