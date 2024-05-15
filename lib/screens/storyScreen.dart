import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoryScreen extends StatefulWidget {
  final String storyId;

  StoryScreen(this.storyId);

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  bool _showFrontSide = true;
  bool isLoading = true;

  late Map<String, dynamic> storyData = {};

  Future<Map<String, dynamic>> fetchStoryDetails(String storyId) async {
    final url = 'https://glutaclass.com:8080/gluta/fam/story?storyId=$storyId';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    });
    fetchStoryDetails(widget.storyId).then((data) {
      setState(() {
        storyData = data;
        isLoading = false;
      });
    }).catchError((error) {
      print("Failed to load game: $error");
      // Optionally set up error handling state here
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _flipCard() {
    setState(() {
      _showFrontSide = !_showFrontSide;
    });
  }

  Widget _buildFront() {
    return GestureDetector(
      onTap: _flipCard,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.network(
              storyData['image'],
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 20.0,
            right: 20.0,
            child: Container(
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.yellow),
                child: IconButton(
                  icon:
                      Icon(Icons.close_rounded, color: Colors.black, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                )),
          ),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: Container(
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.yellow),
                child: IconButton(
                  icon:
                      Icon(Icons.question_mark, color: Colors.black, size: 30),
                  onPressed: _flipCard,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final cues = storyData['cues'];
    return GestureDetector(
      onTap: _flipCard,
      child: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Align items in a row
              children: [
                Text(
                  cues['heading'],
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(width: 1)),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: Colors.black, size: 30),
                      // onPressed: () => Navigator.of(context).pop(),
                      onPressed: _flipCard,
                    ))
              ],
            ),
            SizedBox(height: 10),
            Text(
              cues['helperText'],
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 20),
            ...List.generate(
              cues['points'].length,
              (index) => Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 8.0),
                        width: 24.0,
                        height: 24.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(59, 128, 185, 1),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          cues['points'][index],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )),
            ),
          ],
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    var color = _showFrontSide ? Colors.white : Color.fromRGBO(59, 128, 185, 1);
    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: _showFrontSide ? _buildFront() : _buildBack(),
      ),
    );
  }
}
