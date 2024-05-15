import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../screens/questionCardsScreen.dart';

class TalkQuestions extends StatelessWidget {
  final List<Map<String, dynamic>> questionsList = [
    {"name": "About the Day", "image": "lib/assets/about-the-day.png"},
    {"name": "Would You Rather", "image": "lib/assets/would-you-rather.png"},
    {
      "name": "Know Each Other Better",
      "image": "lib/assets/know-each-other.png"
    },
    {"name": "About the World and Life", "image": "lib/assets/about-world.png"},
    {"name": "Creative Hour", "image": "lib/assets/creative-hour.png"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Color.fromRGBO(59, 128, 185, 1),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: questionsList.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuestionCards(questionsList[index]['name']),
                  ),
                );
              },
              child: buildQuestionCard(questionsList[index]),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget buildQuestionCard(Map<String, dynamic> question) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            child: Image.asset(
              question['image'],
              width:
                  double.infinity, // Ensures the image covers the entire card
              height: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          Container(
            // Dark overlay at the bottom of the card
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(1), Colors.transparent],
              ),
            ),
            child: Text(
              question['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Questions for you',
        style: TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
