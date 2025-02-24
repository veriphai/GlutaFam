import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:eureka_app/services/webSocketService.dart';
// import 'package:eureka_app/utils/socraticTutorHelper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SocraticTutorScreenV2 extends StatefulWidget {
  @override
  _SocraticTutorScreenState createState() => _SocraticTutorScreenState();
}

class _SocraticTutorScreenState extends State<SocraticTutorScreenV2> {
  late WebSocketService webSocketService;
  // SocraticTutorHelper socraticTutorHelper = SocraticTutorHelper();
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

  // String conceptName = "How Nutrients are Replenished in the Soil";
  // String conceptText =
  //     "Why Manure and Fertilisers are Used\nFarmers and gardeners spread manure and fertilisers in fields, lawns, or pots to enrich the soil with nutrients. Nutrients like nitrogen, potassium, and phosphorus are needed to keep plants healthy.\n\nSoil Nutrient Depletion\nPlants absorb minerals and nutrients from the soil. Over time, these nutrients decline and need to be replenished by adding fertilisers and manure.\n\nNitrogen Absorption by Plants\nPrerequisite: Nitrogen Gas – a gas present in the air, essential for plant growth.\nPlants need nitrogen in a soluble form because they cannot absorb it directly from the air.\n\nRole of Rhizobium Bacteria\nPrerequisite: Rhizobium – a type of bacteria that can convert atmospheric nitrogen into a form that plants can use.\nRhizobium lives in the roots of leguminous plants (like gram, peas, moong, and beans). The bacteria convert nitrogen from the air into a usable form for plants.\n\nSymbiotic Relationship\nPrerequisite: Symbiotic Relationship – a close association where both organisms benefit.\nRhizobium provides nitrogen to leguminous plants. In return, the plants provide food and shelter to the bacteria.\n\nImportance for Farmers\nFarmers can use fewer nitrogen fertilisers when growing leguminous crops because these plants get nitrogen from Rhizobium.\n\nLeguminous Plants and Pulses\nMost pulses (dals) like beans, peas, and gram come from leguminous plants.";

  String conceptName =
      "Limits: Illustrative Examples and Practical Examples and Tables";
  String conceptText =
      """To help students understand the concepts outlined in this mini-lesson, we will start with the basics and gradually build up to the main ideas of limits and how they are approached from different directions. Through guided questioning, visual intuition, and practical examples, students will discover these concepts rather than just memorizing formulas.

## 1. Understanding Basic Functions
Before diving into limits, students need a solid understanding of fundamental functions.

### Quadratic Function: f(x) = x²
- "If I take a number and square it, what happens to its value?"  
- "Does squaring a negative number give a negative result?"  
- "If x = 2, what is f(x)? What about if x = -2?"  

➡ Observation: Squaring always gives non-negative values, and larger x-values result in larger squared values.

### Absolute Value Function: g(x) = |x|
- "What does the absolute value function do to negative numbers?"  
- "Can an absolute value ever be negative?"  
- "If x = -3, what is g(x)? What if x = 3?"  

➡ Key Idea: The absolute value measures distance from zero and is always positive.

## 2. Concept of Limits
Limits describe what happens to a function as its input (x) gets closer and closer to a certain value.

### Guided Exploration:
- "What happens to f(x) = x² as x gets very close to 0?"  
- "If x gets smaller and smaller, does f(x) also get smaller?"  
- "Does f(x) ever actually become negative?"  

➡ Key Takeaway: Even if x never actually reaches a point, we can study what happens as it gets arbitrarily close.

## 3. Practical Examples Using Tables
To see limits in action, we examine how function values change as x gets closer to a particular number.

### For f(x) = x² as x → 0:

| x    | f(x) = x²  |
|------|-----------|
| 0.1  | 0.01      |
| 0.01 | 0.0001    |
| 0.001| 0.000001  |
| -0.1 | 0.01      |
| -0.01| 0.0001    |
| -0.001| 0.000001  |

### Guided Questions:
- "What happens to f(x) as x moves closer to 0?"  
- "Are the values of f(x) the same whether x is positive or negative?"  
- "Can we say that f(x) = x² approaches 0 as x → 0?"  

➡ Key Learning: Even if we never actually set x = 0, we see that f(x) gets closer and closer to 0 as x approaches 0.

## 4. Approaching from Different Directions (Left-Hand & Right-Hand Limits)
Before we analyze specific examples, let's first understand what approaching from the left and right means.

### What Does "Approaching from the Left" and "Approaching from the Right" Mean?
Imagine you are walking along a number line toward a particular number (say, x = 0). There are two possible ways to get there:

1. **Approaching from the Left (x → 0⁻):**  
   - You start from negative numbers (e.g., -1, -0.5, -0.1, -0.01) and move towards 0.
   - This is called the left-hand limit or approaching from the left.  
   - "As you get closer to 0 from the left, what happens to the function value?"

2. **Approaching from the Right (x → 0⁺):**  
   - You start from positive numbers (e.g., 1, 0.5, 0.1, 0.01) and move towards 0.
   - This is called the right-hand limit or approaching from the right.  
   - "As you move towards 0 from the right, do you get the same function value as when you approach from the left?"

### Example: Approaching 0 in g(x) = |x|
For the absolute value function g(x) = |x|:

- **Right-hand limit:** As x → 0⁺ (values like 0.1, 0.01, 0.001), the function remains positive and approaches 0.
- **Left-hand limit:** As x → 0⁻ (values like -0.1, -0.01, -0.001), the function still remains positive and approaches 0.

#### Key Observations:
- The function approaches the same value (0) from both directions.
- This means the overall limit exists and is equal to 0.

### Example: A Function Where Left-Hand and Right-Hand Limits Are Different
For h(x) = 1/x, let’s check what happens as x approaches 0:

- **Approaching from the right (x → 0⁺):** The values h(x) (e.g., 1/0.1 = 10, 1/0.01 = 100) become very large and positive.
- **Approaching from the left (x → 0⁻):** The values h(x) (e.g., 1/(-0.1) = -10, 1/(-0.01) = -100) become very large and negative.

#### Key Observations:
- The left-hand and right-hand limits are not equal (one goes to +∞, the other to -∞).
- This means the overall limit does not exist at x = 0.""";

  @override
  void initState() {
    super.initState();
    player = FlutterSoundPlayer();
    webSocketService = WebSocketService();
    webSocketService.onMessageReceived = onMessageReceived;
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
    if (data['type'] == 'session.updated') {
      print(data);
    }
    if (data['type'] ==
        'conversation.item.input_audio_transcription.completed') {
      print("transcript: ${data['transcript']}");
    }
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
    }
  }

  void continueConversation(String imageDescription) {
    String instruction;
    if (imageDescription != "") {
      instruction =
          "You are a Socratic teacher guiding a student to understand a concept. In very short, describe the image to the student in a way that connects it to the ongoing context of the conversation and then pose a thoughtful, open-ended question to encourage critical thinking./n/n Image description: $imageDescription";

      // "You are a Socratic teacher guiding a student to understand a concept. Describe the image to the student in a way that connects it to the ongoing context of the conversation. Keep it crisp. Use this description to create a small visual context and then pose a thoughtful, open-ended question to encourage critical thinking./n/n Image description: $imageDescription";
    } else {
      instruction =
          "You are a Socratic teacher guiding a student to understand a concept. \n Instead of giving direct answers, ask a series of insightful questions to encourage critical thinking and self-discovery. As you proceed, use known analogies or \n real-world examples to help the student relate to the concept better. \n            Your goal is to foster curiosity and ensure the student deeply understands the concept. \n            If the student provides an incorrect or incomplete answer, gently ask further questions \n to guide them toward the correct understanding. Keep in mind to ask one question at a time.\n\n Start the Dialogue:\n\n 1.Begin with a simple question to gauge the student's current understanding.\n 2.Follow up with more specific, thought-provoking questions. Ask one question at a time and let the student answer.\n 3.Use analogies or real-world examples when needed to clarify or deepen understanding.\n 4.Allow the conversation to flow naturally, maintaining a supportive and encouraging tone.\n 5.Conclude by summarizing the key points to ensure the student grasps the concept.";

      // "Use the previous explanation, the student's response, and the ongoing context to ask a thought-provoking question directly, fostering further exploration of the concept.";
    }
    final responseRequest = {
      "type": "response.create",
      "response": {
        "modalities": ["text", "audio"],
        "instructions": instruction
      }
    };
    webSocketService.sendMessage(responseRequest);
  }

  void startConversation(String concept) {
    final startMessage = {
      "event_id": "event_123",
      "type": "session.update",
      "session": {
        "input_audio_transcription": {"model": "whisper-1"},
        "instructions":
            // "You are a teacher guiding a student to deeply understand a concept. Begin with a warm greeting and a very small introduction to what we are studying, just the topic. Never end your conversation with a question or you will die. Keep the intro very short and crisp, and dont explain anything at all. Keep all our conversation short so that the discussion can be mnore engaging."
            "You are a Socratic teacher guiding a student to understand a concept. \n Instead of giving direct answers, ask a series of insightful questions to encourage critical thinking and self-discovery. As you proceed, use known analogies or \n real-world examples to help the student relate to the concept better. \n            Your goal is to foster curiosity and ensure the student deeply understands the concept. \n            If the student provides an incorrect or incomplete answer, gently ask further questions \n to guide them toward the correct understanding. Keep in mind to ask one question at a time.\n\n Start the Dialogue:\n\n 1.Begin with a simple question to gauge the student's current understanding.\n 2.Follow up with more specific, thought-provoking questions. Ask one question at a time and let the student answer.\n 3.Use analogies or real-world examples when needed to clarify or deepen understanding.\n 4.Allow the conversation to flow naturally, maintaining a supportive and encouraging tone.\n 5.Conclude by summarizing the key points to ensure the student grasps the concept.\n\n I will give you the concept and its associated context you need to teach, then you need to start your conversation in a socratic manner.",
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
            "text": "Concept to teach: ${conceptName}. Context: ${conceptText}"
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
