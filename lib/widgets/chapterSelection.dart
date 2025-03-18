import 'package:eureka_app/apis/fetchChaptersV2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChapterSelection extends StatefulWidget {
  final List<Map<String, dynamic>> chapters;
  final Function(int, String) onChapterSelect;
  final String activeChapter;
  final List<Map<String, dynamic>> subjects;
  final String selectedSubject;
  final int standard;
  final Function(String, String) onSubjectSelect;

  const ChapterSelection(
      {Key? key,
      required this.chapters,
      required this.onChapterSelect,
      required this.activeChapter,
      required this.subjects,
      required this.selectedSubject,
      required this.standard,
      required this.onSubjectSelect})
      : super(key: key);

  @override
  _ChapterSelectionState createState() => _ChapterSelectionState();
}

class _ChapterSelectionState extends State<ChapterSelection> {
  late List<Map<String, dynamic>> chapterList;
  late String selectedSubject;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      chapterList = widget.chapters;
      selectedSubject = widget.selectedSubject;
    });
  }

  void _selectSubject(String subjectName, String bookId) async {
    setState(() {
      selectedSubject = subjectName;
      isLoading = true;
    });
    widget.onSubjectSelect(subjectName, bookId);

    try {
      List<Map<String, dynamic>> newChapters = await fetchChaptersV2(
          subject: selectedSubject, standard: widget.standard);
      newChapters.sort((a, b) => a["chapterNo"].compareTo(b["chapterNo"]));

      setState(() {
        chapterList = newChapters;
      });
    } catch (error) {
      print("Error fetching chapters: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(19, 31, 36, 1), // Adjust color as needed
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: widget.subjects.map((subject) {
                    // bool isSelected = subject == selectedSubject;
                    bool isSelected = subject['name']! == selectedSubject;

                    return GestureDetector(
                      onTap: () => _selectSubject(
                        subject['name'],
                        subject["id"],
                      ),
                      child: Chip(
                        label: Text(
                          subject['name']!,
                          style: GoogleFonts.raleway(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                        backgroundColor: isSelected
                            ? Color.fromRGBO(255, 217, 0, 1)
                            : Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? Color.fromRGBO(255, 217, 0, 1)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Chapter List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color.fromRGBO(255, 217, 0, 1),
                      ),
                    )
                  : ListView.builder(
                      itemCount: chapterList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final chapter = chapterList[index];
                        return Column(
                          children: [
                            ListTile(
                              // leading: CircleAvatar(
                              //   backgroundColor: Colors.grey[800],
                              //   child: Text(
                              //     '${index + 1}',
                              //     style: GoogleFonts.raleway(
                              //       color: Colors.white,
                              //       fontWeight: FontWeight.bold,
                              //     ),
                              //   ),
                              // ),
                              title: Text(
                                chapter['name'],
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                // Trigger callback with chapter index and name
                                widget.onChapterSelect(index, chapter['name']);
                                Navigator.pop(
                                    context); // Close the bottom sheet
                              },
                            ),
                            // Add Divider except for the last item
                            if (index < chapterList.length - 1)
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
