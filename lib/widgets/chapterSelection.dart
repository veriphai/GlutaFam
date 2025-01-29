import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChapterSelection extends StatelessWidget {
  final List<Map<String, dynamic>> chapters;
  final Function(int, String) onChapterSelect;
  final String activeChapter;

  const ChapterSelection(
      {Key? key,
      required this.chapters,
      required this.onChapterSelect,
      required this.activeChapter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.black, // Adjust color as needed
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Chapters",
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chapter List
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (BuildContext context, int index) {
                  final chapter = chapters[index];
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          chapter['name'],
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          // Trigger callback with chapter index and name
                          onChapterSelect(index, chapter['name']);
                          Navigator.pop(context); // Close the bottom sheet
                        },
                      ),
                      // Add Divider except for the last item
                      if (index < chapters.length - 1)
                        const Divider(
                          color: Colors.grey,
                          thickness: 0.5,
                          indent: 16.0,
                          endIndent: 16.0,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
