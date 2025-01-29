import 'dart:convert';

import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchQuests.dart';
import 'package:eureka_app/apis/getDailyQuiz.dart';
import 'package:eureka_app/widgets/mcqQuestionsWidget.dart';
import 'package:eureka_app/widgets/quizQuestions.dart';
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

  bool isLoading = true;
  String questsKey = "quests";

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

  Widget questTiles({
    required BuildContext context,
    required List<dynamic> quest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromARGB(255, 91, 91, 91)),
      ),
      child: Column(
        children: quest.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final questItem = entry.value;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                          LinearProgressIndicator(
                            value: questItem["progress"] /
                                questItem["completionCriteria"],
                            backgroundColor:
                                const Color.fromARGB(255, 91, 91, 91),
                            borderRadius: BorderRadius.circular(8),
                            minHeight: 20,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(255, 217, 0, 1)),
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
                  color: Colors.grey,
                  thickness: 1,
                  height: 16,
                ),
            ],
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          "Quests",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                            'lib/assets/glutaclassLogo.png',
                            height: 100,
                            width: 100,
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
                          // Text(
                          //   "Welcome Back Rewards",
                          //   style: GoogleFonts.raleway(
                          //     color: Colors.white,
                          //     fontSize: 24,
                          //     fontWeight: FontWeight.w700,
                          //   ),
                          // ),
                          // const SizedBox(height: 8),
                          // Container(
                          //     decoration: BoxDecoration(
                          //         borderRadius: BorderRadius.circular(12),
                          //         border: Border.all(
                          //             color: Color.fromARGB(255, 91, 91, 91))),
                          //     child: Column(
                          //       crossAxisAlignment: CrossAxisAlignment.center,
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         const SizedBox(height: 16),
                          //         SizedBox(
                          //           height: 120,
                          //           child: ListView.builder(
                          //             scrollDirection: Axis.horizontal,
                          //             itemCount: questData["joiningRewards"].length,
                          //             itemBuilder: (context, index) {
                          //               final reward =
                          //                   questData["joiningRewards"][index];
                          //               return Padding(
                          //                 padding: const EdgeInsets.symmetric(
                          //                     horizontal: 8.0),
                          //                 child: Column(
                          //                   children: [
                          //                     Container(
                          //                       height: 80,
                          //                       width: 80,
                          //                       decoration: BoxDecoration(
                          //                         borderRadius:
                          //                             BorderRadius.circular(8),
                          //                         image: DecorationImage(
                          //                           image:
                          //                               NetworkImage(reward["img"]),
                          //                           fit: BoxFit.cover,
                          //                         ),
                          //                       ),
                          //                     ),
                          //                     const SizedBox(height: 4),
                          //                     Text(
                          //                       "Day ${index + 1}",
                          //                       style: GoogleFonts.raleway(
                          //                         color: Colors.white,
                          //                         fontSize: 14,
                          //                       ),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               );
                          //             },
                          //           ),
                          //         ),
                          //         Center(
                          //           child: Padding(
                          //               padding: EdgeInsets.symmetric(horizontal: 16),
                          //               child: ChicletAnimatedButton(
                          //                 onPressed: () {
                          //                   HapticFeedback.lightImpact();

                          //                   // print('${concepts[index]['name']} clicked');
                          //                 },
                          //                 buttonType:
                          //                     ChicletButtonTypes.roundedRectangle,
                          //                 height: 50,
                          //                 width: double.infinity,
                          //                 padding: const EdgeInsets.all(8),
                          //                 buttonColor: Color.fromRGBO(187, 160, 2, 1),
                          //                 backgroundColor:
                          //                     Color.fromRGBO(255, 217, 0, 1),
                          //                 child: Text(
                          //                   "CLAIM REWARD",
                          //                   style: GoogleFonts.raleway(
                          //                       color: Colors.black,
                          //                       fontSize: 16,
                          //                       fontWeight: FontWeight.w700),
                          //                 ),
                          //               )),
                          //         ),
                          //         const SizedBox(height: 16),
                          //       ],
                          //     )),
                          // const SizedBox(height: 24),

                          //Daily quiz

                          // Friends Quest Section
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
                                getExpiryText(
                                    questData["friendQuest"][0]["expiryTime"]),
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
                              quest: questData["friendQuest"]),
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
