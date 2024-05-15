import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DiscussionScreen extends StatelessWidget {
  final Map<String, dynamic> colours = {
    "About the Day": Color.fromRGBO(79, 161, 82, 1),
    "Would You Rather": Color.fromRGBO(207, 87, 125, 1),
    "About the World and Life": Color.fromRGBO(170, 82, 186, 1),
    "Creative Hour": Color.fromARGB(255, 227, 179, 59)
  };
  final Map<String, Map<String, dynamic>> questionCards = {
    "About the Day": {
      "type": "About the Day",
      "about": {
        "image":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png",
        "text":
            "Questions to learn what's happening in your child's life and what was important today"
      },
      "instructions": {
        "title": "How It Works",
        "steps": [
          "Use questions on the card as a conversation starter.",
          "Ask about child's feeling and thoughts."
        ]
      },
      "cards": [
        {
          "title": "What was the hardest thing you did today?",
          "id": "about_the_day_question_1"
        },
        {
          "title": "What did your class read today?",
          "id": "about_the_day_question_2"
        },
        {
          "title": "What was the easiest thing you did today?",
          "id": "about_the_day_question_3"
        },
        {
          "title": "What nice things have your friends done for you?",
          "id": "about_the_day_question_4"
        },
        {
          "title": "What questons did you ask your teacher today?",
          "id": "about_the_day_question_4"
        }
      ]
    },
    "Would You Rather": {
      "type": "Would You Rather",
      "about": {
        "image":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png",
        "text":
            "This is a set of creative questions for you and your child. Make your choices."
      },
      "instructions": {
        "title": "How It Works",
        "steps": [
          "Share the options",
          "Each of you should pick one of the two choices.",
          "Ask each other to expplain why you made this decision."
        ]
      },
      "cards": [
        {
          "title1": "only be aple to whisper?",
          "title2": "have an incredibely loud voice.",
          "id": "would_you_rather_question_1"
        },
        {
          "title1": "be an Olympic Athelete",
          "title2": "be the President",
          "id": "would_you_rather_question_2"
        },
        {
          "title1": "be able to read people's minds",
          "title2": "be invisible",
          "id": "would_you_rather_question_3"
        }
      ]
    },
    "About the World and Life": {
      "type": "About the World and Life",
      "about": {
        "image":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png",
        "text":
            "Abstract questions to learn your child's thinking and beliefs about the world and life."
      },
      "instructions": {
        "title": "How It Works",
        "steps": [
          "Use as conversation starter, then ask why?",
          "Ask Why?",
          "Discover your child"
        ]
      },
      "cards": [
        {
          "title": "Why do adults smile so little?",
          "id": "about_the_day_question_1"
        },
        {
          "title": "What will life look like in the future?",
          "id": "about_the_day_question_2"
        },
        {
          "title": "If you could, what would you change in this world?",
          "id": "about_the_day_question_3"
        },
        {
          "title": "Can you always say what's on your mind?",
          "id": "about_the_day_question_4"
        },
        {
          "title": "Is it possible to be happy without money",
          "id": "about_the_day_question_4"
        }
      ]
    },
    "Creative Hour": {
      "type": "Creative Hour",
      "about": {
        "image":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png",
        "text": "Questions to boost imagination and creativity of your child."
      },
      "instructions": {
        "title": "How It Works",
        "steps": [
          "Use question on the card as a conversation starter.",
          "Ask additional questions, be curious"
        ]
      },
      "cards": [
        {
          "title": "What does one need to do to stop always being late?",
          "id": "about_the_day_question_1"
        },
        {
          "title": "If you had a time machine, where would you go and why?",
          "id": "about_the_day_question_2"
        },
        {
          "title":
              "If you were as small as an ant, how would you describe our house?",
          "id": "about_the_day_question_3"
        },
        {
          "title": "If you were to write a book, what would it be about?",
          "id": "about_the_day_question_4"
        },
        {
          "title": "What would life be like if now one had a phone?",
          "id": "about_the_day_question_4"
        }
      ]
    }
  };

  final List<Map<String, dynamic>> discussionCards;

  DiscussionScreen(this.discussionCards);

  @override
  Widget build(BuildContext context) {
    List<Widget> carouselItems = [];

    carouselItems.addAll(_buildQuestionCards(discussionCards));

    return Scaffold(
      appBar: appBar(
        "Discussions",
      ),
      backgroundColor: Color.fromARGB(255, 227, 179, 59),
      body: CarouselSlider(
        options: CarouselOptions(
          aspectRatio: 0.8,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
          autoPlay: false,
        ),
        items: carouselItems,
      ),
    );
  }

  List<Widget> _buildQuestionCards(List<Map<String, dynamic>> cards) {
    return cards.map((card) {
      // Assuming 'type' is now a field inside each 'card' map
      Color colorToUse = colours[card['type']];
      if (card['type'] == "Would You Rather") {
        return Container(
            margin: EdgeInsets.only(top: 20),
            child: _buildWouldYouRatherCard(card, colorToUse));
      } else {
        return Container(
            margin: EdgeInsets.only(top: 20),
            child: _buildSimpleQuestionCard(card, colorToUse));
      }
    }).toList();
  }

  Widget _buildWouldYouRatherCard(Map<String, dynamic> card, Color colorToUse) {
    return Card(
      child: Container(
        margin: EdgeInsets.all(20.0),
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          border: Border.all(width: 4.0, color: colorToUse),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                card['title1'],
                style: TextStyle(
                    fontSize: 24.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 2),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "OR",
                      style: TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black, thickness: 2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                card['title2'],
                style: TextStyle(
                    fontSize: 24.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleQuestionCard(Map<String, dynamic> card, Color colorToUse) {
    return Card(
        child: Container(
      margin: EdgeInsets.all(20.0),
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
          border: Border.all(width: 4.0, color: colorToUse),
          borderRadius: BorderRadius.circular(15.0)),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(card['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    ));
  }

  AppBar appBar(String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
