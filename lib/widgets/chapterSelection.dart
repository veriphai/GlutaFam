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
  final ScrollController scrollController;

  const ChapterSelection(
      {Key? key,
      required this.chapters,
      required this.onChapterSelect,
      required this.activeChapter,
      required this.subjects,
      required this.selectedSubject,
      required this.standard,
      required this.scrollController,
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
      decoration: const BoxDecoration(
        color: Color.fromRGBO(19, 31, 36, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          controller: widget.scrollController, // ← key line
          children: [
            // Subject chips row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: widget.subjects.map((subject) {
                      bool isSelected = subject['name'] == selectedSubject;
                      return GestureDetector(
                        onTap: () =>
                            _selectSubject(subject['name'], subject["id"]),
                        child: Chip(
                          label: Text(
                            subject['name'],
                            style: GoogleFonts.raleway(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          backgroundColor: isSelected
                              ? const Color.fromRGBO(255, 217, 0, 1)
                              : Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color.fromRGBO(255, 217, 0, 1)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: CircularProgressIndicator(
                    color: Color.fromRGBO(255, 217, 0, 1),
                  ),
                ),
              )
            else
              ...chapterList.asMap().entries.map((entry) {
                final index = entry.key;
                final chapter = entry.value;
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        chapter['name'],
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        widget.onChapterSelect(index, chapter['name']);
                        Navigator.pop(context);
                      },
                    ),
                    if (index < chapterList.length - 1)
                      const Divider(
                        color: Colors.grey,
                        thickness: 0.5,
                        indent: 16.0,
                        endIndent: 16.0,
                      ),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
