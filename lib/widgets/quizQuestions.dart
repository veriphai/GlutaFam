import 'dart:ffi';

import 'package:audioplayers/audioplayers.dart';
import 'package:eureka_app/apis/fetchLessonQuestions.dart';
import 'package:eureka_app/apis/markLessonCompletion.dart';
import 'package:eureka_app/apis/markQuizCompleted.dart';
import 'package:eureka_app/widgets/conceptResultScreen.dart';
import 'package:eureka_app/widgets/quizResultScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';

class QuizQuestions extends StatefulWidget {
  final String quizId;
  final String quizName;
  final Map<String, dynamic>? quizQuestions;
  const QuizQuestions(
      {Key? key,
      required this.quizId,
      required this.quizName,
      this.quizQuestions})
      : super(key: key);

  @override
  State<QuizQuestions> createState() => _QuizQuestionsState();
}

class _QuizQuestionsState extends State<QuizQuestions> {
  int _correctStreak = 0; // Tracks consecutive correct answers
  bool _isCelebrationVisible = false;
  bool showQuestionStreak = true;

  bool isLoading = true;

  // Mock Data
  late Map<String, dynamic> lessonQuestions;
  List<Map<String, dynamic>> quizReport = [];
  late DateTime questionStartTime;

  Future<void> fetchData() async {
    try {
      Map<String, dynamic>? lessonQuestionsData =
          await fetchLessonQuestions(lessonId: widget.quizId);
      setState(() {
        lessonQuestions = lessonQuestionsData;
        isLoading = false;
        _startTime = DateTime.now();
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching lesson flashcards: $error");
    }
  }

  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _isAnswerChecked = false;
  final AudioPlayer _correctAudioPlayer = AudioPlayer();
  final AudioPlayer _incorrectAudioPlayer = AudioPlayer();
  int _totalXp = 0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    if (widget.quizQuestions != null && widget.quizQuestions!.isNotEmpty) {
      lessonQuestions = widget.quizQuestions!;
      isLoading = false;
      _startTime = DateTime.now();
    } else {
      // Fetch questions if not provided
      fetchData();
    }
    questionStartTime = DateTime.now();

    // fetchData();

    // Preload audio files
    _correctAudioPlayer.setSource(AssetSource('correct_answer.mp3')).then((_) {
      print('Correct answer audio preloaded');
    });

    _incorrectAudioPlayer
        .setSource(AssetSource('incorrect_answer.mp3'))
        .then((_) {
      print('Incorrect answer audio preloaded');
    });
  }

  Color getProgressBarColor(double progress) {
    if (progress <= 0.25) {
      return Colors.red; // Below 25% progress
    } else if (progress <= 0.50) {
      return Colors.orange; // Between 25% and 50%
    } else if (progress <= 0.75) {
      return Colors.yellow; // Between 50% and 75%
    } else {
      return Colors.green; // Above 75%
    }
  }

  void _playSound(String soundPath, bool isCorrect) {
    try {
      if (isCorrect) {
        _correctAudioPlayer.play(AssetSource(soundPath));
      } else {
        _incorrectAudioPlayer.play(
          AssetSource(soundPath),
        );
      }
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  void _checkAnswer() async {
    final currentQuestion = lessonQuestions['questions'][_currentQuestionIndex];
    final isCorrect = _selectedOption == currentQuestion['correctAnswer'];
    final questionTimeTaken =
        DateTime.now().difference(questionStartTime).inSeconds;

    quizReport.add({
      "questionId": currentQuestion["id"],
      "correct": isCorrect,
      "userAnswer": _selectedOption,
      "timeTaken": questionTimeTaken,
    });

    setState(() {
      showQuestionStreak = true;
    });

    if (isCorrect) {
      _playSound('correct_answer.mp3', isCorrect);
      _totalXp += 5;
      _correctStreak++;

      if (_correctStreak == 5 || _correctStreak == 10) {
        setState(() {
          _isCelebrationVisible = true;
        });

        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _isCelebrationVisible = false;
          });
          _nextQuestion();
        });
        return;
      }
    } else {
      _playSound('incorrect_answer.mp3', isCorrect);
      _correctStreak = 0;
    }

    setState(() {
      _isAnswerChecked = true;
    });
  }

  String _calculateTimeTaken() {
    final duration = DateTime.now().difference(_startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  double _calculateAccuracy() {
    final totalQuestions = lessonQuestions['questions'].length;
    return (_totalXp / (totalQuestions * 5)) * 100;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < lessonQuestions['questions'].length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswerChecked = false;
        showQuestionStreak = false;
        questionStartTime = DateTime.now();
      });
    } else {
      final timeTaken = _calculateTimeTaken();
      final accuracy = _calculateAccuracy();
      markQuizCompletion(
          quizId: widget.quizId,
          attemptTime: _startTime.second,
          timeToComplete: DateTime.now().difference(_startTime).inSeconds,
          xpGained: _totalXp,
          accuracy: accuracy,
          correctAnswers: _totalXp ~/ 5,
          report: quizReport);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            conceptName: 'Autotrophs',
            totalXp: _totalXp,
            timeTaken: timeTaken,
            accuracy: accuracy,
            quizQuestions: lessonQuestions,
          ),
        ),
      );
    }
  }

  double getProgress() {
    return (_currentQuestionIndex + 1) / lessonQuestions['questions'].length;
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
              child: CircularProgressIndicator(
                  color: Color.fromRGBO(255, 217, 0, 1)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Bar
                  if (_correctStreak >= 2 && showQuestionStreak)
                    FractionallySizedBox(
                      widthFactor: getProgress(),
                      child: Center(
                          child: SizedBox(
                              height: 20,
                              child: Text(
                                '$_correctStreak in row',
                                style: GoogleFonts.arOneSans(
                                  color: getProgressBarColor(getProgress()),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))),
                    )
                  else
                    SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Stack(
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
                              getProgress(), // Dynamically adjust width
                          height: 16.0,
                          decoration: BoxDecoration(
                            color: getProgressBarColor(getProgress()),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  if (_isCelebrationVisible)
                    Expanded(
                      child: Center(
                        child: Text(
                          '🎉 Great Job! 🎉\nKeep Going!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              lessonQuestions['questions']
                                  [_currentQuestionIndex]['question'],
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Options
                          ...lessonQuestions['questions'][_currentQuestionIndex]
                                  ['options']
                              .map<Widget>((option) {
                            final isSelected = _selectedOption == option['id'];
                            final isCorrect = option['id'] ==
                                lessonQuestions['questions']
                                    [_currentQuestionIndex]['correctAnswer'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ChicletOutlinedAnimatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  if (!_isAnswerChecked) {
                                    setState(() {
                                      _selectedOption = option['id'];
                                    });
                                  }
                                },
                                buttonType: ChicletButtonTypes.roundedRectangle,
                                height: 50,
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                borderWidth: 1.0,
                                borderColor: _isAnswerChecked
                                    ? (isCorrect
                                        ? Color.fromRGBO(187, 160, 2, 1)
                                        : (isSelected
                                            ? Colors.red
                                            : Colors.grey))
                                    : (isSelected ? Colors.blue : Colors.grey),
                                backgroundColor: Colors.black,
                                child: Text(
                                  option['option'],
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          const Spacer(),

                          // Check/Next Button
                          ChicletAnimatedButton(
                            onPressed: _selectedOption == null
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();

                                    if (_isAnswerChecked) {
                                      _nextQuestion();
                                    } else {
                                      _checkAnswer();
                                    }
                                  },
                            buttonType: ChicletButtonTypes.roundedRectangle,
                            height: 50,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            buttonColor: _isAnswerChecked
                                ? Color.fromRGBO(187, 160, 2, 1)
                                : (_selectedOption != null
                                    ? Color.fromRGBO(187, 160, 2, 1)
                                    : Colors.grey),
                            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                            child: Text(
                              _isAnswerChecked ? 'Next' : 'Check',
                              style: GoogleFonts.raleway(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ), // Question Text
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
