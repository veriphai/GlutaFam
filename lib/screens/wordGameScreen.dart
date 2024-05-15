import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameScreen extends StatefulWidget {
  final String gameId;

  GameScreen(this.gameId);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool isLoading = true;

  late Map<String, dynamic> gameData = {};

  @override
  void initState() {
    super.initState();
    fetchGameDetails(widget.gameId).then((data) {
      setState(() {
        gameData = data;
        isLoading = false;
      });
    }).catchError((error) {
      print("Failed to load game: $error");
      // Optionally set up error handling state here
    });
  }

  Future<Map<String, dynamic>> fetchGameDetails(String gameId) async {
    final url =
        'https://glutaclass.com:8080/gluta/fam/word-game?gameId=$gameId';

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
    Color bgColor = Color(int.parse(gameData['color']));
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      backgroundColor: bgColor,
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 3 / 5,
            child: Image.network(
              gameData['image'],
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align text to the start
              children: [
                Text(
                  "${gameData['name']}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white),
                ),
                SizedBox(height: 20), // Space between title and guide points
                Text(
                  "Guide:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white),
                ),
                ...gameData['guidePoints']
                    .map<Widget>((point) => Text("• $point",
                        style: TextStyle(fontSize: 16, color: Colors.white)))
                    .toList(),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
