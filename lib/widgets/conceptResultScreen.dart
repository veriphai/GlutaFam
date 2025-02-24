import 'dart:convert';

import 'package:eureka_app/apis/fetchLeaderboard.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/popups/genericPopupWidget.dart';
import 'package:eureka_app/popups/leaderboardPopup.dart';
import 'package:eureka_app/popups/popUpManager.dart';
import 'package:eureka_app/popups/streakPopup.dart';
import 'package:eureka_app/screens/mistakesCorrectionScreen.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/widgets/questProgressScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';
import 'package:lottie/lottie.dart';

class ConceptResultScreen extends StatefulWidget {
  final String conceptName;
  final int totalXp;
  final String timeTaken;
  final double accuracy;
  final Map<String, dynamic> lessonCompletionResponse;

  const ConceptResultScreen({
    Key? key,
    required this.conceptName,
    required this.totalXp,
    required this.timeTaken,
    required this.accuracy,
    required this.lessonCompletionResponse,
  }) : super(key: key);

  @override
  _ConceptResultScreenState createState() => _ConceptResultScreenState();
}

class _ConceptResultScreenState extends State<ConceptResultScreen> {
  // late Map<String, dynamic> userProfile;

  // Future<void> fetchProfile() async {
  //   try {
  //     final profileData = await refreshProfile();

  //     setState(() {
  //       userProfile = profileData;
  //     });
  //   } catch (error) {
  //     print("Error fetching userProfile: $error");
  //   }
  // }

  @override
  void initState() {
    super.initState();
  }

  void handleClaimXPClick(int xpEarned, BuildContext context) async {
    bool isStreakExtended = widget.lessonCompletionResponse["streakExtended"];
    bool isLeaderboardUpdated =
        widget.lessonCompletionResponse["leaderboardUpdated"];

    if (isStreakExtended) {
      final userProfile = await refreshProfile();
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false, // Prevents manual dismiss
        enableDrag: false, // Prevents swipe-down dismiss
        builder: (context) {
          return StreakPopup(
            streakCount: userProfile["streakDetails"]["activeDays"],
            streakStartEpoch: userProfile["streakDetails"]["startTime"],
            streakGoal: userProfile["streakGoal"],
          );
        },
      ); // ✅ Waits until StreakPopup is closed

      // After StreakPopup is closed, show leaderboard (if needed)
    }

    if (isLeaderboardUpdated) {
      final leaderboard = await fetchLeaderboard(leaderboardType: "weekly");
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          return LeaderboardPopup(
            leaderboard: leaderboard,
            rank: widget.lessonCompletionResponse["newRank"],
          );
        },
      ); // ✅ Waits until LeaderboardPopup is closed
    }

    // Once all modals are closed, navigate to Quest Update screen
    _navigateToQuestUpdateScreen(context, xpEarned);
  }

  // void showEventPopup(BuildContext context, int xpEarned) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return StreakPopup(
  //           streakCount: userProfile["streakDetails"]["activeDays"],
  //           streakStartEpoch: userProfile["streakDetails"]["startTime"],
  //           streakGoal: userProfile["streakGoal"]);
  //     },
  //   ).whenComplete(() {
  //     _navigateToQuestUpdateScreen(context, xpEarned);
  //   });
  // }

  void _navigateToQuestUpdateScreen(BuildContext context, int xpEarned) async {
    Map<String, dynamic> quests = await getQuests();
    if (quests.containsKey("dailyQuests")) {
      List<Map<String, dynamic>> dailyQuests =
          List<Map<String, dynamic>>.from(quests["dailyQuests"]);

      List<Map<String, dynamic>> updatedQuests = [];

      for (var quest in dailyQuests) {
        int progress = quest["progress"];
        int completionCriteria = quest["completionCriteria"];
        String questType = quest["questType"];

        int newProgress = progress;
        if (progress < completionCriteria) {
          switch (questType) {
            case "XP_COLLECT":
              newProgress = progress + xpEarned;
              break;
            case "LESSON_COMPLETE":
              newProgress = progress + 1;
              break;
            case "ACCURACY":
              newProgress = progress + 1;
              break;
            default:
              print("Unknown quest type: $questType");
          }

          if (newProgress > progress) {
            updatedQuests.add({
              "quest": quest,
              "oldProgress": progress,
              "newProgress": newProgress,
            });
          }
        }
      }

      // If there are updated quests, navigate to the QuestProgressScreen
      if (updatedQuests.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestProgressScreen(
              updatedQuests: updatedQuests,
            ),
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color.fromRGBO(19, 31, 36, 1),
            automaticallyImplyLeading: false,
            elevation: 0,
            title: Text(
              widget.conceptName,
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          backgroundColor: Color.fromRGBO(19, 31, 36, 1),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Main Content
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // GIF
                  // SizedBox(
                  //   height: 200,
                  //   width: 200,
                  //   child: Lottie.asset(
                  //     'lib/assets/animations/confetti.json',
                  //     fit: BoxFit.cover,
                  //     // repeat: false,
                  //   ),
                  // ),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Top Left Confetti
                      Positioned(
                        top: -20, // Move slightly above the screen
                        left: -20, // Move slightly outside the screen
                        child: SizedBox(
                          height: 150, // Increase size for better visibility
                          width: 150,
                          child: Lottie.asset(
                            'lib/assets/animations/confetti.json',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Top Right Confetti
                      Positioned(
                        top: 50,
                        right: 100,
                        child: SizedBox(
                          height: 100,
                          width: 100,
                          child: Lottie.asset(
                            'lib/assets/animations/confetti.json',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Main Center Animation
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: Lottie.asset(
                          'lib/assets/animations/lovelyCat.json',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),

                  // Lesson Completed Text
                  const SizedBox(height: 30),
                  Text(
                    'Lesson Complete!',
                    style: GoogleFonts.raleway(
                      color: Color.fromRGBO(255, 217, 0, 1),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  // Tiles Row
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatTile(
                          context: context,
                          title: 'Total XP',
                          value: '${widget.totalXp} XP',
                          icon: Icons.star,
                          color: Colors.green,
                        ),
                        _buildStatTile(
                          context: context,
                          title: 'Time Taken',
                          value: widget.timeTaken,
                          icon: Icons.timer,
                          color: Color.fromRGBO(255, 217, 0, 1),
                        ),
                        _buildStatTile(
                          context: context,
                          title: 'Accuracy',
                          value: '${widget.accuracy.toStringAsFixed(1)}%',
                          icon: Icons.check_circle,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              )),
              // Button at the Bottom
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ChicletAnimatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    handleClaimXPClick(widget.totalXp, context);
                    // Navigator.pop(context); // Go back to the chapter
                  },
                  buttonType: ChicletButtonTypes.roundedRectangle,
                  height: 50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                  backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                  child: Text(
                    'CLAIM XP',
                    style: GoogleFonts.raleway(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildStatTile({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon and Value
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: GoogleFonts.arOneSans(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
