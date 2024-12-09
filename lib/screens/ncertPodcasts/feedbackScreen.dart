import 'package:eureka_app/apis/submitFeedbackApi.dart';
import 'package:eureka_app/screens/ncertPodcasts/endQuestionsScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/sectionsListingScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FeedbackScreen extends StatefulWidget {
  final String chapterId;
  final String? sectionId; // Add sectionId as an optional parameter
  final List<dynamic>? sectionEndQuestions;

  const FeedbackScreen({
    Key? key,
    required this.chapterId,
    this.sectionId,
    this.sectionEndQuestions,
  }) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int selectedRating = 0;
  Set<String> selectedFeedbackOptions = {}; // Store only user-selected options

  final secureStorage = const FlutterSecureStorage();

  // Define feedback options based on the rating given
  List<String> getFeedbackOptions(int rating) {
    if (rating <= 2) {
      return [
        'Content was not clear',
        'Lesson was too long',
        'Lacked interactivity',
        'Other'
      ];
    } else if (rating == 3) {
      return [
        'It was okay',
        'Could be more engaging',
        'Good content but needs improvement',
        'Other'
      ];
    } else {
      return [
        'It was great',
        'Very engaging',
        'Clear and concise',
        'Would love more like this'
      ];
    }
  }

  // Toggle selection of feedback options
  void toggleFeedbackOption(String option) {
    setState(() {
      if (selectedFeedbackOptions.contains(option)) {
        selectedFeedbackOptions.remove(option);
      } else {
        selectedFeedbackOptions.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedbackOptions = getFeedbackOptions(selectedRating);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Feedback',
          style: GoogleFonts.raleway(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Spacer(),
            Text(
              'How do you like our lesson?',
              style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Color.fromRGBO(255, 217, 0, 1),
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedRating = index + 1;
                      selectedFeedbackOptions
                          .clear(); // Clear previous selections
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 24),

            // Feedback Options based on Rating
            if (selectedRating > 0) ...[
              Text(
                selectedRating <= 2
                    ? 'What didn’t you like?'
                    : selectedRating == 3
                        ? 'What could be better?'
                        : 'What did you like?',
                style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16),
              ...feedbackOptions.map((option) {
                return CheckboxListTile(
                  activeColor: Color.fromRGBO(255, 217, 0, 1),
                  checkColor: Colors.black,
                  value: selectedFeedbackOptions.contains(option),
                  title: Text(option,
                      style: GoogleFonts.raleway(color: Colors.white)),
                  onChanged: (selected) {
                    toggleFeedbackOption(option);
                  },
                );
              }).toList(),
            ],
            Spacer(),

            // Action Buttons in Column
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[850],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      submitFeedback(
                          chapterId: widget.chapterId,
                          sectionId: widget.sectionId ?? '',
                          feedbackOptions: selectedFeedbackOptions.toList(),
                          type: 'endLesson',
                          rating: selectedRating);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EndQuestionScreen(
                            chapterId: widget.chapterId,
                            sectionEndQuestions: widget.sectionEndQuestions,
                            sourceScreen: "FeedbackScreen",
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Continue with Q&A',
                      style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      submitFeedback(
                          chapterId: widget.chapterId,
                          sectionId: widget.sectionId ?? '',
                          feedbackOptions: selectedFeedbackOptions.toList(),
                          type: 'endLesson',
                          rating: selectedRating);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Sectionscreen(
                                  chapterId: widget.chapterId,
                                )),
                        (route) => true, // Remove all other routes in the stack
                      );
                    },
                    child: Text(
                      'End Lesson',
                      style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
