import 'package:eureka_app/apis/fetchChapterQuestionsApi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:audio_session/audio_session.dart' as audioSession;
import 'package:http_parser/http_parser.dart';

class EndQuestionScreen extends StatefulWidget {
  final String chapterId;
  final List<dynamic>? sectionEndQuestions;

  const EndQuestionScreen(
      {Key? key, required this.chapterId, this.sectionEndQuestions})
      : super(key: key);

  @override
  _EndQuestionScreenState createState() => _EndQuestionScreenState();
}

class _EndQuestionScreenState extends State<EndQuestionScreen>
    with SingleTickerProviderStateMixin {
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  bool _isRecording = false;
  bool _showFeedback = false;
  bool _isLoading = false;
  bool _questionAnswered = false;

  String? _audioPath;
  List<double> waveformData = []; // Data for the waveform visualization
  Map<String, dynamic>? chapterQuestions;
  int currentQuestionIndex = 0;
  int currentSubQuestionIndex = 0;

  String feedbackText = "";
  String audioFeedbackPath = "";

  late PageController _pageController;

  // Animation controller for the flipping effect
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  final List<LinearGradient> gradients = [
    LinearGradient(
      colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.deepPurple[900]!, Colors.deepPurple[700]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.teal[900]!, Colors.teal[700]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // LinearGradient(
    //   colors: [Colors.orange[900]!, Colors.orange[700]!],
    //   begin: Alignment.topLeft,
    //   end: Alignment.bottomRight,
    // ),
    LinearGradient(
      colors: [Colors.brown[900]!, Colors.brown[700]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.indigo[900]!, Colors.indigo[700]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  late LinearGradient selectedGradient;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initializeRecorder();
    _loadChapterQuestions();
    _initializeAudioSession();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _chooseNewGradient();
  }

  void _chooseNewGradient() {
    final random = Random();
    selectedGradient = gradients[random.nextInt(gradients.length)];
  }

  Future<void> _loadChapterQuestions() async {
    if (widget.sectionEndQuestions != null &&
        widget.sectionEndQuestions!.isNotEmpty) {
      setState(() {
        chapterQuestions = {
          'questions': widget.sectionEndQuestions,
        };
      });
    } else {
      // Fallback to fetch from API if `sectionEndQuestions` is not provided
      final data = await fetchChapterQuestions(chapterId: widget.chapterId);
      if (data != null) {
        setState(() {
          chapterQuestions = data;
        });
      } else {
        print('Failed to load chapter questions.');
      }
    }
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await _audioRecorder!.openRecorder();
    _audioRecorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
    _audioRecorder!.onProgress!.listen((event) {
      if (_isRecording) {
        setState(() {
          double decibels = (event.decibels ?? 0) + 100;
          waveformData.add(decibels);
          if (waveformData.length > 50) {
            waveformData.removeAt(0);
          }
        });
      }
    });
  }

  Future<void> _initializeAudioSession() async {
    final session = await audioSession.AudioSession.instance;
    await session.configure(audioSession.AudioSessionConfiguration(
      avAudioSessionCategory: audioSession.AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          audioSession.AVAudioSessionCategoryOptions.allowBluetooth |
              audioSession.AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: audioSession.AVAudioSessionMode.spokenAudio,
    ));
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder();
    _audioPlayer!.closePlayer();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isLoading) {
      return;
    }
    if (_isRecording) {
      await _audioRecorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        waveformData.clear();
      });

      if (_audioPath != null && _audioPath!.isNotEmpty) {
        print('Audio path: $_audioPath');
        _sendAudioToBackend(File(_audioPath!));
      } else {
        print('Audio path is null or empty');
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/audio_record.wav';

      await _audioRecorder!.startRecorder(
        toFile: _audioPath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        _isRecording = true;
      });

      print('Recording started. File will be saved to: $_audioPath');
    }
  }

  Future<void> _sendAudioToBackend(File audioFile) async {
    setState(() {
      _isLoading = true; // Show loader when sending audio
    });
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://glutaclass.com:8080/gluta/fam/evaluate-oral-answers'),
      );

      final currentQuestion =
          chapterQuestions!['questions'][currentQuestionIndex];
      String questionText = currentQuestion['question'];
      String answer = currentQuestion['answer'] ?? '';

      if (currentQuestion['subQuestions'] != null &&
          currentQuestion['subQuestions'].isNotEmpty &&
          currentSubQuestionIndex < currentQuestion['subQuestions'].length) {
        questionText = questionText +
            currentQuestion['subQuestions'][currentSubQuestionIndex]
                ['question'];
        answer =
            currentQuestion['subQuestions'][currentSubQuestionIndex]['answer'];
      }
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
      ));
      request.fields['chapterQuestionsId'] = chapterQuestions!["id"];
      request.fields['questionNumber'] = currentQuestionIndex.toString();
      request.fields['subQuestionNumber'] = currentSubQuestionIndex.toString();

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> responseJson = json.decode(responseData);

        final evaluationMessage = responseJson['evaluationResponse']['message'];
        final audioBase64 = responseJson['evaluationResponse']['audioMessage'];

        setState(() {
          feedbackText = evaluationMessage;
          _showFeedback = true;
          _questionAnswered = true;
        });

        // Flip the card when showing feedback
        _controller.forward();

        if (audioBase64 != null) {
          _playBase64Audio(audioBase64);
        }
      } else {
        print('Failed to upload audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while sending audio: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loader after the backend response
      });
    }
  }

  Future<void> _playBase64Audio(String base64Audio) async {
    try {
      final audioBytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/response_audio.wav');
      await audioFile.writeAsBytes(audioBytes);
      audioFeedbackPath = audioFile.path;

      await _audioPlayer!.openPlayer();
      await _audioPlayer!.startPlayer(fromURI: audioFile.path);
    } catch (e) {
      print('Error playing base64 audio: $e');
    }
  }

  void _goToNext() async {
    if (_audioPlayer!.isPlaying) {
      await _audioPlayer!.pausePlayer();
    }

    final isFront = _controller.value <= 0.5;

    // If the card is showing the back (feedback), flip it to the front before moving to the next question
    if (!isFront) {
      await _controller.reverse();
    }
    setState(() {
      _showFeedback = false;
      _chooseNewGradient();
    });

    if (chapterQuestions != null && chapterQuestions!['questions'] != null) {
      final questions = chapterQuestions!['questions'];
      if (questions.isNotEmpty) {
        final currentQuestion = questions[currentQuestionIndex];

        if (currentQuestion['subQuestions'] != null &&
            currentQuestion['subQuestions'].isNotEmpty) {
          if (currentSubQuestionIndex <
              currentQuestion['subQuestions'].length - 1) {
            setState(() {
              currentSubQuestionIndex++;
            });
          } else {
            setState(() {
              currentSubQuestionIndex = 0;
              currentQuestionIndex++;
            });
          }
        } else {
          setState(() {
            currentSubQuestionIndex = 0;
            currentQuestionIndex++;
          });
        }

        if (currentQuestionIndex >= questions.length) {
          setState(() {
            currentQuestionIndex = 0;
            currentSubQuestionIndex = 0;
          });
        }
      }
    }
  }

  void _goToPrevious() async {
    // Determine if the card is currently showing the front or back
    if (_audioPlayer!.isPlaying) {
      await _audioPlayer!.pausePlayer();
    }
    final isFront = _controller.value <= 0.5;

    // If the card is showing the back (feedback), flip it to the front before moving to the previous question
    if (!isFront) {
      await _controller.reverse();
    }

    setState(() {
      _showFeedback = false; // Reset feedback state for the previous question
    });

    if (chapterQuestions != null && chapterQuestions!['questions'] != null) {
      final questions = chapterQuestions!['questions'];
      if (questions.isNotEmpty) {
        // If there are subQuestions, navigate within them
        final currentQuestion = questions[currentQuestionIndex];

        if (currentQuestion['subQuestions'] != null &&
            currentQuestion['subQuestions'].isNotEmpty) {
          if (currentSubQuestionIndex > 0) {
            // Go to the previous subQuestion
            setState(() {
              currentSubQuestionIndex--;
              _chooseNewGradient();
            });
          } else if (currentQuestionIndex > 0) {
            // Go to the last subQuestion of the previous question if it exists
            setState(() {
              currentQuestionIndex--;
              _chooseNewGradient();

              currentSubQuestionIndex =
                  questions[currentQuestionIndex]['subQuestions']?.length ?? 0;
              if (currentSubQuestionIndex > 0) {
                currentSubQuestionIndex--; // Adjust to the last valid subQuestion
              }
            });
          }
        } else if (currentQuestionIndex > 0) {
          // If there are no subQuestions, go to the previous question
          setState(() {
            currentQuestionIndex--;
            currentSubQuestionIndex = 0;
          });
        }

        // Wrap to the last question if we go below 0
        if (currentQuestionIndex < 0) {
          setState(() {
            currentQuestionIndex = questions.length - 1;
            currentSubQuestionIndex =
                questions[currentQuestionIndex]['subQuestions']?.length ?? 0;
            if (currentSubQuestionIndex > 0) {
              currentSubQuestionIndex--;
            }
          });
        }
      }
    }
  }

  void _flipCard() {
    if (_showFeedback) {
      setState(() {
        if (_controller.isCompleted) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      });
    }
  }

  Widget build(BuildContext context) {
    String mainQuestionText = "";
    String subQuestionText = "";
    Map<String, dynamic>? currentSubQuestion;

    if (chapterQuestions != null && chapterQuestions!['questions'] != null) {
      final questions = chapterQuestions!['questions'];
      if (questions.isNotEmpty && currentQuestionIndex < questions.length) {
        final currentQuestion = questions[currentQuestionIndex];
        mainQuestionText = currentQuestion["question"];

        if (currentQuestion['subQuestions'] != null &&
            currentQuestion['subQuestions'].isNotEmpty &&
            currentSubQuestionIndex < currentQuestion['subQuestions'].length) {
          currentSubQuestion =
              currentQuestion['subQuestions'][currentSubQuestionIndex];
          subQuestionText = currentSubQuestion?['question'];
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        centerTitle: false,
        title: const Text(
          'Book Q&A',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          // Swipe right
                          if (details.primaryVelocity! > 0) {
                            _goToPrevious();
                          }
                          // Swipe left
                          else if (details.primaryVelocity! < 0) {
                            _goToNext();
                          }
                        }
                      },
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * pi;
                          final isFront = angle <= pi / 2;

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(angle),
                            child: isFront
                                ? _buildQuestionCard(
                                    mainQuestionText,
                                    subQuestionText,
                                    constraints.maxWidth,
                                    constraints.maxHeight - 150,
                                    currentSubQuestion)
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(pi),
                                    child: _buildFeedbackCard(
                                        constraints.maxWidth,
                                        constraints.maxHeight - 150),
                                  ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(bottom: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[850],
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 20,
                                ),
                                alignment: Alignment
                                    .centerLeft, // Align text to the left

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Color.fromRGBO(255, 217, 0, 1),
                              ),
                              label: Text(
                                'Previous',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _goToPrevious,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                          ),
                          Expanded(
                              child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[850],
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              alignment: Alignment
                                  .centerRight, // Align text to the left

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _goToNext,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        8), // Add some space between text and icon
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color.fromRGBO(255, 217, 0, 1),
                                ),
                              ],
                            ),
                          ))
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String mainQuestionText, String subQuestionText,
      double width, double height, Map<String, dynamic>? subQuestion) {
    return Container(
      width: width, // Use the full width available
      height: height, // Use the full height available
      decoration: BoxDecoration(
        gradient: selectedGradient, // Apply the selected gradient
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Question Number at the top
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                'Question ${currentQuestionIndex + 1}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20), // Spacing after question number

            // Center-aligned content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mainQuestionText,
                    style: TextStyle(
                      fontSize: subQuestionText.isNotEmpty ? 20 : 24,
                      fontWeight: subQuestionText.isNotEmpty
                          ? FontWeight.normal
                          : FontWeight.w500,
                      color: subQuestionText.isNotEmpty
                          ? Colors.white70
                          : Colors.white,
                    ),
                    textAlign:
                        TextAlign.center, // Center-align the main question text
                  ),
                  if (subQuestionText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      '${String.fromCharCode(97 + currentSubQuestionIndex)}) $subQuestionText',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign:
                          TextAlign.center, // Center-align the subquestion text
                    ),
                  ],
                  if (subQuestion != null &&
                      subQuestion.containsKey('options')) ...[
                    const SizedBox(height: 20),
                    _buildOptions(subQuestion['options'])
                  ],
                  // const SizedBox(
                  //   height: 100,
                  // ),
                  Spacer(
                    flex: 1,
                  ),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isRecording
                            ? LinearGradient(
                                colors: [Colors.redAccent, Colors.red],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Color.fromRGBO(255, 217, 0, 1),
                                  Color.fromRGBO(255, 217, 0, 1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: _isRecording
                                ? Colors.redAccent
                                : Color.fromRGBO(255, 217, 0, 1),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 50, // Set the desired width
                              height: 50, // Set the desired height
                              child: Center(
                                child: Transform.scale(
                                  scale:
                                      1, // Adjust this scale to make it bigger or smaller
                                  child: CircularProgressIndicator(
                                    color: Colors
                                        .white, // Adjust the color to your preference
                                    strokeWidth:
                                        4.0, // Adjust the thickness of the progress indicator
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              _isRecording ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 50,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLoading
                        ? 'AI Tutor is validating your answer... Please wait'
                        : (_isRecording
                            ? 'Recording... Tap to submit answer'
                            : 'Tap to answer'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign
                        .center, // Center-align the microphone hint text
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(Map<String, dynamic> options) {
    return Column(
      children: options.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '${entry.key}) ${entry.value}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            textAlign: TextAlign.left,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackCard(double width, double height) {
    return Container(
      width: width, // Use the full width available
      height: height, // Use the full height available
      decoration: BoxDecoration(
        gradient: selectedGradient, // Apply the selected gradient
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Feedback',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                      0.3), // Optional background color for better readability
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Text(
                    feedbackText,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (audioFeedbackPath.isNotEmpty) {
                  await _audioPlayer!.startPlayer(fromURI: audioFeedbackPath);
                }
              },
              child: const Text('Replay Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
