import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sectionsListingScreen.dart';

class Chapterscreen extends StatefulWidget {
  final int standard = 8;

  const Chapterscreen({Key? key}) : super(key: key);

  @override
  _ChapterscreenState createState() => _ChapterscreenState();
}

class _ChapterscreenState extends State<Chapterscreen> {
  Set<String> bookmarkedChapters = {};

  Map<String, List<Map<String, dynamic>>> subjectChapters = {
    'Science': [],
    'Maths': [],
    'History': [],
    'Geography': [],
  };

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchAllChapters();
  }

  Future<void> fetchAllChapters() async {
    try {
      // Fetch chapters for each subject
      await Future.wait([
        fetchChapterList('Science'),
        fetchChapterList('Maths'),
        fetchChapterList('History'),
        fetchChapterList('Geography'),
      ]);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> fetchChapterList(String subject) async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/chapters?subject=$subject&standard=${widget.standard}';

    try {
      print("Fetching data for $subject from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response for $subject: $response");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Sorting the chapters based on the 'chapterNo'
        List<Map<String, dynamic>> sortedChapters = data
            .map((e) => e as Map<String, dynamic>)
            .toList()
          ..sort((a, b) => a['chapterNo'].compareTo(b['chapterNo']));

        setState(() {
          subjectChapters[subject] = sortedChapters;
        });
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : hasError
                ? Center(
                    child: Text(
                      'Failed to load chapters',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : _buildChapterContent(),
      ),
    );
  }

  Widget _buildChapterContent() {
    return ListView(
      children: subjectChapters.keys.map((subject) {
        final chapters = subjectChapters[subject] ?? [];
        if (chapters.isEmpty) {
          return const SizedBox.shrink(); // Don't display empty subjects
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed subject title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Scrollable chapters for the subject
            SizedBox(
              height: 350, // Adjust height as needed for chapters view
              child: PageView.builder(
                controller: PageController(
                    viewportFraction: 0.9), // Fraction for better visibility
                itemCount: (chapters.length / 4).ceil(),
                itemBuilder: (context, pageIndex) {
                  final pageChapters =
                      chapters.skip(pageIndex * 4).take(4).toList();
                  return Transform.translate(
                    offset:
                        Offset(-16, 0), // Shift each item slightly to the left
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: pageChapters.length,
                      itemBuilder: (context, index) {
                        final chapter = pageChapters[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Sectionscreen(
                                  chapterId: chapter['id'],
                                ),
                              ),
                            );
                          },
                          child: _buildChapterItem(chapter),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: const Text("GlutaClass",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  Widget _buildChapterItem(Map<String, dynamic> chapter) {
    return Card(
      color: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                chapter['image'],
                fit: BoxFit.cover,
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Chapter ${chapter['chapterNo']} • ${chapter['sections'].length} Sections • ${chapter['timeToComplete']} mins",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                _showBottomSheet(context, chapter);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Map<String, dynamic> chapter) {
    bool isBookmarked = bookmarkedChapters.contains(chapter['id']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    chapter['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  chapter['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Chapter ${chapter['chapterNo']} • ${chapter['sections'].length} Sections • ${chapter['timeToComplete']} mins",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: Icon(Icons.play_circle_outline_rounded,
                    color: Colors.white),
                title: Text(
                  "Go To Chapter",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Sectionscreen(
                        chapterId: chapter['id'],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isBookmarked
                      ? Icons.bookmark
                      : Icons
                          .bookmark_outline, // Toggle between outline and filled
                  color: Colors.white,
                ),
                title: Text(
                  isBookmarked ? "Bookmarked" : "Bookmark",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    if (isBookmarked) {
                      bookmarkedChapters.remove(chapter['id']);
                    } else {
                      bookmarkedChapters.add(chapter['id']);
                    }
                  });
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.share_outlined, color: Colors.white),
              //   title: Text(
              //     "Share",
              //     style: TextStyle(color: Colors.white),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     // Handle Share Action
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
