import 'package:eureka_app/parentDashboard/models.dart';

class DashboardData {
  final Student student;
  final List<FeedGroup> feed; // date-grouped cards for the main list
  final Map<String, ConceptDetailsModel> conceptDetails; // overlay payload
  final int studyStreak; // keep your own logic or pass from backend
  final int parentPresenceStreak;
  final String bestWindow;
  final List<String> subjects; // e.g. ['All','Chemistry', 'Math'...]

  DashboardData({
    required this.student,
    required this.feed,
    required this.conceptDetails,
    required this.studyStreak,
    required this.parentPresenceStreak,
    required this.bestWindow,
    required this.subjects,
  });
}
