import 'package:chiclet/chiclet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class Quests extends StatelessWidget {
  final Map<String, dynamic> questData = {
    "joiningRewards": [
      {
        "id": "day_1",
        "type": "gems",
        "count": 5,
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg"
      },
      {
        "id": "day_2",
        "type": "chest",
        "items": [
          {"type": "xp", "param": 15}
        ],
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg"
      },
      {
        "id": "day_3",
        "type": "gems",
        "count": 10,
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg"
      },
      {
        "id": "day_4",
        "type": "chest",
        "items": [
          {"type": "xp", "param": 15}
        ],
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg"
      },
      {
        "id": "day_5",
        "type": "gems",
        "count": 15,
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg"
      },
      {
        "id": "day_6",
        "type": "megaChest",
        "items": [
          {"type": "xp", "param": 15},
          {"type": "avatar", "param": "url"}
        ],
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg"
      }
      // More rewards
    ],
    "friendsQuests": [
      {
        "id": "follow_first_friend",
        "name": "Follow First Friend",
        "total": 0,
        "completionCriteria": 1,
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg"
      }
    ],
    "dailyQuests": [
      {
        "id": "xp_1",
        "name": "Earn 10 XP",
        "total": 1,
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg",
        "type": "xp",
        "completionCriteria": 10
      },
      {
        "id": "lesson_complete_1",
        "name": "Complete 1 Lesson",
        "total": 1,
        "img": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg",
        "type": "lesson_complete",
        "completionCriteria": 1
      }
    ]
  };

  Widget questTiles({
    required BuildContext context,
    required dynamic quest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          // color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color.fromARGB(255, 91, 91, 91))),
      child: Column(
        children: quest.map<Widget>((quest) {
          return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Image.network(
                    quest["img"],
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest["name"],
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: quest["total"] / quest["completionCriteria"],
                          backgroundColor:
                              const Color.fromARGB(255, 91, 91, 91),
                          minHeight: 20,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.green),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ],
                    ),
                  ),
                ],
              ));
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Container
            Container(
              color: Colors.orange,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back!",
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Complete quests to earn rewards",
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "rewards",
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
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
            ),
            const SizedBox(height: 16),

            // Joining Rewards Section
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Back Rewards",
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Color.fromARGB(255, 91, 91, 91))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: questData["joiningRewards"].length,
                                itemBuilder: (context, index) {
                                  final reward =
                                      questData["joiningRewards"][index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 80,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image:
                                                  NetworkImage(reward["img"]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Day ${index + 1}",
                                          style: GoogleFonts.raleway(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Center(
                              child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: ChicletAnimatedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();

                                      // print('${concepts[index]['name']} clicked');
                                    },
                                    buttonType:
                                        ChicletButtonTypes.roundedRectangle,
                                    height: 50,
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                    backgroundColor:
                                        Color.fromRGBO(255, 217, 0, 1),
                                    child: Text(
                                      "CLAIM REWARD",
                                      style: GoogleFonts.raleway(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  )),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )),
                    const SizedBox(height: 24),

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
                          "4 hours",
                          style: GoogleFonts.raleway(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    questTiles(
                        context: context, quest: questData["friendsQuests"]),
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
                          "4 hours",
                          style: GoogleFonts.raleway(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    questTiles(
                        context: context, quest: questData["dailyQuests"]),
                    const SizedBox(height: 8),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
