import 'package:audioplayers/audioplayers.dart';
import 'package:eureka_app/apis/fetchLessonQuestions.dart';
import 'package:eureka_app/apis/markLessonCompletion.dart';
import 'package:eureka_app/screens/mistakesCorrectionScreen.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/lifelinesManager.dart';
import 'package:eureka_app/widgets/conceptResultScreen.dart';
import 'package:eureka_app/widgets/lifelinesWidget.dart';
import 'package:eureka_app/widgets/mistakeCorrectionPopup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

class MCQQuestions extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final Map<String, dynamic>? quizQuestions;
  final int maxXP;

  const MCQQuestions(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      this.quizQuestions,
      required this.maxXP})
      : super(key: key);

  @override
  State<MCQQuestions> createState() => _MCQQuestionsState();
}

class _MCQQuestionsState extends State<MCQQuestions> {
  int _correctStreak = 0; // Tracks consecutive correct answers
  bool _isCelebrationVisible = false;
  bool showQuestionStreak = true;

  late Map<String, dynamic> userProfile;

  bool isLoading = true;

  List<Map<String, dynamic>> lessonReport = [];
  List<Map<String, dynamic>> incorrectQuestions = [];

  late DateTime questionStartTime;
  late int lifelines;
  late LifelineManager lifelineManager;
  late bool unlimitedLifelines;
  late int xpPerQuestion;

  // Mock Data
  late Map<String, dynamic> lessonQuestions;
  Future<void> fetchData() async {
    try {
      Map<String, dynamic>? lessonQuestionsData =
          await fetchLessonQuestions(lessonId: widget.conceptId);

      prefs = await SharedPreferences.getInstance();
      final lifelinesFromCache = prefs.getInt("lifelines");
      final bookIdSelected = prefs.getString("bookId");
      final unLimitedLifelinesEnabled = prefs.getBool("unlimitedLifelines");

      // final profileData = await getProfile();

      setState(() {
        // userProfile = profileData;
        lessonQuestions = lessonQuestionsData;
        lifelines = lifelinesFromCache ?? 0;
        bookId = bookIdSelected ?? "";
        unlimitedLifelines = unLimitedLifelinesEnabled ?? false;

        xpPerQuestion =
            (widget.maxXP / lessonQuestionsData["questions"].length).toInt();

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
  late SharedPreferences prefs;
  late String bookId;

  @override
  void initState() {
    super.initState();
    lifelineManager = LifelineManager();
    lifelineManager.initializeLifelines();
    if (widget.quizQuestions != null && widget.quizQuestions!.isNotEmpty) {
      lessonQuestions = widget.quizQuestions!;
      isLoading = false;
      _startTime = DateTime.now();
    } else {
      // Fetch questions if not provided
      fetchData();
    }
    questionStartTime = DateTime.now();
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

  void _showLifelinesSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return LifelinesWidget(
          lifelines: lifelines,
          onLifelinesUpdated: (updatedLifelines, updatedCredits) {
            setState(() {
              lifelines = updatedLifelines;
            });
          },
        );
      },
    );
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

    // Add report object for the current question
    lessonReport.add({
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
      _totalXp += xpPerQuestion;
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
      if (!unlimitedLifelines) {
        setState(() {
          lifelines -= 1;
          // updateLifelines(prefs, lifelines);
        });
        if (lifelines <= 0) {
          _showLifelinesSheet(context);
        }
        lifelineManager.reduceLifeline();
      }
      currentQuestion["userAnswer"] = _selectedOption;
      incorrectQuestions.add(currentQuestion);
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
    return (_totalXp / (totalQuestions * xpPerQuestion)) * 100;
  }

  void _nextQuestion() async {
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
      final Map<String, dynamic> lessonCompletionResponse =
          await markLessonCompletion(
              lessonId: widget.conceptId,
              attemptTime: _startTime.second,
              timeToComplete: DateTime.now().difference(_startTime).inSeconds,
              xpGained: _totalXp,
              accuracy: accuracy,
              bookId: bookId,
              report: lessonReport,
              correctlyAnswered: lessonQuestions['questions'].length -
                  incorrectQuestions.length);
      if (incorrectQuestions.isEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ConceptResultScreen(
              conceptName: widget.conceptName,
              totalXp: _totalXp,
              timeTaken: timeTaken,
              accuracy: accuracy,
              lessonCompletionResponse: lessonCompletionResponse,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MistakeCorrectionPopup(
              conceptName: widget.conceptName,
              conceptId: widget.conceptId,
              totalXp: _totalXp,
              timeTaken: timeTaken,
              accuracy: accuracy,
              incorrectQuestions: incorrectQuestions,
              lessonCompletionResponse: lessonCompletionResponse,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  double getProgress() {
    return (_currentQuestionIndex + 1) / lessonQuestions['questions'].length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.grey,
        ),
        title: Text(
          widget.conceptName,
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
                    child: Row(children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            return Stack(
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
                                  width: availableWidth *
                                      getProgress(), // Dynamically adjust width
                                  height: 16.0,
                                  decoration: BoxDecoration(
                                    color: getProgressBarColor(getProgress()),
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 20),
                      Row(children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 24,
                        ),
                        SizedBox(width: 5),
                        Text(unlimitedLifelines ? "∞" : "$lifelines",
                            style: TextStyle(color: Colors.white))
                      ])
                    ]),
                  ),
                  SizedBox(
                    height: 20,
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: MarkdownBody(
                                selectable: true,
                                data: lessonQuestions['questions']
                                    [_currentQuestionIndex]['question'],
                                builders: {
                                  'latex': LatexElementBuilder(
                                    textStyle: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700),
                                  ),
                                },
                                extensionSet: md.ExtensionSet(
                                  [LatexBlockSyntax()],
                                  [LatexInlineSyntax()],
                                ),
                                styleSheet: MarkdownStyleSheet(
                                  p: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                  blockSpacing: 8.0,
                                ),
                              )),

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
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
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
                                      : (isSelected
                                          ? Colors.blue
                                          : Colors.grey),
                                  backgroundColor:
                                      Color.fromRGBO(19, 31, 36, 1),
                                  child: MarkdownBody(
                                    selectable: true,
                                    data: option['option'],
                                    builders: {
                                      'latex': LatexElementBuilder(
                                        textStyle: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    },
                                    extensionSet: md.ExtensionSet(
                                      [LatexBlockSyntax()],
                                      [LatexInlineSyntax()],
                                    ),
                                    styleSheet: MarkdownStyleSheet(
                                      p: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      blockSpacing: 8.0,
                                    ),
                                  )
                                  //  Text(
                                  //   option['option'],
                                  //   style: GoogleFonts.raleway(
                                  //     color: Colors.white,
                                  //     fontSize: 16,
                                  //   ),
                                  // ),
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
