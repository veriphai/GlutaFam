import 'package:eureka_app/apis/logEventsApi.dart';

void logBookEndQnAScreenView(String chapterId, String source) {
  logEvent(
    eventName: "book_end_qna_sv",
    screenName: "BookEndQnAScreen",
    eventType: "screen_view",
    eventDetails: {"chapterId": chapterId, "source": source},
  );
}

void logAnswerQuestionMicrophoneOn(
    String chapterId, String questionId, String subquestionId) {
  logEvent(
    eventName: "book_end_qna_microphone_on",
    screenName: "BookEndQnAScreen",
    eventType: "button_click",
    eventDetails: {
      "chapterId": chapterId,
      "questionId": questionId,
      "subquestionId": subquestionId
    },
  );
}

void logAnswerQuestionMicrophoneClose(
    String chapterId, String questionId, String subquestionId) {
  logEvent(
      eventName: "book_end_qna_microphone_close",
      screenName: "BookEndQnAScreen",
      eventType: "button_click",
      eventDetails: {
        "chapterId": chapterId,
        "questionId": questionId,
        "subquestionId": subquestionId
      });
}

// mode : "attempt" or "review"

void logAnswerQuestionFeedbackPlayed(
    String chapterId, String questionId, String subquestionId, String mode) {
  logEvent(
      eventName: "book_end_qna_feedback_played",
      screenName: "BookEndQnAScreen",
      eventType: "button_click",
      eventDetails: {
        "chapterId": chapterId,
        "questionId": questionId,
        "subquestionId": subquestionId,
        "mode": mode
      });
}

void logQuestionViewScreen(
    String chapterId, String questionId, String subquestionId, String mode) {
  logEvent(
      eventName: "book_end_qna_question_view",
      screenName: "BookEndQnAScreen",
      eventType: "screen_view",
      eventDetails: {
        "chapterId": chapterId,
        "questionId": questionId,
        "subquestionId": subquestionId,
        "mode": mode
      });
}

void logMovedToNextQuestion(
    String chapterId, String questionId, String subquestionId, String mode) {
  logEvent(
      eventName: "book_end_qna_next",
      screenName: "BookEndQnAScreen",
      eventType: "button_click",
      eventDetails: {
        "chapterId": chapterId,
        "questionId": questionId,
        "subquestionId": subquestionId,
        "mode": mode
      });
}

void logMovedToPreviousQuestion(
    String chapterId, String questionId, String subquestionId, String mode) {
  logEvent(
      eventName: "book_end_qna_previous",
      screenName: "BookEndQnAScreen",
      eventType: "button_click",
      eventDetails: {
        "chapterId": chapterId,
        "questionId": questionId,
        "subquestionId": subquestionId,
        "mode": mode
      });
}

void logResultScreenView(String chapterId, int correctAnswers,
    int partiallyCorrectAnswers, int totalQuestions) {
  logEvent(
      eventName: "book_end_qna_result_sv",
      screenName: "BookEndQnAResultScreen",
      eventType: "screen_view",
      eventDetails: {
        "chapterId": chapterId,
        "correctAnswers": correctAnswers,
        "partiallyCorrectAnswers": partiallyCorrectAnswers,
        "totalQuestions": totalQuestions,
      });
}

void logReviewQuestionsClickedOnResult(String chapterId) {
  logEvent(
      eventName: "book_end_qna_result_review",
      screenName: "BookEndQnAResultScreen",
      eventType: "button_click",
      eventDetails: {"chapterId": chapterId});
}

void logReattemptQuestions(String chapterId) {
  logEvent(
      eventName: "book_end_qna_result_reattempt",
      screenName: "BookEndQnAResultScreen",
      eventType: "button_click",
      eventDetails: {"chapterId": chapterId});
}

void logGoBackToChapter(String chapterId) {
  logEvent(
      eventName: "book_end_qna_result_back_to_chapter",
      screenName: "BookEndQnAResultScreen",
      eventType: "button_click",
      eventDetails: {"chapterId": chapterId});
}

//sideClicked : "question_side" or "feedback_side"
void logCardFlip(String chapterId, String questionId, String subquestionId,
    String sideClicked, String mode) {
  logEvent(
    eventName: "book_end_qna_card_flip",
    screenName: "BookEndQnAScreen",
    eventType: "button_click",
    eventDetails: {
      "chapterId": chapterId,
      "questionId": questionId,
      "subquestionId": subquestionId,
      "side_clicked": sideClicked,
      "mode": mode
    },
  );
}

void logReplayFeedbackButton(
    String chapterId, String questionId, String subquestionId, String mode) {
  logEvent(
    eventName: "book_end_qna_replay_feedback",
    screenName: "BookEndQnAScreen",
    eventType: "button_click",
    eventDetails: {
      "chapterId": chapterId,
      "questionId": questionId,
      "subquestionId": subquestionId,
      "mode": mode
    },
  );
}
