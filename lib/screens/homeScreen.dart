import 'package:eureka_app/screens/discussionsScreen.dart';
import 'package:eureka_app/screens/moodTrackerScreen.dart';
import 'package:eureka_app/screens/storyScreen.dart';
import 'package:eureka_app/screens/wordGameScreen.dart';
import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/skillCard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Map<String, dynamic>> softSkills = [];
  late List<Map<String, dynamic>> topActivities = [];

  Color currentBackgroundColor =
      Color.fromRGBO(207, 87, 125, 1); // Default color

  // Function to change the background color
  List<Color> colors = [
    Color.fromARGB(255, 143, 126, 82), // Example colors for different slides
    Color.fromRGBO(59, 128, 185, 1),
    Color.fromRGBO(79, 161, 82, 1),
    Color.fromRGBO(207, 87, 125, 1),
    Color.fromRGBO(170, 82, 186, 1),
  ];
  void changeBackgroundColor(int index) {
    setState(() {
      currentBackgroundColor = colors[index % colors.length];
    });
  }

  @override
  void initState() {
    super.initState();
    fetchSoftSkills().then((data) {
      setState(() {
        softSkills = data;
      });
    }).catchError((error) {
      print("Failed to load soft skills: $error");
      // Optionally set up error handling state here
    });

    fetchRecommendedActivities().then((data) {
      setState(() {
        topActivities = data;
      });
    }).catchError((error) {
      print("Failed to load activities: $error");
      // Optionally set up error handling state here
    });
  }

  Future<List<Map<String, dynamic>>> fetchSoftSkills() async {
    const url = 'https://glutaclass.com:8080/gluta/fam/soft-skills';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((data) => data as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load soft skills');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecommendedActivities() async {
    const url = 'https://glutaclass.com:8080/gluta/fam/recommendations';
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
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);
    ThemeData themeData = Theme.of(context);

    var screenHeight = MediaQuery.of(context).size.height;
    var carouselHeight = screenHeight * 0.6;

    return Scaffold(
      appBar: appBar(),
      body: bodyContent(carouselHeight),
      backgroundColor: currentBackgroundColor,
      bottomNavigationBar:
          CustomBottomNavBar(currentIndex: appState.currentIndex),
    );
  }

  Widget buildCard(Map<String, dynamic> activity) {
    switch (activity['cardType']) {
      case 'BUILD_STORY':
        return buildStoryCard(activity);
      case 'DISCUSSION':
        if (activity['cards'] != null && activity['cards'].isNotEmpty) {
          return buildDiscussionCard(activity);
        }
        return Container();
      case 'GAME':
        return buildGameCard(activity);
      case 'MOOD_TRACKER':
        return buildMoodTrackerCard(activity);
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
        margin: EdgeInsets.symmetric(horizontal: 8),
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
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
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
                  // crossAxisAlignment: CrossAxisAlignment.start,
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
                          // textAlign: TextAlign.center,
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
        margin: EdgeInsets.symmetric(horizontal: 8),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align children to the start

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
                    )
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
        margin: EdgeInsets.symmetric(horizontal: 8),
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

  Widget buildMoodTrackerCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoodTrackerScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.orange,
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
                  children: [
                    Image.network(card['image'],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: 200),
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
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: card.containsKey('tags')
                      ? card['tags'].map<Widget>((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10.0),
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

  SingleChildScrollView bodyContent(carousalHeight) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SizedBox(height: 10),
          CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 0.9,
              height: carousalHeight,
              // padEnds: true,
              // enlargeCenterPage: true
              onPageChanged: (index, reason) {
                changeBackgroundColor(index); // Change color on slide change
              },
            ),
            items: topActivities.map((activity) {
              return Builder(
                builder: (BuildContext context) {
                  return buildCard(activity);
                },
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Text('Soft Skills',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                height: 130,
                padding: EdgeInsets.only(left: 8.0),
                child: ListView.builder(
                    itemCount: softSkills.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Container(
                          child: SkillCard(
                        name: softSkills[index]['name'],
                        id: softSkills[index]['id'],
                        imageUrl: softSkills[index]['image'],
                        context: context,
                        colour: colors[index % colors.length],
                      ));
                    }),
              )
            ],
          ),
        ],
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Ideas for You',
            style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontWeight: FontWeight.bold)));
  }
}
