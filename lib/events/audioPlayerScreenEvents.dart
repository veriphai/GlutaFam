import 'package:eureka_app/apis/logEventsApi.dart';

void logPodcastScreenView(String chapterId, String topicId) {
  logEvent(
    eventName: "audio_player_sv",
    screenName: "AudioPlayerScreen",
    eventType: "screen_view",
    eventDetails: {"chapterId": chapterId, "topicId": topicId},
  );
}

void logBestPracticesModalView(String topicId) {
  logEvent(
    eventName: "audio_player_best_practices",
    screenName: "AudioPlayerScreen",
    eventType: "screen_view",
    eventDetails: {"topicId": topicId},
  );
}

void logBestPracticesClosed(String topicId) {
  logEvent(
    eventName: "audio_player_best_practices_closed",
    screenName: "AudioPlayerScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId},
  );
}

void logBestPracticesStartLessonClick(String topicId, String language) {
  logEvent(
    eventName: "audio_player_best_practices_start_lesson_click",
    screenName: "AudioPlayerScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId, "language": language},
  );
}

void logBestPracticesToggleLanguage(String topicId, String language) {
  logEvent(
    eventName: "audio_player_best_practices_toggle_language",
    screenName: "AudioPlayerScreen",
    eventType: "button_click",
    eventDetails: {"topicId": topicId, "language": language},
  );
}

void logPodcastStart(String topicId) {
  logEvent(
    eventName: "audio_player_audio_start",
    screenName: "AudioPlayerScreen",
    eventType: "audio_play",
    eventDetails: {"topicId": topicId},
  );
}

void logGoToBookQnaButtonClick(
    String topicId, bool audioPlaying, int audioDuration) {
  logEvent(
    eventName: "audio_player_book_end_qna",
    screenName: "AudioPlayerScreen",
    eventType: "button_click",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration
    },
  );
}

void logLanguageChangeButtonClick(
    String topicId, bool audioPlaying, int audioDuration) {
  logEvent(
    eventName: "audio_player_language_change",
    screenName: "AudioPlayerScreen",
    eventType: "button_click",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration
    },
  );
}

void logLanguageSelected(
    String topicId, bool audioPlaying, int audioDuration, String language) {
  logEvent(
    eventName: "audio_player_language_selected",
    screenName: "AudioPlayerScreen",
    eventType: "button_click",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration,
      "language": language
    },
  );
}

void logPlayButtonClick(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_play_button_click",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId
      });
}

void logPauseButtonClick(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_pause_button_click",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId
      });
}

void logSeekerClick(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_seeker_click",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId
      });
}

void logForwardBackwardClick(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId, String action) {
  logEvent(
      eventName: "audio_player_forward_backward_click",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "action": action
      });
}

void logSubsectionsChanged(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_subsections_change",
      screenName: "AudioPlayerScreen",
      eventType: "auto",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId
      });
}

void logSubsectionsBottomSheetOpened(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_subsections_bottom_sheet",
      screenName: "AudioPlayerScreen",
      eventType: "screen_view",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId
      });
}

void logSubsectionSelected(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId, String selectedSubsectionId) {
  logEvent(
      eventName: "audio_player_subsection_selected",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "selectedSubsectionId": selectedSubsectionId
      });
}

// skip intro, skip concept, skip Qna, end Lesson
void logSkipClick(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId, String skippedSection) {
  logEvent(
      eventName: "audio_player_skip_section",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "skippedSection": skippedSection
      });
}

void logAskQuestionButtonClick(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_ask_question",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
      });
}

void logAskQuestionMicrophoneOn(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_ask_question_microphone_on",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
      });
}

void logAskQuestionMicrophoneOff(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_ask_question_microphone_off",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
      });
}

void logAskQuestionResponsePlayed(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_ask_question_response_played",
      screenName: "AudioPlayerScreen",
      eventType: "auto_play",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
      });
}

void logAskQuestionClosed(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_ask_question_closed",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
      });
}

void logViewBookButtonClick(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_view_book",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
      });
}

void logViewBookPdfLoaded(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId, bool pdfLoaded) {
  logEvent(
      eventName: "audio_player_view_book_pdf_loaded",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "pdfLoaded": pdfLoaded
      });
}

//check how to apply this event
void logViewBookPdfScroll(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId, int scrollPosition) {
  logEvent(
      eventName: "audio_player_view_book_pdf_scroll",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "scrollPosition": scrollPosition
      });
}

void logViewBookClosed(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId) {
  logEvent(
      eventName: "audio_player_view_book_closed",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
      });
}

void logCheckpointAppeared(String topicId, bool audioPlaying, int audioDuration,
    String activeSubsectionId, String checkpointId) {
  logEvent(
      eventName: "audio_player_checkpoint_view",
      screenName: "AudioPlayerScreen",
      eventType: "screen_view",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId
      });
}

void logCheckpointClosedWithoutMcq(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId, String checkpointId) {
  logEvent(
      eventName: "audio_player_checkpoint_closed_without_mcq",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId
      });
}

void logCheckpointMcqSectionOpened(String topicId, bool audioPlaying,
    int audioDuration, String activeSubsectionId, String checkpointId) {
  logEvent(
      eventName: "audio_player_checkpoint_mcq_section",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId,
      });
}

void logCheckpointMcqViewed(
    String topicId,
    bool audioPlaying,
    int audioDuration,
    String activeSubsectionId,
    String checkpointId,
    String mcqId,
    String viewMode) {
  logEvent(
      eventName: "audio_player_checkpoint_mcq",
      screenName: "AudioPlayerScreen",
      eventType: "screen_view",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId,
        "mcqId": mcqId,
        "viewMode": viewMode
      });
}

void logCheckpointMcqOptionSelect(
    String topicId,
    bool audioPlaying,
    int audioDuration,
    String activeSubsectionId,
    String checkpointId,
    String mcqId,
    String optionId) {
  logEvent(
      eventName: "audio_player_checkpoint_mcq_option_select",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId,
        "mcqId": mcqId,
        "optionId": optionId
      });
}

void logCheckpointNextMcq(
    String topicId,
    bool audioPlaying,
    int audioDuration,
    String activeSubsectionId,
    String checkpointId,
    String mcqId,
    String optionId,
    String viewMode) {
  logEvent(
      eventName: "audio_player_checkpoint_mcq_next",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId,
        "mcqId": mcqId,
        "optionId": optionId,
        "viewMode": viewMode
      });
}

void logCheckpointResultsScreen(
    String topicId,
    bool audioPlaying,
    int audioDuration,
    String activeSubsectionId,
    String checkpointId,
    String viewMode,
    int score) {
  logEvent(
    eventName: "audio_player_checkpoint_completed",
    screenName: "AudioPlayerScreen",
    eventType: "screen_view",
    eventDetails: {
      "topicId": topicId,
      "audioPlaying": audioPlaying,
      "audioDuration": audioDuration,
      "activeSubsectionId": activeSubsectionId,
      "checkpointId": checkpointId,
      "viewMode": viewMode,
      "score": score
    },
  );
}

void logCheckpointContinueLesson(
    String topicId,
    bool audioPlaying,
    int audioDuration,
    String activeSubsectionId,
    String checkpointId,
    String viewMode) {
  logEvent(
      eventName: "audio_player_checkpoint_continue_lesson",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId,
        "viewMode": viewMode,
      });
}

void logCheckpointCuriousQna(
    String topicId,
    bool audioPlaying,
    int audioDuration,
    String activeSubsectionId,
    String checkpointId,
    String viewMode) {
  logEvent(
      eventName: "audio_player_checkpoint_curious_qna",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId,
        "viewMode": viewMode,
      });
}

void logCheckpointReviewQuestions(
    String topicId,
    bool audioPlaying,
    int audioDuration,
    String activeSubsectionId,
    String checkpointId,
    String viewMode) {
  logEvent(
      eventName: "audio_player_checkpoint_review_questions",
      screenName: "AudioPlayerScreen",
      eventType: "button_click",
      eventDetails: {
        "topicId": topicId,
        "audioPlaying": audioPlaying,
        "audioDuration": audioDuration,
        "activeSubsectionId": activeSubsectionId,
        "checkpointId": checkpointId,
        "viewMode": viewMode,
      });
}
