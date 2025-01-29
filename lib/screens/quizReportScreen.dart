import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchQuizReport.dart';
import 'package:eureka_app/widgets/quizReviewMode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class QuizReportScreen extends StatefulWidget {
  final String quizId;
  final String quizName;
  final Map<String, dynamic> quizQuestions;

  const QuizReportScreen(
      {Key? key,
      required this.quizId,
      required this.quizName,
      required this.quizQuestions})
      : super(key: key);

  @override
  State<QuizReportScreen> createState() => _QuizReportScreenState();
}

class _QuizReportScreenState extends State<QuizReportScreen> {
  bool isLoading = true;
  late Map<String, dynamic> quizSummary;
  late List<dynamic> quizQuestionsReports;
  late Map<String, dynamic> quizData;

  Future<void> getQuizReport() async {
    try {
      final quizReportData = await fetchQuizReport(quizId: widget.quizId);
      // final userProfile = await refreshProfile();

      setState(() {
        quizData = quizReportData;
        quizSummary = quizReportData["quizReportSummary"];
        quizQuestionsReports = quizReportData["quizQuestionsReports"];

        isLoading = false;
      });
    } catch (error) {
      print("Error fetching quizReport: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    getQuizReport();
  }

  @override
  Widget build(BuildContext context) {
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
      body: isLoading
          ? Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[300]!,
                child: Text(
                  'Loading...',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Quiz Summary",
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Tiles
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GridView wrapped in a constrained container
                      Container(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 2,
                          shrinkWrap:
                              true, // Ensures the GridView takes up only as much space as needed
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _buildReportTile(
                              "Rank",
                              "${quizSummary["rank"]}",
                              "lib/assets/gemIcon.png",
                            ),
                            _buildReportTile(
                              "Accuracy",
                              "${quizSummary["correctAnswers"] / quizSummary["totalQuestions"] * 100}%",
                              "lib/assets/accuracyIcon.png",
                            ),
                            _buildReportTile(
                              "Time Taken",
                              "${quizSummary["timeTaken"]}s",
                              "lib/assets/watchIcon.png",
                            ),
                            _buildReportTile(
                              "Ideal Time",
                              "${quizSummary["averageTimeTaken"]}s",
                              "lib/assets/watchIcon.png",
                            ),
                            _buildReportTile(
                              "Percentile",
                              "${quizSummary["percentile"]}%",
                              "lib/assets/gemIcon.png",
                            ),
                          ],
                        ),
                      ),
                      // Large Percentile Tile
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: _buildLargePercentileTile(
                          quizSummary["percentileTimings"],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  ChicletAnimatedButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewModeQuiz(
                            quizName: widget.quizName,
                            quizData: quizData,
                            quizQuestions: List<Map<String, dynamic>>.from(
                                widget.quizQuestions["questions"]),
                          ),
                        ),
                      );
                    },
                    buttonType: ChicletButtonTypes.roundedRectangle,
                    height: 50,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                    backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                    child: Text(
                      'QUESTION WISE PERFORMANCE',
                      style: GoogleFonts.raleway(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildReportTile(String title, String value, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
              mainAxisAlignment: MainAxisAlignment.center,
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
