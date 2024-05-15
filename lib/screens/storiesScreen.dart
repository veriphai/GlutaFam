import 'package:eureka_app/screens/storyScreen.dart';
import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoriesScreen extends StatefulWidget {
  @override
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  late List<Map<String, dynamic>> stories = [];

  @override
  void initState() {
    super.initState();
    fetchStories().then((data) {
      setState(() {
        stories = data;
      });
    }).catchError((error) {
      print("Failed to load stories: $error");
      // Optionally set up error handling state here
    });
  }

  Future<List<Map<String, dynamic>>> fetchStories() async {
    const url = 'https://glutaclass.com:8080/gluta/fam/stories';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((data) => data as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      backgroundColor: Color.fromRGBO(59, 128, 185, 1),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: stories.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryScreen(stories[index]['id']),
                  ),
                );
              },
              child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: buildStoryCard(stories[index])),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget buildStoryCard(Map<String, dynamic> story) {
    return Card(
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.white,
      // color: const Color.fromARGB(255, 254, 203, 200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9, // Adjust the aspect ratio as needed
            child: Image.network(
              story['image'],
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              story['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
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
        'Stories for you',
        style: TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
