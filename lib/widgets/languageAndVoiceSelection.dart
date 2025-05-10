import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageAndVoiceSelection extends StatefulWidget {
  final Map<String, String> languages; // name: id
  final Map<String, String> voices; // name: id
  final String selectedLanguage;
  final String selectedVoice;
  final Function(String name, String id) onLanguageSelect;
  final Function(String name, String id) onVoiceSelect;

  const LanguageAndVoiceSelection({
    Key? key,
    required this.languages,
    required this.voices,
    required this.selectedLanguage,
    required this.selectedVoice,
    required this.onLanguageSelect,
    required this.onVoiceSelect,
  }) : super(key: key);

  @override
  _LanguageAndVoiceSelectionState createState() =>
      _LanguageAndVoiceSelectionState();
}

class _LanguageAndVoiceSelectionState extends State<LanguageAndVoiceSelection> {
  late String selectedLanguage;
  late String selectedVoice;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.selectedLanguage;
    selectedVoice = widget.selectedVoice;
  }

  void _showOptionsDialog(String type, Map<String, String> options,
      Function(String, String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        children: options.entries.map((entry) {
          final isSelected =
              (type == "Language" && entry.key == selectedLanguage) ||
                  (type == "Voice" && entry.key == selectedVoice);
          return ListTile(
            title: Text(
              entry.value,
              style: GoogleFonts.raleway(
                color:
                    isSelected ? Color.fromRGBO(255, 217, 0, 1) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onSelect(entry.key, entry.value);
              setState(() {
                if (type == "Language") selectedLanguage = entry.key;
                if (type == "Voice") selectedVoice = entry.key;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectorTile(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.fromRGBO(21, 40, 48, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              "$label:",
              style: GoogleFonts.raleway(color: Colors.white, fontSize: 16),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.raleway(
                    color: Color.fromRGBO(255, 217, 0, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(19, 31, 36, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSelectorTile(
              "Language", widget.languages[selectedLanguage] ?? "English", () {
            _showOptionsDialog(
                "Language", widget.languages, widget.onLanguageSelect);
          }),
          SizedBox(height: 16),
          _buildSelectorTile("Voice", widget.voices[selectedVoice] ?? "Puck",
              () {
            _showOptionsDialog("Voice", widget.voices, widget.onVoiceSelect);
          }),
        ],
      ),
    );
  }
}
