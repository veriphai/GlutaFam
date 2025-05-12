import 'dart:convert';

import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchQuests.dart';
import 'package:eureka_app/apis/getDailyQuiz.dart';
import 'package:eureka_app/apis/giftPowerup.dart';
import 'package:eureka_app/apis/nudgeYourFriend.dart';
import 'package:eureka_app/apis/startFriendQuest.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/widgets/findMyFriendsWidget.dart';
import 'package:eureka_app/widgets/mcqQuestionsWidget.dart';
import 'package:eureka_app/widgets/nudgeWidget.dart';
import 'package:eureka_app/widgets/quizQuestions.dart';
import 'package:eureka_app/widgets/rewardScreen.dart';
import 'package:eureka_app/widgets/sendPowerupToFriendWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class QuestsScreen extends StatefulWidget {
  @override
  _QuestsScreenState createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  Map<String, dynamic> questData = {};
  Map<String, dynamic> dailyQuiz = {};
  late Map<String, dynamic> userProfile;

  bool isLoading = true;
  String questsKey = "quests";

  Future<void> fetchProfile() async {
    try {
      final profileData = await getProfile();

      setState(() {
        userProfile = profileData;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  Future<void> getData() async {
    try {
      final quests = await fetchQuests();
      // final dailyQuizData = await fetchDailyQuiz(examPrep: "", standard: 8);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(questsKey, json.encode(quests));

      setState(() {
        questData = quests;

        // dailyQuiz = dailyQuizData;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching quests: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
    fetchProfile();
  }

  String getImageAsset(String questType) {
    if (questType == "XP_COLLECT") {
      return "lib/assets/xpIcon.png";
    } else if (questType == "ACCURACY") {
      return "lib/assets/accuracyIcon.png";
    } else if (questType == "LESSON_COMPLETE") {
      return "lib/assets/gemIcon.png";
    } else {
      return "lib/assets/gemIcon.png";
    }
  }

  Map<String, dynamic> findFriendObject(String? friendId) {
    if (friendId == null) return {}; // Handle null friendId gracefully

    return userProfile["friends"].firstWhere(
      (friend) => friend["id"] == friendId,
      orElse: () => {}, // Return an empty map if not found
    );
  }

  String findFriendName(String? friendId) {
    if (friendId == null) return "Unknown"; // Handle null friendId gracefully

    final friend = userProfile["friends"].firstWhere(
      (friend) => friend["id"] == friendId,
      orElse: () => {"name": "Unknown"}, // Provide default name
    );

    return friend["name"] ?? "Unknown"; // Ensure return type is always a String
  }

  String findFriendAvatar(String? friendId) {
    if (friendId == null) return "default_avatar"; // Handle null friendId

    final friend = userProfile["friends"].firstWhere(
      (friend) => friend["id"] == friendId,
      orElse: () => {"avatar": "default_avatar"}, // Provide default avatar
    );

    return friend["avatar"] ??
        "default_avatar"; // Ensure return type is always a String
  }

  Widget questTilesForFriendQuest({
    required BuildContext context,
    required List<dynamic> quest,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromARGB(255, 91, 91, 91)),
      ),
      child: Column(
        children: quest.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final questItem = entry.value;

          return GestureDetector(
              onTap: () async {
                if (questItem["rewardAvailable"]) {
                  HapticFeedback.lightImpact();

                  // Navigate to Reward Screen
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return RewardScreen(
                          rewardFor: "quest",
                          taskId: questItem["id"],
                        );
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                  await getData();
                }
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                questItem["name"],
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              questItem["questType"] == "START_FRIEND_QUEST"
                                  ? ChicletAnimatedButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _showFriendSelectionBottomSheet();
                                        // Navigator.pop(context);
                                      },
                                      buttonType:
                                          ChicletButtonTypes.roundedRectangle,
                                      width: double.infinity,
                                      height: 50,
                                      buttonHeight: 4,
                                      padding: const EdgeInsets.all(8),
                                      borderRadius: 12,
                                      buttonColor: const Color.fromARGB(
                                          255, 187, 160, 2),
                                      backgroundColor: const Color.fromARGB(
                                          255, 255, 217, 0),
                                      child: Text(
                                        "ADD FRIEND",
                                        style: GoogleFonts.raleway(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final availableWidth =
                                                  constraints.maxWidth;
                                              return Stack(
                                                children: [
                                                  // Background Bar
                                                  Container(
                                                    height: 25,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[
                                                          800], // Background color
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(8),
                                                              bottomLeft: Radius
                                                                  .circular(8)),
                                                    ),
                                                  ),
                                                  // Filled Bar
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds:
                                                            300), // Animation duration
                                                    curve: Curves
                                                        .easeInOut, // Animation curve
                                                    width: availableWidth *
                                                        ((questItem["friendContribution"] +
                                                                questItem[
                                                                    "userContribution"]) /
                                                            questItem[
                                                                "completionCriteria"]), // Dynamically adjust width
                                                    height: 25.0,
                                                    decoration: BoxDecoration(
                                                      color: Color.fromRGBO(
                                                          255,
                                                          217,
                                                          0,
                                                          1), // Friend's progress color
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(8),
                                                              bottomLeft: Radius
                                                                  .circular(8)),
                                                    ),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds:
                                                            300), // Animation duration
                                                    curve: Curves
                                                        .easeInOut, // Animation curve
                                                    width: availableWidth *
                                                        ((questItem[
                                                                "userContribution"]) /
                                                            questItem[
                                                                "completionCriteria"]), // Dynamically adjust width
                                                    height: 25.0,
                                                    decoration: BoxDecoration(
                                                      color: const Color
                                                              .fromARGB(
                                                              255, 198, 81, 218)
                                                          .withOpacity(
                                                              0.9), // Your progress color
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(8),
                                                              bottomLeft: Radius
                                                                  .circular(8)),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        questItem["rewardClaimed"]
                                            ? Image.asset(
                                                "lib/assets/gemIcon.png",
                                                height: 40,
                                              )
                                            : questItem["rewardAvailable"]
                                                ? Image.asset(
                                                    "lib/assets/streakIcon.png",
                                                    height: 40,
                                                  )
                                                : Image.asset(
                                                    "lib/assets/questIcon.png",
                                                    height: 40,
                                                  )
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (questItem["questType"] != "START_FRIEND_QUEST")
                    Column(children: [
                      const Divider(
                        color: Color.fromARGB(255, 91, 91, 91),
                        thickness: 1,
                        height: 16,
                      ),
                      Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        60), // Circular image
                                    child: Container(
                                        color: Colors.amber,
                                        child: Image.asset(
                                          getAvatar(userProfile["avatar"])[
                                              "imagePath"]!,
                                          height: 60,
                                        ))),
                                SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  "You",
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "${questItem["userContribution"]} lessons",
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              ]),
                              SizedBox(
                                height: 110,
                                child: VerticalDivider(
                                  color: Color.fromARGB(255, 91, 91, 91),
                                  thickness: 0.5,
                                  width: 1,
                                ),
                              ),
                              Column(children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        60), // Circular image
                                    child: Container(
                                        color: Colors.amber,
                                        child: Image.asset(
                                          getAvatar(findFriendAvatar(
                                                  questItem["friendId"]))[
                                              "imagePath"]!,
                                          height: 60,
                                        ))),
                                SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  findFriendName(questItem["friendId"])
                                      .split(" ")[0],
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "${questItem["friendContribution"]} lessons",
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              ])
                            ],
                          )),
                      Padding(
                        padding:
                            EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ChicletOutlinedAnimatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _showNudgeBottomSheet(
                                        context,
                                        findFriendObject(questItem["friendId"]),
                                        getQuestProgressMessage(questItem));
                                    // TODO: Handle first button action
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  height: 40,
                                  padding: EdgeInsets.all(8),
                                  borderWidth: 1,
                                  borderRadius: 12,
                                  buttonHeight: 2,
                                  borderColor: Colors.grey,
                                  backgroundColor:
                                      Color.fromRGBO(19, 31, 36, 1),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.waving_hand_rounded,
                                          color:
                                              Color.fromRGBO(255, 217, 0, 1)),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        "NUDGE",
                                        style: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                            SizedBox(width: 16), // Adds spacing between buttons
                            Expanded(
                              child: ChicletOutlinedAnimatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _showGiftBottomSheet(
                                        context,
                                        findFriendObject(questItem["friendId"]),
                                        "");
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  height: 40,
                                  padding: EdgeInsets.all(8),
                                  borderWidth: 1,
                                  borderRadius: 12,
                                  buttonHeight: 2,
                                  borderColor: Colors.grey,
                                  backgroundColor:
                                      Color.fromRGBO(19, 31, 36, 1),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.card_giftcard_rounded,
                                        color: Color.fromRGBO(255, 217, 0, 1),
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        "GIFT",
                                        style: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ]),
                ],
              ));
        }).toList(),
      ),
    );
  }

  Widget questTiles({
    required BuildContext context,
    required List<dynamic> quest,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromARGB(255, 91, 91, 91)),
      ),
      child: Column(
        children: quest.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final questItem = entry.value;

          return GestureDetector(
              onTap: () async {
                if (questItem["rewardAvailable"]) {
                  HapticFeedback.lightImpact();

                  // Navigate to Reward Screen
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return RewardScreen(
                          rewardFor: "quest",
                          taskId: questItem["id"],
                        );
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                  await getData();
                }
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Image.asset(
                          getImageAsset(questItem["questType"]),
                          height: 60,
                          width: 60,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                questItem["name"],
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                      child: LinearProgressIndicator(
                                    value: questItem["progress"] /
                                        questItem["completionCriteria"],
                                    backgroundColor:
                                        const Color.fromARGB(255, 91, 91, 91),
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8)),
                                    minHeight: 20,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color.fromRGBO(255, 217, 0, 1)),
                                  )),
                                  questItem["rewardClaimed"]
                                      ? Image.asset(
                                          "lib/assets/openChest.png",
                                          height: 45,
                                        )
                                      : questItem["rewardAvailable"]
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Image.asset(
                                                  "lib/assets/questIcon.png",
                                                  height: 40,
                                                ),
                                                Positioned.fill(
                                                  child: Shimmer.fromColors(
                                                    baseColor: Colors
                                                        .transparent, // Transparent to keep original colors
                                                    highlightColor: Colors.amber
                                                        .withOpacity(
                                                            0.3), // Subtle highlight
                                                    child: Center(
                                                        child: Container(
                                                      width: 30,
                                                      height: 30,
                                                      color: Colors.amber
                                                          .withOpacity(0.5),
                                                    )),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Image.asset(
                                              "lib/assets/questIcon.png",
                                              height: 40,
                                            )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Divider between items, except for the last one
                  if (index < quest.length - 1)
                    const Divider(
                      color: Color.fromARGB(255, 91, 91, 91),
                      thickness: 1,
                      height: 16,
                    ),
                ],
              ));
        }).toList(),
      ),
    );
  }

  String getExpiryText(int expiryEpoch) {
    // Extract expiry time from quest (assuming it is epoch in seconds)
    DateTime expiryDateTime =
        DateTime.fromMillisecondsSinceEpoch(expiryEpoch * 1000);
    Duration difference = expiryDateTime.difference(DateTime.now());

    if (difference.inSeconds <= 0) {
      return "Expired";
    } else if (difference.inMinutes < 1) {
      return "${difference.inSeconds} seconds";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes} minutes";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours";
    } else {
      return "${difference.inDays} days";
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      "JANUARY",
      "FEBRUARY",
      "MARCH",
      "APRIL",
      "MAY",
      "JUNE",
      "JULY",
      "AUGUST",
      "SEPTEMBER",
      "OCTOBER",
      "NOVEMBER",
      "DECEMBER"
    ];
    return monthNames[month - 1]; // Adjust index as months start from 1
  }

  void _showFriendSelectionBottomSheet() {
    final friends = userProfile["friends"];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled:
          true, // Allows the modal to expand for scrollable content
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.5, // Set max height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Friend to start quest",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              friends.isEmpty
                  ? Column(
                      children: [
                        Text(
                          "No friends added yet!",
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16), // Add spacing for better UI
                        SizedBox(
                          width: double
                              .infinity, // Ensures full width inside a column
                          child: ChicletAnimatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FindMyFriendsScreen(
                                    profileData: userProfile,
                                  ),
                                ),
                              ).then((_) async {
                                final profileData = await refreshProfile();
                                setState(() {
                                  userProfile = profileData;
                                });
                              });
                            },
                            buttonType: ChicletButtonTypes.roundedRectangle,
                            height: 50,
                            padding: const EdgeInsets.all(8),
                            buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                            backgroundColor:
                                const Color.fromRGBO(255, 217, 0, 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add_alt,
                                    color: Colors.black),
                                const SizedBox(width: 10),
                                Text(
                                  "ADD FRIENDS",
                                  style: GoogleFonts.raleway(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Image.asset(
                                getAvatar(friend.containsKey("avatar") &&
                                        friend["avatar"] != null
                                    ? friend["avatar"]
                                    : "random")["imagePath"]!,
                                height: 50,
                              ),
                              title: Text(
                                friend["name"]!,
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: ChicletAnimatedButton(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    await startFriendQuest(
                                        friendId: friend["id"]);
                                    await getData();
                                    Navigator.pop(context);
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  height: 40,
                                  width: 100,
                                  padding: const EdgeInsets.all(8),
                                  buttonColor:
                                      const Color.fromRGBO(25, 151, 213, 1),
                                  backgroundColor:
                                      const Color.fromRGBO(74, 193, 249, 1),
                                  child: Text(
                                    "START",
                                    style: GoogleFonts.raleway(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )));
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  String getQuestProgressMessage(Map<String, dynamic> questItem) {
    int progress = questItem["progress"] ?? 0;
    int completionCriteria = questItem["completionCriteria"] ?? 1;
    int remaining =
        (completionCriteria - progress).clamp(0, completionCriteria);

    switch (questItem["questType"]) {
      case "XP_COLLECT":
        return remaining > 0
            ? "Earn $remaining more XP to complete the quest!"
            : "XP goal achieved! 🎉";

      case "ACCURACY":
        return remaining > 0
            ? "Only $remaining lessons with ${questItem["accuracyCriteria"]}% accuracy to go!"
            : "Great accuracy! 🎯 Quest completed.";

      case "LESSON_COMPLETE":
        return remaining > 0
            ? "Just $remaining more lessons to complete!"
            : "All lessons completed! ✅";

      case "STREAK":
        return remaining > 0
            ? "Keep going! Maintain your streak for $remaining more days."
            : "Streak goal achieved! 🔥";

      default:
        return remaining > 0
            ? "Only $remaining more to go!"
            : "Quest completed!";
    }
  }

  void _showNudgeBottomSheet(
      BuildContext context, Map<String, dynamic> friend, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return NudgeWidget(
          friendData: friend,
          userProfile: userProfile,
          message: message,
          onNudgeSent: (friendId, headingMessage, image, message) {
            print("Nudge sent to $friendId with message: $message");
            nudgeYourFriend(
                friendId: friendId,
                message: message,
                headingMessage: headingMessage,
                image: image);
            // Call API here
          },
        );
      },
    );
  }

  void _showGiftBottomSheet(
      BuildContext context, Map<String, dynamic> friend, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SendPowerupToFriendWidget(
          friendData: friend,
          userProfile: userProfile,
          message: message,
          powerupCost: 20,
          onPowerupSent: (friendId, powerupId) {
            giftPowerup(friendId: friendId, powerupId: powerupId);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Quests",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            )),
      ),
      body: isLoading
          ? Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[300]!,
                child: Text(
                  'Loading...',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Container
                  Container(
                    color: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getMonthName(DateTime.now().month),
                                    style: GoogleFonts.raleway(
                                      color: Colors.orange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )),
                              SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                width: 210,
                                child: Text(
                                  questData["monthlyQuest"][0]["name"],
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                  getExpiryText(questData["monthlyQuest"][0]
                                      ["expiryTime"]),
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Image.asset(
                            'lib/assets/quests-generic.png',
                            height: 120,
                            // width: 150,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Color.fromRGBO(19, 31, 36, 1),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 24),
                          child: Column(children: [
                            Row(
                              children: [
                                Text(
                                  "Complete 30 quests",
                                  style: GoogleFonts.arOneSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Spacer(),
                                Row(
                                  children: [
                                    Text(
                                        "${questData["monthlyQuest"][0]["progress"]}",
                                        style: GoogleFonts.arOneSans(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        )),
                                    Text(
                                        "/${questData["monthlyQuest"][0]["completionCriteria"]}",
                                        style: GoogleFonts.arOneSans(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                )
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            LinearProgressIndicator(
                              value: questData["monthlyQuest"][0]["progress"] /
                                  questData["monthlyQuest"][0]
                                      ["completionCriteria"],
                              backgroundColor:
                                  const Color.fromARGB(255, 91, 91, 91),
                              borderRadius: BorderRadius.circular(8),
                              minHeight: 20,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color.fromRGBO(255, 217, 0, 1)),
                            )
                          ])),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (dailyQuiz.isNotEmpty)
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          // borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Streak Info
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFC0C0C0), // Light silver
                                            Color(0xFFE8E8E8), // Almost white
                                            Color(
                                                0xFFB0B0B0), // Mid-tone silver
                                            Color(
                                                0xFFFFFFFF), // White for the shine effect
                                            Color(
                                                0xFF808080), // Darker silver for depth
                                          ],
                                          stops: [
                                            0.0,
                                            0.2,
                                            0.5,
                                            0.8,
                                            1.0
                                          ], // Gradient stops for smooth transition
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            4), // Optional rounded corners
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            "Today's Quiz",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors
                                                  .black, // Text color for contrast
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      dailyQuiz["name"],
                                      style: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    ChicletAnimatedButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  QuizQuestions(
                                                quizId: dailyQuiz["id"],
                                                quizName: dailyQuiz["name"],
                                                quizQuestions: dailyQuiz,
                                              ),
                                            ),
                                          );
                                          // print('${concepts[index]['name']} clicked');
                                        },
                                        buttonType:
                                            ChicletButtonTypes.roundedRectangle,
                                        height: 50,
                                        width: 200,
                                        padding: const EdgeInsets.all(8),
                                        buttonColor:
                                            Color.fromRGBO(187, 160, 2, 1),
                                        backgroundColor:
                                            Color.fromRGBO(255, 217, 0, 1),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.play_circle,
                                                color: Colors.black),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              "START NOW !!",
                                              style: GoogleFonts.raleway(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        )),
                                  ],
                                ),
                                Spacer(),
                                Image.network(
                                  dailyQuiz["image"],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                          ],
                        )),

                  // Joining Rewards Section
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Friends Quest Section
                          if (questData["friendQuest"].isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Friends Quest",
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  getExpiryText(questData["friendQuest"][0]
                                      ["expiryTime"]),
                                  style: GoogleFonts.raleway(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          if (questData["friendQuest"].isNotEmpty)
                            const SizedBox(height: 8),
                          if (questData["friendQuest"].isNotEmpty)
                            questData["friendQuest"][0]["questType"] ==
                                    "FOLLOW_FRIEND"
                                ? questTiles(
                                    context: context,
                                    quest: questData["friendQuest"])
                                : questTilesForFriendQuest(
                                    context: context,
                                    quest: questData["friendQuest"]),
                          if (questData["friendQuest"].isNotEmpty)
                            const SizedBox(height: 24),

                          // Daily Quest Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Daily Quest",
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                getExpiryText(
                                    questData["dailyQuests"][0]["expiryTime"]),
                                style: GoogleFonts.raleway(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          questTiles(
                              context: context,
                              quest: questData["dailyQuests"]),
                          const SizedBox(height: 8),
                        ],
                      )),
                ],
              ),
            ),
    );
  }
}
