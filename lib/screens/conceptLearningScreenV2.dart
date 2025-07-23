//final updated code

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:bubble_box/bubble_box.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:chiclet/chiclet.dart';
import 'package:confetti/confetti.dart';
import 'package:eureka_app/apis/checkConceptCheckpointCompleted.dart';
import 'package:eureka_app/apis/checkGreetingsAndIntroCompleted.dart';
import 'package:eureka_app/apis/createTutorAssistPrompt.dart';
import 'package:eureka_app/apis/fetchConceptDetails.dart';
import 'package:eureka_app/apis/fetchLanguagesAndVoices.dart';
import 'package:eureka_app/apis/getAITutorPrompts.dart';
import 'package:eureka_app/apis/getAITutorPromptsV2.dart';
import 'package:eureka_app/apis/getAdditionalPrompts.dart';
import 'package:eureka_app/apis/markLessonCompletion.dart';
import 'package:eureka_app/apis/saveConceptConversations.dart';
import 'package:eureka_app/apis/saveTokenUsage.dart';
import 'package:eureka_app/apis/saveUserFeedback.dart';
import 'package:eureka_app/apis/transcribeAudio.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
import 'package:eureka_app/screens/conceptStartScreen.dart';
import 'package:eureka_app/screens/mistakesCorrectionScreen.dart';
import 'package:eureka_app/services/webSocketService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/utils/tutorAvatars.dart';
import 'package:eureka_app/widgets/conceptResultScreen.dart';
import 'package:eureka_app/widgets/conversationScreen.dart';
import 'package:eureka_app/widgets/languageAndVoiceSelection.dart';
import 'package:eureka_app/widgets/lessonCheckpoints.dart';
import 'package:eureka_app/widgets/mcqQuestionsWidget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';

// import 'package:wakelock_plus/wakelock_plus.dart';

class ConceptLearningScreenV2 extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;
  final String name;
  final String subject;
  final int standard;
  final String? selectedLanguage;
  final String? selectedVoice;
  final Map<String, dynamic>? tutorSelected;

  const ConceptLearningScreenV2(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.maxXP,
      required this.name,
      required this.subject,
      required this.standard,
      this.selectedLanguage,
      this.selectedVoice,
      this.tutorSelected})
      : super(key: key);
  @override
  _ConceptLearningScreenState createState() => _ConceptLearningScreenState();
}

class _ConceptLearningScreenState extends State<ConceptLearningScreenV2> {
  late WebSocketService webSocketService;
  late WebSocketService webSocketForRealTimeTranscription;
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
  String base64AudioString = "";
  String userPrompt =
      "You are a world-class, real-time AI tutor designed to teach students in Grades 6–10 with unmatched clarity, patience, and adaptability.\n\n🎭 ROLE CLARITY:\n- You are not just a content explainer. You are a deeply thoughtful, emotionally intelligent *Socratic tutor*.\n- You teach by asking questions, building from the student’s existing ideas, and guiding discovery — never by dumping information.\n- You are kind, curious, and humble — you treat the student like a peer in thought, not a passive listener.\n\n🎯 CORE OBJECTIVE:\nYour job is to ensure the student *deeply understands* the concept through guided conversation, starting from zero assumptions.\nNever assume prior knowledge. Never rush to explain. *Earn every concept.*\n\n🧠 TEACHING PROCESS (STRUCTURE TO FOLLOW):\n\n1. 🔍 *Start With Conversation, Not Concepts*\n   - Begin with a natural, real-world question that might connect to the concept (e.g., a feeling, memory, oddity, or daily habit).\n   - Use curiosity hooks, story recall, “have you ever” questions, or sense-based prompts.\n\n2. 🔄 *Pivot Smoothly If Needed*\n   - If the first anchor doesn’t land (e.g. short response), gently pivot to another.\n   - You may try body-related cues, personal habits, games, feelings, or mistakes.\n\n3. 🎯 *Once Anchor Is Found → Route to Teaching Technique*\n   - Based on the student’s response, choose the best-fit teaching method:\n     - First-principles breakdown\n     - Real-world analogy\n     - Story-based concept reveal\n     - Mental model or system analogy\n     - Socratic puzzle-solving\n     - Interest-aligned example\n   - Deliver the concept through *conversation*, not lecture.\n\n4. 🧪 *Use Micro-Check Questions Midway*\n   - Ask the student to predict, explain, or rephrase in their own words\n   - Use “what if” challenges, small scenario questions, or quick recaps\n\n5. 🧽 *Explain Every Term*\n   - Never assume a word is understood. Define everything the moment it appears.\n   - Examples: “enzyme”, “ion”, “valency”, “haemoglobin”, “emulsify”, “digest”\n\n6. ✅ *Wrap Up With Reflection*\n   - Ask the student to explain the concept back to you in their words\n   - Offer a quick “myth” or “what if” to lock the learning\n   - Then ask if they’d like to:\n     - Go deeper\n     - Do a challenge\n     - Or stop for now\n\n⚠️ WHAT NOT TO DO:\n- ❌ Don’t deliver textbook-style explanations\n- ❌ Don’t assume they’ve heard a term before\n- ❌ Don’t lecture or list without engagement\n- ❌ Don’t ask multiple questions at once\n\nBegin by engaging the student naturally and warmly.\nYou do not know what they know yet — so start with curiosity.";
  bool responseStarted = false;
  bool responseCompleted = false;
  int responseDelayRetries = 0;
  String lastMessageAudio = "";
  late List<Map<String, dynamic>> conceptCheckpoints;
  String previousSessionHandle = "";
  bool sessionResumed = false;
  bool goAwayEventReceived = false;
  String selectedLanguage = "en-US";
  String selectedVoice = "Zephyr";
  late DateTime lessonStartTime;
  int timeTakenToCompleteLessonWithAiTutor = 0;
  late Map<String, dynamic> selectedTutor = {'id': "persona-1"};
  late Map<String, dynamic> additionalPrompts = {};
  bool firstLesson = true;
  bool wasFirstLesson = true;
  String tutorName = "Tuto Prime";
  bool showDots = true;
  late ConfettiController _confettiController;

  // Map<String, String> languageOptions = {
  //   "en-US": "English",
  //   "hi-IN": "Hinglish"
  // };
  // Map<String, String> voiceOptions = {
  //   "Puck": "Puck",
  //   "Charon": "Charon",
  //   "Kore": "Kore",
  //   "Fenrir": "Fenrir",
  //   "Aoede": "Aoede",
  //   "Leda": "Leda",
  //   "Orus": "Orus",
  //   "Zephyr": "Zephyr"
  // };

  late Map<String, String> languageOptions = {};
  late Map<String, String> voiceOptions = {};

  Map<String, dynamic> usage = {};

  late String conceptConversationsKey = "";

  late final prefs;

  Future<void> loadLanguageAndVoiceOptions() async {
    try {
      final data = await fetchLanguagesAndVoices();

      final List<dynamic> languages = data['languages'] ?? [];
      final List<dynamic> voices = data['voices'] ?? [];

      languageOptions = {for (var lang in languages) lang['id']: lang['name']};

      voiceOptions = {for (var voice in voices) voice['id']: voice['name']};
      final defaultLang = languages.firstWhere(
        (lang) => lang['defaultLanguage'] == true,
        orElse: () => null,
      );

      if (defaultLang != null) {
        selectedLanguage = defaultLang['id'];
      }

      setState(() {
        // trigger UI update if needed
      });
    } catch (e) {
      print("Error loading language and voice options: $e");
    }
  }

  Future<void> getConceptDetails() async {
    try {
      Map<String, dynamic>? conceptDetails =
          await fetchConceptDetails(conceptId: widget.conceptId);

      setState(() {
        conceptCheckpoints = (conceptDetails?["conceptCheckpoints"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        isConceptCheckpointLoading = false;
      });
    } catch (error) {
      print("Error fetching concept details: $error");
    }
  }

  Future<void> fetchAdditionalPrompts() async {
    try {
      Map<String, dynamic>? additionalPromptsData =
          await getAdditionalPrompts();
      // final profileData = await getProfile();

      setState(() {
        additionalPrompts = additionalPromptsData;
        // aiTutorPrompt =
        //     aiTutorPrompts['aiTutorPrompt$selectedLanguageName']['content'];
      });
    } catch (error) {
      print("Error fetching additional prompts: $error");
    }
  }

  Future<void> fetchAITutorPrompts({bool fetchPersonaPrompt = true}) async {
    try {
      String selectedLanguageName =
          languageOptions[selectedLanguage] ?? "English";
      Map<String, dynamic>? aiTutorPrompts =
          await getAITutorPrompts(language: selectedLanguageName);
      // final profileData = await getProfile();

      setState(() {
        greetingPrompt =
            aiTutorPrompts['aiTutorGreetings$selectedLanguageName']['content'];
        // aiTutorPrompt =
        //     aiTutorPrompts['aiTutorPrompt$selectedLanguageName']['content'];
      });
      if (fetchPersonaPrompt) {
        await fetchAITutorPromptsV2(
            selectedTutor.isEmpty ? "persona-1" : selectedTutor['id']);
      }
    } catch (error) {
      print("Error fetching tutor prompts: $error");
    }
  }

  Future<void> fetchAITutorPromptsV2(String teacherId) async {
    try {
      Map<String, dynamic>? aiTutorPromptFromDB = await getAITutorPromptsV2(
          language: selectedLanguage, teacherId: teacherId);
      // final profileData = await getProfile();

      setState(() {
        aiTutorPrompt = aiTutorPromptFromDB['content'];
        // tutorName = aiTutorPromptFromDB["name"];
      });
    } catch (error) {
      print("Error fetching ai prompt: $error");
    }
  }

  void startWebsocket() async {
    webSocketService = WebSocketService();
    // webSocketService = WebSocketServiceForOpenai();

    // webSocketService.useOpenAI = false;
    webSocketService.useGemini = true;
    if (webSocketService.useGemini) {
      webSocketService.onMessageReceived = onMessageReceivedForGemini;
    } else {
      webSocketService.onMessageReceived = onMessageReceived;
    }
    await webSocketService.initialize();
    webSocketService.connect();
  }

  void startWebsocketForTranscription() {
    webSocketForRealTimeTranscription = WebSocketService();
    // webSocketService = WebSocketServiceForOpenai();

    // webSocketService.useOpenAI = false;

    webSocketForRealTimeTranscription.onMessageReceived = onMessageReceived;
    webSocketForRealTimeTranscription.connect();
  }

  void setLanguageAndVoice() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("aiTutorLanguage")) {
      selectedLanguage = await prefs.getString("aiTutorLanguage") ?? "en-US";
    }
    if (prefs.containsKey("aiTutorVoice")) {
      selectedVoice = await prefs.getString("aiTutorVoice") ?? "Zephyr";
    }
    if (prefs.containsKey("firstLesson")) {
      firstLesson = await prefs.getBool("firstLesson") ?? true;
      wasFirstLesson = firstLesson;
    }
  }

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // WakelockPlus.enable();

    studentName = widget.name;
    _scrollController = ScrollController();
    startWebsocket();
    loadLanguageAndVoiceOptions();
    setLanguageAndVoice();
    fetchAdditionalPrompts();
    lessonStartTime = DateTime.now();
    // startWebsocketForTranscription();
    player = FlutterSoundPlayer();

    _recorder = FlutterSoundRecorder();

    _initializeRecorder();
    _initPlayer();
    // selectedLanguage = widget.selectedLanguage ?? "en-US";
    // selectedVoice = widget.selectedVoice ?? "Zephyr";
    selectedTutor = widget.tutorSelected ?? {};
    if (selectedTutor.isNotEmpty) {
      tutorName = selectedTutor['name'];
    }

    conceptConversationsKey =
        "${widget.name}_${widget.conceptId}_${DateTime.now().millisecondsSinceEpoch}";

    // startConversation();
    // getConceptDetails();
    getConceptDetails().then((_) {
      fetchAITutorPrompts().then((_) {
        if (webSocketService.useGemini) {
          sessionConnect();
          // startSessionForRealTimeTranscription();
        } else {
          greetingAndIntroConversation();
        }
      });
    });

    webSocketService.onConnectionError = (reason) {
      if (reason == "1011") {
        // Small delay can help prevent race conditions
        Future.delayed(Duration(milliseconds: 200), () {
          sessionConnect();
        });
      } else if (reason == "Service unavailable") {
        Future.delayed(Duration(milliseconds: 200), () {
          resumeExistingSession();
        });
      } else if (reason == "Deadline Expired") {
        Future.delayed(Duration(milliseconds: 200), () {
          resumeExistingSession();
        });
      } else {
        Future.delayed(Duration(milliseconds: 200), () {
          resumeExistingSession();
        });
      }
    };
  }

  void _startResponseMonitor() {
    responseMonitorTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (lastResponseTime != null) {
        Duration elapsed = DateTime.now().difference(lastResponseTime!);

        if (elapsed.inSeconds > 5 &&
            responseStreaming &&
            responseStarted &&
            !responseCompleted &&
            !skipAudioTutor) {
          // Change threshold if needed
          print("⚠️ Response delay detected: ${elapsed.inSeconds} seconds");
          responseDelayRetries += 1;
          if (responseDelayRetries > 4) {
            _handleResponseDelay();
          } else {
            print("message sent after response delay");
            responseStreaming = false;
            responseStarted = false;
            lastResponseTime = DateTime.now();
            sendAudioResponseForGemini(lastMessageAudio, "");
          }
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
                        "CONTINUE WITH AI TUTOR   +${widget.maxXP ~/ 2} XP",
                        style: GoogleFonts.arOneSans(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  SizedBox(height: 12),
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
                            maxXP: widget.maxXP ~/ 2,
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
                      "JUMP TO QUESTIONS   +${widget.maxXP ~/ 2} XP",
                      style: GoogleFonts.arOneSans(
                        color: Colors.red,
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
            selectedTutor.isNotEmpty
                ? getTutorAvatar(selectedTutor['avatar'])["imagePath"]!
                : getTutorAvatar("tutoprime")["imagePath"]!,
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

  Widget loadingMessage(final conversation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (greetingDone)
          Image.asset(
            selectedTutor.isNotEmpty
                ? getTutorAvatar(selectedTutor['avatar'])["imagePath"]!
                : getTutorAvatar("tutoprime")["imagePath"]!,
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: Lottie.asset(
                        "lib/assets/animations/3-dots.json",
                        fit: BoxFit.cover,
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
    // WakelockPlus.disable();
    webSocketService.disconnect();
    responseMonitorTimer?.cancel();
    _recorder?.closeRecorder();
    if (player.isPlaying) {
      player.stopPlayer();
    }
    player.closePlayer();
    _confettiController.dispose();

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

  Future<void> onMessageReceivedForGemini(dynamic message) async {
    print("respones received");
    // print("responseStreaming top level: $responseStreaming");

    final stringMessage = utf8.decode(message);

    final Map<String, dynamic> data = jsonDecode(stringMessage);

    if (data.containsKey("usageMetadata")) {
      setState(() {
        usage = data["usageMetadata"];
      });
      saveTokenUsage(
          tokenUsageData: data["usageMetadata"], conceptId: widget.conceptId);
    }
    if (data.containsKey("setupComplete") && !sessionResumed) {
      if (!greetingDone) {
        greetingAndIntroConversationForGemini();
      } else {
        startConversationWithGemini();
      }
      return;
    } else if (data.containsKey("serverContent")) {
      Map<String, dynamic> serverContent = data["serverContent"];
      if (serverContent.containsKey("generationComplete") &&
          serverContent["generationComplete"]) {
        print("Conversation complete");
        // String text = await transcribeBase64Audio(base64AudioString);
        // setState(() {
        //   base64AudioString = "";
        // });
        responseStreaming = false;
        responseCompleted = true;
        conversationText = "";
        if (goAwayEventReceived) {
          resumeExistingSession();
        }

        Uint8List silence = generateSilence(durationMs: 1000); // 300ms silence
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
      } else if (serverContent.containsKey("turnComplete") &&
          serverContent["turnComplete"]) {
        lastResponseTime = DateTime.now();
        saveConceptConversations(
            conversationsKey: conceptConversationsKey,
            conversations: conversations,
            conceptId: widget.conceptId,
            language: selectedLanguage);
        return;
      } else if (serverContent.containsKey("modelTurn")) {
        //case for text response
        // print(
        //     "Conversation: ${serverContent["modelTurn"]["parts"][0]["text"]}");

        // for audio response
        responseStreaming = true;
        responseStarted = true;
        // print("responseStreaming: $responseStreaming");
        lastResponseTime = DateTime.now();

        // print(serverContent["modelTurn"]["parts"][0]["inlineData"]["mimeType"]);

        // Append conversation text
        String base64Audio =
            serverContent["modelTurn"]["parts"][0]["inlineData"]["data"] ?? "";
        if (base64Audio.isNotEmpty && _isPlayerReady && !isMuted) {
          base64AudioString += base64Audio;
          // transcribeBase64Audio(base64Audio);
          Uint8List rawData = base64Decode(base64Audio);
          // Send the chunk into the audio stream
          player.foodSink?.add(FoodData(rawData));
        }
      } else if (serverContent.containsKey("outputTranscription")) {
        String deltaText = serverContent["outputTranscription"]["text"] ?? "";
        setState(() {
          conversationText += deltaText;
          showDots = false;
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
      } else {
        print("server content $serverContent");
      }
    } else if (data.containsKey("toolCall")) {
//       {
//   "toolCall": {
//     "functionCalls": [
//       {
//         "name": "skip_ahead",
//         "args": {},
//         "id": "function-call-..."
//       }
//     ]
//   }
// }
      final toolCall = data["toolCall"];
      final functionCalls = toolCall["functionCalls"];

      for (final call in functionCalls) {
        final toolName = call["name"];

        switch (toolName) {
          case "celebrate":
            // _triggerConfetti(type, message);
            print("celebrate");
            _confettiController.play();
            break;

          case "show_encouragement":
            // _showEncouragementOverlay(type, message);
            break;

          case "skip_ahead":
            completedCheckpointIndexes.add(currentCheckpointIndex);
            setState(() {
              showCheckpointContinueButton = true;
            });
            break;

          default:
            print("⚠️ Unknown tool: $toolName");
        }
      }

      // moveToNextCheckpoint();
    } else if (data.containsKey("sessionResumptionUpdate")) {
      Map<String, dynamic> sessionResumtionUpdate =
          data["sessionResumptionUpdate"];

      if (sessionResumtionUpdate.containsKey("newHandle")) {
        previousSessionHandle = data["sessionResumptionUpdate"]["newHandle"];
      }
    } else if (data.containsKey("goAway")) {
      // if (data["sessionResumptionUpdate"].contains("timeLeft")) {
      goAwayEventReceived = true;
      // print("restarting websocket due to go away");
      // webSocketService.disconnect();
      // startWebsocket();
      // resumeSession(previousSessionHandle);
      // }
    } else {
      print(data);
    }
  }

  void resumeExistingSession() {
    goAwayEventReceived = false;
    webSocketService.disconnect();
    print("restarting websocket due to go away");

    // startWebsocket();
    webSocketService.connect();
    resumeSession(previousSessionHandle);
  }

  Future<File> convertRawPCMToWAV(Uint8List pcmData,
      {int sampleRate = 24000, int numChannels = 1, int byteRate = 2}) async {
    int bytePerSample = byteRate; // 2 bytes = 16 bits
    int totalAudioLen = pcmData.length;
    int totalDataLen = totalAudioLen + 36;
    int byteRateTotal = sampleRate * numChannels * bytePerSample;

    final header = BytesBuilder();
    header.add(ascii.encode('RIFF'));
    header.add(_intToBytes(totalDataLen, 4));
    header.add(ascii.encode('WAVE'));
    header.add(ascii.encode('fmt '));
    header.add(_intToBytes(16, 4)); // Subchunk1Size for PCM
    header.add(_intToBytes(1, 2)); // AudioFormat = 1 (PCM)
    header.add(_intToBytes(numChannels, 2));
    header.add(_intToBytes(sampleRate, 4));
    header.add(_intToBytes(byteRateTotal, 4));
    header.add(_intToBytes(numChannels * bytePerSample, 2)); // BlockAlign
    header.add(_intToBytes(bytePerSample * 8, 2)); // BitsPerSample
    header.add(ascii.encode('data'));
    header.add(_intToBytes(totalAudioLen, 4));

    // Combine header + PCM data
    final wavData = BytesBuilder();
    wavData.add(header.toBytes());
    wavData.add(pcmData);

    final tempDir = await getTemporaryDirectory();
    final wavFile = File("${tempDir.path}/converted_audio.wav");
    await wavFile.writeAsBytes(wavData.toBytes(), flush: true);
    return wavFile;
  }

  List<int> _intToBytes(int value, int byteCount) {
    final bytes = <int>[];
    for (int i = 0; i < byteCount; i++) {
      bytes.add((value >> (8 * i)) & 0xFF);
    }
    return bytes;
  }

  Future<String> transcribeBase64Audio(String base64Audio) async {
    try {
      // Decode base64 to bytes
      Uint8List bytes = base64Decode(base64Audio);

      // Write to temp file
      File wavFile = await convertRawPCMToWAV(bytes);

      // Proceed with transcription
      String text = await transcribeAudio(wavFile);
      print("Transcript: $text");
      return text;
    } catch (e) {
      print("Error in transcribeBase64Audio: $e");
    }
    return "";
  }

  Future<void> onMessageReceived(dynamic message) async {
    final data = jsonDecode(message);
    print("respones received GPT");

    if (data['type'] == 'response.text.delta') {
      // if (data['type'] == 'response.audio_transcript.delta') {
      String deltaText = data['delta'] ?? "";
      print("detta text : $deltaText");

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
      print("audio respones");
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
      // Uint8List silence = generateSilence(durationMs: 1500); // 300ms silence
      // player.foodSink?.add(FoodData(silence));
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
    // bool greetingsCompleted = result['greetingsCompleted'] ?? false;
    bool greetingsCompleted = true;

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

    // conversationItemCreationForUser(contentText);
    sendConversationItemToGemini(contentText);

    setState(() {
      showContinuationButtons = true;
    });
  }

  void moveToNextCheckpoint() async {
    if (completedCheckpointIndexes.contains(currentCheckpointIndex)) {
      setState(() {
        showDots = true;
      });
      logAITutorCheckpointEnd(conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId, currentCheckpointIndex + 1);

      currentCheckpointIndex += 1;

      const additionalTextForNextCheckpoints =
          " Moving to next checkpoint of the concept.";
      final checkpoint = conceptCheckpoints[currentCheckpointIndex];
      final contentText = prepareContextForCheckpoint(
          checkpoint, currentCheckpointIndex + 1,
          nextCheckpointAdditionalPrompt: additionalTextForNextCheckpoints);

      final images = checkpoint['images'] as List<dynamic>? ?? [];
      final imageParts = await prepareImageContextForCheckpoint(images);

      logAITutorCheckpointStart(
          conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId,
          currentCheckpointIndex + 1);

      sendConversationItemWithImagesToGemini(contentText, imageParts);
    } else {
      String contentText = "Start from where we have left";

      // conversationItemCreationForUser(contentText);
      sendConversationItemToGemini(contentText);
    }
  }

  void movingToQuestionConversation() {
    setState(() {
      showDots = true;
    });
    String contentText =
        "Now all checkpoints have been completed. Ask user to move to questions so test their understanding.";

    // conversationItemCreationForUser(contentText);
    sendConversationItemToGemini(contentText);

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

    if (currentCheckpointIndex == conceptCheckpoints.length - 1) {
      setState(() {
        xpGained += 45;
        allCheckpointsCompleted = true;
      });
      logAITutorCheckpointEnd(conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId, currentCheckpointIndex + 1);
      saveConceptConversations(
          conversationsKey: conceptConversationsKey,
          conversations: conversations,
          conceptId: widget.conceptId,
          language: selectedLanguage);
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
    // conversationItemCreationForUser(contentText);
    sendConversationItemToGemini(contentText);
  }

  void afterQuestionsConversation(Map<String, dynamic> questionCompletion) {
    String contentText = "";
    setState(() {
      showDots = true;
    });
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
          "The student moved to attempt the questions associated with the concept but left in between, without completing it. Tell them that they can try again whenever they feel like. And dont start them teaching anything. Keep the conversation natural like you are directly tellin it to the student. ";
      setState(() {
        showJumpToQuestionsButton = true;
        showContinuationButtons = false;
      });
    }
    // setState(() {
    //   questionsAttemptedDetails = questionCompletion;
    // });
    // conversationItemCreationForUser(contentText);
    sendConversationItemToGemini(contentText);
  }

  void afterMistakesCorrectionConversation() {
    setState(() {
      showDots = true;
    });
    String contentText =
        "Now the student has completed the questions and corrected their mistakes too, associated with the concept. Congratulate the student, and ask them to check their result.";
    setState(() {
      showMistakeCorrectionButton = false;
      showCheckResultButton = true;
    });
    // conversationItemCreationForUser(contentText);
    sendConversationItemToGemini(contentText);
  }

  void greetingAndIntroConversation() {
    final startMessage = {
      "event_id": "event_123_greeting",
      "type": "session.update",
      "session": {"instructions": greetingPrompt}
    };

    webSocketService.sendMessage(startMessage);

    String contentText =
        "Student's name:$studentName \n Concept to teach: ${widget.conceptName}.";

    conversationItemCreationForUser(contentText);
  }

  void sessionConnect() {
    setState(() {
      showDots = true;
    });
    final sessionCreateMessage = {
      "setup": {
        // "model": "models/gemini-2.0-flash-live-preview-04-09",

        "model": "models/gemini-2.5-flash-preview-native-audio-dialog",
        "generationConfig": {
          // "temperature": 0.1,
          "responseModalities": ["AUDIO"],
          // "enableAffectiveDialog": true,
          "speechConfig": {
            "languageCode": selectedLanguage,
            "voiceConfig": {
              "prebuiltVoiceConfig": {"voiceName": selectedVoice}
            }
          }
        },
        "systemInstruction": {
          "parts": [
            {"text": greetingPrompt}
          ]
        },
        "realtimeInputConfig": {
          "automaticActivityDetection": {"disabled": true}
        },
        "outputAudioTranscription": {},
        "contextWindowCompression": {"slidingWindow": {}}
      }
    };
    webSocketService.sendMessage(sessionCreateMessage);
  }

  double getRandomTemperature() {
    final random = Random();
    int step = random.nextInt(11); // 0 to 10 inclusive
    return double.parse((step / 100).toStringAsFixed(2)); // e.g. 0.03
  }

  void sessionConnectForLEssonStart(String handle) {
    setState(() {
      showDots = true;
    });
    String additionalPrompt =
        additionalPrompts['aiTutorPromptForSystem']['content'];
    additionalPrompt = additionalPrompt
        .replaceFirst("{subject}", widget.subject)
        .replaceFirst("{standard}", widget.standard.toString());
    final sessionCreateMessage = {
      "setup": {
        "model": "models/gemini-2.5-flash-preview-native-audio-dialog",
        "generationConfig": {
          // "temperature": getRandomTemperature(),
          "responseModalities": ["AUDIO"],
          "speechConfig": {
            "languageCode": selectedLanguage,
            "voiceConfig": {
              "prebuiltVoiceConfig": {"voiceName": selectedVoice}
            }
          }
        },
        "systemInstruction": {
          "parts": [
            {
              "text":
                  "$aiTutorPrompt.\n You also have access to tools that you must invoke in specific situations:\n\n1. If the student gives a **correct answer**, invoke the tool named **\"celebrate\"** .\n\n2. If the student gives a **wrong**, **partial**, or **uncertain** answer, invoke the tool named **\"show_encouragement\"**.\n\n3. If the student says anything like **\"I already know this\"**, **\"skip this\"**, **\"move on\"**, or expresses any **clear intent to proceed ahead**, invoke the tool **\"skip_ahead\"** immediately. Do **not** try to explain or challenge them further. Just acknowledge their request kindly and trigger the tool.\n\nUse these tools only when the student's message clearly fits the scenario. Do not invoke them randomly."
            }
          ]
        },
        "tools": [
          {
            "functionDeclarations": [
              {
                "name": "skip_ahead",
                "description":
                    "Invoke this tool when the user wants to skip or move to the next checkpoint.",
                "behavior": "NON_BLOCKING"
              },
              {
                "name": "celebrate",
                "description":
                    "Use this when the student gives an correct answer. This should trigger celebratory UI like confetti, sound, and tutor praise.",
                "behavior": "NON_BLOCKING"
              },
              {
                "name": "show_encouragement",
                "description":
                    "Use this when the student gives a wrong or incomplete answer. It helps to show emotional support or guide the student with a soft retry animation.",
                "behavior": "NON_BLOCKING"
              }
            ]
          }
        ],
        "realtimeInputConfig": {
          "automaticActivityDetection": {"disabled": true}
        },
        "outputAudioTranscription": {},
        "contextWindowCompression": {"slidingWindow": {}},
        "sessionResumption": {"handle": handle}
      }
    };
    webSocketService.sendMessage(sessionCreateMessage);
  }

  void resumeSession(String handle) {
    sessionResumed = true;
    final sessionCreateMessage = {
      "setup": {
        "model": "models/gemini-2.5-flash-preview-native-audio-dialog",
        "generationConfig": {
          "responseModalities": ["AUDIO"],
          "speechConfig": {
            "languageCode": selectedLanguage,
            "voiceConfig": {
              "prebuiltVoiceConfig": {"voiceName": selectedVoice}
            }
          }
        },
        "realtimeInputConfig": {
          "automaticActivityDetection": {"disabled": true}
        },
        "outputAudioTranscription": {},
        "contextWindowCompression": {"slidingWindow": {}},
        "sessionResumption": {"handle": handle}
      }
    };
    webSocketService.sendMessage(sessionCreateMessage);
  }

  void sessionReconnectOnLanguageChange(String handle) {
    webSocketService.disconnect();
    webSocketService.connect();
    sessionResumed = true;
    final sessionCreateMessage = {
      "setup": {
        "model": "models/gemini-2.5-flash-preview-native-audio-dialog",
        "generationConfig": {
          "responseModalities": ["AUDIO"],
          "speechConfig": {"languageCode": selectedLanguage}
        },
        // "systemInstruction": {
        //   "parts": [
        //     {"text": aiTutorPrompt}
        //   ]
        // },
        "realtimeInputConfig": {
          "automaticActivityDetection": {"disabled": true}
        },
        "outputAudioTranscription": {},
        "contextWindowCompression": {"slidingWindow": {}},
        "sessionResumption": {"handle": handle}
      }
    };
    webSocketService.sendMessage(sessionCreateMessage);
  }

  void greetingAndIntroConversationForGemini() {
    String contentText =
        "Student's name:$studentName \n Concept to teach: ${widget.conceptName}.";

    sendConversationItemToGemini(contentText);
  }

  void sendConversationItemWithImagesToGemini(
      String content, List<Map<String, dynamic>>? imageParts) {
    final parts = <Map<String, dynamic>>[
      if (content.trim().isNotEmpty) {"text": content},
      if (imageParts != null) ...imageParts,
    ];

    final message = {
      "clientContent": {
        "turns": {
          "role": "user",
          "parts": parts,
        },
        "turn_complete": true,
      }
    };

    webSocketService.sendMessage(message);
  }

  void sendConversationItemToGemini(String content) {
    final startMessage = {
      "clientContent": {
        "turns": {
          "role": "user",
          "parts": [
            {"text": content}
          ]
        },
        "turn_complete": true
      }
    };
    webSocketService.sendMessage(startMessage);
  }

  String getMimeTypeFromUrl(String url) {
    if (url.endsWith('.png')) return 'image/png';
    if (url.endsWith('.jpg') || url.endsWith('.jpeg')) return 'image/jpeg';
    if (url.endsWith('.gif')) return 'image/gif';
    if (url.endsWith('.webp')) return 'image/webp';
    // fallback
    return 'application/octet-stream';
  }

  Future<String> imageUrlToBase64(String url) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        return base64Encode(bytes);
      } else {
        print("Failed to load image: $url");
        return '';
      }
    } catch (e) {
      print("Error converting image to base64: $e");
      return '';
    }
  }

  String prepareContextForCheckpoint(
      Map<String, dynamic> checkpoint, int checkpointNumber,
      {String nextCheckpointAdditionalPrompt = ''}) {
    final learningObjectives =
        (checkpoint['learningObjective'] as List<dynamic>)
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value}')
            .join('\n');

    final blackboardText = checkpoint['blackboardText'] ?? '';
    final teacherNotes = checkpoint['teacherNotes'] ?? '';

    // Compose prompt
    final additionalPrompt =
        additionalPrompts['aiTutorPromptForCheckpoint']['content'];
    final contentText = '''
        STRICTLY FOLLOW: If there are any images GIVEN, then talk about those images while teaching too, like if the images contain some examples about something, then asking user to also check the image for examples.

        Concept being taught: ${widget.conceptName}.
        $nextCheckpointAdditionalPrompt
        Checkpoint ${checkpointNumber.toString()}:

        Learning Objectives:
        $learningObjectives

        Blackboard Text:
        $blackboardText

        Teacher Notes:
        $teacherNotes

        $additionalPrompt
        ''';
    return contentText;
  }

  Future<List<Map<String, dynamic>>> prepareImageContextForCheckpoint(
      List<dynamic> images) async {
    final imageParts = <Map<String, dynamic>>[];

    for (final url in images) {
      final base64 = await imageUrlToBase64(url);
      final mimeType = getMimeTypeFromUrl(url);

      if (base64.isNotEmpty && mimeType != 'image/webp') {
        imageParts.add({
          "inlineData": {
            "mimeType": mimeType,
            "data": base64,
          }
        });
      }
    }
    return imageParts;
  }

  void startConversationWithGemini() async {
    setState(() {
      showDots = true;
    });

    final checkpoint = conceptCheckpoints[0];
    final contentText = prepareContextForCheckpoint(checkpoint, 1);

    final images = checkpoint['images'] as List<dynamic>? ?? [];
    final imageParts = await prepareImageContextForCheckpoint(images);
    print(checkpoint['blackboardText']);

    logAITutorCheckpointStart(checkpoint['id'], widget.conceptId, 1);
    sendConversationItemWithImagesToGemini(contentText, imageParts);
  }

  // void startConversationWithGemini() {
  //   // String additionalPrompt =
  //   //     additionalPrompts['aiTutorPromptForSystem']['content'];
  //   // additionalPrompt = additionalPrompt
  //   //     .replaceFirst("{subject}", widget.subject)
  //   //     .replaceFirst("{standard}", widget.standard.toString());
  //   setState(() {
  //     showDots = true;
  //   });
  //   String additionalPrompt =
  //       additionalPrompts['aiTutorPromptForCheckpoint']['content'];
  //   String contentText =
  //       "$aiTutorPrompt \n\n Concept being taught: ${widget.conceptName}. Checkpoint 1: ${conceptCheckpoints[0]}. $additionalPrompt";
  //   logAITutorCheckpointStart(conceptCheckpoints[0]['id'], widget.conceptId, 1);
  //   sendConversationItemToGemini(contentText);
  // }

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
        " Concept being taught: ${widget.conceptName}. Checkpoint 1: ${conceptCheckpoints[0]}.";
    logAITutorCheckpointStart(conceptCheckpoints[0]['id'], widget.conceptId, 1);
    conversationItemCreationForUser(contentText);
  }

  void _scheduleLoadingReset() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && _isLoading && !responseStreaming) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> handleTextResponses() async {
    responseCompleted = false;
    responseStarted = false;
    setState(() {
      _isLoading = true;
    });
    final List<Map<String, String>> conversationToSend =
        List.from(conversations);

    conversationToSend.insert(conversations.length, {
      "text": userCurrentResponse,
      "role": "user",
    });
    final result = await createTutorAssistPrompt(
        conversations: conversationToSend,
        conceptName: widget.conceptName,
        conceptCheckpoint: conceptCheckpoints[currentCheckpointIndex]);

    print(result);
    sendTextResponseForGemini(userCurrentResponse, result['message']);
  }

  void sendTextResponseForGemini(
      String userCurrentResponse, String tutorAssistMessage) async {
    setState(() {
      originalConversation = true;
    });
    final activityStartMessage = {
      "realtimeInput": {"activityStart": {}}
    };
    webSocketService.sendMessage(activityStartMessage);
    // await Future.delayed(Duration(milliseconds: 500));

    List<String> completedObjectives = [];
    List<String> leftObjectives = [];
    checkpointLearningObjectiveStatus.forEach((objective, isCompleted) {
      if (isCompleted) {
        completedObjectives.add(objective);
      } else {
        leftObjectives.add(objective);
      }
    });

    String completedStr = completedObjectives.join(", ");
    String leftStr = leftObjectives.join(", ");

    String additionalPrompt =
        additionalPrompts['aiTutorPromptForAudio']['content'];
    additionalPrompt = additionalPrompt
        .replaceFirst("{completedObjectives}", completedStr)
        .replaceFirst("{leftObjectives}", leftStr);

    String additionalPromptForTutorAssistance =
        additionalPrompts['aiTutorPromptForTutorAssistancePrompt']['content'];

    additionalPromptForTutorAssistance = additionalPromptForTutorAssistance
        .replaceFirst("{tutorAssistMessage}", tutorAssistMessage);

    final textMessage = {
      "realtimeInput": {
        "text":
            "Strudent's response: $userCurrentResponse /n/n/n/n $additionalPrompt /n/n STRICTLY FOLLOW: If there are any images GIVEN, then talk about those images while teaching too, like if the images contain some examples about something, then asking user to also check the image for examples./n $additionalPromptForTutorAssistance"
      }
    };

    webSocketService.sendMessage(textMessage);

    final activityEndMessage = {
      "realtimeInput": {"activityEnd": {}}
    };
    webSocketService.sendMessage(activityEndMessage);
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
        // sendAudioResponse(base64Audio);
        responseCompleted = false;
        responseStarted = false;
        setState(() {
          firstLesson = false;
          _isLoading = true;
        });

        await prefs.setBool("firstLesson", false);
        final List<Map<String, String>> conversationToSend =
            List.from(conversations);

        await transcribeAudio(File(_audioPath!)).then((transcribedText) {
          userCurrentResponse = transcribedText;
          conversationToSend.insert(conversations.length, {
            "text": userCurrentResponse,
            "role": "user",
          });
          // userCurrentResponse = "";
          print("User Response: $userCurrentResponse");
        });
        final result = await createTutorAssistPrompt(
            conversations: conversationToSend,
            conceptName: widget.conceptName,
            conceptCheckpoint: conceptCheckpoints[currentCheckpointIndex]);

        print(result);

        sendAudioResponseForGemini(base64Audio, result['message']);
      } else {
        print('Audio path is null or empty');
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/audio_record.wav';
      final session = await AudioSession.instance;

      // Configure audio routing/session
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      await _recorder!.startRecorder(
          toFile: _audioPath, codec: Codec.pcm16WAV, sampleRate: 24000);

      setState(() {
        isRecording = true;
      });

      print('Recording started. File will be saved to: $_audioPath');
    }
  }

  void sendAudioResponseForGemini(
      String base64Audio, String tutorAssistMessage) async {
    setState(() {
      originalConversation = true;
      _isLoading = true;
      lastMessageAudio = base64Audio;
    });
    final activityStartMessage = {
      "realtimeInput": {"activityStart": {}}
    };
    webSocketService.sendMessage(activityStartMessage);
    // await Future.delayed(Duration(milliseconds: 500));

    final audioMessage = {
      "realtimeInput": {
        "audio": {"mimeType": "audio/pcm;rate=24000", "data": base64Audio}
      }
    };
    webSocketService.sendMessage(audioMessage);

    List<String> completedObjectives = [];
    List<String> leftObjectives = [];
    checkpointLearningObjectiveStatus.forEach((objective, isCompleted) {
      if (isCompleted) {
        completedObjectives.add(objective);
      } else {
        leftObjectives.add(objective);
      }
    });

    String completedStr = completedObjectives.join(", ");
    String leftStr = leftObjectives.join(", ");

    String additionalPrompt =
        additionalPrompts['aiTutorPromptForAudio']['content'];
    additionalPrompt = additionalPrompt
        .replaceFirst("{completedObjectives}", completedStr)
        .replaceFirst("{leftObjectives}", leftStr);

    String additionalPromptForTutorAssistance =
        additionalPrompts['aiTutorPromptForTutorAssistancePrompt']['content'];

    additionalPromptForTutorAssistance = additionalPromptForTutorAssistance
        .replaceFirst("{tutorAssistMessage}", tutorAssistMessage);

    final textMessage = {
      "realtimeInput": {
        "text":
            "$additionalPrompt /n/n STRICTLY FOLLOW: If there are any images GIVEN, then talk about those images while teaching too, like if the images contain some examples about something, then asking user to also check the image for examples./n $additionalPromptForTutorAssistance"
      }
    };

    webSocketService.sendMessage(textMessage);

    final activityEndMessage = {
      "realtimeInput": {"activityEnd": {}}
    };
    webSocketService.sendMessage(activityEndMessage);
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
          }
          // },
          // {
          //   "type": "input_text",
          //   "text":
          //       "Current completion status of learning objectives: $checkpointLearningObjectiveStatus"
          // }
        ]
      }
    };

    webSocketForRealTimeTranscription.sendMessage(audioMessage);
    final responseRequest = {
      "type": "response.create",
      "response": {
        "modalities": ["text"]
      }
    };
    webSocketForRealTimeTranscription.sendMessage(responseRequest);
  }

  Widget _buildRecordingButton() {
    return Column(
      children: [
        ChicletAnimatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _toggleRecording();
            // _scheduleLoadingReset();
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
        if (firstLesson) const SizedBox(height: 8),
        if (firstLesson)
          Text(
            _isLoading ? "" : (isRecording ? 'Tap to send' : 'Tap to speak'),
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign:
                TextAlign.center, // Center-align the microphone hint text
          ),
        if (!showCheckpointContinueButton)
          AbsorbPointer(
            absorbing: _isLoading,
            child: renderMessageBar(),
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

  void _showExitFeedbackSheet(BuildContext context) {
    final List<String> feedbackOptions = [
      "😴 Too slow / felt boring",
      "🛠️ Tech glitch – tutor bugged/ stuck",
      "👀 Just browsing for now",
      "🔇 Speaking out loud felt awkward",
      "🤔 Didn't understand",
      "⏳ Not worth the time",
      "😕 Expected something else",
      "📝 Other (tell us!)"
    ];

    final Set<String> selectedOptions = {};
    final TextEditingController feedbackController = TextEditingController();

    // bool hasInput = false;

    // feedbackController.addListener(() {
    //   final newHasInput = feedbackController.text.trim().isNotEmpty;
    //   if (newHasInput != hasInput) {
    //     setState(() {
    //       hasInput = newHasInput;
    //     });
    //   }
    // });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          bool hasInput = feedbackController.text.trim().isNotEmpty;

          feedbackController.addListener(() {
            final newHasInput = feedbackController.text.trim().isNotEmpty;
            if (newHasInput != hasInput) {
              setState(() {
                hasInput = newHasInput;
              });
            }
          });
          return Padding(
            padding: MediaQuery.of(context)
                .viewInsets
                .add(const EdgeInsets.symmetric(vertical: 16, horizontal: 8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Why are you leaving?",
                  style: GoogleFonts.raleway(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Choice Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: feedbackOptions.map((option) {
                    final isSelected = selectedOptions.contains(option);
                    return ChoiceChip(
                      label: Text(
                        option,
                        style: GoogleFonts.raleway(
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color.fromRGBO(255, 217, 0, 1),
                      backgroundColor: const Color.fromRGBO(34, 41, 49, 1),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedOptions.add(option);
                          } else {
                            selectedOptions.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Text Field
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.yellow,
                      decoration: InputDecoration(
                        hintText: "Enter your feedback",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color.fromRGBO(34, 41, 49, 1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    )),

                const SizedBox(height: 16),

                // Submit Button
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: ChicletAnimatedButton(
                      onPressed: selectedOptions.isNotEmpty || hasInput
                          ? () {
                              final reasons = selectedOptions.toList();
                              final message = feedbackController.text.trim();
                              final checkpointNo =
                                  greetingDone ? currentCheckpointIndex + 1 : 0;

                              logAITutorExitFeedbackSubmitted(
                                  conceptCheckpoints[currentCheckpointIndex]
                                      ['id'],
                                  widget.conceptId,
                                  checkpointNo);
                              saveUserFeedback(lessonFeedback: {
                                "conceptId": widget.conceptId,
                                "reasons": reasons,
                                "feedback": message
                              });
                              Navigator.pop(context); // close feedback sheet

                              // 🔁 Handle your backend or analytics here
                              print("Exit reasons: $reasons");
                              print("Feedback: $message");

                              if (wasFirstLesson) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MainPage()),
                                  (route) => false,
                                );
                              } else {
                                Navigator.pop(context, {"completed": false});
                              }
                            }
                          : null, // Disabled if nothing selected
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      width: double.infinity,
                      height: 50,
                      backgroundColor: selectedOptions.isNotEmpty || hasInput
                          ? const Color.fromRGBO(255, 217, 0, 1)
                          : Colors.grey[700],
                      child: Text(
                        "SUBMIT",
                        style: GoogleFonts.raleway(
                          color: selectedOptions.isNotEmpty || hasInput
                              ? Colors.black
                              : Colors.white54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
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
                  HapticFeedback.lightImpact();
                  Navigator.pop(context); // close XP modal
                  final checkpointNo =
                      greetingDone ? currentCheckpointIndex + 1 : 0;
                  logAITutorExit(
                      conceptCheckpoints[currentCheckpointIndex]['id'],
                      widget.conceptId,
                      checkpointNo);
                  Future.delayed(Duration(milliseconds: 100), () {
                    _showExitFeedbackSheet(context); // open feedback sheet
                  });
                  // if (wasFirstLesson) {
                  //   Navigator.pushAndRemoveUntil(
                  //     context,
                  //     MaterialPageRoute(builder: (context) => MainPage()),
                  //     (route) => false,
                  //   );
                  // } else {
                  //   Navigator.pop(context);
                  //   Navigator.pop(context, {"completed": false});
                  // }

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

  void showLanguageAndVoiceSelectionSheet(BuildContext context) {
    final previousLanguage = selectedLanguage;
    final previousVoice = selectedVoice;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LanguageAndVoiceSelection(
        languages: languageOptions,
        voices: voiceOptions,
        selectedLanguage: selectedLanguage,
        selectedVoice: selectedVoice,
        onLanguageSelect: (id, name) => selectedLanguage = id,
        onVoiceSelect: (id, name) => selectedVoice = id,
      ),
    ).then((value) async {
      if (selectedLanguage != previousLanguage ||
          selectedVoice != previousVoice) {
        print("Language or voice changed!");
        await prefs.setString("aiTutorLanguage", selectedLanguage);
        await prefs.setString("aiTutorVoice", selectedVoice);
        if (selectedLanguage != previousLanguage) {
          await fetchAITutorPrompts();
        }
        webSocketService.disconnect();
        webSocketService.connect();
        sessionConnect();
      }
    });
  }

  void _handleMessageSend(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      userCurrentResponse = message.trim();
    });

    _messageController.clear();
    handleTextResponses();
  }

  TextEditingController _messageController = TextEditingController();

  Widget renderMessageBar() {
    return Container(
      color: const Color.fromRGBO(19, 31, 36, 1),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              enabled: !_isLoading, // ✅ This disables typing
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type your message...",
                hintStyle: GoogleFonts.raleway(color: Colors.grey.shade400),
                fillColor: const Color.fromRGBO(30, 42, 48, 1),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onFieldSubmitted: _handleMessageSend,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send,
                color: _isLoading
                    ? Color.fromRGBO(63, 63, 62, 1)
                    : Color.fromRGBO(255, 217, 0, 1)),
            onPressed: _isLoading
                ? null
                : () => _handleMessageSend(_messageController.text),
          )
        ],
      ),
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
                        if (!(showMistakeCorrectionButton ||
                            showCheckResultButton ||
                            showJumpToQuestionsButton))
                          if (greetingDone)
                            GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  logAITutorMenuButtonClick(widget.conceptId);
                                  _showMenuToSwitch(context);
                                },
                                child: Icon(
                                  Icons.more_vert_outlined,
                                )),
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
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: pi / 2, // downward
                          emissionFrequency: 0.05,
                          numberOfParticles: 20,
                          maxBlastForce: 10,
                          minBlastForce: 5,
                          gravity: 0.3,
                          shouldLoop: false,
                        ),
                      ),
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
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 🐶 Tutor Avatar
                                Container(
                                  color: const Color.fromRGBO(19, 31, 36, 1),
                                  child: Image.asset(
                                    selectedTutor.isNotEmpty
                                        ? getTutorAvatar(
                                                selectedTutor['avatar'])[
                                            "imagePath"]!
                                        : getTutorAvatar(
                                            "tutoprime")["imagePath"]!,
                                    height: 150,
                                    fit: BoxFit.scaleDown,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 👨🏽‍🏫 Tutor name + change
                                if (tutorName.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      logAITutorSwitchTutorClick(
                                          widget.conceptId);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ConceptStartScreen(
                                            conceptId: widget.conceptId,
                                            conceptName: widget.conceptName,
                                            maxXP: widget.maxXP,
                                            name: widget.name,
                                            subject: widget.subject,
                                            standard: widget.standard,
                                            firstLesson: false,
                                            teacherId: selectedTutor['id'],
                                          ),
                                        ),
                                      ).then((response) async {
                                        if (selectedLanguage !=
                                                response['language'] ||
                                            selectedVoice !=
                                                response['voice']) {
                                          await prefs.setString(
                                              "aiTutorLanguage",
                                              response['language']);
                                          await prefs.setString("aiTutorVoice",
                                              response['voice']);
                                          selectedVoice = response['voice'];
                                          if (selectedLanguage !=
                                              response['language']) {
                                            selectedLanguage =
                                                response['language'];
                                            await fetchAITutorPrompts(
                                                fetchPersonaPrompt: false);
                                          }
                                          webSocketService.disconnect();
                                          webSocketService.connect();
                                          sessionConnect();
                                        }

                                        setState(() {
                                          selectedTutor = response['tutor'];
                                          tutorName = response['tutor']['name'];
                                        });

                                        logAITutorSelected(
                                            widget.conceptId,
                                            response['tutor']['id'],
                                            selectedLanguage,
                                            selectedVoice);

                                        fetchAITutorPromptsV2(
                                            response['tutor']['id']);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "You are studying with $tutorName. ",
                                            style: GoogleFonts.raleway(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "Change",
                                            style: GoogleFonts.raleway(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color.fromRGBO(
                                                  255, 217, 0, 1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // 💬 Greeting Message
                                if (!skipAudioTutor)
                                  GestureDetector(
                                    onTap: () {
                                      // Handle conversation click
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: showDots
                                          ? loadingMessage("")
                                          : othersMessage(displayedConversations
                                              .last["text"]),
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                // ✅ Learning Objectives
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: LessonCheckpoints(
                                        conceptCheckpoints:
                                            conceptCheckpoints)),

                                const SizedBox(height: 40), // bottom padding
                              ],
                            ),
                          ),
                        ),

                      if (greetingDone)
                        Expanded(
                            child: Container(
                          child: Expanded(
                              child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Blackboard Text
                                !skipAudioTutor &&
                                        displayedConversations.isNotEmpty
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
                                              // if (conversations.isNotEmpty) {
                                              //   _showAllConversations(context);
                                              // }
                                            },
                                            child: showDots
                                                ? loadingMessage("")
                                                : othersMessage(
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
                                  Padding(
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
                                              fontSize: 16),
                                        ),
                                      },
                                      extensionSet: md.ExtensionSet(
                                        [LatexBlockSyntax()],
                                        [LatexInlineSyntax()],
                                      ),
                                      styleSheet: MarkdownStyleSheet(
                                        p: GoogleFonts.notoSans(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                        h1: GoogleFonts.notoSans(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        h2: GoogleFonts.notoSans(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        h3: GoogleFonts.notoSans(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        listBullet: GoogleFonts.notoSans(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        blockSpacing: 8.0,
                                      ),
                                    ),
                                  ),

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
                                    timeTakenToCompleteLessonWithAiTutor =
                                        DateTime.now()
                                            .difference(lessonStartTime)
                                            .inSeconds;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MCQQuestions(
                                          conceptId: widget.conceptId,
                                          conceptName: widget.conceptName,
                                          maxXP: widget.maxXP ~/ 2,
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
                                                  timeToComplete: value[
                                                          'timeToComplete'] +
                                                      timeTakenToCompleteLessonWithAiTutor,
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

                                    player.stopPlayer();

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
                                      _initPlayer();

                                      final totalQuestions =
                                          questionsAttemptedDetails[
                                                  'totalQuestions'] ??
                                              1; // avoid divide-by-zero

                                      final xpPerQuestion =
                                          (45 / totalQuestions).toInt();
                                      xpGained = xpGained +
                                          (xpPerQuestion * value as int);
                                      final Map<String, dynamic>
                                          lessonCompletionResponse =
                                          await markLessonCompletion(
                                              lessonId: widget.conceptId,
                                              attemptTime:
                                                  questionsAttemptedDetails[
                                                      'attemptTime'],
                                              timeToComplete: questionsAttemptedDetails[
                                                      'timeToComplete'] +
                                                  timeTakenToCompleteLessonWithAiTutor,
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

                                    player.stopPlayer();

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
                                            timeTaken: questionsAttemptedDetails[
                                                    'timeToComplete'] +
                                                timeTakenToCompleteLessonWithAiTutor,
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
                  if (greetingDone &&
                      !showContinuationButtons &&
                      !showJumpToQuestionsButton &&
                      !showMistakeCorrectionButton &&
                      !showCheckResultButton &&
                      !skipAudioTutor &&
                      // !responseStreaming &&
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
                      !showDots &&
                      !responseStreaming &&
                      (showAfterGreetingContinueButton ||
                          showCheckpointContinueButton))
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color.fromRGBO(19, 31, 36, 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 12),
                          child: Row(
                            children: [
                              if (showCheckpointContinueButton)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _buildRecordingButton(),
                                ),
                              Expanded(
                                child: ChicletAnimatedButton(
                                  onPressed: () {
                                    if (showAfterGreetingContinueButton) {
                                      setState(() {
                                        greetingDone = true;
                                        showAfterGreetingContinueButton = false;
                                      });
                                      webSocketService.disconnect();
                                      webSocketService.connect();
                                      sessionConnectForLEssonStart(
                                          previousSessionHandle);
                                    } else if (showCheckpointContinueButton) {
                                      checkpointContinueButtonClick();
                                    }
                                  },
                                  buttonType:
                                      ChicletButtonTypes.roundedRectangle,
                                  width: double.infinity,
                                  height: 50,
                                  buttonColor:
                                      const Color.fromRGBO(187, 160, 2, 1),
                                  backgroundColor:
                                      const Color.fromRGBO(255, 217, 0, 1),
                                  child: Text(
                                    "CONTINUE",
                                    style: GoogleFonts.raleway(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ]),
              ));
  }
}
