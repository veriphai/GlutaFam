import 'package:eureka_app/apis/fetchAiTeachers.dart';
import 'package:eureka_app/apis/getAITutorPrompts.dart';
import 'package:eureka_app/apis/getAITutorPromptsV2.dart';
import 'package:eureka_app/screens/conceptLearningScreenV2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eureka_app/widgets/aiTeacherSelection.dart';
import 'package:eureka_app/widgets/languageAndVoiceSelection.dart';
import 'package:eureka_app/apis/fetchLanguagesAndVoices.dart';
import 'package:chiclet/chiclet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConceptStartScreen extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;
  final String name;
  final String subject;
  final int standard;
  final bool firstLesson;
  final String? teacherId;
  const ConceptStartScreen(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.maxXP,
      required this.name,
      required this.subject,
      required this.standard,
      required this.firstLesson,
      this.teacherId})
      : super(key: key);

  @override
  State<ConceptStartScreen> createState() => _ConceptStartScreenState();
}

class _ConceptStartScreenState extends State<ConceptStartScreen> {
  late String selectedAITeacherId = "persona-1";
  late String selectedLanguage = "en-US";
  late String selectedVoice = "Zephyr";

  Map<String, String> languageOptions = {};
  Map<String, String> voiceOptions = {};
  List<Map<String, dynamic>> aiTeachers = [];

  late Map<String, dynamic> selectedAITeacher;
  late final prefs;

  bool isLoading = true;

  Future<void> loadDataFromCache() async {
    prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString("aiTutorLanguage") ?? "en-US";
    selectedVoice = prefs.getString("aiTutorVoice") ?? "Zephyr";
  }

  @override
  void initState() {
    super.initState();
    loadDataFromCache();
    loadLanguageAndVoiceOptions();
    getAITeachers();
  }

  Future<void> loadLanguageAndVoiceOptions() async {
    try {
      final data = await fetchLanguagesAndVoices();

      final List<dynamic> languages = data['languages'] ?? [];
      final List<dynamic> voices = data['voices'] ?? [];

      languageOptions = {for (var lang in languages) lang['id']: lang['name']};
      voiceOptions = {for (var voice in voices) voice['id']: voice['name']};

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading language and voice options: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getAITeachers() async {
    try {
      final aiTeachersData = await fetchAITeachers();
      setState(() {
        aiTeachers = aiTeachersData;
      });

      if (widget.teacherId == null) {
        selectedAITeacher = aiTeachersData.firstWhere(
            (teacher) => teacher["useAsDefault"] == true,
            orElse: () => {});
        selectedAITeacherId = selectedAITeacher["id"] ?? "persona-1";
      } else {
        selectedAITeacherId = widget.teacherId ?? "persona-1";
        selectedAITeacher = aiTeachersData.firstWhere(
            (teacher) => teacher["id"] == selectedAITeacherId,
            orElse: () => {});
      }
    } catch (error) {
      print("❌ Error fetching AI teachers: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
        title: Text(
          "Choose Your Tutor & Language",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  /// AI Teacher Selection Widget
                  Expanded(
                    flex: 2,
                    child: AITeacherSelection(
                        initialAITeacherSelected: selectedAITeacherId,
                        aiTeachers: aiTeachers,
                        key: UniqueKey(),
                        onSelectionChanged: (teacher) async {
                          // await prefs.setString("aiTutorId", teacher["id"]);
                          selectedAITeacherId = teacher["id"];
                          selectedAITeacher = teacher;
                        }),
                  ),

                  const SizedBox(height: 16),

                  /// Language and Voice Selection
                  LanguageAndVoiceSelection(
                    languages: languageOptions,
                    voices: voiceOptions,
                    selectedLanguage: selectedLanguage,
                    selectedVoice: selectedVoice,
                    onLanguageSelect: (id, name) async {
                      if (selectedLanguage != id) {
                        await prefs.setString("aiTutorLanguage", id);
                        setState(() {
                          selectedLanguage = id;
                        });
                      }
                    },
                    onVoiceSelect: (id, name) async {
                      await prefs.setString("aiTutorVoice", id);
                      setState(() {
                        selectedVoice = id;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  /// Confirm Button
                  ChicletAnimatedButton(
                    onPressed: () {
                      if (widget.firstLesson) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConceptLearningScreenV2(
                              conceptId: widget.conceptId,
                              conceptName: widget.conceptName,
                              maxXP: widget.maxXP,
                              name: widget.name,
                              subject: widget.subject,
                              standard: widget.standard,
                              tutorSelected: selectedAITeacher,
                              selectedLanguage: selectedLanguage,
                              selectedVoice: selectedVoice,
                            ),
                          ),
                        );
                      } else {
                        final response = {
                          "language": selectedLanguage,
                          "voice": selectedVoice,
                          "tutor": selectedAITeacher
                        };
                        Navigator.pop(context, response);
                      }
                    },
                    buttonType: ChicletButtonTypes.roundedRectangle,
                    height: 50,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                    backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                    child: Text(
                      "START LESSON",
                      style: GoogleFonts.raleway(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
    );
  }
}
