import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';

class ReviewModeQuiz extends StatefulWidget {
  final String quizName;
  final Map<String, dynamic> quizData;
  final List<Map<String, dynamic>> quizQuestions;

  const ReviewModeQuiz({
    Key? key,
    required this.quizName,
    required this.quizData,
    required this.quizQuestions,
  }) : super(key: key);

  @override
  State<ReviewModeQuiz> createState() => _ReviewModeQuizState();
}

class _ReviewModeQuizState extends State<ReviewModeQuiz> {
  int _currentQuestionIndex = 0;

  List<dynamic> get quizQuestionsReports =>
      widget.quizData["quizQuestionsReports"];
  Map<String, dynamic> get quizReportSummary =>
      widget.quizData["quizReportSummary"];

  Map<String, dynamic> getCurrentQuestion() {
    return widget.quizQuestions[_currentQuestionIndex];
  }

  Map<String, dynamic> getCurrentQuestionReport() {
    return quizQuestionsReports.firstWhere(
        (report) => report["questionId"] == getCurrentQuestion()["id"]
        // Corrected empty map type
        );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = getCurrentQuestion();
    final currentQuestionReport = getCurrentQuestionReport();
    final bool isCorrect = currentQuestionReport["correct"] ?? false;
    final String userAnswer = currentQuestionReport["userAnswer"] ?? '';
    final String correctAnswer = currentQuestion["correctAnswer"];
    final int timeTaken = currentQuestionReport["timeTaken"] ?? 0;
    final int totalQuestions = widget.quizQuestions.length;

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text(
            widget.quizName,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Question ${_currentQuestionIndex + 1} of $totalQuestions",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Custom Progress Bar using Stack
                Stack(
                  children: [
                    // Background Bar
                    Container(
                      height: 16.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    // Filled Bar
                    AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 300), // Animation duration
                      curve: Curves.easeInOut, // Animation curve
                      width: MediaQuery.of(context).size.width *
                          ((_currentQuestionIndex + 1) /
                              totalQuestions), // Dynamic width
                      height: 16.0,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Indicator
                  const SizedBox(height: 20),

                  // Question
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      currentQuestion["question"] ?? "No Question Text",
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Time Taken: ${timeTaken}s",
                          style: GoogleFonts.raleway(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          isCorrect ? "Correct" : "Incorrect",
                          style: GoogleFonts.raleway(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Options with User and Correct Answer Indication
                  ...currentQuestion["options"].map<Widget>((option) {
                    final bool isSelected = userAnswer == option["id"];
                    final bool isActualCorrect = correctAnswer == option["id"];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AbsorbPointer(
                        absorbing: true, // Prevent taps but keep appearance
                        child: ChicletOutlinedAnimatedButton(
                          onPressed:
                              () {}, // This won't show ripple or press effect
                          buttonType: ChicletButtonTypes.roundedRectangle,
                          height: 50,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          borderWidth: 1.0,
                          borderColor: isActualCorrect
                              ? Colors.green
                              : (isSelected ? Colors.red : Colors.grey),
                          backgroundColor: Colors.black,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option["option"] ?? "N/A",
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              if (isActualCorrect)
                                Icon(Icons.check, color: Colors.green, size: 24)
                              else if (isSelected)
                                Icon(Icons.close, color: Colors.red, size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                        color: Colors.grey[900],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Performance Overview",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Row 1: Correctly Answered and Ideal Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildOverviewTile(
                                  "Correctly Answered %",
                                  "${currentQuestionReport["correctlyAnsweredPercentile"].toStringAsFixed(1)}%",
                                  "lib/assets/accuracyIcon.png",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildOverviewTile(
                                  "Ideal Time to Answer",
                                  "${currentQuestionReport["idealTimeToAnswer"]} s",
                                  "lib/assets/watchIcon.png",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Row 2: Percentile Timings Summary
                          _buildLargePercentileTile(
                            currentQuestionReport["percentileTimings"],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation Buttons
                ],
              ),
            )),
          ),
          ChicletAnimatedButton(
            onPressed: _currentQuestionIndex < totalQuestions - 1
                ? _nextQuestion
                : null,
            buttonType: ChicletButtonTypes.roundedRectangle,
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.all(0),
            buttonColor: Colors.grey[800],
            backgroundColor: _currentQuestionIndex < totalQuestions - 1
                ? Colors.yellow
                : Colors.grey[800],
            child: Text(
              "CONTINUE",
              style: GoogleFonts.raleway(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ]));
  }

  Widget _buildOverviewTile(String title, String value, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                imagePath,
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.raleway(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargePercentileTile(Map<String, dynamic> timings) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'lib/assets/gemIcon.png',
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Percentile Timings",
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Timings breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPercentileTime("20%", timings["20"], Colors.orange),
              _buildPercentileTime("50%", timings["50"], Colors.blue),
              _buildPercentileTime("80%", timings["80"], Colors.green),
              _buildPercentileTime("90%", timings["90"], Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentileTime(String label, int time, Color color) {
    return Column(
      children: [
        Text(
          "$time s",
          style: GoogleFonts.raleway(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.raleway(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
