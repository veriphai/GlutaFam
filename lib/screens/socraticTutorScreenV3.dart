import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:eureka_app/apis/checkConceptCheckpointCompleted.dart';
import 'package:eureka_app/services/webSocketService.dart';
import 'package:eureka_app/utils/socraticTutorHelper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SocraticTutorScreenV3 extends StatefulWidget {
  @override
  _SocraticTutorScreenState createState() => _SocraticTutorScreenState();
}

class _SocraticTutorScreenState extends State<SocraticTutorScreenV3> {
  late WebSocketService webSocketService;
  String conversationText = "";
  bool isRecording = false;
  FlutterSoundRecorder? _recorder;
  String? _audioPath;
  late FlutterSoundPlayer player;
  Queue<String> audioQueue = Queue<String>();
  bool isPlaying = false;
  String? fetchedImageUrl;
  bool originalConversation = true;
  bool _isPlayerReady = false;
  int currentCheckpointIndex = 0;
  List<Map<String, String>> conversations = [];

  // String conceptName = "How Nutrients are Replenished in the Soil";
  // String conceptText =
  //     "Why Manure and Fertilisers are Used\nFarmers and gardeners spread manure and fertilisers in fields, lawns, or pots to enrich the soil with nutrients. Nutrients like nitrogen, potassium, and phosphorus are needed to keep plants healthy.\n\nSoil Nutrient Depletion\nPlants absorb minerals and nutrients from the soil. Over time, these nutrients decline and need to be replenished by adding fertilisers and manure.\n\nNitrogen Absorption by Plants\nPrerequisite: Nitrogen Gas – a gas present in the air, essential for plant growth.\nPlants need nitrogen in a soluble form because they cannot absorb it directly from the air.\n\nRole of Rhizobium Bacteria\nPrerequisite: Rhizobium – a type of bacteria that can convert atmospheric nitrogen into a form that plants can use.\nRhizobium lives in the roots of leguminous plants (like gram, peas, moong, and beans). The bacteria convert nitrogen from the air into a usable form for plants.\n\nSymbiotic Relationship\nPrerequisite: Symbiotic Relationship – a close association where both organisms benefit.\nRhizobium provides nitrogen to leguminous plants. In return, the plants provide food and shelter to the bacteria.\n\nImportance for Farmers\nFarmers can use fewer nitrogen fertilisers when growing leguminous crops because these plants get nitrogen from Rhizobium.\n\nLeguminous Plants and Pulses\nMost pulses (dals) like beans, peas, and gram come from leguminous plants.";

  String conceptName =
      "Limits: Illustrative Examples and Practical Examples and Tables";

  List<Map<String, dynamic>> conceptCheckpoints = [
    {
      "title": "Checkpoint 1: Understanding Basic Functions",
      "learningObjective":
          "Understand basic functions like quadratic functions and absolute value functions before approaching limits.",
      "blackboard_text":
          "\\[ f(x) = x^2 \\]  \n\\[ g(x) = |x| \\]  \n\n\\[ f(2) = 4, f(-2) = 4 \\]  \n\\[ g(3) = 3, g(-3) = 3 \\]",
      "theory":
          "Before learning about limits, it's essential to understand functions. A function takes an input (x) and produces an output (f(x)). Two important functions are:\n\n- Quadratic Function: f(x) = x². This function squares the input value.\n- Absolute Value Function: g(x) = |x|. This function gives the non-negative value of x.\n\nObserving how these functions behave for positive and negative inputs helps us analyze their limits later.",
      "guidingQuestions": [
        "If I take a number and square it, what happens to its value?",
        "Does squaring a negative number give a negative result?",
        "How does the absolute value function behave for positive and negative numbers?",
        "Can an absolute value ever be negative?"
      ]
    },
    {
      "title": "Checkpoint 2: Introduction to Limits",
      "learningObjective":
          "Understand what a limit is and why it is important in calculus.",
      "blackboard_text":
          "\\[ \\lim_{x \\to 0} f(x) = ? \\]  \n\\[ \\lim_{x \\to 2} f(x) = ? \\]  \n\nExample: \\[ f(x) = x^2 \\]  \n- What happens when \\[ x \\to 0 \\]?",
      "theory":
          "A limit describes how a function behaves as its input approaches a certain value. It tells us the value that f(x) is getting closer to, even if x never actually reaches that value.",
      "guidingQuestions": [
        "What happens to f(x) = x² as x gets closer to 0?",
        "If x gets smaller and smaller, does f(x) also get smaller?",
        "Does f(x) ever actually become negative?"
      ]
    },
    {
      "title": "Checkpoint 3: Practical Exploration Using Tables",
      "learningObjective":
          "Analyze function behavior numerically by observing function values in a table.",
      "blackboard_text":
          "| \\[ x \\]  | \\[ f(x) = x^2 \\]  |\n|------|-----------|\n| 0.1  | 0.01      |\n| 0.01 | 0.0001    |\n| 0.001| 0.000001  |\n\nWhat do we observe?",
      "theory":
          "By creating tables of values, we can see patterns in how functions behave as x approaches a number.",
      "guidingQuestions": [
        "What happens to f(x) as x moves closer to 0?",
        "Are the values of f(x) the same whether x is positive or negative?",
        "Can we predict the limit from this pattern?"
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    player = FlutterSoundPlayer();
    webSocketService = WebSocketService();
    // webSocketService.onMessageReceived = onMessageReceived;
    webSocketService.connect();
    _recorder = FlutterSoundRecorder();

    _initializeRecorder();
    _initPlayer();
    startConversation("Introduce the Socratic Tutor concept");
  }

  Future<void> _initPlayer() async {
    await player.openPlayer();

    // Start streaming PCM data
    await player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 24000,
      whenFinished: () {
        debugPrint('Audio stream finished.');
      },
    );

    setState(() {
      _isPlayerReady = true;
    });
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    _recorder?.closeRecorder();
    if (player.isPlaying) {
      player.stopPlayer();
    }
    player.closePlayer();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await _recorder!.openRecorder();
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
  }

  Future<void> onMessageReceived(String message) async {
    final data = jsonDecode(message);
    print("respones received");
    if (data['type'] == 'response.audio_transcript.delta') {
      String deltaText = data['delta'] ?? "";

      setState(() {
        conversationText += deltaText;
      });
    } else if (data['type'] == 'response.audio.delta') {
      // Append conversation text
      String deltaText = data['delta'] ?? "";
      String base64Audio = data['delta'] ?? "";
      if (base64Audio.isNotEmpty && _isPlayerReady) {
        Uint8List rawData = base64Decode(base64Audio);
        // Send the chunk into the audio stream
        player.foodSink?.add(FoodData(rawData));
      }
    } else if (data['type'] == 'response.done') {
      print("Conversation complete");
      setState(() {
        conversationText += "\n";
      });
      if (data['response']['output'].length > 0) {
        conversations.add({
          "text": data['response']['output'][0]['content'][0]["transcript"],
          "role": "assistant"
        });
      }
      checkConceptCompleted();
    }
  }

  void checkConceptCompleted() async {
    // final result = {'checkpointCompleted': true};

    final result = await checkConceptCheckpointCompleted(
        conversations: conversations,
        conceptName: conceptName,
        greeting: false,
        conceptCheckpoint: conceptCheckpoints[currentCheckpointIndex]);
    bool conceptCompleted = result['checkpointCompleted'] ?? false;

    if (conceptCompleted) {
      currentCheckpointIndex += 1;
      final nextCheckpointStartMessage = {
        "type": "conversation.item.create",
        "item": {
          "type": "message",
          "role": "user",
          "content": [
            {
              "type": "input_text",
              "text":
                  "Concept to teach: $conceptName. Moving to next checkpoint of the concept. Checkpoint ${currentCheckpointIndex + 1}: ${conceptCheckpoints[currentCheckpointIndex]} "
            }
          ]
        }
      };

      webSocketService.sendMessage(nextCheckpointStartMessage);

      final responseRequest = {
        "type": "response.create",
        "response": {
          "modalities": ["text", "audio"]
        }
      };
      webSocketService.sendMessage(responseRequest);
    }
  }

  void startConversation(String concept) {
    final startMessage = {
      "event_id": "event_123",
      "type": "session.update",
      "session": {
        "instructions":
            // "You are a teacher guiding a student to deeply understand a concept. Begin with a warm greeting and a very small introduction to what we are studying, just the topic. Never end your conversation with a question or you will die. Keep the intro very short and crisp, and dont explain anything at all. Keep all our conversation short so that the discussion can be mnore engaging."
            "You are a Socratic teacher guiding a student to understand a concept. Each concept is broken down into multiple checkpoints, and we would be doing each checkpoint one by one. \n Instead of giving direct answers, ask a series of insightful questions to encourage critical thinking and self-discovery. As you proceed, use known analogies or \n real-world examples to help the student relate to the concept better. \n Keep in mind while ending the checkpoint: Never end your conversation with a question \n            Your goal is to foster curiosity and ensure the student deeply understands the concept. \n            If the student provides an incorrect or incomplete answer, gently ask further questions \n to guide them toward the correct understanding. Keep in mind to ask one question at a time.\n\n Start the Dialogue:\n\n 1.Begin with a simple question to gauge the student's current understanding.\n 2.Follow up with more specific, thought-provoking questions. Ask one question at a time and let the student answer.\n 3.Use analogies or real-world examples when needed to clarify or deepen understanding.\n 4.Allow the conversation to flow naturally, maintaining a supportive and encouraging tone.\n 5.Conclude by summarizing the key points to ensure the student grasps the concept, and never end your conversation with a question.\n\n I will give you the concept and its associated context you need to teach, then you need to start your conversation in a socratic manner.",
      }
    };

    webSocketService.sendMessage(startMessage);

    final conversationStartMessage = {
      "type": "conversation.item.create",
      "item": {
        "type": "message",
        "role": "user",
        "content": [
          {
            "type": "input_text",
            "text":
                "Concept to teach: $conceptName. Checkpoint 1: ${conceptCheckpoints[0]} "
          }
        ]
      }
    };

    webSocketService.sendMessage(conversationStartMessage);

    final responseRequest = {
      "type": "response.create",
      "response": {
        "modalities": ["text", "audio"]
      }
    };
    webSocketService.sendMessage(responseRequest);
  }

  Future<void> _toggleRecording() async {
    if (isRecording) {
      await _recorder!.stopRecorder();
      setState(() {
        isRecording = false;
      });

      if (_audioPath != null && _audioPath!.isNotEmpty) {
        print('Audio path: $_audioPath');
        final fileData = await File(_audioPath!).readAsBytes();
        final base64Audio = base64Encode(fileData);
        sendAudioResponse(base64Audio);
      } else {
        print('Audio path is null or empty');
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/audio_record.wav';
      await _recorder!.startRecorder(
          toFile: _audioPath, codec: Codec.pcm16WAV, sampleRate: 24000);

      setState(() {
        isRecording = true;
      });

      print('Recording started. File will be saved to: $_audioPath');
    }
  }

  void sendAudioResponse(String base64Audio) {
    setState(() {
      originalConversation = true;
    });
    final audioMessage = {
      "type": "conversation.item.create",
      "item": {
        "type": "message",
        "role": "user",
        "content": [
          {
            "type": "input_audio",
            "audio": base64Audio,
          }
        ]
      }
    };

    webSocketService.sendMessage(audioMessage);
    final responseRequest = {
      "type": "response.create",
      "response": {
        "modalities": ["text", "audio"]
      }
    };
    webSocketService.sendMessage(responseRequest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Socratic Tutor")),
      body: Column(
        children: [
          // Always visible image panel
          if (fetchedImageUrl != null)
            Image.network(
              fetchedImageUrl!,
              height: 200,
              width: double.infinity, // Use full width of the screen
              fit: BoxFit.cover,
            ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversationText,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(isRecording ? Icons.stop : Icons.mic),
                      label: Text(
                          isRecording ? "Stop Recording" : "Record Response"),
                      onPressed: _toggleRecording,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
