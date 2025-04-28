import 'package:eureka_app/apis/logEventsApi.dart';

void logProgressReportScreenView() {
  logEvent(
    eventName: "progress_report_sv",
    screenName: "ProgressReportScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logSubjectSelectionButtonClick() {
  logEvent(
    eventName: "subject_selection_clicked",
    screenName: "ProgressReportScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logSubjectSelected(String subject) {
  logEvent(
    eventName: "subject_selected",
    screenName: "ProgressReportScreen",
    eventType: "button_click",
    eventDetails: {"subject": subject},
  );
}

void logChapterProgressButtonClick(String chapterId) {
  logEvent(
    eventName: "chapter_progress",
    screenName: "ProgressReportScreen",
    eventType: "button_click",
    eventDetails: {"chapterId": chapterId},
  );
}

void logCompareProgressReportButtonClicked() {
  logEvent(
    eventName: "progress_compare_clicked",
    screenName: "ProgressReportScreen",
    eventType: "button_click",
    eventDetails: {},
  );
}

void logFriendProgressReportViewed(String friendId) {
  logEvent(
    eventName: "friends_progress_report_sv",
    screenName: "ProgressReportScreen",
    eventType: "button_click",
    eventDetails: {"friendId": friendId},
  );
}
