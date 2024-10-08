import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sectionsListingScreen.dart'; // Import the screen for sections

class Chapterscreen extends StatefulWidget {
  final String subject;
  final int standard;

  const Chapterscreen({Key? key, required this.subject, required this.standard})
      : super(key: key);

  @override
  _ChapterscreenState createState() => _ChapterscreenState();
}

class _ChapterscreenState extends State<Chapterscreen> {
  late List<Map<String, dynamic>> chapterList = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchChapterList(); // Fetch chapters from API
  }

  Future<void> fetchChapterList() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/chapters?subject=${widget.subject}&standard=${widget.standard}';

    try {
      print("Fetching data from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response: $response");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          chapterList = data.map((e) => e as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator()) // Show loader while loading
            : hasError
                ? Center(
                    child: Text('Failed to load chapters',
                        style: TextStyle(color: Colors.white))) // Error state
                : ListView.builder(
                    itemCount: chapterList.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Sectionscreen(
                                          chapterName: chapterList[index]
                                              ['name'],
                                          sections: chapterList[index]
                                              ['sections'],
                                          chapterImage: chapterList[index]
                                              ['image'],
                                        )));
                          },
                          child: _buildChapterCard(chapterList[index]));
                    }),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text("Chapters",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter) {
    return Card(
        color: Colors.grey[900],
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  chapter['image'],
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chapter['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    "${chapter['sections'].length} sections",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  )
                ],
              )),
              Text(
                "${chapter['timeToComplete']} mins",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ));
  }
}
