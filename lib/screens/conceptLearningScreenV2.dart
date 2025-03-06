import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:bubble_box/bubble_box.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/checkConceptCheckpointCompleted.dart';
import 'package:eureka_app/apis/checkGreetingsAndIntroCompleted.dart';
import 'package:eureka_app/apis/transcribeAudio.dart';
import 'package:eureka_app/screens/mistakesCorrectionScreen.dart';
import 'package:eureka_app/services/webSocketService.dart';
import 'package:eureka_app/services/webSocketServiceForOpenai.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/utils/socraticTutorHelper.dart';
import 'package:eureka_app/widgets/conceptResultScreen.dart';
import 'package:eureka_app/widgets/conversationScreen.dart';
import 'package:eureka_app/widgets/mcqQuestionsWidget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ConceptLearningScreenV2 extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;
  final String name;

  const ConceptLearningScreenV2(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.maxXP,
      required this.name})
      : super(key: key);
  @override
  _ConceptLearningScreenState createState() => _ConceptLearningScreenState();
}

class _ConceptLearningScreenState extends State<ConceptLearningScreenV2> {
  late WebSocketService webSocketService;
  // late WebSocketServiceForOpenai webSocketService;

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
  String studentName = "";
  bool greetingDone = false;
  bool showContinuationButtons = false;
  bool showJumpToQuestionsButton = false;
  bool showMistakeCorrectionButton = false;
  bool showCheckResultButton = false;
  late ScrollController _scrollController;
  Map<String, bool> checkpointLearningObjectiveStatus = {};
  String userCurrentResponse = "";
  String storyModeStatus = "";
  late Map<String, dynamic> questionsAttemptedDetails;
  DateTime? lastResponseTime;
  Timer? responseMonitorTimer;
  bool skipAudioTutor = false;
  bool responseStreaming = false;
  bool _isLoading = false;

  // String conceptName = "How Nutrients are Replenished in the Soil";
  // String conceptText =
  //     "Why Manure and Fertilisers are Used\nFarmers and gardeners spread manure and fertilisers in fields, lawns, or pots to enrich the soil with nutrients. Nutrients like nitrogen, potassium, and phosphorus are needed to keep plants healthy.\n\nSoil Nutrient Depletion\nPlants absorb minerals and nutrients from the soil. Over time, these nutrients decline and need to be replenished by adding fertilisers and manure.\n\nNitrogen Absorption by Plants\nPrerequisite: Nitrogen Gas – a gas present in the air, essential for plant growth.\nPlants need nitrogen in a soluble form because they cannot absorb it directly from the air.\n\nRole of Rhizobium Bacteria\nPrerequisite: Rhizobium – a type of bacteria that can convert atmospheric nitrogen into a form that plants can use.\nRhizobium lives in the roots of leguminous plants (like gram, peas, moong, and beans). The bacteria convert nitrogen from the air into a usable form for plants.\n\nSymbiotic Relationship\nPrerequisite: Symbiotic Relationship – a close association where both organisms benefit.\nRhizobium provides nitrogen to leguminous plants. In return, the plants provide food and shelter to the bacteria.\n\nImportance for Farmers\nFarmers can use fewer nitrogen fertilisers when growing leguminous crops because these plants get nitrogen from Rhizobium.\n\nLeguminous Plants and Pulses\nMost pulses (dals) like beans, peas, and gram come from leguminous plants.";

  // String conceptName = "SAS Congruence Rule";
  String conceptName = "Thrust and Pressure";

  List<Map<String, dynamic>> conceptCheckpoints = [
    {
      "title": "Checkpoint 1: Understanding Pressure in Fluids",
      "learningObjective": [
        "Fluids exert pressure in all directions due to their weight.",
        "Fluid pressure increases with depth due to the weight of the fluid above.",
        "The mathematical expression for pressure in a fluid is \\[ P = \\rho gh \\]."
      ],
      "blackboard_text":
          "Pressure in Fluids: \n\\[ P = \\rho gh \\]  \n\\[ P \\propto h \\] (More depth = More pressure)",
      "theory":
          "Fluids exert pressure not only at the base but also on the walls of their container. The pressure at any point in a fluid is given by \\[ P = \\rho gh \\], where \\( h \\) is the height of the fluid column."
    },
    {
      "title": "Checkpoint 2: Isotropic Nature of Fluid Pressure",
      "learningObjective": [
        "Fluid pressure is exerted equally in all directions (isotropic property).",
        "This principle is responsible for various real-world fluid behaviors, such as hydraulic lifts and deep-sea diving effects.",
        "Fluid pressure increases with depth but remains equal in all directions at a given depth."
      ],
      "blackboard_text":
          "Fluid Pressure is Isotropic: \n\\[ P_1 = P_2 = P_3 \\] at same depth",
      "theory":
          "Fluids exert pressure equally in all directions at a given depth. This isotropic property is fundamental in applications like hydraulic systems and explains the uniform force distribution in underwater environments."
    },
    {
      "title": "Checkpoint 3: Understanding Buoyancy",
      "learningObjective": [
        "Buoyancy is the upward force exerted by a fluid on an immersed object.",
        "Objects feel lighter in a fluid due to the buoyant force.",
        "The magnitude of the buoyant force depends on the weight of the displaced fluid."
      ],
      "blackboard_text":
          "Buoyancy: \n\\[ F_b = \\rho_{fluid} \\times V_{displaced} \\times g \\]  \nWhy do objects feel lighter in water?",
      "theory":
          "Buoyancy is the upward force exerted by a fluid on an object. This force opposes gravity and depends on the weight of the displaced fluid. If the buoyant force is greater than the object's weight, it floats."
    },
    {
      "title": "Checkpoint 4: Archimedes’ Principle",
      "learningObjective": [
        "Archimedes' Principle states that an object submerged in a fluid experiences an upward buoyant force equal to the weight of the displaced fluid.",
        "This principle explains why objects float, sink, or remain suspended in a fluid.",
        "The formula for buoyant force is \\[ F_b = \\rho_{fluid} \\times V_{displaced} \\times g \\]."
      ],
      "blackboard_text":
          "Archimedes' Principle: \n\\[ F_b = \\text{Weight of Displaced Fluid} \\]",
      "theory":
          "According to Archimedes' Principle, a submerged object experiences an upward force equal to the weight of the fluid it displaces. This principle is used in ship design and submarine buoyancy control."
    },
    {
      "title": "Checkpoint 5: Activity-Based Learning – Exploring Buoyancy",
      "learningObjective": [
        "The buoyant force increases as an object is pushed deeper into the water.",
        "Objects float when their weight is less than the buoyant force acting on them.",
        "The balance between gravitational force and buoyant force determines an object’s floating or sinking behavior."
      ],
      "blackboard_text":
          "Activity: Push a bottle underwater \nObserve resistance \\( \\uparrow \\) as depth \\( \\uparrow \\).",
      "theory":
          "When an object is submerged in water, it experiences an increasing upward force as it is pushed deeper. This activity helps in visualizing buoyant force and understanding why some objects float while others sink."
    },
    {
      "title": "Checkpoint 6: Real-World Applications of Thrust and Pressure",
      "learningObjective": [
        "Fluid pressure concepts are used in hydraulic systems like brakes and jacks.",
        "Buoyancy principles explain why ships float and submarines submerge.",
        "Understanding fluid mechanics is essential in designing water tanks, dams, and underwater structures."
      ],
      "blackboard_text":
          "Applications of Fluid Pressure: \n1. Ship Floating \n2. Hydraulic Brakes \n3. Dams & Water Tanks",
      "theory":
          "Thrust, pressure, and buoyancy principles are applied in engineering, shipbuilding, and hydraulic machinery. Understanding these concepts helps in real-world problem-solving related to fluid mechanics."
    }
  ];

  // List<Map<String, dynamic>> conceptCheckpoints = [
  //   {
  //     "title": "Checkpoint 1: Understanding Triangles",
  //     "learningObjective": [
  //       "A triangle is a three-sided polygon with three angles.",
  //       "The three line segments that form a triangle are called its sides.",
  //       "The sum of the interior angles of a triangle is always 180°."
  //     ],
  //     "blackboard_text":
  //         "Triangle: \n\\[ \\triangle ABC \\]  \n\nThree sides: AB, BC, AC  \n\nThree angles: \\( \\angle A, \\angle B, \\angle C \\)",
  //     "theory":
  //         "A triangle is a closed figure formed by three line segments. It has three interior angles, and the sum of these angles is always 180°."
  //   },
  //   {
  //     "title": "Checkpoint 2: Introduction to Congruence in Triangles",
  //     "learningObjective": [
  //       "Congruent triangles have the same shape and size.",
  //       "If two triangles are congruent, their corresponding sides and angles are equal.",
  //       "Congruence means one triangle can be placed exactly over another without any gaps."
  //     ],
  //     "blackboard_text":
  //         "Congruent Triangles: \n\\[ \\triangle ABC \\cong \\triangle DEF \\]  \nEqual sides: AB = DE, BC = EF, AC = DF  \nEqual angles: \\( \\angle A = \\angle D, \\angle B = \\angle E, \\angle C = \\angle F \\)",
  //     "theory":
  //         "Two triangles are congruent if they have equal corresponding sides and angles. This means they can be perfectly superimposed onto each other."
  //   },
  //   {
  //     "title": "Checkpoint 3: SAS Congruence Rule (Axiom 7.1)",
  //     "learningObjective": [
  //       "Two triangles are congruent if two sides and the included angle of one triangle are equal to the corresponding two sides and the included angle of another triangle.",
  //       "SAS stands for Side-Angle-Side, meaning two sides and the angle between them are given.",
  //       "The SAS rule is a fundamental way to establish triangle congruence."
  //     ],
  //     "blackboard_text":
  //         "SAS Congruence Rule: \nIf \\[ AB = DE, AC = DF, \\angle A = \\angle D \\]  \nThen \\[ \\triangle ABC \\cong \\triangle DEF \\]",
  //     "theory":
  //         "According to the SAS Congruence Rule, if two sides and the included angle of one triangle are equal to the corresponding sides and included angle of another triangle, then the triangles are congruent."
  //   },
  // ];

  @override
  void initState() {
    super.initState();
    studentName = widget.name;
    _startResponseMonitor();
    _scrollController = ScrollController();

    player = FlutterSoundPlayer();
    webSocketService = WebSocketService();
    // webSocketService = WebSocketServiceForOpenai();

    webSocketService.onMessageReceived = onMessageReceived;
    webSocketService.useOpenAI = false;
    webSocketService.connect();
    _recorder = FlutterSoundRecorder();

    _initializeRecorder();
    _initPlayer();
    // startConversation();
    greetingAndIntroConversation();
  }

  void _startResponseMonitor() {
    responseMonitorTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (lastResponseTime != null) {
        Duration elapsed = DateTime.now().difference(lastResponseTime!);

        if (elapsed.inSeconds > 5 && responseStreaming && !skipAudioTutor) {
          // Change threshold if needed
          print("⚠️ Response delay detected: ${elapsed.inSeconds} seconds");

          // Take action - either stop WebSocket or notify user
          _handleResponseDelay();
        }
      }
    });
  }

  void _handleResponseDelay() {
    print("🚨 Significant delay detected!");

    // Option 1: Stop WebSocket Calls
    webSocketService.disconnect();
    setState(() {
      skipAudioTutor = true;
      showContinuationButtons = true;
    });
  }

  Widget othersMessage(final conversation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (greetingDone)
          Image.asset(
            getAvatar("avatar-9")["imagePath"]!,
            height: 40,
          ),
        Flexible(
            child: BubbleBox(
                maxWidth: double.infinity,
                shape: BubbleShapeBorder(
                    border: BubbleBoxBorder(
                      color: Colors.grey.shade700,
                      width: 3,
                    ),
                    radius: BorderRadius.circular(12),
                    position: const BubblePosition.start(10),
                    direction: BubbleDirection.left,
                    arrowHeight: 10),
                backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: MarkdownBody(
                      selectable: false,
                      data: conversation,
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
                    ))))
      ],
    );
  }

  Widget yourMessage(final conversation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
            child: BubbleBox(
                maxWidth: double.infinity,
                shape: BubbleShapeBorder(
                    border: BubbleBoxBorder(
                      color: Colors.grey.shade700,
                      width: 3,
                    ),
                    radius: BorderRadius.circular(12),
                    position: const BubblePosition.start(10),
                    direction: BubbleDirection.right,
                    arrowHeight: 10),
                backgroundColor: Color.fromRGBO(19, 36, 22, 1),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: MarkdownBody(
                      selectable: true,
                      data: conversation!,
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
                    )))),
      ],
    );
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    responseMonitorTimer?.cancel();
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

  void conversationItemCreationForUser(String contentText) {
    final conversationStartMessage = {
      "type": "conversation.item.create",
      "item": {
        "type": "message",
        "role": "user",
        "content": [
          {"type": "input_text", "text": contentText}
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

  Uint8List generateSilence({int durationMs = 100}) {
    int sampleRate = 24000;
    int numSamples = (sampleRate * durationMs) ~/ 1000;
    return Uint8List(numSamples * 2);
  }

  Future<void> onMessageReceived(String message) async {
    final data = jsonDecode(message);
    print("respones received");
    if (data['type'] == 'response.audio_transcript.delta') {
      String deltaText = data['delta'] ?? "";

      setState(() {
        conversationText += deltaText;
      });
      setState(() {
        if (userCurrentResponse.isNotEmpty) {
          if ((conversations.isNotEmpty &&
              conversations.last['role'] == 'streaming')) {
            conversations.insert(conversations.length - 1, {
              "text": userCurrentResponse,
              "role": "user",
            });
          } else {
            conversations.add({
              "text": userCurrentResponse,
              "role": "user",
            });
          }
          userCurrentResponse = "";
        }
        if (conversations.isNotEmpty &&
            conversations.last['role'] == 'streaming') {
          // Update the current streaming message
          conversations.last['text'] =
              (conversations.last['text'] ?? '') + deltaText;
        } else {
          // Add a new streaming message
          conversations.add({'text': deltaText, 'role': 'streaming'});
        }
        _scrollToBottom();
      });
    } else if (data['type'] == 'response.audio.delta') {
      responseStreaming = true;
      lastResponseTime = DateTime.now();

      // Append conversation text
      String base64Audio = data['delta'] ?? "";
      if (base64Audio.isNotEmpty && _isPlayerReady) {
        Uint8List rawData = base64Decode(base64Audio);
        // Send the chunk into the audio stream
        player.foodSink?.add(FoodData(rawData));
      }
    } else if (data['type'] == 'response.done') {
      print("Conversation complete");
      responseStreaming = false;
      conversationText = "";
      // if (data['response']['output'].length > 0) {
      //   conversations.add({
      //     "text": data['response']['output'][0]['content'][0]["transcript"],
      //     "role": "assistant"
      //   });
      // }
      Uint8List silence = generateSilence(durationMs: 1500); // 300ms silence
      player.foodSink?.add(FoodData(silence));
      setState(() {
        _isLoading = false;
        if (conversations.isNotEmpty &&
            conversations.last['role'] == 'streaming') {
          conversations.last['role'] = 'assistant';
        }
      });
      if (!showContinuationButtons &&
          !showJumpToQuestionsButton &&
          !showMistakeCorrectionButton &&
          !showCheckResultButton) {
        if (greetingDone) {
          checkConceptCompleted();
        } else {
          checkGreetingCompleted();
        }
      }
      // } else {
      //   if (storyModeStatus == "completed") {
      //     movingToQuestionConversation();
      //   } else {
      //     showingOptionsIfStoryModeNotCompleted();
      //   }
      // }
    }
  }

  void checkGreetingCompleted() async {
    // final result = {'checkpointCompleted': true};

    final result = await checkGreetingsAndIntroCompleted(
        conversations: conversations,
        conceptName: conceptName,
        greeting: !greetingDone);
    bool greetingsCompleted = result['greetingsCompleted'] ?? false;

    if (greetingsCompleted) {
      greetingDone = true;
      startConversation();
    }
  }

  void showingOptionsIfStoryModeNotCompleted() {
    String contentText =
        "There are 2 available options to continue from here. 1.Continue learning with Tutor \n 2.Jump to questions. Ask user to choose one of the option";

    conversationItemCreationForUser(contentText);
    setState(() {
      showContinuationButtons = true;
    });
  }

  void moveToNextCheckpoint() {
    currentCheckpointIndex += 1;
    String contentText =
        "Concept to teach: $conceptName. Moving to next checkpoint of the concept. Checkpoint ${currentCheckpointIndex + 1}: ${conceptCheckpoints[currentCheckpointIndex]}";

    conversationItemCreationForUser(contentText);
  }

  void movingToQuestionConversation() {
    String contentText =
        "Now all checkpoints have been completed. Ask user to move to questions so test their understanding.";

    conversationItemCreationForUser(contentText);
    setState(() {
      showJumpToQuestionsButton = true;
    });
  }

  void checkConceptCompleted() async {
    // final result = {'checkpointCompleted': true};

    final result = await checkConceptCheckpointCompleted(
        conversations: conversations,
        conceptName: conceptName,
        greeting: !greetingDone,
        conceptCheckpoint: conceptCheckpoints[currentCheckpointIndex]);
    checkpointLearningObjectiveStatus = Map<String, bool>.from(result);
    bool conceptCompleted = checkpointLearningObjectiveStatus.values
        .every((value) => value == true);

    if (conceptCompleted) {
      if (currentCheckpointIndex == 0 && !showContinuationButtons) {
        String contentText =
            "Now there are 3 available options to continue from here. 1.Continue learning with Tutor \n 2.Proceed with story mode \n 3.Jump to questions. Ask user to choose one of the option";

        conversationItemCreationForUser(contentText);
        setState(() {
          showContinuationButtons = true;
        });
      } else if (currentCheckpointIndex == conceptCheckpoints.length - 1) {
        movingToQuestionConversation();
      } else {
        moveToNextCheckpoint();
      }
    }
  }

  void afterStoryConversation(String completionStatus) {
    String contentText = "";
    if (completionStatus == "completed") {
      contentText =
          "Now the student has completed the concept using the story mode. Congratulate the student and ask them to move to questions so test their understanding.";
      setState(() {
        showJumpToQuestionsButton = true;
        showContinuationButtons = false;
      });
    } else {
      contentText =
          "The student has selected the story mode option to continue with the concept but left in between, without completing it. Tell them that you didnt like the story but no need to worry and there are 2 available options to continue from here. 1.Continue learning with Tutor \n 2.Jump to questions. Ask user to choose one of the option ";
      setState(() {
        showContinuationButtons = true;
      });
    }

    setState(() {
      storyModeStatus = completionStatus;
    });
    conversationItemCreationForUser(contentText);
  }

  void afterQuestionsConversation(Map<String, dynamic> questionCompletion) {
    String contentText = "";
    if (questionCompletion['completed']) {
      if (questionCompletion['incorrectQuestions'].length > 0) {
        contentText =
            "Now the student has completed the questions associated with the concept and attempted ${questionCompletion['incorrectQuestions'].length} incorrectly out of ${questionCompletion['totalQuestions']} total questions. Say something to the student based on the performance. There is an option available to Correct the mistakes made. Ask the  student to select the option.";
      } else {
        contentText =
            "Now the student has completed the questions associated with the concept with a perfect score. Congratulate the student";
      }
      setState(() {
        showJumpToQuestionsButton = false;
        showContinuationButtons = false;
        showMistakeCorrectionButton = true;
      });
    } else {
      contentText =
          "The student moved to attempt the questions associated with the concept but left in between, without completing it. Tell them that they can try again ";
      setState(() {
        showJumpToQuestionsButton = true;
        showContinuationButtons = false;
      });
    }
    setState(() {
      questionsAttemptedDetails = questionCompletion;
    });
    conversationItemCreationForUser(contentText);
  }

  void afterMistakesCorrectionConversation() {
    String contentText =
        "Now the student has completed the questions and corrected their mistakes too, associated with the concept. Congratulate the student, and ask them to check their result.";
    setState(() {
      showMistakeCorrectionButton = false;
      showCheckResultButton = true;
    });
    conversationItemCreationForUser(contentText);
  }

  void greetingAndIntroConversation() {
    final startMessage = {
      "event_id": "event_123_greeting",
      "type": "session.update",
      "session": {
        "instructions":
            // "You are a teacher guiding a student to deeply understand a concept. Begin with a warm greeting and a very small introduction to what we are studying, just the topic. Never end your conversation with a question or you will die. Keep the intro very short and crisp, and dont explain anything at all. Keep all our conversation short so that the discussion can be mnore engaging."
            "You are a Socratic teacher teaching a concept to a student. Follow these steps: \n 1. Begin with a warm greeting, just like a teacher starting a class. \n2. Wait for the student to respond to the greeting. \n3. Provide a very brief introduction (20-30 words) about the concept you are going to teach, and dont ask any questions while introducing the topic. \n4. Do not end the introduction with a question. \n5. Use the student's name and the concept name (which will be provided) while introducing the topic.",
      }
    };

    webSocketService.sendMessage(startMessage);

    String contentText =
        "Student's name:$studentName \n Concept to teach: $conceptName.";

    conversationItemCreationForUser(contentText);
  }

  void startConversation() {
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

    String contentText =
        "Concept to teach: $conceptName. Checkpoint 1: ${conceptCheckpoints[0]}";
    conversationItemCreationForUser(contentText);
  }

  Future<void> _toggleRecording() async {
    if (_isLoading) {
      return;
    }
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
        transcribeAudio(File(_audioPath!)).then((transcribedText) {
          userCurrentResponse = transcribedText;
          print("User Response: $userCurrentResponse");
        });
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
      _isLoading = true;
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
          },
          {
            "type": "input_text",
            "text":
                "Current completion status of learning objectives: $checkpointLearningObjectiveStatus"
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

  Widget _buildRecordingButton() {
    return Column(
      children: [
        ChicletAnimatedButton(
          onPressed: _toggleRecording,
          buttonType: ChicletButtonTypes.roundedRectangle,
          width: 100,
          height: 50,
          buttonColor:
              isRecording ? Colors.red : Color.fromRGBO(187, 160, 2, 1),
          backgroundColor:
              isRecording ? Colors.redAccent : Color.fromRGBO(255, 217, 0, 1),
          child: _isLoading
              ? SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: Transform.scale(
                      scale: 1,
                      child: CircularProgressIndicator(
                        color: Color.fromRGBO(19, 31, 36, 1),
                        strokeWidth: 4.0,
                      ),
                    ),
                  ),
                )
              : Icon(
                  isRecording ? Icons.mic : Icons.mic_none,
                  color: Color.fromRGBO(19, 31, 36, 1),
                  size: 40,
                ),
        ),
        const SizedBox(height: 20),
        Text(
          _isLoading
              ? ""
              : (isRecording
                  ? 'Recording... Tap to submit answer'
                  : 'Tap to answer'),
          style: GoogleFonts.raleway(
            fontSize: 16,
            color: Colors.white,
          ),
          textAlign: TextAlign.center, // Center-align the microphone hint text
        ),
      ],
    );
  }

  Widget _buildRecordingButtonV2() {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(8),
              gradient: isRecording
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
                  color: isRecording
                      ? Colors.redAccent
                      : Color.fromRGBO(255, 217, 0, 1),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _isLoading
                ? SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: Transform.scale(
                        scale: 1,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4.0,
                        ),
                      ),
                    ),
                  )
                : Icon(
                    isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 50,
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isLoading
              ? ""
              : (isRecording
                  ? 'Recording... Tap to submit answer'
                  : 'Tap to answer'),
          style: GoogleFonts.raleway(
            fontSize: 16,
            color: Colors.white,
          ),
          textAlign: TextAlign.center, // Center-align the microphone hint text
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedConversations = List.from(conversations);

    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        title: Text(
          widget.conceptName,
          style: GoogleFonts.raleway(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.grey,
        ),
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Always visible image panel
          SizedBox(
            height: 20,
          ),
          !greetingDone
              ? Center(
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(150),
                  child: Container(
                      color: Colors.amber,
                      child: Image.asset(
                        getAvatar("avatar-9")["imagePath"]!,
                        height: 150,
                        fit: BoxFit.scaleDown,
                      )),
                ))
              : Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: 150),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: MarkdownBody(
                            selectable: false,
                            data: conceptCheckpoints[currentCheckpointIndex]
                                ['blackboard_text'],
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
                          )))),
          // Scrollable content
          SizedBox(
            height: 16,
          ),
          if (skipAudioTutor)
            Expanded(
                child: Center(
                    child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Color.fromRGBO(255, 217, 0, 1)),
                        child: Row(children: [
                          Icon(
                            Icons.network_check_rounded,
                            size: 50,
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Expanded(
                              child: Text(
                            "Our AI Tutor is currently experiencing lot of traffic, please start with story mode or questions directly.",
                            style: GoogleFonts.raleway(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ))
                        ])))),
          !skipAudioTutor && displayedConversations.isNotEmpty
              ? Flexible(
                  child: ListView.builder(
                  controller: _scrollController,
                  itemCount: displayedConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];

                    return conversation['role'] == "user"
                        ? SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12.0),
                            child: othersMessage(conversation["text"]));
                  },
                ))
              : Spacer(),
          SizedBox(height: 16),
          if (showContinuationButtons)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!skipAudioTutor)
                      ChicletAnimatedButton(
                        onPressed: () {
                          setState(() {
                            showContinuationButtons = false;
                          });
                          moveToNextCheckpoint();
                        },
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        width: double.infinity,
                        height: 50,
                        buttonColor: Color.fromRGBO(187, 160, 2, 1),
                        backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                        child: Text(
                          "CONTINUE WITH AI TUTOR",
                          style: GoogleFonts.raleway(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    SizedBox(height: 12),

                    // 🔄 Cancel Button
                    if (storyModeStatus.isEmpty && !skipAudioTutor)
                      ChicletOutlinedAnimatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conceptId: widget.conceptId,
                                conceptName: widget.conceptName,
                                maxXP: widget.maxXP,
                              ),
                            ),
                          ).then((value) {
                            afterStoryConversation(value);
                          });
                        },
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        width: double.infinity,
                        height: 50,
                        borderColor: Colors.transparent,
                        // buttonColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        child: Text(
                          "START STORY MODE",
                          style: GoogleFonts.raleway(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (storyModeStatus.isEmpty && skipAudioTutor)
                      ChicletAnimatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConversationScreen(
                                conceptId: widget.conceptId,
                                conceptName: widget.conceptName,
                                maxXP: widget.maxXP,
                              ),
                            ),
                          ).then((value) {
                            setState(() {
                              showJumpToQuestionsButton = true;
                              showContinuationButtons = false;
                            });
                          });
                        },
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        width: double.infinity,
                        height: 50,
                        buttonColor: Color.fromRGBO(187, 160, 2, 1),
                        backgroundColor: Color.fromRGBO(
                            255, 217, 0, 1), // buttonColor: Colors.transparent,
                        child: Text(
                          "START STORY MODE",
                          style: GoogleFonts.raleway(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ChicletOutlinedAnimatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MCQQuestions(
                              conceptId: widget.conceptId,
                              conceptName: widget.conceptName,
                              maxXP: widget.maxXP,
                            ),
                          ),
                        ).then((value) {
                          if (skipAudioTutor) {
                            setState(() {
                              questionsAttemptedDetails = value;
                              showContinuationButtons = false;
                              if (value['completed']) {
                                showJumpToQuestionsButton = false;
                                if (value.containsKey('incorrectQuestions') &&
                                    value['incorrectQuestions'].isNotEmpty) {
                                  showMistakeCorrectionButton = true;
                                } else {
                                  showCheckResultButton = true;
                                }
                              } else {
                                showJumpToQuestionsButton = true;
                              }
                            });
                          } else {
                            afterQuestionsConversation(value);
                          }
                        });
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      width: double.infinity,
                      height: 50,
                      borderColor: Colors.transparent,
                      // buttonColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        "JUMP TO QUESTIONS",
                        style: GoogleFonts.raleway(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )),

          if (showJumpToQuestionsButton)
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChicletAnimatedButton(
                      onPressed: () {
                        setState(() {
                          showJumpToQuestionsButton = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MCQQuestions(
                              conceptId: widget.conceptId,
                              conceptName: widget.conceptName,
                              maxXP: widget.maxXP,
                            ),
                          ),
                        ).then((value) {
                          if (skipAudioTutor) {
                            setState(() {
                              questionsAttemptedDetails = value;
                              if (value['completed']) {
                                showJumpToQuestionsButton = false;
                                if (value['incorrectQuestions'].length > 0) {
                                  showMistakeCorrectionButton = true;
                                } else {
                                  showCheckResultButton = true;
                                }
                              } else {
                                showJumpToQuestionsButton = true;
                              }
                            });
                          } else {
                            afterQuestionsConversation(value);
                          }
                        });
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      width: double.infinity,
                      height: 50,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "START QUESTIONS",
                        style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )),

          if (showMistakeCorrectionButton)
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChicletAnimatedButton(
                      onPressed: () {
                        setState(() {
                          showJumpToQuestionsButton = false;
                        });
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MistakesCorrectionScreen(
                                conceptName: conceptName,
                                conceptId: widget.conceptId,
                                totalXp: questionsAttemptedDetails['totalXp'],
                                timeTaken:
                                    questionsAttemptedDetails['timeTaken'],
                                accuracy: questionsAttemptedDetails['accuracy'],
                                incorrectQuestions: questionsAttemptedDetails[
                                    'incorrectQuestions'],
                                lessonCompletionResponse:
                                    questionsAttemptedDetails[
                                        'lessonCompletionResponse'],
                              ),
                            )).then((value) {
                          if (skipAudioTutor) {
                            setState(() {
                              showMistakeCorrectionButton = false;
                              showCheckResultButton = true;
                            });
                          } else {
                            afterMistakesCorrectionConversation();
                          }
                        });
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      width: double.infinity,
                      height: 50,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "CORRECT YOUR MISTAKES",
                        style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )),
          if (showCheckResultButton)
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChicletAnimatedButton(
                      onPressed: () {
                        setState(() {
                          showJumpToQuestionsButton = false;
                        });
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConceptResultScreen(
                                conceptName: conceptName,
                                totalXp: questionsAttemptedDetails['totalXp'],
                                timeTaken:
                                    questionsAttemptedDetails['timeTaken'],
                                accuracy: questionsAttemptedDetails['accuracy'],
                                lessonCompletionResponse:
                                    questionsAttemptedDetails[
                                        'lessonCompletionResponse'],
                              ),
                            ));
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      width: double.infinity,
                      height: 50,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "CHECK RESULTS",
                        style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )),

          if (!showContinuationButtons &&
              !showJumpToQuestionsButton &&
              !showMistakeCorrectionButton &&
              !showCheckResultButton &&
              !skipAudioTutor)
            _buildRecordingButton(),

          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}
