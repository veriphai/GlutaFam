import 'package:eureka_app/popups/popUpDataModel.dart';
import 'package:eureka_app/popups/popUpType.dart';

class PopupManager {
  static PopupData? getPopupForEvent(Map<String, dynamic> event) {
    if (event["lessonCompleted"] == true) {
      return PopupData(
        type: PopupType.lessonCompletion,
        title: "Lesson Completed!",
        description: "Great job! You have completed the lesson.",
        image: "",
        onAction: () {
          // Navigate to next lesson or show rewards
        },
      );
    } else if (event["questCompleted"] == true) {
      return PopupData(
        type: PopupType.questCompletion,
        title: "Quest Accomplished!",
        description: "You've successfully completed your quest!",
        image: "",
        onAction: () {
          // Show quest rewards
        },
      );
    } else if (event["streakIncreased"] == true) {
      return PopupData(
        type: PopupType.streakIncrease,
        title: "Streak Increased!",
        description: "Your streak is now ${event['newStreak']} days!",
        image: "",
        onAction: null,
      );
    } else if (event["powerupEnded"] == true) {
      return PopupData(
        type: PopupType.powerupEnded,
        title: "Powerup Ended",
        description: "Your ${event['powerupName']} has ended now.",
        image: "",
        onAction: null,
      );
    }
    return null; // No popup for the event
  }
}
