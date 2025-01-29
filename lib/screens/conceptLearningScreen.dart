import 'package:eureka_app/apis/fetchLessonFlashcards.dart';
import 'package:eureka_app/widgets/conversationScreen.dart';
import 'package:eureka_app/widgets/flashcardWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConceptLearningScreen extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;

  const ConceptLearningScreen(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.maxXP})
      : super(key: key);

  @override
  _ConceptLearningScreenState createState() => _ConceptLearningScreenState();
}

class _ConceptLearningScreenState extends State<ConceptLearningScreen> {
  // Mock Data
  late List<Map<String, dynamic>> flashcards;
  bool isLoading = true;

  Future<void> fetchData() async {
    try {
      Map<String, dynamic>? lessonFlashcards =
          await fetchLessonFlashcards(lessonId: widget.conceptId);
      setState(() {
        flashcards = (lessonFlashcards!["flashcards"] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching lesson flashcards: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(
                color: Color.fromRGBO(255, 217, 0, 1)))
        : Scaffold(
            backgroundColor: Colors.black,
            body: ConversationScreen(
              conceptId: widget.conceptId,
              conceptName: widget.conceptName,
              maxXP: widget.maxXP,
            ));
  }

  // @override
  // Widget build(BuildContext context) {
  //   return isLoading
  //       ? Center(
  //           child: CircularProgressIndicator(
  //               color: Color.fromRGBO(255, 217, 0, 1)))
  //       : Scaffold(
  //           appBar: AppBar(
  //             backgroundColor: Colors.black,
  //             elevation: 0,
  //             title: Text(
  //               widget.conceptName,
  //               style: GoogleFonts.raleway(
  //                 color: Colors.white,
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //           backgroundColor: Colors.black,
  //           body: FlashcardWidget(
  //             flashcards: flashcards,
  //             conceptId: widget.conceptId,
  //             conceptName: widget.conceptName,
  //           ),
  //         );
  // }
}
