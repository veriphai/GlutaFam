import 'package:eureka_app/apis/fetchQuizzes.dart';
import 'package:eureka_app/screens/quizReportScreen.dart';
import 'package:eureka_app/widgets/quizQuestions.dart';
import 'package:eureka_app/widgets/quizReviewMode.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({Key? key}) : super(key: key);

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  List<Map<String, dynamic>> quizzes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getQuizzzes();
  }

  Future<void> getQuizzzes() async {
    try {
      final quizList = await fetchQuizzes();

      setState(() {
        quizzes = quizList;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching quizzes: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Quizzes",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.yellow[600],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return _buildQuizTile(context, quiz);
              },
            ),
    );
  }

  Widget _buildQuizTile(BuildContext context, Map<String, dynamic> quiz) {
    final alreadyAttempted = quiz["alreadyAttempted"] ?? false;
    final isExpired =
        quiz["validity"] * 1000 < DateTime.now().millisecondsSinceEpoch;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quiz Name
              Expanded(
                child: Text(
                  quiz["name"] ?? "Quiz",
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Quiz Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  quiz["image"] ?? "",
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Button for starting quiz or viewing report
          ChicletAnimatedButton(
            onPressed: () {
              if (alreadyAttempted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizReportScreen(
                      quizName: quiz["name"],
                      quizId: quiz["id"],
                      quizQuestions: quiz,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizQuestions(
                      quizId: quiz["id"],
                      quizName: quiz["name"],
                      quizQuestions: quiz,
                    ),
                  ),
                );
              }
            },
            buttonType: ChicletButtonTypes.roundedRectangle,
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            buttonColor: Colors.yellow[700]!,
            backgroundColor:
                alreadyAttempted ? Colors.grey : Colors.yellow[600],
            child: Text(
              alreadyAttempted
                  ? "View Report"
                  : isExpired
                      ? "Expired"
                      : "Start Quiz",
              style: GoogleFonts.raleway(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
