import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectSelection extends StatefulWidget {
  final String selectedSubject; // Already selected subject
  final Function(String) onSubjectSelect; // Callback to pass selected subject

  const SubjectSelection({
    Key? key,
    required this.selectedSubject,
    required this.onSubjectSelect,
  }) : super(key: key);

  @override
  State<SubjectSelection> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelection> {
  late String _selectedSubject; // Local state for selected subject

  final List<Map<String, String>> subjects = [
    {"name": "Science", "imagePath": "lib/assets/glutaclassLogo.png"},
    {"name": "English", "imagePath": "lib/assets/glutaclassLogo.png"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubject =
        widget.selectedSubject; // Initialize with already selected subject
  }

  void _selectSubject(String subjectName) {
    setState(() {
      _selectedSubject = subjectName;
    });
    widget.onSubjectSelect(subjectName);
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
                children: subjects.map((subject) {
                  return _SubjectTile(
                    subjectName: subject['name']!,
                    imagePath: subject['imagePath']!,
                    isSelected: _selectedSubject == subject['name'],
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
  final String imagePath;
  final bool isSelected;
  final Function(String) onSelect;

  const _SubjectTile({
    Key? key,
    required this.subjectName,
    required this.imagePath,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(subjectName), // Call the onSelect callback
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
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )),
            ),
            const SizedBox(height: 8),
            Text(
              subjectName,
              style: GoogleFonts.raleway(
                color: isSelected ? Colors.yellow : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
