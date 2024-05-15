import 'package:eureka_app/screens/wordGameScreen.dart';
import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WordGames extends StatefulWidget {
  @override
  _WordGamesState createState() => _WordGamesState();
}

class _WordGamesState extends State<WordGames> {
  late List<Map<String, dynamic>> wordGames = [];

  @override
  void initState() {
    super.initState();
    fetchWordGames().then((data) {
      setState(() {
        wordGames = data;
      });
    }).catchError((error) {
      print("Failed to load games: $error");
      // Optionally set up error handling state here
    });
  }

  Future<List<Map<String, dynamic>>> fetchWordGames() async {
    const url = 'https://glutaclass.com:8080/gluta/fam/word-games';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((data) => data as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load word games');
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
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: wordGames.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(wordGames[index]['id']),
                  ),
                );
              },
              child: buildGameCard(wordGames[index]),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget buildGameCard(Map<String, dynamic> question) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Image.network(
              question['coverImage'],
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              question['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
        'Word Games',
        style: TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
