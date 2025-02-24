import 'package:bubble_box/bubble_box.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/screens/mistakesCorrectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class MistakeCorrectionPopup extends StatelessWidget {
  final String conceptId;
  final String conceptName;
  final int totalXp;
  final String timeTaken;
  final double accuracy;
  final List<Map<String, dynamic>> incorrectQuestions;
  final Map<String, dynamic> lessonCompletionResponse;

  const MistakeCorrectionPopup(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.totalXp,
      required this.timeTaken,
      required this.accuracy,
      required this.incorrectQuestions,
      required this.lessonCompletionResponse})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
                child: BubbleBox(
                    maxWidth: double.infinity,
                    shape: BubbleShapeBorder(
                        border: BubbleBoxBorder(
                          color: Colors.grey.shade700,
                          width: 3,
                        ),
                        radius: BorderRadius.circular(12),
                        position: const BubblePosition.center(0),
                        direction: BubbleDirection.bottom,
                        arrowHeight: 10),
                    backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text("Its time to correct your mistakes!!",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ))))),
            Transform.translate(
                offset: Offset(10, -25), // Moves it up slightly
                child: Lottie.asset("lib/assets/animations/coolCat.json",
                    width: 150, height: 150, repeat: true)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ChicletAnimatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MistakesCorrectionScreen(
                  conceptName: conceptName,
                  conceptId: conceptId,
                  totalXp: totalXp,
                  timeTaken: timeTaken,
                  accuracy: accuracy,
                  incorrectQuestions: incorrectQuestions,
                  lessonCompletionResponse: lessonCompletionResponse,
                ),
              ),
              (route) => false,
            );
          },
          buttonType: ChicletButtonTypes.roundedRectangle,
          height: 50,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          buttonColor: Color.fromRGBO(187, 160, 2, 1),
          backgroundColor: Color.fromRGBO(255, 217, 0, 1),
          child: Text(
            "CONTINUE",
            style: GoogleFonts.raleway(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
