import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionCards extends StatefulWidget {
  final String activityName;

  QuestionCards(this.activityName);
  @override
  _QuestionCardsState createState() => _QuestionCardsState();
}

class _QuestionCardsState extends State<QuestionCards> {
  bool isLoading = true;

  final Map<String, dynamic> colours = {
    "About the Day": Color.fromRGBO(79, 161, 82, 1),
    "Would You Rather": Color.fromRGBO(207, 87, 125, 1),
    "About the World and Life": Color.fromRGBO(170, 82, 186, 1),
    "Creative Hour": Color.fromARGB(255, 227, 179, 59),
    "Know Each Other Better": Color.fromARGB(255, 227, 179, 59)
  };

  late Map<String, dynamic> activityData = {};

  @override
  void initState() {
    super.initState();
    fetchQuestionCards(widget.activityName).then((data) {
      setState(() {
        activityData = data;
        isLoading = false;
      });
    }).catchError((error) {
      print("Failed to load game: $error");
      // Optionally set up error handling state here
    });
  }

  Future<Map<String, dynamic>> fetchQuestionCards(String activityName) async {
    final url =
        'https://glutaclass.com:8080/gluta/fam/talk-cards?type=$activityName';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load word game');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    var colorToUse = colours[widget.activityName];
    List<Widget> carouselItems = [];
    print(activityData);
    if (activityData != null) {
      print(activityData);
      print(activityData);
      if (activityData['about'] != null) {
        carouselItems.add(Container(
            margin: EdgeInsets.only(top: 20),
            child: _buildAboutCard(activityData['about'], colorToUse)));
      }
      if (activityData['instructions'] != null) {
        carouselItems.add(Container(
            margin: EdgeInsets.only(top: 20),
            child: _buildInstructionsCard(
                activityData['instructions'], colorToUse)));
      }
      if (List<Map<String, dynamic>>.from(activityData['cards']).isEmpty) {
        carouselItems.add(Center(
            child: Text('Coming Soon!',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ))));
      } else {
        carouselItems.addAll(_buildQuestionCards(
            List<Map<String, dynamic>>.from(activityData['cards']),
            widget.activityName,
            colorToUse));
      }
    }

    return Scaffold(
      appBar: appBar(widget.activityName),
      backgroundColor: colorToUse,
      body: CarouselSlider(
        options: CarouselOptions(
          aspectRatio: 0.85,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
          autoPlay: false,
        ),
        items: carouselItems,
      ),
    );
  }

  Widget _buildAboutCard(Map<String, dynamic> about, Color colorToUse) {
    return Card(
        child: Container(
      margin: EdgeInsets.all(20.0),
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
          border: Border.all(width: 4.0, color: colorToUse),
          borderRadius: BorderRadius.circular(15.0)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            about['image'],
            height: 100,
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.all(0.0),
            child: Text(about['text'],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ));
  }

  Widget _buildInstructionsCard(
      Map<String, dynamic> instructions, Color colorToUse) {
    return Card(
      child: Container(
        margin: EdgeInsets.all(20.0),
        padding: EdgeInsets.only(left: 20.0, right: 20.0),
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
                instructions['title'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: List.generate(
                instructions['steps'].length,
                (index) => ListTile(
                  leading: CircleAvatar(
                    radius: 15.0,
                    backgroundColor: colorToUse,
                    foregroundColor: Colors.white,
                    child: Text('${index + 1}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    instructions['steps'][index],
                    style: TextStyle(fontSize: 16.0, color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestionCards(
      List<Map<String, dynamic>> cards, String type, Color colorToUse) {
    if (type == "Would You Rather") {
      return cards
          .map((card) => Container(
              margin: EdgeInsets.only(top: 20),
              child: _buildWouldYouRatherCard(card, colorToUse)))
          .toList();
    } else {
      return cards
          .map((card) => Container(
              margin: EdgeInsets.only(top: 20),
              child: _buildSimpleQuestionCard(card, colorToUse)))
          .toList();
    }
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
