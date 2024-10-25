import 'package:flutter/material.dart';
import 'dart:convert'; // For decoding JSON
import 'package:http/http.dart' as http;

class ChaptersTestScreen extends StatefulWidget {
  @override
  _ChaptersScreenState createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersTestScreen> {
  List chapters = [];
  List engChapters = [];

  bool loading = true;
  String error = '';
  Map<String, dynamic>? selectedChapter;
  Map<String, dynamic>? chapterDetails;

  // Function to fetch the list of chapters
  Future<void> fetchChapters() async {
    setState(() {
      loading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://glutaclass.com:8080/gluta/fam/chaptersV2?subject=Science&standard=8'));
      if (response.statusCode == 200) {
        setState(() {
          chapters = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          error = 'Error fetching chapters';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        loading = false;
      });
    }
  }

  Future<void> fetchEnglishChapters(subject) async {
    setState(() {
      loading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://glutaclass.com:8080/gluta/fam/chaptersV2?subject=$subject&standard=8'));
      if (response.statusCode == 200) {
        setState(() {
          engChapters = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          error = 'Error fetching chapters';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        loading = false;
      });
    }
  }

  // Function to fetch details for a selected chapter
  Future<void> fetchChapterDetails(String chapterId) async {
    setState(() {
      loading = true;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://glutaclass.com:8080/gluta/fam/chapterV2?chapterId=$chapterId'));
      if (response.statusCode == 200) {
        setState(() {
          chapterDetails = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          error = 'Error fetching chapter details';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchChapters();
    fetchEnglishChapters('English - It So Happened');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Chapters')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Chapters')),
        body: Center(child: Text(error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chapters'),
      ),
      body: selectedChapter == null
          ? Column(
              children: [
                SizedBox(
                  height: 400.0, // Set a fixed height
                  child: ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return ListTile(
                        title: Text(chapter['name']),
                        subtitle: Text('Chapter No: ${chapter['chapterNo']}'),
                        onTap: () {
                          setState(() {
                            selectedChapter = chapter;
                          });
                          fetchChapterDetails(chapter['id']);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 200.0, // Set a fixed height
                  child: ListView.builder(
                    itemCount: engChapters.length,
                    itemBuilder: (context, index) {
                      final chapter = engChapters[index];
                      return ListTile(
                        title: Text(chapter['name']),
                        subtitle: Text('Chapter No: ${chapter['chapterNo']}'),
                        onTap: () {
                          setState(() {
                            selectedChapter = chapter;
                          });
                          fetchChapterDetails(chapter['id']);
                        },
                      );
                    },
                  ),
                ),
              ],
            )
          : chapterDetails != null
              ? ChapterDetails(
                  chapter: selectedChapter!,
                  details: chapterDetails!,
                  subject: chapterDetails?['subject'],
                  onBack: () {
                    setState(() {
                      selectedChapter = null;
                      chapterDetails = null;
                    });
                  },
                )
              : Center(child: CircularProgressIndicator()),
    );
  }
}

class ChapterDetails extends StatelessWidget {
  final Map<String, dynamic> chapter;
  final Map<String, dynamic> details;
  final String subject;
  final VoidCallback onBack;

  ChapterDetails(
      {required this.chapter,
      required this.details,
      required this.subject,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: onBack, child: Text('Back to Chapters')),
        Expanded(
          child: ListView.builder(
            itemCount: details['sections'].length,
            itemBuilder: (context, index) {
              final section = details['sections'][index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section['name'],
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text(section['description']),
                        SizedBox(height: 10),
                        if (subject == 'Science') ...[
                          Text('Dialogues:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...section['dialogues'].map<Widget>((dialogue) {
                            return ListTile(
                              title: Text(
                                  '${dialogue['speaker']}: ${dialogue['text']}'),
                            );
                          }).toList(),
                        ] else ...[
                          // If the subject is not Science, show the separate headings with different lists
                          Text('Introduction:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...section['intro'].map<Widget>((introItem) {
                            return ListTile(
                              title: Text(
                                  '${introItem['speaker']}: ${introItem['text']}'),
                            );
                          }).toList(),

                          SizedBox(
                              height: 20), // Adding some space between sections

                          Text('Reading:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...section['reading'].map<Widget>((readingItem) {
                            return ListTile(
                              title: Text(
                                  '${readingItem['speaker']}: ${readingItem['text']}'),
                            );
                          }).toList(),

                          SizedBox(height: 20),

                          Text('Explanation:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...section['explanation']
                              .map<Widget>((explanationItem) {
                            return ListTile(
                              title: Text(
                                  '${explanationItem['speaker']}: ${explanationItem['text']}'),
                            );
                          }).toList(),

                          SizedBox(height: 20),

                          Text('QnA:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...section['qna'].map<Widget>((qnaItem) {
                            return ListTile(
                              title: Text(
                                  '${qnaItem['speaker']}: ${qnaItem['text']}'),
                            );
                          }).toList(),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
