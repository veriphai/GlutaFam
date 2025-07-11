import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectSelection extends StatefulWidget {
  final String selectedSubject;
  final Function(String, String) onSubjectSelect;
  final List<Map<String, dynamic>> books;

  const SubjectSelection(
      {Key? key,
      required this.selectedSubject,
      required this.onSubjectSelect,
      required this.books})
      : super(key: key);

  @override
  State<SubjectSelection> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelection> {
  late String _selectedSubject; // Local state for selected subject

  @override
  void initState() {
    super.initState();
    _selectedSubject =
        widget.selectedSubject; // Initialize with already selected subject
  }

  void _selectSubject(String subjectName, String bookId) {
    setState(() {
      _selectedSubject = subjectName;
    });
    widget.onSubjectSelect(subjectName, bookId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3, // Adjust height
      decoration: const BoxDecoration(
        color: Colors.transparent,
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
                  "Subjects",
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

            // Horizontal List of Subjects
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.books.map((subject) {
                  return _SubjectTile(
                    subjectName: subject['name']!,
                    bookId: subject["id"],
                    imagePath: subject['image']!,
                    isSelected: _selectedSubject == subject['subject'],
                    onSelect: _selectSubject,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final String subjectName;
  final String bookId;
  final String imagePath;
  final bool isSelected;
  final Function(String, String) onSelect;

  const _SubjectTile({
    Key? key,
    required this.subjectName,
    required this.bookId,
    required this.imagePath,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelect(subjectName, bookId);
      }, // Call the onSelect callback
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: Colors.yellow, width: 2) // Highlight border
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: Padding(
                  padding: EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )),
            ),
            const SizedBox(height: 8),
            SizedBox(
                width: 80, // match image width
                child: Text(
                  subjectName,
                  style: GoogleFonts.raleway(
                    color: isSelected ? Colors.yellow : Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )),
          ],
        ),
      ),
    );
  }
}
