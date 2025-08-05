import 'package:eureka_app/apis/logEventsApi.dart';

void logAITutorScreenView(String conceptId) {
  logEvent(
    eventName: "tutor_sv",
    screenName: "AITutorScreen",
    eventType: "screen_view",
    eventDetails: {"conceptId": conceptId},
  );
}

void logAITutorMenuButtonClick(String conceptId) {
  logEvent(
    eventName: "tutor_menu_clicked",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

void logAITutorSwitchTutorClick(String conceptId) {
  logEvent(
    eventName: "switch_tutor_clicked",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

void logAITutorSelected(
    String conceptId, String tutorId, String language, String voice) {
  logEvent(
    eventName: "ai_tutor_selected",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {
      "conceptId": conceptId,
      "tutorId": tutorId,
      "language": language,
      "voice": voice
    },
  );
}

void logAITutorGreetingCompleted(String conceptId) {
  logEvent(
    eventName: "tutor_greeting_completed",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {"conceptId": conceptId},
  );
}

void logAITutorCheckpointStart(
    String checkpointId, String conceptId, int checkpointNumber) {
  logEvent(
    eventName: "tutor_checkpoint_start",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {
      "checkpointId": checkpointId,
      "checkpointNo": checkpointNumber,
      "conceptId": conceptId
    },
  );
}

void logAITutorCheckpointEnd(
    String checkpointId, String conceptId, int checkpointNumber) {
  logEvent(
    eventName: "tutor_checkpoint_end",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {
      "checkpointId": checkpointId,
      "checkpointNo": checkpointNumber,
      "conceptId": conceptId
    },
  );
}

void logAITutorCheckpointsCompleted(String conceptId, int totalCheckpoints) {
  logEvent(
    eventName: "total_checkpoints_completed",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {
      "totalCheckpoints": totalCheckpoints,
      "conceptId": conceptId
    },
  );
}

void logAITutorCheckpointSkipped(
    String checkpointId, String conceptId, int checkpointNumber) {
  logEvent(
    eventName: "tutor_checkpoint_skipped",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {
      "checkpointId": checkpointId,
      "checkpointNo": checkpointNumber,
      "conceptId": conceptId
    },
  );
}

void logAITutorCheckpointSkippedOnExit(
    String checkpointId, String conceptId, int checkpointNumber) {
  logEvent(
    eventName: "tutor_checkpoint_skipped_on_exit",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {
      "checkpointId": checkpointId,
      "checkpointNo": checkpointNumber,
      "conceptId": conceptId
    },
  );
}

void logAITutorThoughtClicked(String conceptId, int checkpointNumber) {
  logEvent(
    eventName: "tutor_thoughts_viewed",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"checkpointNo": checkpointNumber, "conceptId": conceptId},
  );
}

void logAITutorExit(
    String checkpointId, String conceptId, int checkpointNumber) {
  logEvent(
    eventName: "tutor_exit",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {
      "checkpointId": checkpointId,
      "checkpointNo": checkpointNumber,
      "conceptId": conceptId
    },
  );
}

void logAITutorExitFeedbackSubmitted(
    String checkpointId, String conceptId, int checkpointNumber) {
  logEvent(
    eventName: "tutor_exit_feedback_submitted",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {
      "checkpointId": checkpointId,
      "checkpointNo": checkpointNumber,
      "conceptId": conceptId
    },
  );
}

void logStoryModeButtonClickFromMenu(String checkpointId, String conceptId) {
  logEvent(
    eventName: "story_mode_clicked_from_menu",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"checkpointId": checkpointId, "conceptId": conceptId},
  );
}

void logQuestionsButtonClickFromMenu(String checkpointId, String conceptId) {
  logEvent(
    eventName: "questions_clicked_from_menu",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"checkpointId": checkpointId, "conceptId": conceptId},
  );
}

//after completion of first checkpoint
void logStoryModeButtonClick(String checkpointId, String conceptId) {
  logEvent(
    eventName: "story_mode_clicked",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"checkpointId": checkpointId, "conceptId": conceptId},
  );
}

//after completion of first checkpoint
void logQuestionsButtonClick(String checkpointId, String conceptId) {
  logEvent(
    eventName: "questions_clicked",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"checkpointId": checkpointId, "conceptId": conceptId},
  );
}

void logCheckpointImageClick(String checkpointId, String conceptId) {
  logEvent(
    eventName: "checkpoint_image_clicked",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"checkpointId": checkpointId, "conceptId": conceptId},
  );
}

void logMistakeCorrectionButtonClick(String conceptId) {
  logEvent(
    eventName: "mistake_correction_clicked",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

void logCheckResultsButtonClick(String conceptId) {
  logEvent(
    eventName: "check_results_clicked",
    screenName: "AITutorScreen",
    eventType: "button_click",
    eventDetails: {"conceptId": conceptId},
  );
}

void logStoryModeCompleted(String conceptId) {
  logEvent(
    eventName: "story_mode_completed",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {"conceptId": conceptId},
  );
}

void logStoryModeNotCompleted(String conceptId) {
  logEvent(
    eventName: "story_mode_not_completed",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {"conceptId": conceptId},
  );
}

void logQuestionsCompleted(String conceptId) {
  logEvent(
    eventName: "questions_completed",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {"conceptId": conceptId},
  );
}

void logQuestionsNotCompleted(String conceptId) {
  logEvent(
    eventName: "questions_not_completed",
    screenName: "AITutorScreen",
    eventType: "auto",
    eventDetails: {"conceptId": conceptId},
  );
}
