import 'package:flutter/material.dart';
import 'package:eureka_app/screens/moodTrackerScreen.dart';
import 'package:eureka_app/screens/storiesScreen.dart';
import 'package:eureka_app/screens/wordGamesScreen.dart';
import 'package:eureka_app/widgets/customBottomBar.dart';
import '../screens/talkQuestionsScreen.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class ExploreScreen extends StatelessWidget {
  final List<Map<String, dynamic>> talkOptions = [
    {"name": "Word Games", "image": "lib/assets/word-games.png"},
    {"name": "Tell a Story", "image": "lib/assets/tell-a-story.png"}
  ];

  final List<Map<String, dynamic>> mindfulActivities = [
    {"name": "Mood Tracker", "image": "lib/assets/mood-tracker.png"},
    {"name": "Know your Child", "image": "lib/assets/know-your-child.png"},
  ];

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: appBar(),
      backgroundColor: Color.fromRGBO(59, 128, 185, 1),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          height: 400, // Increased height to accommodate images
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Intriguing Conversations",
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: talkOptions.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => navigateToScreen(
                                context, talkOptions[index]['name']),
                            child: Container(
                              width: 120,
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      talkOptions[index]['image'],
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      talkOptions[index]['name'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Divider(
                    thickness: 1,
                  )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Mindful Check-ins",
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: mindfulActivities.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => navigateToScreen(
                                context, mindfulActivities[index]['name']),
                            child: Container(
                              width: 120,
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      mindfulActivities[index]['image'],
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      mindfulActivities[index]['name'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          CustomBottomNavBar(currentIndex: appState.currentIndex),
    );
  }

  void navigateToScreen(BuildContext context, String screenName) {
    if (screenName == "Know your Child") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => TalkQuestions()));
    } else if (screenName == "Tell a Story") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => StoriesScreen()));
    } else if (screenName == "Word Games") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => WordGames()));
    } else if (screenName == "Mood Tracker") {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => MoodTrackerScreen()));
    }
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Text(
        'Explore',
        style: TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
