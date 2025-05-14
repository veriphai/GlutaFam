import 'package:audioplayers/audioplayers.dart';
import 'package:eureka_app/apis/fetchLessonQuestions.dart';
import 'package:eureka_app/apis/markLessonCompletion.dart';
import 'package:eureka_app/main.dart';
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
import 'package:lottie/lottie.dart';
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
  Set<String> _selectedOptions = {}; // For MCMA questions

  bool _isAnswerChecked = false;
  final AudioPlayer _correctAudioPlayer = AudioPlayer();
  final AudioPlayer _incorrectAudioPlayer = AudioPlayer();
  final AudioPlayer _correctStreakPlayer = AudioPlayer();

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
    _totalXp = widget.maxXP;
    questionStartTime = DateTime.now();
    // Preload audio files
    _correctAudioPlayer.setSource(AssetSource('correct_answer.mp3')).then((_) {
      print('Correct answer audio preloaded');
    });

    _correctStreakPlayer.setSource(AssetSource('jumpSound.mp3')).then((_) {
      print('Correct answer audio preloaded');
    });

    _incorrectAudioPlayer
        .setSource(AssetSource('incorrect_answer.mp3'))
        .then((_) {
      print('Incorrect answer audio preloaded');
    });
  }

  void _showLifelinesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: LifelinesWidget(
            lifelines: lifelines,
            isUnclosable: true,
            onLifelinesUpdated: (updatedLifelines, updatedCredits) {
              setState(() {
                lifelines = updatedLifelines;
              });
            },
          ),
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
    final isMCMA =
        currentQuestion['type'] == "Multiple Choice - Multiple Answers";

    // final isCorrect = _selectedOption == currentQuestion['correctAnswer'];
    final questionTimeTaken =
        DateTime.now().difference(questionStartTime).inSeconds;

    bool isCorrect;
    if (isMCMA) {
      Set<String> correctAnswers =
          currentQuestion['correctAnswer'].split(", ").toSet();
      isCorrect = _selectedOptions.length == correctAnswers.length &&
          _selectedOptions.every((option) => correctAnswers.contains(option));
    } else {
      isCorrect = _selectedOption == currentQuestion['correctAnswer'];
    }

    // Add report object for the current question
    lessonReport.add({
      "questionId": currentQuestion["id"],
      "correct": isCorrect,
      "userAnswer": isMCMA ? _selectedOptions.join(", ") : _selectedOption,
      "timeTaken": questionTimeTaken,
    });

    setState(() {
      showQuestionStreak = true;
    });

    if (isCorrect) {
      _playSound('correct_answer.mp3', isCorrect);
      // _totalXp += xpPerQuestion;
      _correctStreak++;

      if (_correctStreak == 5 || _correctStreak == 10) {
        setState(() {
          _isCelebrationVisible = true;
        });
        _correctAudioPlayer.stop();
        _correctStreakPlayer.play(AssetSource('jumpSound.mp3'));

        Future.delayed(const Duration(milliseconds: 1500), () {
          setState(() {
            _isCelebrationVisible = false;
          });
          _nextQuestion();
        });
        return;
      }
    } else {
      _playSound('incorrect_answer.mp3', isCorrect);
      _totalXp -= xpPerQuestion;
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
      currentQuestion["userAnswer"] =
          isMCMA ? _selectedOptions.join(", ") : _selectedOption;
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
    // final totalQuestions = lessonQuestions['questions'].length;
    return (_totalXp / widget.maxXP) * 100;
  }

  void _nextQuestion() async {
    if (_currentQuestionIndex < lessonQuestions['questions'].length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _selectedOptions.clear();

        _isAnswerChecked = false;
        showQuestionStreak = false;
        questionStartTime = DateTime.now();
      });
    } else {
      final timeTaken = _calculateTimeTaken();
      final accuracy = _calculateAccuracy();
      // final Map<String, dynamic> lessonCompletionResponse =
      //     await markLessonCompletion(
      //         lessonId: widget.conceptId,
      //         attemptTime: _startTime.second,
      //         timeToComplete: DateTime.now().difference(_startTime).inSeconds,
      //         xpGained: _totalXp,
      //         accuracy: accuracy,
      //         bookId: bookId,
      //         report: lessonReport,
      //         correctlyAnswered: lessonQuestions['questions'].length -
      //             incorrectQuestions.length);
      if (incorrectQuestions.isEmpty) {
        Navigator.pop(context, {
          "completed": true,
          // "lessonCompletionResponse": lessonCompletionResponse,
          "attemptTime": _startTime.second,
          "totalXp": _totalXp,
          "timeTaken": timeTaken,
          "accuracy": accuracy,
          "totalQuestions": lessonQuestions['questions'].length,
          "timeToComplete": DateTime.now().difference(_startTime).inSeconds,
          "bookId": bookId,
          "report": lessonReport,
          "correctlyAnswered":
              lessonQuestions['questions'].length - incorrectQuestions.length
        });
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ConceptResultScreen(
        //       conceptName: widget.conceptName,
        //       totalXp: _totalXp,
        //       timeTaken: timeTaken,
        //       accuracy: accuracy,
        //       lessonCompletionResponse: lessonCompletionResponse,
        //     ),
        //   ),
        //   (route) => false,
        // );
      } else {
        Navigator.pop(context, {
          "completed": true,
          "incorrectQuestions": incorrectQuestions,
          // "lessonCompletionResponse": lessonCompletionResponse,
          "attemptTime": _startTime.second,

          "totalXp": _totalXp,
          "timeTaken": timeTaken,
          "accuracy": accuracy,
          "totalQuestions": lessonQuestions['questions'].length,
          "timeToComplete": DateTime.now().difference(_startTime).inSeconds,
          "bookId": bookId,
          "report": lessonReport,
          "correctlyAnswered":
              lessonQuestions['questions'].length - incorrectQuestions.length
        });

        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => MistakeCorrectionPopup(
        //       conceptName: widget.conceptName,
        //       conceptId: widget.conceptId,
        //       totalXp: _totalXp,
        //       timeTaken: timeTaken,
        //       accuracy: accuracy,
        //       incorrectQuestions: incorrectQuestions,
        //       lessonCompletionResponse: lessonCompletionResponse,
        //     ),
        //   ),
        //   (route) => false,
        // );
      }
    }
  }

  double getProgress() {
    return (_currentQuestionIndex + 1) / lessonQuestions['questions'].length;
  }

  void _showExitConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎯 Image at the top
              Container(
                height: 150,
                width: 150,
                child: Center(
                  child: Image.asset(
                    "lib/assets/lesson-quit.png",
                    height: 150,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // ⚠️ Warning Text
              Text(
                "Quit and you'll lose all XP gained in this lesson!",
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16),

              // ❌ Exit Button
              ChicletAnimatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                buttonType: ChicletButtonTypes.roundedRectangle,
                width: double.infinity,
                height: 50,
                buttonColor: Color.fromRGBO(187, 160, 2, 1),
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                child: Text(
                  "KEEP GOING",
                  style: GoogleFonts.raleway(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // 🔄 Cancel Button
              ChicletOutlinedAnimatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigator.pop(context);
                  // Navigator.pop(context);
                  Navigator.pop(context, {"completed": false});

                  // Navigator.pushAndRemoveUntil(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => MainPage()),
                  //   (route) => false,
                  // );
                },
                buttonType: ChicletButtonTypes.roundedRectangle,
                width: double.infinity,
                height: 50,
                borderColor: Colors.transparent,
                // buttonColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                child: Text(
                  "QUIT",
                  style: GoogleFonts.raleway(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateButtonHeight(String text, double maxWidth) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.raleway(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: maxWidth - 20); // Adjust padding for width

    int lineCount = textPainter.computeLineMetrics().length;
    return lineCount > 1 ? 70 : 50;
  }

  String sanitizeLatex(String input) {
    return input
        .replaceAll('ext', r'\text') // Tab + ext
        .replaceAll('imes', r'\times'); // Tab + imes
    // .replaceAll('ightarrow', r'\\rightarrow'); // Tab + imes
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _showExitConfirmation(context);
          return false; // Prevent immediate back navigation
        },
        child: Scaffold(
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
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                      ),
                                    ),
                                    // Filled Bar
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds:
                                              300), // Animation duration
                                      curve:
                                          Curves.easeInOut, // Animation curve
                                      width: availableWidth *
                                          getProgress(), // Dynamically adjust width
                                      height: 16.0,
                                      decoration: BoxDecoration(
                                        color:
                                            getProgressBarColor(getProgress()),
                                        borderRadius:
                                            BorderRadius.circular(16.0),
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
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('$_correctStreak in a row!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.raleway(
                                    color: Color.fromRGBO(255, 217, 0, 1),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  )),
                              SizedBox(
                                height: 20,
                              ),
                              Lottie.asset(
                                  "lib/assets/animations/catLiftingWeights.json",
                                  fit: BoxFit.cover,
                                  height: 250,
                                  width: 250),
                            ],
                          )),
                        )
                      else
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(255, 217, 0, 1),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 10),
                                      child: Text(
                                        lessonQuestions['questions']
                                                        [_currentQuestionIndex]
                                                    ['type'] ==
                                                "Multiple Choice - Multiple Answers"
                                            ? "MCA"
                                            : "MCQ",
                                        style: GoogleFonts.raleway(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                Color.fromRGBO(19, 31, 36, 1)),
                                      ))),
                              Padding(
                                  // padding: const EdgeInsets.symmetric(
                                  //     vertical: 16.0),
                                  padding: const EdgeInsets.only(
                                      bottom: 16.0, top: 8),
                                  child: MarkdownBody(
                                    selectable: false,
                                    data: sanitizeLatex(
                                        lessonQuestions['questions']
                                                [_currentQuestionIndex]
                                            ['question']),
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
                              ...lessonQuestions['questions']
                                      [_currentQuestionIndex]['options']
                                  .map<Widget>((option) {
                                final isMCMA = lessonQuestions['questions']
                                        [_currentQuestionIndex]['type'] ==
                                    "Multiple Choice - Multiple Answers";

                                final isSelected = isMCMA
                                    ? _selectedOptions.contains(option['id'])
                                    : _selectedOption == option['id'];

                                final isCorrect = lessonQuestions['questions']
                                        [_currentQuestionIndex]['correctAnswer']
                                    .split(", ")
                                    .contains(option['id']);
                                return LayoutBuilder(
                                    builder: (context, constraints) {
                                  double buttonHeight = _calculateButtonHeight(
                                      option['option'], constraints.maxWidth);
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ChicletOutlinedAnimatedButton(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          if (!_isAnswerChecked) {
                                            setState(() {
                                              if (isMCMA) {
                                                // Toggle selection for MCMA
                                                if (_selectedOptions
                                                    .contains(option['id'])) {
                                                  _selectedOptions
                                                      .remove(option['id']);
                                                } else {
                                                  _selectedOptions
                                                      .add(option['id']);
                                                }
                                              } else {
                                                // Standard MCQ behavior
                                                _selectedOption = option['id'];
                                              }
                                            });
                                          }
                                        },
                                        buttonType:
                                            ChicletButtonTypes.roundedRectangle,
                                        height: buttonHeight,
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
                                        child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: MarkdownBody(
                                              selectable: false,
                                              data: sanitizeLatex(
                                                  option['option']),
                                              builders: {
                                                'latex': LatexElementBuilder(
                                                  textStyle:
                                                      GoogleFonts.raleway(
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
                                            ))
                                        //  Text(
                                        //   option['option'],
                                        //   style: GoogleFonts.raleway(
                                        //     color: Colors.white,
                                        //     fontSize: 16,
                                        //   ),
                                        // ),
                                        ),
                                  );
                                });
                              }).toList(),

                              const Spacer(),

                              // Check/Next Button
                              ChicletAnimatedButton(
                                onPressed: (lessonQuestions['questions']
                                                        [_currentQuestionIndex]
                                                    ['type'] ==
                                                'Multiple Choice - Multiple Answers' &&
                                            _selectedOptions.isEmpty) ||
                                        (lessonQuestions['questions']
                                                        [_currentQuestionIndex]
                                                    ['type'] ==
                                                'MCQ' &&
                                            _selectedOption == null)
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
                                    : ((lessonQuestions['questions'][
                                                            _currentQuestionIndex]
                                                        ['type'] ==
                                                    'Multiple Choice - Multiple Answers' &&
                                                _selectedOptions.isNotEmpty) ||
                                            (lessonQuestions['questions'][
                                                            _currentQuestionIndex]
                                                        ['type'] ==
                                                    'MCQ' &&
                                                _selectedOption != null))
                                        ? Color.fromRGBO(187, 160, 2, 1)
                                        : Colors.grey,
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
        ));
  }
}
