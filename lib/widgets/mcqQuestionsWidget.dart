import 'package:audioplayers/audioplayers.dart';
import 'package:eureka_app/widgets/conceptResultScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';

class MCQQuestions extends StatefulWidget {
  const MCQQuestions({Key? key}) : super(key: key);

  @override
  State<MCQQuestions> createState() => _MCQQuestionsState();
}

class _MCQQuestionsState extends State<MCQQuestions> {
  // Mock Data
  final Map<String, dynamic> concept = {
    "id": "concept_1",
    "name": "First Concept",
    "questions": [
      {
        "id": "flashcard-1",
        "question": "What are Autotrophs?",
        "options": [
          {
            "id": "option_1",
            "option": "Organisms that feed on other organisms"
          },
          {"id": "option_2", "option": "Organisms that make their own food"},
          {"id": "option_3", "option": "Organisms that live on water only"},
          {"id": "option_4", "option": "Organisms that rely on symbiosis"}
        ],
        "correctAnswer": "option_2"
      },
      {
        "id": "flashcard-2",
        "question": "What is the main source of energy for autotrophs?",
        "options": [
          {"id": "option_1", "option": "Chemical reactions"},
          {"id": "option_2", "option": "Sunlight"},
          {"id": "option_3", "option": "Water currents"},
          {"id": "option_4", "option": "Wind"}
        ],
        "correctAnswer": "option_2"
      },
      {
        "id": "flashcard-3",
        "question": "Which organisms are autotrophs?",
        "options": [
          {"id": "option_1", "option": "Dogs"},
          {"id": "option_2", "option": "Fungi"},
          {"id": "option_3", "option": "Green plants"},
          {"id": "option_4", "option": "Humans"}
        ],
        "correctAnswer": "option_3"
      }
    ]
  };

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
    _startTime = DateTime.now();
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
    final currentQuestion = concept['questions'][_currentQuestionIndex];
    final isCorrect = _selectedOption == currentQuestion['correctAnswer'];

    if (isCorrect) {
      _playSound('correct_answer.mp3', isCorrect);
      _totalXp += 5;
    } else {
      _playSound('incorrect_answer.mp3', isCorrect);
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
    final totalQuestions = concept['questions'].length;
    return (_totalXp / (totalQuestions * 5)) * 100;
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < concept['questions'].length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswerChecked = false;
      });
    } else {
      final timeTaken = _calculateTimeTaken();
      final accuracy = _calculateAccuracy();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConceptResultScreen(
            conceptName: 'Autotrophs',
            totalXp: _totalXp,
            timeTaken: timeTaken,
            accuracy: accuracy,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = concept['questions'][_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / concept['questions'].length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          concept['name'],
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Stack(
                children: [
                  // Background Bar
                  Container(
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  // Filled Bar
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: getProgressBarColor(progress),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
            ),
            // Question Text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                currentQuestion['question'],
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Options
            ...currentQuestion['options'].map<Widget>((option) {
              final isSelected = _selectedOption == option['id'];
              final isCorrect =
                  option['id'] == currentQuestion['correctAnswer'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isAnswerChecked
                          ? (isCorrect
                              ? Color.fromRGBO(187, 160, 2, 1)
                              : (isSelected ? Colors.red : Colors.grey))
                          : (isSelected ? Colors.blue : Colors.grey),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ChicletAnimatedButton(
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
                    buttonColor: _isAnswerChecked
                        ? (isCorrect
                            ? Color.fromRGBO(187, 160, 2, 1)
                            : (isSelected ? Colors.red : Colors.grey))
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

            const SizedBox(height: 16),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
