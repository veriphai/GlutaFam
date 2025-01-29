import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:eureka_app/services/webSocketService.dart';
import 'package:eureka_app/utils/socraticTutorHelper.dart';
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
  SocraticTutorHelper socraticTutorHelper = SocraticTutorHelper();
  String conversationText = "";
  bool isRecording = false;
  FlutterSoundRecorder? _recorder;
  String? _audioPath;
  FlutterSoundPlayer player = FlutterSoundPlayer();
  Queue<String> audioQueue = Queue<String>();
  bool isPlaying = false;
  String? fetchedImageUrl;
  bool originalConversation = true;

  String conceptName = "How Nutrients are Replenished in the Soil";
  String conceptText =
      "Why Manure and Fertilisers are Used\nFarmers and gardeners spread manure and fertilisers in fields, lawns, or pots to enrich the soil with nutrients. Nutrients like nitrogen, potassium, and phosphorus are needed to keep plants healthy.\n\nSoil Nutrient Depletion\nPlants absorb minerals and nutrients from the soil. Over time, these nutrients decline and need to be replenished by adding fertilisers and manure.\n\nNitrogen Absorption by Plants\nPrerequisite: Nitrogen Gas – a gas present in the air, essential for plant growth.\nPlants need nitrogen in a soluble form because they cannot absorb it directly from the air.\n\nRole of Rhizobium Bacteria\nPrerequisite: Rhizobium – a type of bacteria that can convert atmospheric nitrogen into a form that plants can use.\nRhizobium lives in the roots of leguminous plants (like gram, peas, moong, and beans). The bacteria convert nitrogen from the air into a usable form for plants.\n\nSymbiotic Relationship\nPrerequisite: Symbiotic Relationship – a close association where both organisms benefit.\nRhizobium provides nitrogen to leguminous plants. In return, the plants provide food and shelter to the bacteria.\n\nImportance for Farmers\nFarmers can use fewer nitrogen fertilisers when growing leguminous crops because these plants get nitrogen from Rhizobium.\n\nLeguminous Plants and Pulses\nMost pulses (dals) like beans, peas, and gram come from leguminous plants.";

  Map<String, String> imgDescription = {
    "img_manure_field_001":
        "A lush agricultural field showing manure application, emphasizing the role of microorganisms in decomposing organic matter to enrich soil.",
    "img_nutrient_deficiency_002":
        "A close-up of healthy and nutrient-deficient plants, illustrating how microorganisms assist in nutrient absorption for plant growth.",
    "img_rhizobium_nodules_003":
        "Roots of a leguminous plant with visible Rhizobium nodules, showcasing microorganisms' role in nitrogen fixation for soil fertility.",
    "img_fertiliser_application_006":
        "A farmer applying organic fertilizers in a field, highlighting how microorganisms contribute to recycling nutrients in the environment."
  };

  @override
  void initState() {
    super.initState();
    webSocketService = WebSocketService();
    webSocketService.onMessageReceived = onMessageReceived;
    webSocketService.connect();
    _recorder = FlutterSoundRecorder();

    _initializeRecorder();
    player.openPlayer();
    startConversation("Introduce the Socratic Tutor concept");
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    _recorder?.closeRecorder();
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

      // setState(() {
      //   conversationText += deltaText;
      // });

      if (base64Audio.isNotEmpty) {
        // Decode and enqueue the audio chunk
        audioQueue.add(base64Audio);

        // Start playing if not already playing
        if (!isPlaying && audioQueue.length > 4) {
          _playAudioFromQueue();
        }
      }
    } else if (data['type'] == 'response.done') {
      // final audioBytes = base64Decode(conversationText);

      // await _playAudio(audioBytes);

      print("Conversation complete");
      setState(() {
        conversationText += "\n";
      });
      // if (originalConversation) {
      //   socraticTutorHelper
      //       .getImage(data["response"]["output"][0]["content"][0]["transcript"],
      //           (imageUrl) {
      //     // Update the UI with the fetched image
      //     setState(() {
      //       fetchedImageUrl = imageUrl;
      //       originalConversation = false;
      //     });
      //     if (imageUrl != "") {
      //       continueConversation(imgDescription['img_manure_field_001'] ?? "");
      //     } else {
      //       continueConversation("");
      //     }
      //   });
      // }
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

  Future<void> _playAudioFromQueue() async {
    if (isPlaying || audioQueue.isEmpty) return;

    isPlaying = true;

    while (audioQueue.isNotEmpty) {
      // Retrieve up to 5 audio chunks from the queue
      List<String> batch = [];
      while (batch.length < 5 && audioQueue.isNotEmpty) {
        batch.add(audioQueue.removeFirst());
      }

      // Play each audio chunk in the batch sequentially
      String joinedAudio = "";
      for (String audioString in batch) {
        joinedAudio += audioString;
      }
      final audioBytes = base64Decode(joinedAudio);

      await _playAudio(audioBytes);
    }

    isPlaying = false;
  }

  Future<void> _playAudio(Uint8List audioBytes) async {
    try {
      await player.startPlayer(
          fromDataBuffer: audioBytes,
          codec: Codec.pcm16, // Ensure the codec matches your audio format
          sampleRate: 24000,
          numChannels: 1);

      // Wait until the player finishes playing
      while (player.isPlaying) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      print("Finished playing current audio chunk.");
    } catch (e) {
      print("Error during playback: $e");
    }
  }

  // Future<void> _playAudio(Uint8List audioBytes) async {
  //   // await player.openPlayer();
  //   await player.startPlayer(
  //       fromDataBuffer: audioBytes, codec: Codec.pcm16, sampleRate: 24000);
  // }

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
