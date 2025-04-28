import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:bubble_box/bubble_box.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/checkConceptCheckpointCompleted.dart';
import 'package:eureka_app/apis/checkGreetingsAndIntroCompleted.dart';
import 'package:eureka_app/apis/fetchConceptDetails.dart';
import 'package:eureka_app/apis/getAITutorPrompts.dart';
import 'package:eureka_app/apis/markLessonCompletion.dart';
import 'package:eureka_app/apis/transcribeAudio.dart';
import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shimmer/shimmer.dart';

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
  bool showAfterGreetingContinueButton = false;
  bool showCheckpointContinueButton = false;
  late String greetingPrompt;
  late String aiTutorPrompt;
  bool isConceptCheckpointLoading = true;
  int xpGained = 0;
  bool allCheckpointsCompleted = false;
  List<int> completedCheckpointIndexes = [];
  bool isMuted = false;

  late List<Map<String, dynamic>> conceptCheckpoints;

  Future<void> getConceptDetails() async {
    try {
      Map<String, dynamic>? conceptDetails =
          await fetchConceptDetails(conceptId: widget.conceptId);
      // await fetchConceptDetails(conceptId: "thrust_and_pressure_concept_1");

      // final profileData = await getProfile();

      setState(() {
        conceptCheckpoints = (conceptDetails["conceptCheckpoints"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        isConceptCheckpointLoading = false;
      });
    } catch (error) {
      print("Error fetching concept details: $error");
    }
  }

  Future<void> fetchAITutorPrompts() async {
    try {
      Map<String, dynamic>? aiTutorPrompts = await getAITutorPrompts();
      // final profileData = await getProfile();

      setState(() {
        greetingPrompt = aiTutorPrompts['aiTutorGreetings'];
        aiTutorPrompt = aiTutorPrompts['aiTutorPrompt'];
      });
    } catch (error) {
      print("Error fetching concept details: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);
    studentName = widget.name;
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
    // getConceptDetails();
    getConceptDetails().then((_) {
      fetchAITutorPrompts().then((_) {
        greetingAndIntroConversation();
      });
    });
    // greetingAndIntroConversation();
    _startResponseMonitor();
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

  void _showAllConversations(BuildContext context) {
    final displayedConversations = List.from(conversations);

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        builder: (BuildContext context) {
          return !skipAudioTutor && displayedConversations.isNotEmpty
              ? Flexible(
                  child: Padding(
                      padding: EdgeInsets.only(top: 60),
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
                      )))
              : Spacer();
        });
  }

  void _showMenuToSwitch(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        builder: (BuildContext context) {
          return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!skipAudioTutor && !allCheckpointsCompleted)
                    ChicletAnimatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
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
                        "CONTINUE WITH AI TUTOR   +45 XP",
                        style: GoogleFonts.arOneSans(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  SizedBox(height: 12),
                  if (storyModeStatus.isEmpty)
                    ChicletOutlinedAnimatedButton(
                      onPressed: () {
                        player.stopPlayer();
                        HapticFeedback.lightImpact();
                        logStoryModeButtonClickFromMenu(
                            conceptCheckpoints[currentCheckpointIndex]['id'],
                            widget.conceptId);
                        Navigator.pop(context);
                        setState(() {
                          showCheckpointContinueButton = false;
                          showAfterGreetingContinueButton = false;
                        });

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
                          _initPlayer();
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
                        "START STORY MODE   +45 XP",
                        style: GoogleFonts.arOneSans(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ChicletOutlinedAnimatedButton(
                    onPressed: () async {
                      // setState(() {
                      //   isMuted = true;
                      // });
                      // player.pausePlayer();
                      player.stopPlayer();
                      HapticFeedback.lightImpact();
                      logQuestionsButtonClickFromMenu(
                          conceptCheckpoints[currentCheckpointIndex]['id'],
                          widget.conceptId);

                      Navigator.pop(context);
                      setState(() {
                        showCheckpointContinueButton = false;
                        showAfterGreetingContinueButton = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MCQQuestions(
                            conceptId: widget.conceptId,
                            conceptName: widget.conceptName,
                            maxXP: 45,
                          ),
                        ),
                      ).then((value) async {
                        _initPlayer();
                        // player.setVolume(0.9);
                        // player.resumePlayer();
                        // setState(() {
                        //   isMuted = false;
                        // });

                        if (value['completed']) {
                          if (!value.containsKey('incorrectQuestions')) {
                            final Map<String, dynamic>
                                lessonCompletionResponse =
                                await markLessonCompletion(
                                    lessonId: widget.conceptId,
                                    attemptTime: value['attemptTime'],
                                    timeToComplete: value['timeToComplete'],
                                    xpGained: value['totalXp'] + xpGained,
                                    accuracy: value['accuracy'],
                                    bookId: value['bookId'],
                                    report: value['report'],
                                    correctlyAnswered:
                                        value['correctlyAnswered'],
                                    mistakesCorrected: 0);
                            value['lessonCompletionResponse'] =
                                lessonCompletionResponse;
                          }

                          setState(() {
                            questionsAttemptedDetails = value;
                          });
                        }
                        if (skipAudioTutor) {
                          setState(() {
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
                      "JUMP TO QUESTIONS   +45 XP",
                      style: GoogleFonts.arOneSans(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ChicletAnimatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      setState(() {
                        showContinuationButtons = false;
                      });
                      startConversation();
                    },
                    buttonType: ChicletButtonTypes.roundedRectangle,
                    width: double.infinity,
                    height: 50,
                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                    backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                    child: Text(
                      "Move to Next Checkpoint -Testing",
                      style: GoogleFonts.arOneSans(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ));
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
      if (base64Audio.isNotEmpty && _isPlayerReady && !isMuted) {
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
        conceptName: widget.conceptName,
        greeting: !greetingDone);
    bool greetingsCompleted = result['greetingsCompleted'] ?? false;

    if (greetingsCompleted) {
      // greetingDone = true;
      setState(() {
        showAfterGreetingContinueButton = true;
      });
      logAITutorGreetingCompleted(widget.conceptId);
      // startConversation();
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
    if (completedCheckpointIndexes.contains(currentCheckpointIndex)) {
      currentCheckpointIndex += 1;

      logAITutorCheckpointStart(
          conceptCheckpoints[currentCheckpointIndex]['id'], widget.conceptId);

      String contentText =
          "Concept to teach: ${widget.conceptName}. Moving to next checkpoint of the concept. Checkpoint ${currentCheckpointIndex + 1}: ${conceptCheckpoints[currentCheckpointIndex]}";

      conversationItemCreationForUser(contentText);
    } else {
      String contentText = "Start from where we have left";

      conversationItemCreationForUser(contentText);
    }
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
        conceptName: widget.conceptName,
        greeting: !greetingDone,
        conceptCheckpoint: conceptCheckpoints[currentCheckpointIndex]);
    checkpointLearningObjectiveStatus = Map<String, bool>.from(result);
    bool conceptCompleted = checkpointLearningObjectiveStatus.values
        .every((value) => value == true);

    if (conceptCompleted) {
      setState(() {
        showCheckpointContinueButton = true;
      });
      completedCheckpointIndexes.add(currentCheckpointIndex);
      //  checkpointContinueButtonClick();
    }
  }

  void checkpointContinueButtonClick() {
    setState(() {
      showCheckpointContinueButton = false;
    });
    if (currentCheckpointIndex == 0 && !showContinuationButtons) {
      String contentText =
          "Now there are 3 available options to continue from here. 1.Continue learning with Tutor \n 2.Proceed with story mode \n 3.Jump to questions. Ask user to choose one of the option";

      conversationItemCreationForUser(contentText);
      setState(() {
        showContinuationButtons = true;
      });
    } else if (currentCheckpointIndex == conceptCheckpoints.length - 1) {
      setState(() {
        xpGained += 45;
        allCheckpointsCompleted = true;
      });
      movingToQuestionConversation();
    } else {
      moveToNextCheckpoint();
    }
  }

  void afterStoryConversation(String completionStatus) {
    String contentText = "";
    if (completionStatus == "completed") {
      logStoryModeCompleted(widget.conceptId);
      contentText =
          "Now the student has completed the concept using the story mode. Congratulate the student and ask user to choose one of the 2 available options to continue from here. 1.Continue learning with Tutor \n 2.Jump to questions. ";
      setState(() {
        // showJumpToQuestionsButton = true;
        showContinuationButtons = true;
        xpGained += 45;
      });
    } else {
      logStoryModeNotCompleted(widget.conceptId);

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
      if (questionCompletion.containsKey('incorrectQuestions') &&
          questionCompletion['incorrectQuestions'].length > 0) {
        contentText =
            "Now the student has completed the questions associated with the concept and attempted ${questionCompletion['incorrectQuestions'].length} incorrectly out of ${questionCompletion['totalQuestions']} total questions. Say something to the student based on the performance. There is an option available to Correct the mistakes made. Ask the  student to select the option.";
      } else {
        contentText =
            "Now the student has completed the questions associated with the concept with a perfect score. Congratulate the student";
      }
      setState(() {
        showJumpToQuestionsButton = false;
        showContinuationButtons = false;
        if (questionCompletion.containsKey('incorrectQuestions') &&
            questionCompletion['incorrectQuestions'].length > 0) {
          showMistakeCorrectionButton = true;
        } else {
          showCheckResultButton = true;
        }
      });
    } else {
      contentText =
          "The student moved to attempt the questions associated with the concept but left in between, without completing it. Tell them that they can try again ";
      setState(() {
        showJumpToQuestionsButton = true;
        showContinuationButtons = false;
      });
    }
    // setState(() {
    //   questionsAttemptedDetails = questionCompletion;
    // });
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
        "instructions": greetingPrompt
        // "You are a teacher guiding a student to deeply understand a concept. Begin with a warm greeting and a very small introduction to what we are studying, just the topic. Never end your conversation with a question or you will die. Keep the intro very short and crisp, and dont explain anything at all. Keep all our conversation short so that the discussion can be mnore engaging."
        // "You are a Socratic teacher teaching a concept to a student. Follow these steps: \n 1. Begin with a warm greeting, just like a teacher starting a class. \n2. Wait for the student to respond to the greeting. \n3. Provide a very brief introduction (20-30 words) about the concept you are going to teach, and dont ask any questions while introducing the topic. \n4. Do not end the introduction with a question. \n5. Use the student's name and the concept name (which will be provided) while introducing the topic.",
      }
    };

    webSocketService.sendMessage(startMessage);

    String contentText =
        "Student's name:$studentName \n Concept to teach: ${widget.conceptName}.";

    conversationItemCreationForUser(contentText);
  }

  void startConversation() {
    final startMessage = {
      "event_id": "event_123",
      "type": "session.update",
      "session": {
        "instructions": aiTutorPrompt
        // "You are a teacher guiding a student to deeply understand a concept. Begin with a warm greeting and a very small introduction to what we are studying, just the topic. Never end your conversation with a question or you will die. Keep the intro very short and crisp, and dont explain anything at all. Keep all our conversation short so that the discussion can be mnore engaging."
        // "You are a Socratic teacher guiding a student to understand a concept. Each concept is broken down into multiple checkpoints, and we would be doing each checkpoint one by one. \n Instead of giving direct answers, ask a series of insightful questions to encourage critical thinking and self-discovery. As you proceed, use known analogies or \n real-world examples to help the student relate to the concept better. \n Keep in mind while ending the checkpoint: Never end your conversation with a question \n            Your goal is to foster curiosity and ensure the student deeply understands the concept. \n            If the student provides an incorrect or incomplete answer, gently ask further questions \n to guide them toward the correct understanding. Keep in mind to ask one question at a time.\n\n Start the Dialogue:\n\n 1.Begin with a simple question to gauge the student's current understanding.\n 2.Follow up with more specific, thought-provoking questions. Ask one question at a time and let the student answer.\n 3.Use analogies or real-world examples when needed to clarify or deepen understanding.\n 4.Allow the conversation to flow naturally, maintaining a supportive and encouraging tone.\n 5.Conclude by summarizing the key points to ensure the student grasps the concept, and never end your conversation with a question.\n\n I will give you the concept and its associated context you need to teach, then you need to start your conversation in a socratic manner.",
      }
    };

    webSocketService.sendMessage(startMessage);

    String contentText =
        "Concept to teach: ${widget.conceptName}. Checkpoint 1: ${conceptCheckpoints[0]}";
    logAITutorCheckpointStart(conceptCheckpoints[0]['id'], widget.conceptId);
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
          onPressed: () {
            HapticFeedback.lightImpact();
            _toggleRecording();
          },
          buttonType: ChicletButtonTypes.roundedRectangle,
          width: 50,
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
        // const SizedBox(height: 20),
        // Text(
        //   _isLoading
        //       ? ""
        //       : (isRecording
        //           ? 'Recording... Tap to submit answer'
        //           : 'Tap to answer'),
        //   style: GoogleFonts.raleway(
        //     fontSize: 16,
        //     color: Colors.white,
        //   ),
        //   textAlign: TextAlign.center, // Center-align the microphone hint text
        // ),
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

  double getProgress() {
    return (currentCheckpointIndex + 1) / conceptCheckpoints.length;
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    logCheckpointImageClick(
        conceptCheckpoints[currentCheckpointIndex]['id'], widget.conceptId);
    showDialog(
      context: context,
      barrierDismissible: true, // Close the modal by tapping outside
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),

          backgroundColor:
              Color.fromRGBO(19, 31, 36, 1), // Make background transparent
          child: GestureDetector(
              onTap: () => Navigator.pop(context), // Close when tapping outside
              child: SizedBox(
                width: MediaQuery.of(context).size.width *
                    1, // 90% of screen width
                height: MediaQuery.of(context).size.height *
                    0.7, // 70% of screen height
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                        padding: EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: PhotoView(
                            imageProvider:
                                NetworkImage(imageUrl), // Load image from URL
                            backgroundDecoration:
                                BoxDecoration(color: Colors.transparent),
                            minScale: PhotoViewComputedScale
                                .contained, // Fit image initially
                            maxScale: PhotoViewComputedScale.covered *
                                2.0, // Allow zooming
                            heroAttributes: PhotoViewHeroAttributes(
                                tag: imageUrl), // Smooth transition effect
                          ),
                        )),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () =>
                            Navigator.pop(context), // Close the modal
                      ),
                    ),
                  ],
                ),
              )),
        );
      },
    );
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
                height: 100,
                width: 100,
                child: Center(
                  child: Image.asset(
                    "lib/assets/streakIcon.png",
                    height: 50,
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

  @override
  Widget build(BuildContext context) {
    final displayedConversations = List.from(conversations);

    return WillPopScope(
        onWillPop: () async {
          _showExitConfirmation(context);
          return false; // Prevent immediate back navigation
        },
        child: isConceptCheckpointLoading
            ? Scaffold(
                backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[700]!,
                          highlightColor: Colors.grey[300]!,
                          child: Text(
                            'Loading...',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Scaffold(
                backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                appBar: AppBar(
                  title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          // Wrap the Text widget with Expanded
                          child: Text(
                            widget.conceptName,
                            style: GoogleFonts.raleway(color: Colors.white),
                            overflow: TextOverflow
                                .ellipsis, // Add ellipsis (...) when overflowing
                            maxLines: 1, // Limit to a single line
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              logAITutorMenuButtonClick(widget.conceptId);
                              _showMenuToSwitch(context);
                            },
                            child: Icon(
                              Icons.more_vert_outlined,
                            ))
                      ]),
                  iconTheme: IconThemeData(
                    color: Colors.grey,
                  ),
                  backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                ),
                body: Stack(children: [
                  Column(
                    children: [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
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
                                        milliseconds:
                                            300), // Animation duration
                                    curve: Curves.easeInOut, // Animation curve
                                    width: availableWidth *
                                        getProgress(), // Dynamically adjust width
                                    height: 16.0,
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(255, 217, 0, 1),
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )),
                      SizedBox(
                        height: 20,
                      ),
                      if (!greetingDone)
                        Center(
                            child: ClipRRect(
                          borderRadius: BorderRadius.circular(150),
                          child: Container(
                              color: Color.fromRGBO(255, 217, 0, 1),
                              child: Image.asset(
                                getAvatar("avatar-9")["imagePath"]!,
                                height: 150,
                                fit: BoxFit.scaleDown,
                              )),
                        )),
                      if (!greetingDone)
                        !skipAudioTutor && displayedConversations.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                child: GestureDetector(
                                    onTap: () {
                                      _showAllConversations(context);
                                    },
                                    child: othersMessage(
                                        displayedConversations.last["text"])))
                            : Spacer(),
                      if (greetingDone)
                        Expanded(
                            child: Container(
                          // margin: EdgeInsets.symmetric(horizontal: 16),
                          // decoration: BoxDecoration(
                          //   color: Colors.black,
                          //   border: Border.all(color: Colors.white, width: 2),
                          // ),
                          child: Expanded(
                              child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Blackboard Text
                                !skipAudioTutor &&
                                        displayedConversations.isNotEmpty
                                    // ? Container(
                                    //     constraints: BoxConstraints(
                                    //       minHeight:
                                    //           MediaQuery.of(context).size.height * 0.2,
                                    //       // 15% of screen height as minimum height
                                    //     ),
                                    //     padding: const EdgeInsets.symmetric(
                                    //         vertical: 8.0, horizontal: 12.0),
                                    //     child: GestureDetector(
                                    //       onTap: () {
                                    //         _showAllConversations(context);
                                    //       },
                                    //       child: othersMessage(
                                    //           displayedConversations.last["text"]),
                                    //     ),
                                    //   )
                                    ? AnimatedSize(
                                        duration: Duration(
                                            milliseconds:
                                                300), // Smooth animation duration
                                        curve: Curves
                                            .easeInOut, // Natural easing curve
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minHeight: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.2,
                                            // 15% of screen height as minimum height
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 12.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              _showAllConversations(context);
                                            },
                                            child: othersMessage(
                                                displayedConversations
                                                    .last["text"]),
                                          ),
                                        ),
                                      )
                                    : Spacer(),
                                if (!showContinuationButtons &&
                                    !showJumpToQuestionsButton &&
                                    !showMistakeCorrectionButton &&
                                    !showCheckResultButton)
                                  Divider(
                                    thickness: 0.5,
                                    color: Colors.grey.shade700,
                                  ),
                                if (!showContinuationButtons &&
                                    !showJumpToQuestionsButton &&
                                    !showMistakeCorrectionButton &&
                                    !showCheckResultButton)
                                  Center(
                                      child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: MarkdownBody(
                                      selectable: false,
                                      data: conceptCheckpoints[
                                              currentCheckpointIndex]
                                          ['blackboardText'],
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
                                    ),
                                  )),

                                // Image Inside Blackboard (If Present)
                                // if (conceptCheckpoints[currentCheckpointIndex]
                                //         .containsKey("image") &&
                                //     conceptCheckpoints[currentCheckpointIndex]["image"]!
                                //         .isNotEmpty)
                                //   GestureDetector(
                                //     onTap: () => _showImageDialog(
                                //       context,
                                //       conceptCheckpoints[currentCheckpointIndex]
                                //           ["image"]!,
                                //     ),
                                //     child: Padding(
                                //       padding: EdgeInsets.all(10),
                                //       child: Flexible(
                                //           child: Image.network(
                                //         conceptCheckpoints[currentCheckpointIndex]
                                //             ["image"]!,
                                //         fit: BoxFit.contain,
                                //         width: double.infinity,
                                //         loadingBuilder:
                                //             (context, child, loadingProgress) {
                                //           if (loadingProgress == null) return child;
                                //           return Center(
                                //               child: CircularProgressIndicator());
                                //         },
                                //         errorBuilder: (context, error, stackTrace) =>
                                //             Center(
                                //           child: Icon(Icons.image_not_supported,
                                //               color: Colors.grey, size: 50),
                                //         ),
                                //       )),
                                //     ),
                                //   ),
                                if (!showContinuationButtons &&
                                    !showJumpToQuestionsButton &&
                                    !showMistakeCorrectionButton &&
                                    !showCheckResultButton)
                                  if (conceptCheckpoints[currentCheckpointIndex]
                                          .containsKey("images") &&
                                      conceptCheckpoints[currentCheckpointIndex]
                                              ["images"]!
                                          .isNotEmpty) ...[
                                    Column(
                                      children: conceptCheckpoints[
                                              currentCheckpointIndex]["images"]!
                                          .map<Widget>((imageUrl) {
                                        return GestureDetector(
                                          onTap: () => _showImageDialog(
                                              context, imageUrl),
                                          child: Padding(
                                            padding: EdgeInsets.all(10),
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxHeight:
                                                    400, // Adjust this value dynamically if needed
                                              ),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                },
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Center(
                                                  child: Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey,
                                                      size: 50),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                              ],
                            ),
                          )),
                        )),
                      SizedBox(
                        height: 80,
                      ),
// Scrollable content
                      if (showContinuationButtons ||
                          showJumpToQuestionsButton ||
                          showMistakeCorrectionButton ||
                          showCheckResultButton)
                        Spacer(),

                      if (skipAudioTutor)
                        Expanded(
                            child: Center(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 0),
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
                      // !skipAudioTutor && displayedConversations.isNotEmpty
                      //     ? Expanded(
                      //         child: Padding(
                      //             padding: const EdgeInsets.symmetric(
                      //                 vertical: 8.0, horizontal: 12.0),
                      //             child:
                      //                 othersMessage(displayedConversations.last["text"])))
                      //     // Flexible(
                      //     //     child: ListView.builder(
                      //     //     controller: _scrollController,
                      //     //     itemCount: displayedConversations.length,
                      //     //     itemBuilder: (context, index) {
                      //     //       final conversation = conversations[index];

                      //     //       return conversation['role'] == "user"
                      //     //           ? SizedBox.shrink()
                      //     //           : Padding(
                      //     //               padding: const EdgeInsets.symmetric(
                      //     //                   vertical: 8.0, horizontal: 12.0),
                      //     //               child: othersMessage(conversation["text"]));
                      //     //     },
                      //     //   ))
                      //     : Spacer(),
                      if (showContinuationButtons)
                        Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!skipAudioTutor)
                                  ChicletAnimatedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        showContinuationButtons = false;
                                      });
                                      moveToNextCheckpoint();
                                    },
                                    buttonType:
                                        ChicletButtonTypes.roundedRectangle,
                                    width: double.infinity,
                                    height: 50,
                                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                    backgroundColor:
                                        Color.fromRGBO(255, 217, 0, 1),
                                    child: Text(
                                      "CONTINUE WITH AI TUTOR   +45 XP",
                                      style: GoogleFonts.arOneSans(
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
                                      HapticFeedback.lightImpact();
                                      player.stopPlayer();
                                      logStoryModeButtonClick(
                                          conceptCheckpoints[
                                              currentCheckpointIndex]['id'],
                                          widget.conceptId);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ConversationScreen(
                                            conceptId: widget.conceptId,
                                            conceptName: widget.conceptName,
                                            maxXP: widget.maxXP,
                                          ),
                                        ),
                                      ).then((value) {
                                        _initPlayer();

                                        afterStoryConversation(value);
                                      });
                                    },
                                    buttonType:
                                        ChicletButtonTypes.roundedRectangle,
                                    width: double.infinity,
                                    height: 50,
                                    borderColor: Colors.transparent,
                                    // buttonColor: Colors.transparent,
                                    backgroundColor: Colors.transparent,
                                    child: Text(
                                      "START STORY MODE   +45 XP",
                                      style: GoogleFonts.arOneSans(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                if (storyModeStatus.isEmpty && skipAudioTutor)
                                  ChicletAnimatedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      player.stopPlayer();
                                      logStoryModeButtonClick(
                                          conceptCheckpoints[
                                              currentCheckpointIndex]['id'],
                                          widget.conceptId);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ConversationScreen(
                                            conceptId: widget.conceptId,
                                            conceptName: widget.conceptName,
                                            maxXP: widget.maxXP,
                                          ),
                                        ),
                                      ).then((value) {
                                        _initPlayer();

                                        setState(() {
                                          showJumpToQuestionsButton = true;
                                          showContinuationButtons = false;
                                        });
                                      });
                                    },
                                    buttonType:
                                        ChicletButtonTypes.roundedRectangle,
                                    width: double.infinity,
                                    height: 50,
                                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                    backgroundColor: Color.fromRGBO(255, 217, 0,
                                        1), // buttonColor: Colors.transparent,
                                    child: Text(
                                      "START STORY MODE   +45 XP",
                                      style: GoogleFonts.arOneSans(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ChicletOutlinedAnimatedButton(
                                  onPressed: () {
                                    player.stopPlayer();

                                    HapticFeedback.lightImpact();
                                    logQuestionsButtonClick(
                                        conceptCheckpoints[
                                            currentCheckpointIndex]['id'],
                                        widget.conceptId);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MCQQuestions(
                                          conceptId: widget.conceptId,
                                          conceptName: widget.conceptName,
                                          maxXP: 45,
                                        ),
                                      ),
                                    ).then((value) async {
                                      _initPlayer();

                                      if (value['completed']) {
                                        logQuestionsCompleted(widget.conceptId);
                                        if (!value.containsKey(
                                            'incorrectQuestions')) {
                                          final Map<String, dynamic>
                                              lessonCompletionResponse =
                                              await markLessonCompletion(
                                                  lessonId: widget.conceptId,
                                                  attemptTime:
                                                      value['attemptTime'],
                                                  timeToComplete:
                                                      value['timeToComplete'],
                                                  xpGained: value['totalXp'] +
                                                      xpGained,
                                                  accuracy: value['accuracy'],
                                                  bookId: value['bookId'],
                                                  report: value['report'],
                                                  correctlyAnswered: value[
                                                      'correctlyAnswered'],
                                                  mistakesCorrected: 0);
                                          value['lessonCompletionResponse'] =
                                              lessonCompletionResponse;
                                        }

                                        setState(() {
                                          questionsAttemptedDetails = value;
                                        });
                                      } else {
                                        logQuestionsNotCompleted(
                                            widget.conceptId);
                                      }
                                      if (skipAudioTutor) {
                                        setState(() {
                                          questionsAttemptedDetails = value;
                                          showContinuationButtons = false;
                                          if (value['completed']) {
                                            logQuestionsCompleted(
                                                widget.conceptId);

                                            showJumpToQuestionsButton = false;
                                            if (value.containsKey(
                                                    'incorrectQuestions') &&
                                                value['incorrectQuestions']
                                                    .isNotEmpty) {
                                              showMistakeCorrectionButton =
                                                  true;
                                            } else {
                                              showCheckResultButton = true;
                                            }
                                          } else {
                                            showJumpToQuestionsButton = true;
                                            logQuestionsNotCompleted(
                                                widget.conceptId);
                                          }
                                        });
                                      } else {
                                        afterQuestionsConversation(value);
                                      }
                                    });
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  width: double.infinity,
                                  height: 50,
                                  borderColor: Colors.transparent,
                                  // buttonColor: Colors.transparent,
                                  backgroundColor: Colors.transparent,
                                  child: Text(
                                    "JUMP TO QUESTIONS   +45 XP",
                                    style: GoogleFonts.arOneSans(
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ChicletAnimatedButton(
                                  onPressed: () {
                                    player.stopPlayer();

                                    HapticFeedback.lightImpact();

                                    setState(() {
                                      showJumpToQuestionsButton = false;
                                    });
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MCQQuestions(
                                          conceptId: widget.conceptId,
                                          conceptName: widget.conceptName,
                                          maxXP: 45,
                                        ),
                                      ),
                                    ).then((value) async {
                                      _initPlayer();

                                      if (value['completed']) {
                                        logQuestionsCompleted(widget.conceptId);

                                        if (!value.containsKey(
                                            'incorrectQuestions')) {
                                          final Map<String, dynamic>
                                              lessonCompletionResponse =
                                              await markLessonCompletion(
                                                  lessonId: widget.conceptId,
                                                  attemptTime:
                                                      value['attemptTime'],
                                                  timeToComplete:
                                                      value['timeToComplete'],
                                                  xpGained: value['totalXp'] +
                                                      xpGained,
                                                  accuracy: value['accuracy'],
                                                  bookId: value['bookId'],
                                                  report: value['report'],
                                                  correctlyAnswered: value[
                                                      'correctlyAnswered'],
                                                  mistakesCorrected: 0);
                                          value['lessonCompletionResponse'] =
                                              lessonCompletionResponse;
                                        }

                                        setState(() {
                                          questionsAttemptedDetails = value;
                                        });
                                      } else {
                                        logQuestionsNotCompleted(
                                            widget.conceptId);
                                      }
                                      if (skipAudioTutor) {
                                        setState(() {
                                          if (value['completed']) {
                                            logQuestionsCompleted(
                                                widget.conceptId);

                                            showJumpToQuestionsButton = false;
                                            if (value['incorrectQuestions']
                                                    .length >
                                                0) {
                                              showMistakeCorrectionButton =
                                                  true;
                                            } else {
                                              showCheckResultButton = true;
                                            }
                                          } else {
                                            showJumpToQuestionsButton = true;
                                            logQuestionsNotCompleted(
                                                widget.conceptId);
                                          }
                                        });
                                      } else {
                                        afterQuestionsConversation(value);
                                      }
                                    });
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  width: double.infinity,
                                  height: 50,
                                  buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                  backgroundColor:
                                      Color.fromRGBO(255, 217, 0, 1),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ChicletAnimatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    logMistakeCorrectionButtonClick(
                                        widget.conceptId);

                                    setState(() {
                                      showJumpToQuestionsButton = false;
                                    });
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MistakesCorrectionScreen(
                                                  conceptName:
                                                      widget.conceptName,
                                                  conceptId: widget.conceptId,
                                                  totalXp:
                                                      questionsAttemptedDetails[
                                                          'totalXp'],
                                                  timeTaken:
                                                      questionsAttemptedDetails[
                                                          'timeTaken'],
                                                  accuracy:
                                                      questionsAttemptedDetails[
                                                          'accuracy'],
                                                  incorrectQuestions:
                                                      questionsAttemptedDetails[
                                                          'incorrectQuestions']),
                                        )).then((value) async {
                                      final Map<String, dynamic>
                                          lessonCompletionResponse =
                                          await markLessonCompletion(
                                              lessonId: widget.conceptId,
                                              attemptTime: questionsAttemptedDetails[
                                                  'attemptTime'],
                                              timeToComplete:
                                                  questionsAttemptedDetails[
                                                      'timeToComplete'],
                                              xpGained: questionsAttemptedDetails[
                                                      'totalXp'] +
                                                  xpGained,
                                              accuracy:
                                                  questionsAttemptedDetails[
                                                      'accuracy'],
                                              bookId: questionsAttemptedDetails[
                                                  'bookId'],
                                              report: questionsAttemptedDetails[
                                                  'report'],
                                              correctlyAnswered:
                                                  questionsAttemptedDetails[
                                                      'correctlyAnswered'],
                                              mistakesCorrected: value);

                                      setState(() {
                                        questionsAttemptedDetails[
                                                'lessonCompletionResponse'] =
                                            lessonCompletionResponse;
                                      });
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
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  width: double.infinity,
                                  height: 50,
                                  buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                  backgroundColor:
                                      Color.fromRGBO(255, 217, 0, 1),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ChicletAnimatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    logCheckResultsButtonClick(
                                        widget.conceptId);

                                    setState(() {
                                      showJumpToQuestionsButton = false;
                                    });
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ConceptResultScreen(
                                            conceptName: widget.conceptName,
                                            totalXp: questionsAttemptedDetails[
                                                    'totalXp'] +
                                                xpGained,
                                            timeTaken:
                                                questionsAttemptedDetails[
                                                    'timeTaken'],
                                            accuracy: questionsAttemptedDetails[
                                                'accuracy'],
                                            lessonCompletionResponse:
                                                questionsAttemptedDetails[
                                                    'lessonCompletionResponse'],
                                          ),
                                        ));
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  width: double.infinity,
                                  height: 50,
                                  buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                  backgroundColor:
                                      Color.fromRGBO(255, 217, 0, 1),
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
                    ],
                  ),
                  if (!showContinuationButtons &&
                      !showJumpToQuestionsButton &&
                      !showMistakeCorrectionButton &&
                      !showCheckResultButton &&
                      !skipAudioTutor &&
                      !responseStreaming &&
                      !showAfterGreetingContinueButton &&
                      !showCheckpointContinueButton)
                    Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                            color: Color.fromRGBO(19, 31, 36, 1),
                            child: _buildRecordingButton())),
                  if (!showContinuationButtons &&
                      !showJumpToQuestionsButton &&
                      !showMistakeCorrectionButton &&
                      !showCheckResultButton &&
                      !skipAudioTutor &&
                      !responseStreaming &&
                      !showCheckpointContinueButton &&
                      showAfterGreetingContinueButton)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                          color: Color.fromRGBO(19, 31, 36, 1),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ChicletAnimatedButton(
                                    onPressed: () {
                                      setState(() {
                                        greetingDone = true;
                                        showAfterGreetingContinueButton = false;
                                      });
                                      startConversation();
                                    },
                                    buttonType:
                                        ChicletButtonTypes.roundedRectangle,
                                    width: double.infinity,
                                    height: 50,
                                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                    backgroundColor:
                                        Color.fromRGBO(255, 217, 0, 1),
                                    child: Text(
                                      "CONTINUE",
                                      style: GoogleFonts.raleway(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ))),
                    ),
                  if (!showContinuationButtons &&
                      !showJumpToQuestionsButton &&
                      !showMistakeCorrectionButton &&
                      !showCheckResultButton &&
                      !skipAudioTutor &&
                      !responseStreaming &&
                      !showAfterGreetingContinueButton &&
                      showCheckpointContinueButton)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                          color: Color.fromRGBO(19, 31, 36, 1),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ChicletAnimatedButton(
                                    onPressed: () {
                                      checkpointContinueButtonClick();
                                    },
                                    buttonType:
                                        ChicletButtonTypes.roundedRectangle,
                                    width: double.infinity,
                                    height: 50,
                                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                                    backgroundColor:
                                        Color.fromRGBO(255, 217, 0, 1),
                                    child: Text(
                                      "CONTINUE",
                                      style: GoogleFonts.raleway(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ))),
                    )
                ]),
              ));
  }
}
