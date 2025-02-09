import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchRewardDetails.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:eureka_app/widgets/collectionDetailsWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButton extends StatefulWidget {
  final String buttonText;
  final Map<String, dynamic> feed;
  final VoidCallback onPress;
  final bool isReacted;

  const ActionButton(
      {Key? key,
      required this.buttonText,
      required this.feed,
      required this.onPress,
      required this.isReacted})
      : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  late String buttonText;
  late Color borderColor;
  late bool reacted;

  @override
  void initState() {
    super.initState();
    buttonText = widget.isReacted ? "celebrated" : widget.buttonText;
    borderColor =
        widget.isReacted ? Colors.blue : Color.fromARGB(255, 91, 91, 91);
    reacted = widget.isReacted;
  }

  void _handleButtonClick(BuildContext context, String buttonText) {
    if (buttonText == "Celebrate") {
      _celebrate();
    } else if (buttonText == "Thankyou") {
      _thank();
    } else if (buttonText == "Share") {
      _shareFeed(context, widget.feed);
    } else if (buttonText == "View Profile") {
      _viewProfile(context, widget.feed);
    } else if (buttonText == "Follow Back") {
      _followBack(context, widget.feed);
    } else if (buttonText == "Get Back Up") {
      _getBackUp(context);
    } else if (buttonText == "View") {
      _viewAchievement(context, widget.feed);
    } else if (buttonText == "View Friend Quest") {
      _viewFriendQuest(context);
    } else {
      print("Unknown action for button: $buttonText");
    }
  }

  void _celebrate() {
    setState(() {
      buttonText = "Celebrated";
      borderColor = Colors.blue;
      reacted = true;
    });

    widget.onPress(); // Call the backend callback function
  }

  void _thank() {
    setState(() {
      borderColor = Colors.blue;
      reacted = true;
    });

    widget.onPress(); // Call the backend callback function
  }

  void _shareFeed(BuildContext context, Map<String, dynamic> feed) {
    final description = feed['description'];
    print("Sharing feed: $description");
  }

  void _viewProfile(BuildContext context, Map<String, dynamic> feed) {
    final userId =
        feed['feedData']['followedId'] ?? feed['feedData']['receiverId'];
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

  void _viewFriendQuest(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(
          initialIndex: 4,
        ),
      ),
    );
  }

  void _followBack(BuildContext context, Map<String, dynamic> feed) {
    final followerId = feed['feedData']['followerId'];
    print("Following back user: $followerId");
  }

  void _getBackUp(BuildContext context) {
    print("Encourage user to get back up!");
  }

  @override
  Widget build(BuildContext context) {
    return ChicletOutlinedAnimatedButton(
      onPressed: () {
        _handleButtonClick(context, buttonText);
      },
      buttonType: ChicletButtonTypes.roundedRectangle,
      height: 50,
      width: 150,
      padding: const EdgeInsets.all(0),
      borderColor: borderColor,
      // buttonColor: borderColor,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      borderWidth: 1.5,
      child: Text(
        buttonText.toUpperCase(),
        style: GoogleFonts.raleway(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
