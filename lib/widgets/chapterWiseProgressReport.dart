import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChapterProgressReport extends StatefulWidget {
  final Map<String, dynamic> chapter;

  const ChapterProgressReport({Key? key, required this.chapter})
      : super(key: key);

  @override
  _ChapterProgressReportState createState() => _ChapterProgressReportState();
}

class _ChapterProgressReportState extends State<ChapterProgressReport> {
  String? expandedTopicId;

  @override
  Widget build(BuildContext context) {
    final progress = widget.chapter["progress"];
    final List<Map<String, dynamic>> topics =
        widget.chapter["topics"].cast<Map<String, dynamic>>() ?? [];

    // Categorize topics
    final topPerformers =
        topics.where((topic) => topic['progress']['accuracy'] > 75).toList();
    final keepPushing = topics
        .where((topic) =>
            topic['progress']['accuracy'] > 50 &&
            topic['progress']['accuracy'] <= 75)
        .toList();
    final needsAttention = topics
        .where((topic) =>
            topic['progress']['accuracy'] > 0 &&
            topic['progress']['accuracy'] <= 50)
        .toList();
    final yetToBegin =
        topics.where((topic) => topic['progress']['accuracy'] == 0).toList();

    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16, top: 40.0, bottom: 20),
              color: const Color.fromARGB(255, 221, 133, 0), // Background color
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close the screen
                    },
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  Spacer(), // Spacing between icon and text
                  Expanded(
                    child: Text(
                      widget.chapter["name"],
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow:
                          TextOverflow.ellipsis, // Handle long names gracefully
                    ),
                  ),
                  Spacer()
                ],
              ),
            ),
            // Top Container with overall stats
            _buildOverallStats(progress),

            // Topic Performance Sections
            Expanded(
              child: ListView(
                children: [
                  if (topPerformers.isNotEmpty)
                    _buildSection("Top Performers", topPerformers),
                  if (keepPushing.isNotEmpty)
                    _buildSection("Keep Pushing", keepPushing),
                  if (needsAttention.isNotEmpty)
                    _buildSection("Needs Attention", needsAttention),
                  if (yetToBegin.isNotEmpty)
                    _buildSection("Yet to Begin", yetToBegin),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(Map<String, dynamic> progress) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 221, 133, 0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress['topicCompleted']} topics completed',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${progress['completionPercentage']}% chapter completed',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${progress['totalXP']} XP gained',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        // Outline Text
                        Text(
                          '${(progress['accuracy'] as num).toStringAsFixed(0)}%',
                          style: GoogleFonts.raleway(
                            fontSize: 80,
                            fontWeight: FontWeight.w700,
                            height: 0.9,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 12
                              ..color = const Color.fromARGB(255, 159, 129, 81),
                          ),
                        ),
                        // Filled Text
                        Text(
                          '${(progress['accuracy'] as num).toStringAsFixed(0)}%',
                          style: GoogleFonts.raleway(
                            fontSize: 80,
                            fontWeight: FontWeight.w700,
                            height: 0.9,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> topics) {
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
          ...topics.map((topic) {
            final isExpanded = expandedTopicId == topic["_id"];
            return Column(
              children: [
                _buildTopicTile(topic, isExpanded),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopicTile(Map<String, dynamic> topic, bool isExpanded) {
    final started = topic["started"];
    final accuracy = topic['progress']['accuracy'];

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
          topic["name"],
          style: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "${(topic['progress']['accuracy'] as num).toStringAsFixed(0)}% Accuracy  ${topic['progress']['lessonCompleted']} lessons completed",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            expandedTopicId = isExpanded ? null : topic["_id"]; // Toggle topic
          });
        },
      ),
    );
  }
}
