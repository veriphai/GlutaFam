import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchBooks.dart';
import 'package:eureka_app/apis/fetchProgressReport.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/widgets/chapterWiseProgressReport.dart';
import 'package:eureka_app/widgets/findMyFriendsWidget.dart';
import 'package:eureka_app/widgets/subjectSelection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ProgressReportScreen extends StatefulWidget {
  final String? userId;

  const ProgressReportScreen({Key? key, this.userId}) : super(key: key);

  @override
  _ProgressReportScreenState createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  late Map<String, dynamic> progressReport = {};
  late List<Map<String, dynamic>> books;
  bool isLoading = true;
  String selectedSubject = "";
  String selectedBookId = "";

  late Map<String, dynamic> userProfile;

  Future<void> getProgressReport() async {
    final progressReportData = await fetchProgressReport(
      bookId: selectedBookId,
      userId: widget.userId,
    );
    setState(() {
      progressReport = progressReportData;
      isLoading = false;
    });
  }

  Future<void> getBooks() async {
    final booksData = await fetchBooks(standard: userProfile["standard"]);
    setState(() {
      books = booksData;
      selectedSubject = booksData[0]["name"];
      selectedBookId = booksData[0]["id"];
    });
  }

  Future<void> fetchProfile() async {
    try {
      final profileData = await getProfile();

      setState(() {
        userProfile = profileData;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile().then((_) => getBooks().then((_) => getProgressReport()));
  }

  void _showChapterReportSheet(
      BuildContext context, Map<String, dynamic> chapter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return ChapterProgressReport(chapter: chapter);
      },
    );
  }

  void _showSubjectSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return SubjectSelection(
          selectedSubject: selectedSubject,
          books: books,
          onSubjectSelect: (selected, bookId) async {
            setState(() {
              selectedSubject = selected;
              selectedBookId = bookId;
            });
            await getProgressReport();
          },
        );
      },
    );
  }

  void _showCompareWithFriendsSheet(BuildContext context) {
    final List<Map<String, dynamic>> friends =
        userProfile["friends"].cast<Map<String, dynamic>>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.5, // Set max height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Compare with Friends",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // List of Friends
              friends.isEmpty
                  ? Column(
                      children: [
                        Text(
                          "No friends added yet!",
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16), // Add spacing for better UI
                        SizedBox(
                          width: double
                              .infinity, // Ensures full width inside a column
                          child: ChicletAnimatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FindMyFriendsScreen(
                                    profileData: userProfile,
                                  ),
                                ),
                              );
                            },
                            buttonType: ChicletButtonTypes.roundedRectangle,
                            height: 50,
                            padding: const EdgeInsets.all(8),
                            buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                            backgroundColor:
                                const Color.fromRGBO(255, 217, 0, 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add_alt,
                                    color: Colors.black),
                                const SizedBox(width: 10),
                                Text(
                                  "ADD FRIENDS",
                                  style: GoogleFonts.raleway(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Image.asset(
                                getAvatar(friend.containsKey("avatar") &&
                                        friend["avatar"] != null
                                    ? friend["avatar"]
                                    : "random")["imagePath"]!,
                                height: 50,
                              ),
                              title: Text(
                                friend["name"]!,
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: ChicletAnimatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                    String encodedFriendId = friend["id"]
                                            .startsWith('+')
                                        ? friend["id"].replaceFirst('+', '%2B')
                                        : friend["id"];
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProgressReportScreen(
                                                userId: encodedFriendId),
                                      ),
                                    );
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  height: 40,
                                  width: 100,
                                  padding: const EdgeInsets.all(8),
                                  buttonColor:
                                      const Color.fromRGBO(25, 151, 213, 1),
                                  backgroundColor:
                                      const Color.fromRGBO(74, 193, 249, 1),
                                  child: Text(
                                    "COMPARE",
                                    style: GoogleFonts.raleway(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )));
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> chapters = [];
    Map<String, dynamic> overallProgress = {};
    if (progressReport != null && progressReport.isNotEmpty) {
      overallProgress = progressReport["overallProgress"];
      chapters = progressReport["chapters"].cast<Map<String, dynamic>>();

      // Categorize chapters
    }
    final bestChapters = chapters
        .where((chapter) => chapter['progress']['accuracy'] > 75)
        .toList();
    final averageChapters = chapters
        .where((chapter) =>
            chapter['progress']['accuracy'] > 50 &&
            chapter['progress']['accuracy'] <= 75)
        .toList();
    final worstChapters = chapters
        .where((chapter) =>
            chapter['progress']['accuracy'] > 0 &&
            chapter['progress']['accuracy'] <= 50)
        .toList();
    final notAttemptedChapters = chapters
        .where((chapter) => chapter['progress']['accuracy'] == 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Progress Report",
          style: TextStyle(color: Colors.white),
        ),
        scrolledUnderElevation: 0,
        actions: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                  onTap: () {
                    _showSubjectSelectionSheet(context);
                  },
                  child: Row(children: [
                    Text(
                      selectedSubject,
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                    )
                  ])))
        ],
        backgroundColor: Color.fromARGB(255, 221, 133, 0),
      ),
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: isLoading
          ? Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[300]!,
                child: Text(
                  'Loading...',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Container with overall stats
                  _buildOverallStats(overallProgress),

                  // Chapter Performance Sections
                  Expanded(
                    child: ListView(
                      children: [
                        if (bestChapters.isNotEmpty)
                          _buildSection("Top Performers", bestChapters),
                        if (averageChapters.isNotEmpty)
                          _buildSection("Keep Pushing", averageChapters),
                        if (worstChapters.isNotEmpty)
                          _buildSection("Needs Attention", worstChapters),
                        if (notAttemptedChapters.isNotEmpty)
                          _buildSection("Yet to Begin", notAttemptedChapters),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallStats(Map<String, dynamic> overallProgress) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 221, 133, 0),
      ),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streak Info
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${overallProgress['chaptersCompleted']} lessons completed',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${overallProgress['completionPercentage']}% subject completed',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${overallProgress['totalXP']} XP gained',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          // Outline Text
                          Text(
                            '${(overallProgress['accuracy'] as num).toStringAsFixed(0)}%',
                            style: GoogleFonts.raleway(
                              fontSize: 80,
                              fontWeight: FontWeight.w700,
                              height: 0.9,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 12
                                ..color = Color.fromARGB(255, 159, 129, 81),
                            ),
                          ),
                          // Filled Text
                          Text(
                            '${(overallProgress['accuracy'] as num).toStringAsFixed(0)}%',
                            style: GoogleFonts.raleway(
                              fontSize: 80,
                              fontWeight: FontWeight.w700,
                              height: 0.9,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'accuracy',
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              if (widget.userId == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add Friends Button
                    Expanded(
                      child: ChicletAnimatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showCompareWithFriendsSheet(context);
                          // _showFriendSelectionBottomSheet();

                          // Logic for adding friends
                        },
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        height: 50,
                        padding: const EdgeInsets.all(8),
                        buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                        backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_add_alt,
                                color: Colors.black),
                            const SizedBox(width: 10),
                            Text(
                              "COMPARE WITH FRIENDS",
                              style: GoogleFonts.raleway(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          )),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> chapters) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...chapters.map((chapter) {
            return Column(
              children: [
                _buildChapterTile(chapter),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildChapterTile(Map<String, dynamic> chapter) {
    final started = chapter["started"];
    final accuracy = chapter['progress']['accuracy'];

    // Determine colors based on accuracy
    Color borderColor;
    Color backgroundColor;

    if (accuracy > 75) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (accuracy > 50) {
      borderColor = Colors.yellow;
      backgroundColor = Colors.yellow.withOpacity(0.1);
    } else {
      borderColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    }
    if (!started) {
      borderColor = Colors.grey;
      backgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      color: backgroundColor,
      child: ListTile(
        leading: Icon(
          started ? Icons.check_circle : Icons.hourglass_empty,
          color: started ? Colors.green : Colors.grey,
        ),
        title: Text(
          chapter["name"],
          style: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "${(chapter['progress']['accuracy'] as num).toStringAsFixed(0)}% Accuracy  ${chapter['progress']['topicCompleted']} lessons Completed",
          style: GoogleFonts.raleway(
              color: Colors.white, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
        ),
        onTap: () {
          _showChapterReportSheet(context, chapter);
        },
      ),
    );
  }
}
