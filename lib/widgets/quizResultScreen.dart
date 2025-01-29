import 'dart:convert';

import 'package:eureka_app/apis/fetchQuizReport.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/widgets/questProgressScreen.dart';
import 'package:eureka_app/widgets/quizReviewMode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';
import 'package:http/http.dart';

class QuizResultScreen extends StatelessWidget {
  final String conceptName;
  final int totalXp;
  final String timeTaken;
  final double accuracy;
  final Map<String, dynamic> quizQuestions;
  // Map<String, dynamic> quizData = {
  //   "id": "c5910d5e-e1bb-447a-9573-d6069d6381f6",
  //   "quizId": "quiz_1",
  //   "userId": "STWZIvNgJCflTEB6tLwszmSWuNB3",
  //   "quizReportSummary": {
  //     "rank": 7,
  //     "correctAnswers": 4,
  //     "totalQuestions": 10,
  //     "timeTaken": 8,
  //     "percentile": 30,
  //     "averageTimeTaken": 172,
  //     "points": 1992,
  //     "percentileTimings": {"80": 250, "50": 160, "20": 20, "90": 300}
  //   },
  //   "quizQuestionsReports": [
  //     {
  //       "questionId": "q_1",
  //       "correct": true,
  //       "userAnswer": "option_2",
  //       "timeTaken": 1,
  //       "correctlyAnsweredPercentile": 80.0,
  //       "idealTimeToAnswer": 0,
  //       "percentileTimings": {"80": 35, "50": 20, "20": 3, "90": 40}
  //     },
  //     {
  //       "questionId": "q_2",
  //       "correct": true,
  //       "userAnswer": "option_2",
  //       "timeTaken": 1,
  //       "correctlyAnsweredPercentile": 90.0,
  //       "idealTimeToAnswer": 0,
  //       "percentileTimings": {"80": 30, "50": 30, "20": 4, "90": 40}
  //     },
  //     {
  //       "questionId": "q_3",
  //       "correct": true,
  //       "userAnswer": "option_3",
  //       "timeTaken": 0,
  //       "correctlyAnsweredPercentile": 90.0,
  //       "idealTimeToAnswer": 0,
  //       "percentileTimings": {"80": 40, "50": 10, "20": 3, "90": 40}
  //     },
  //     {
  //       "questionId": "q_4",
  //       "correct": true,
  //       "userAnswer": "option_2",
  //       "timeTaken": 0,
  //       "correctlyAnsweredPercentile": 80.0,
  //       "idealTimeToAnswer": 0,
  //       "percentileTimings": {"80": 40, "50": 20, "20": 5, "90": 60}
  //     },
  //     {
  //       "questionId": "q_5",
  //       "correct": false,
  //       "userAnswer": "option_3",
  //       "timeTaken": 1,
  //       "correctlyAnsweredPercentile": 60.0,
  //       "idealTimeToAnswer": 0,
  //       "percentileTimings": {"80": 30, "50": 30, "20": 2, "90": 40}
  //     },
  //     {
  //       "questionId": "q_6",
  //       "correct": false,
  //       "userAnswer": "option_4",
  //       "timeTaken": 1,
  //       "correctlyAnsweredPercentile": 50.0,
  //       "idealTimeToAnswer": 0,
  //       "percentileTimings": {"80": 50, "50": 45, "20": 3, "90": 50}
  //     }
  //   ]
  // };

  Future<Map<String, dynamic>> getQuizReport() async {
    return fetchQuizReport(quizId: quizQuestions["id"]);
  }

  QuizResultScreen(
      {Key? key,
      required this.conceptName,
      required this.totalXp,
      required this.timeTaken,
      required this.accuracy,
      required this.quizQuestions})
      : super(key: key);

  void handleClaimXPClick(int xpEarned, BuildContext context) async {
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
            case "LESSON_COMPLETE":
              newProgress = progress + 1; // Increment completed lessons
            case "ACCURACY":
              newProgress = progress + 1; // Example for accuracy quest
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

      // If there are updated quests, navigate to the progress widget
      if (updatedQuests.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuestProgressScreen(updatedQuests: updatedQuests),
          ),
        );
      } else {
        print("No quests were updated.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          conceptName,
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.black,
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
              SizedBox(
                height: 200,
                width: 200,
                child: Image.network(
                  'https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif', // Example GIF
                  fit: BoxFit.cover,
                ),
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
                      value: '$totalXp XP',
                      icon: Icons.star,
                      color: Colors.green,
                    ),
                    _buildStatTile(
                      context: context,
                      title: 'Time Taken',
                      value: timeTaken,
                      icon: Icons.timer,
                      color: Color.fromRGBO(255, 217, 0, 1),
                    ),
                    _buildStatTile(
                      context: context,
                      title: 'Accuracy',
                      value: '${accuracy.toStringAsFixed(1)}%',
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
              onPressed: () async {
                HapticFeedback.lightImpact();
                Map<String, dynamic> quizData = await getQuizReport();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewModeQuiz(
                      quizName: 'Autotrophs',
                      quizData: quizData,
                      quizQuestions: List<Map<String, dynamic>>.from(
                          quizQuestions["questions"]),
                    ),
                  ),
                );
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
    );
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
