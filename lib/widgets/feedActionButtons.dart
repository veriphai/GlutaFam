import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchRewardDetails.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:eureka_app/widgets/collectionDetailsWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButton extends StatelessWidget {
  final String buttonText;
  final Map<String, dynamic> feed;

  const ActionButton({Key? key, required this.buttonText, required this.feed})
      : super(key: key);

  void _handleButtonClick(BuildContext context, String buttonText) {
    if (buttonText == "Celebrate") {
      _celebrate(context);
    } else if (buttonText == "Share") {
      _shareFeed(context, feed);
    } else if (buttonText == "View Profile") {
      _viewProfile(context, feed);
    } else if (buttonText == "Follow Back") {
      _followBack(context, feed);
    } else if (buttonText == "Get Back Up") {
      _getBackUp(context);
    } else if (buttonText == "View") {
      _viewAchievement(context, feed);
    } else {
      print("Unknown action for button: $buttonText");
    }
  }

  void _celebrate(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Celebrate!"),
        content: Text("Woohoo! 🎉 Let’s celebrate your achievement!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _shareFeed(BuildContext context, Map<String, dynamic> feed) {
    final description = feed['description'];
    // Implement sharing logic here (e.g., using Share package)
    print("Sharing feed: $description");
  }

  void _viewProfile(BuildContext context, Map<String, dynamic> feed) {
    final userId =
        feed['feedData']['followedId'] ?? feed['feedData']['receiverId'];
    // Navigate to profile screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FriendsProfileScreen(friendId: userId, following: true),
      ),
    );
  }

  void _viewAchievement(BuildContext context, Map<String, dynamic> feed) async {
    final rewardId = feed['feedData']['rewardId'];
    // Navigate to profile screen
    Map<String, dynamic> rewardData =
        await fetchRewardDetails(rewardId: rewardId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CollectionDetailsWidget(collectionItem: rewardData),
      ),
    );
  }

  void _followBack(BuildContext context, Map<String, dynamic> feed) {
    final followerId = feed['feedData']['followerId'];
    // Implement follow-back functionality
    print("Following back user: $followerId");
  }

  void _getBackUp(BuildContext context) {
    // Logic to handle "Get Back Up" action
    print("Encourage user to get back up!");
  }

  @override
  Widget build(BuildContext context) {
    return ChicletOutlinedAnimatedButton(
      onPressed: () {
        _handleButtonClick(context, buttonText);
      },
      buttonType: ChicletButtonTypes.roundedRectangle,
      height: 40,
      width: 100,
      padding: const EdgeInsets.all(0),
      buttonColor: Colors.grey,
      backgroundColor: Colors.black,
      borderWidth: 1.0,
      child: Text(
        buttonText,
        style: GoogleFonts.raleway(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
