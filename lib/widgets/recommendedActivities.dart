import 'package:eureka_app/screens/discussionsScreen.dart';
import 'package:eureka_app/screens/storyScreen.dart';
import 'package:eureka_app/screens/wordGameScreen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendedActivities extends StatefulWidget {
  final String skillId;
  RecommendedActivities(this.skillId);
  @override
  _RecommendedActivities createState() => _RecommendedActivities();
}

class _RecommendedActivities extends State<RecommendedActivities> {
  late List<Map<String, dynamic>> activities = [];

  Future<List<Map<String, dynamic>>> fetchRecommendedActivities(
      String skillId) async {
    final url =
        'https://glutaclass.com:8080/gluta/fam/skill-based-recommendations?skillId=$skillId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((data) => data as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load recommended activities');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    fetchRecommendedActivities(widget.skillId).then((data) {
      setState(() {
        activities = data;
      });
    }).catchError((error) {
      print("Failed to load activities: $error");
      // Optionally set up error handling state here
    });
  }

  // final Map<String, List<Map<String, dynamic>>> recommendedActivities = {
  //   "strategic_thinking": [
  //     {
  //       "id": "card-1",
  //       "name": "Animals having a conversation",
  //       "categoryName": "Tell a story",
  //       "cardType": "BUILD_STORY",
  //       "type": "INTEREST_LED",
  //       "tags": ["Creative Thinking", "Communication"],
  //       "itemId": "story-1",
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/app-story-1.jpeg"
  //     },
  //     {
  //       "id": "card-2",
  //       "name": "Boost your critical thinking skills",
  //       "type": "SKILL_BASED",
  //       "cardType": "DISCUSSION",
  //       "categoryName": "Discussion",
  //       "tags": ["Critical Thinking", "Effective Tradeoffs"],
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png",
  //       "cards": [
  //         {
  //           "title": "What was the hardest thing you did today?",
  //           "id": "about_the_day_question_1",
  //           "type": "About the Day"
  //         },
  //         {
  //           "title": "What did your class read today?",
  //           "id": "about_the_day_question_2",
  //           "type": "Creative Hour"
  //         },
  //         {
  //           "title1": "only be aple to whisper?",
  //           "title2": "have an incredibely loud voice.",
  //           "id": "about_the_day_question_3",
  //           "type": "Would You Rather"
  //         },
  //         {
  //           "title": "What nice things have your friends done for you?",
  //           "id": "about_the_day_question_4",
  //           "type": "About the World and Life"
  //         },
  //         {
  //           "title": "What questons did you ask your teacher today?",
  //           "id": "about_the_day_question_4",
  //           "type": "Creative Hour"
  //         }
  //       ]
  //     },
  //     {
  //       "id": "card-3",
  //       "name": "A-Z Words",
  //       "type": "INTEREST_LED",
  //       "cardType": "GAME",
  //       "categoryName": "Games",
  //       "tags": ["Critical Thinking", "Effective Tradeoffs"],
  //       "itemId": "wgame-1",
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
  //     }
  //   ],
  //   "problem_solving": [
  //     {
  //       "id": "card-1",
  //       "name": "Animals having a conversation",
  //       "categoryName": "Tell a story",
  //       "cardType": "BUILD_STORY",
  //       "type": "INTEREST_LED",
  //       "tags": ["Creative Thinking", "Communication"],
  //       "itemId": "story-1",
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/app-story-1.jpeg"
  //     },
  //     {
  //       "id": "card-2",
  //       "name": "Boost your critical thinking skills",
  //       "type": "SKILL_BASED",
  //       "cardType": "DISCUSSION",
  //       "categoryName": "Discussion",
  //       "tags": ["Critical Thinking", "Effective Tradeoffs"],
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png",
  //       "cards": [
  //         {
  //           "title": "What was the hardest thing you did today?",
  //           "id": "about_the_day_question_1",
  //           "type": "About the Day"
  //         },
  //         {
  //           "title": "What did your class read today?",
  //           "id": "about_the_day_question_2",
  //           "type": "Creative Hour"
  //         },
  //         {
  //           "title1": "only be aple to whisper?",
  //           "title2": "have an incredibely loud voice.",
  //           "id": "about_the_day_question_3",
  //           "type": "Would You Rather"
  //         },
  //         {
  //           "title": "What nice things have your friends done for you?",
  //           "id": "about_the_day_question_4",
  //           "type": "About the World and Life"
  //         },
  //         {
  //           "title": "What questons did you ask your teacher today?",
  //           "id": "about_the_day_question_4",
  //           "type": "Creative Hour"
  //         }
  //       ]
  //     },
  //     {
  //       "id": "card-3",
  //       "name": "A-Z Words",
  //       "type": "INTEREST_LED",
  //       "cardType": "GAME",
  //       "categoryName": "Games",
  //       "tags": ["Critical Thinking", "Effective Tradeoffs"],
  //       "itemId": "wgame-1",
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
  //     }
  //   ],
  //   "decision_making": [
  //     {
  //       "id": "card-1",
  //       "name": "Animals having a conversation",
  //       "categoryName": "Tell a story",
  //       "cardType": "BUILD_STORY",
  //       "type": "INTEREST_LED",
  //       "tags": ["Creative Thinking", "Communication"],
  //       "itemId": "story-1",
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/app-story-1.jpeg"
  //     },
  //     {
  //       "id": "card-2",
  //       "name": "Boost your critical thinking skills",
  //       "type": "SKILL_BASED",
  //       "cardType": "DISCUSSION",
  //       "categoryName": "Discussion",
  //       "tags": ["Critical Thinking", "Effective Tradeoffs"],
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png",
  //       "cards": [
  //         {
  //           "title": "What was the hardest thing you did today?",
  //           "id": "about_the_day_question_1",
  //           "type": "About the Day"
  //         },
  //         {
  //           "title": "What did your class read today?",
  //           "id": "about_the_day_question_2",
  //           "type": "Creative Hour"
  //         },
  //         {
  //           "title1": "only be aple to whisper?",
  //           "title2": "have an incredibely loud voice.",
  //           "id": "about_the_day_question_3",
  //           "type": "Would You Rather"
  //         },
  //         {
  //           "title": "What nice things have your friends done for you?",
  //           "id": "about_the_day_question_4",
  //           "type": "About the World and Life"
  //         },
  //         {
  //           "title": "What questons did you ask your teacher today?",
  //           "id": "about_the_day_question_4",
  //           "type": "Creative Hour"
  //         }
  //       ]
  //     },
  //     {
  //       "id": "card-3",
  //       "name": "A-Z Words",
  //       "type": "INTEREST_LED",
  //       "cardType": "GAME",
  //       "categoryName": "Games",
  //       "tags": ["Critical Thinking", "Effective Tradeoffs"],
  //       "itemId": "wgame-1",
  //       "image":
  //           "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
  //     }
  //   ]
  // };

  // @override
  // void initState() {
  //   super.initState();
  //   activities = recommendedActivities[widget.skillId] ?? [];
  // }

  Widget buildCarouselCard(Map<String, dynamic> activity) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit
              .loose, // Allows the child to have a max size less than infinite
          child: Card(
            margin: EdgeInsets.all(8.0),
            // elevation: 5.0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: buildCard(activity),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        likeDislikeSection(),
        SizedBox(
          height: 10,
        )
      ],
    );
  }

  Widget buildCard(Map<String, dynamic> activity) {
    switch (activity['cardType']) {
      case 'BUILD_STORY':
        return buildStoryCard(activity);
      case 'DISCUSSION':
        return buildDiscussionCard(activity);
      case 'GAME':
        return buildGameCard(activity);
      // case 'MOOD_TRACKER':
      //   return buildMoodTrackerCard(activity);
      default:
        print("no type defined");
        return Container(); // Default empty container in case of unknown type
    }
  }

  Widget buildStoryCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryScreen(card['itemId']),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        // margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                  ),
                  Text(card['categoryName'],
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // To keep the content together
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Image.network(card['image'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 200),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(card['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Wrap(
                  spacing: 4.0,
                  runSpacing: 8.0,
                  children: card.containsKey('tags')
                      ? card['tags'].map<Widget>((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList()
                      : [],
                ))
          ],
        ),
      ),
    );
  }

  Widget buildDiscussionCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionScreen(
                List<Map<String, dynamic>>.from(card['cards'])),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        // margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                  ),
                  Text(card['categoryName'],
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        card['image'],
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(card['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Wrap(
                  spacing: 4.0,
                  runSpacing: 8.0,
                  children: card.containsKey('tags')
                      ? card['tags'].map<Widget>((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList()
                      : [],
                ))
          ],
        ),
      ),
    );
  }

  Widget buildGameCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(card['itemId']),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        // margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                  ),
                  Text(card['categoryName'],
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        card['image'],
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Text(card['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Wrap(
                  spacing: 4.0,
                  runSpacing: 8.0,
                  children: card.containsKey('tags')
                      ? card['tags'].map<Widget>((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList()
                      : [],
                ))
          ],
        ),
      ),
    );
  }

  Widget likeDislikeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.thumb_up,
              size: 40,
            ),
            onPressed: () {
              // Implement like functionality
            },
            color: Colors.green,
          ),
        ),
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.thumb_down, size: 40),
            onPressed: () {
              // Implement dislike functionality
            },
            color: Colors.red,
          ),
        ),
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.bookmark, size: 40),
            onPressed: () {
              // Implement save functionality
            },
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var carouselHeight = screenHeight * 0.75;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 15),
          CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 0.9,
              height: carouselHeight,
              // onPageChanged: (index, reason) {
              //   changeBackgroundColor(index); // Change color on slide change
              // },
            ),
            items: activities.map((activity) {
              return Builder(
                builder: (BuildContext context) {
                  return buildCarouselCard(activity);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
