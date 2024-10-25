import 'package:eureka_app/apis/fetchChapterQuestionsApi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class EndQuestionScreen extends StatefulWidget {
  const EndQuestionScreen({Key? key}) : super(key: key);

  @override
  _EndQuestionScreenState createState() => _EndQuestionScreenState();
}

class _EndQuestionScreenState extends State<EndQuestionScreen> {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  bool _isLoading = false;

  String? _audioPath;
  List<double> waveformData = []; // Data for the waveform visualization
  Map<String, dynamic>? chapterQuestions;
  int currentQuestionIndex = 0;
  int currentSubQuestionIndex = 0;

  // Mock question data
  final List<Map<String, dynamic>> mockQuestions = [
    {
      "question": "Explain how fertilsers are different from manure.",
      "question_type": "subjective",
      "answer":
          "Manure is an organic substance obtained from the decomposition of plant or animal wastes but fertilsers are inorganic substance prepared in factories. Fertilsers are rich in nutrients but manure has relatively less nutrients. Manure do not harm the soil if used in greater quantity but fertilsers may harm the plants as well as soil. Manure is cheap and mostly prepared by farmers itself on the other hand fertilsers are costly and prepared in factories using chemicals."
    }
  ];

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initializeRecorder();
    _loadChapterQuestions();
  }

  Future<void> _loadChapterQuestions() async {
    // Replace these parameters with actual values if needed
    int standard = 8;
    int chapterNo = 1;
    String subject = 'Science';

    // Fetch chapter questions
    final data = await fetchChapterQuestions(
        standard: standard, chapterNo: chapterNo, subject: subject);

    if (data != null) {
      setState(() {
        chapterQuestions = data;
      });
    } else {
      print('Failed to load chapter questions.');
    }
  }

  Future<void> _initializeRecorder() async {
    // Request microphone permission
    await Permission.microphone.request();

    // Initialize the audio recorder
    await _audioRecorder!.openRecorder();
    _audioRecorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
    _audioRecorder!.onProgress!.listen((event) {
      if (_isRecording) {
        setState(() {
          // Update waveform data with real-time decibel values during recording
          double decibels = (event.decibels ?? 0) + 100; // Mock waveform data
          waveformData.add(decibels);

          // Keep waveformData length manageable for smoother visualization
          if (waveformData.length > 50) {
            waveformData.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await _audioRecorder!.stopRecorder();

      // Ensure the audio file is saved at the specified path
      setState(() {
        _isRecording = false;
        waveformData.clear(); // Clear the waveform after stopping
      });

      if (_audioPath != null && _audioPath!.isNotEmpty) {
        print('Audio path: $_audioPath'); // Debug line to check audio path
        _sendAudioToBackend(File(_audioPath!));
      } else {
        print('Audio path is null or empty');
      }
    } else {
      // Set the path where the audio file will be saved
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/audio_record.wav';

      // Start recording
      await _audioRecorder!.startRecorder(
        toFile: _audioPath, // Use the absolute file path
        codec: Codec.pcm16WAV, // Use WAV codec
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

      // Add the audio file, question, and answer as form data
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
      print(questionText);
      print(answer);
      request.files
          .add(await http.MultipartFile.fromPath('audio', audioFile.path));
      request.fields['questionText'] = questionText;
      request.fields['answer'] = answer;

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> responseJson = json.decode(responseData);

        // Get the evaluation result and audio message from the response
        final evaluationResult =
            responseJson['evaluationResponse']['evaluationResult'];
        final evaluationMessage = responseJson['evaluationResponse']['message'];
        final audioBase64 = responseJson['evaluationResponse']['audioMessage'];

        // Decode base64 audio and play it
        if (audioBase64 != null) {
          _playBase64Audio(audioBase64);
        }

        // You can show the evaluation result and message to the user
        print('Evaluation Result: $evaluationResult');
        print('Evaluation Message: $evaluationMessage');
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
      // Decode the base64 string to binary data
      final audioBytes = base64Decode(base64Audio);

      // Get the temporary directory to save the audio file
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/response_audio.wav');

      // Write the binary data to a file
      await audioFile.writeAsBytes(audioBytes);

      // Initialize FlutterSoundPlayer
      final player = FlutterSoundPlayer();
      await player.openPlayer(); // Open the player session

      // Subscribe to player events to handle when the audio finishes
      player.setSubscriptionDuration(
          Duration(milliseconds: 500)); // Adjust as needed
      player.onProgress!.listen((event) {
        if (event.position == event.duration) {
          // Playback is complete
          player.stopPlayer();
          player.closePlayer();
        }
      });

      // Play the saved audio file
      await player.startPlayer(fromURI: audioFile.path);
    } catch (e) {
      print('Error playing base64 audio: $e');
    }
  }

  void _goToNext() {
    if (chapterQuestions != null && chapterQuestions!['questions'] != null) {
      final questions = chapterQuestions!['questions'];

      // Ensure there is a current question
      if (questions.isNotEmpty) {
        final currentQuestion = questions[currentQuestionIndex];

        // Check if the current question has subQuestions
        if (currentQuestion['subQuestions'] != null &&
            currentQuestion['subQuestions'].isNotEmpty) {
          // If more subquestions are available, go to the next subquestion
          if (currentSubQuestionIndex <
              currentQuestion['subQuestions'].length - 1) {
            setState(() {
              currentSubQuestionIndex++;
            });
          } else {
            // If no more subquestions, move to the next question
            setState(() {
              currentSubQuestionIndex = 0;
              currentQuestionIndex++;
            });
          }
        } else {
          // If there are no subquestions, move to the next question
          setState(() {
            currentSubQuestionIndex = 0;
            currentQuestionIndex++;
          });
        }

        // Reset if we go beyond the last question
        if (currentQuestionIndex >= questions.length) {
          setState(() {
            currentQuestionIndex = 0;
            currentSubQuestionIndex = 0;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String mainQuestionText = "Loading question...";
    String subQuestionText = "";

    // Check if the questions are loaded and set the question text
    if (chapterQuestions != null && chapterQuestions!['questions'] != null) {
      final questions = chapterQuestions!['questions'];

      // Ensure there is a question to display
      if (questions.isNotEmpty && currentQuestionIndex < questions.length) {
        final currentQuestion = questions[currentQuestionIndex];

        // Set the main question text
        mainQuestionText = currentQuestion["question"];

        // Check if the current question has subQuestions and set the subQuestion text
        if (currentQuestion['subQuestions'] != null &&
            currentQuestion['subQuestions'].isNotEmpty &&
            currentSubQuestionIndex < currentQuestion['subQuestions'].length) {
          subQuestionText = currentQuestion['subQuestions']
              [currentSubQuestionIndex]['question'];
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        title: Text(
          'End Question Screen',
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${currentQuestionIndex + 1}. $mainQuestionText',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              // textAlign: TextAlign.center,
            ),

            // SubQuestion Text (if available)
            if (subQuestionText.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '${String.fromCharCode(97 + currentSubQuestionIndex)}) $subQuestionText',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
            ],
            const SizedBox(height: 40),

            // Waveform Visualization
            if (_isRecording && waveformData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: PolygonWaveform(
                  maxDuration: Duration(minutes: 1), // Set max duration
                  elapsedDuration: Duration(seconds: 10), // Example duration
                  samples: waveformData,
                  height: 150,
                  width: MediaQuery.of(context).size.width,
                  inactiveColor: Colors.grey[300]!,
                  activeColor: Colors.blueAccent,
                ),
              ),

            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                ),
              ),

            const Spacer(),
            ElevatedButton(
              onPressed: _goToNext,
              child: const Text('Next'),
            ),

            const SizedBox(height: 20),

            // Microphone Button
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
                          colors: [Colors.blueAccent, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _isRecording ? Colors.redAccent : Colors.blueAccent,
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _isRecording
                  ? 'Recording... Tap to stop'
                  : 'Tap the microphone to start recording',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
