import 'package:eureka_app/events/bookEndQnaEvents.dart';
import 'package:eureka_app/screens/ncertPodcasts/endQuestionsScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/sectionsListingScreen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatelessWidget {
  final int correctAnswers;
  final int partiallyCorrect;
  final int totalQuestions;
  final String chapterId;
  final Map<String, QuestionResult>? questionResults;

  ResultScreen(
      {required this.correctAnswers,
      required this.partiallyCorrect,
      required this.totalQuestions,
      required this.chapterId,
      this.questionResults});

  Future<void> _setCurrentScreen() async {
    await FirebaseAnalytics.instance.logScreenView(
        screenClass: 'ResultScreen',
        screenName: "Result Screen",
        parameters: {
          "chapterId": chapterId,
        });
  }

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

    logResultScreenView(
        chapterId, correctAnswers, partiallyCorrect, totalQuestions);

    _setCurrentScreen();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        centerTitle: false,
        title: Text(
          'Q&A Results',
          style: GoogleFonts.raleway(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: correctAnswers / totalQuestions,
                        strokeWidth: 8.0,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(255, 217, 0, 1),
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toInt()}%',
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Text(
                  'You have done $correctAnswers out of $totalQuestions correct',
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'You have done $partiallyCorrect out of $totalQuestions partially correct',
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 80),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(
                      context,
                      label: 'Review Questions',
                      icon: Icons.replay,
                      color: Color.fromRGBO(255, 217, 0, 1),
                      onPressed: () {
                        logReviewQuestionsClickedOnResult(chapterId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EndQuestionScreen(
                              chapterId: chapterId, // Pass chapter ID
                              sectionEndQuestions: null, // Pass questions here
                              isReviewMode: true, // Enable review mode
                              questionResults: questionResults,
                              sourceScreen: "BookEndQuestionResultScreen",
                            ),
                          ),
                        );
                      },
                    ),
                    _buildButton(
                      context,
                      label: 'Reattempt Questions',
                      icon: Icons.refresh,
                      color: Colors.grey[850]!,
                      borderColor: Color.fromRGBO(255, 217, 0, 1),
                      onPressed: () {
                        logReattemptQuestions(chapterId);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EndQuestionScreen(
                              chapterId: chapterId,
                              sectionEndQuestions: null,
                              isReviewMode: false,
                              sourceScreen: "BookEndQuestionResultScreen",
                            ),
                          ),
                        );
                      },
                    ),
                    _buildButton(
                      context,
                      label: 'Go Back to Chapter',
                      icon: Icons.arrow_back,
                      color: Color.fromRGBO(255, 217, 0, 1),
                      // borderColor: Color.fromRGBO(255, 217, 0, 1),
                      onPressed: () {
                        logGoBackToChapter(chapterId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Sectionscreen(
                              chapterId: chapterId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: borderColor != null
                  ? BorderSide(color: borderColor, width: 2)
                  : BorderSide.none,
            ),
          ),
          icon: Icon(
            icon,
            color: borderColor != null ? borderColor : Colors.black,
          ),
          label: Text(
            label,
            style: GoogleFonts.raleway(
              color: borderColor != null ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
