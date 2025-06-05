//final updated code

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
import 'package:eureka_app/apis/fetchLanguagesAndVoices.dart';
import 'package:eureka_app/apis/getAITutorPrompts.dart';
import 'package:eureka_app/apis/getAITutorPromptsV2.dart';
import 'package:eureka_app/apis/markLessonCompletion.dart';
import 'package:eureka_app/apis/transcribeAudio.dart';
import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
import 'package:eureka_app/screens/mistakesCorrectionScreen.dart';
import 'package:eureka_app/services/webSocketService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/widgets/conceptResultScreen.dart';
import 'package:eureka_app/widgets/conversationScreen.dart';
import 'package:eureka_app/widgets/languageAndVoiceSelection.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';

class ConceptLearningScreenV2 extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;
  final String name;
  final String aiTeacherId;
  final String languageCode;
  final String voice;

  const ConceptLearningScreenV2(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.maxXP,
      required this.name,
      required this.aiTeacherId,
      required this.languageCode,
      required this.voice})
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
  bool greetingDone = true;
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
  String selectedVoice = "Puck";
  late DateTime lessonStartTime;
  int timeTakenToCompleteLessonWithAiTutor = 0;

  late Map<String, String> languageOptions = {};
  late Map<String, String> voiceOptions = {};

  late final prefs;

  Future<void> loadLanguageAndVoiceOptions() async {
    try {
      final data = await fetchLanguagesAndVoices();

      final List<dynamic> languages = data['languages'] ?? [];
      final List<dynamic> voices = data['voices'] ?? [];

      languageOptions = {for (var lang in languages) lang['id']: lang['name']};

      voiceOptions = {for (var voice in voices) voice['id']: voice['name']};

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

  Future<void> fetchAITutorPrompts() async {
    try {
      Map<String, dynamic>? aiTutorPromptFromDB = await getAITutorPromptsV2(
          language: selectedLanguage, teacherId: widget.aiTeacherId);
      // final profileData = await getProfile();

      setState(() {
        aiTutorPrompt = aiTutorPromptFromDB?['content'];
      });
    } catch (error) {
      print("Error fetching ai prompt: $error");
    }
  }

  void startWebsocket() {
    webSocketService = WebSocketService();
    // webSocketService = WebSocketServiceForOpenai();

    // webSocketService.useOpenAI = false;
    webSocketService.useGemini = true;
    if (webSocketService.useGemini) {
      webSocketService.onMessageReceived = onMessageReceivedForGemini;
    } else {
      webSocketService.onMessageReceived = onMessageReceived;
    }
    webSocketService.connect();
  }

  void setLanguageAndVoice() async {
    selectedLanguage = widget.languageCode;
    selectedVoice = widget.voice;
  }

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);

    // WakelockPlus.enable();

    studentName = widget.name;
    _scrollController = ScrollController();
    startWebsocket();
    // loadLanguageAndVoiceOptions();
    setLanguageAndVoice();
    lessonStartTime = DateTime.now();
    player = FlutterSoundPlayer();

    _recorder = FlutterSoundRecorder();

    _initializeRecorder();
    _initPlayer();
    getConceptDetails().then((_) {
      fetchAITutorPrompts().then((_) {
        if (webSocketService.useGemini) {
          sessionConnectForLEssonStart();
          // startSessionForRealTimeTranscription();
        } else {
          greetingAndIntroConversation();
        }
      });
    });
    // greetingAndIntroConversation();
    // _startResponseMonitor();
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
    // WakelockPlus.disable();
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

  Future<void> onMessageReceivedForGemini(dynamic message) async {
    print("respones received");
    print("responseStreaming top level: $responseStreaming");

    final stringMessage = utf8.decode(message);

    final Map<String, dynamic> data = jsonDecode(stringMessage);

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

        return;
      } else if (serverContent.containsKey("modelTurn")) {
        //case for text response
        // print(
        //     "Conversation: ${serverContent["modelTurn"]["parts"][0]["text"]}");

        // for audio response
        responseStreaming = true;
        responseStarted = true;
        print("responseStreaming: $responseStreaming");
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

    startWebsocket();
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

  void moveToNextCheckpoint() {
    if (completedCheckpointIndexes.contains(currentCheckpointIndex)) {
      currentCheckpointIndex += 1;

      logAITutorCheckpointStart(
          conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId,
          currentCheckpointIndex + 1);

      String contentText =
          "Concept to teach: ${widget.conceptName}. Moving to next checkpoint of the concept. Checkpoint ${currentCheckpointIndex + 1}: ${conceptCheckpoints[currentCheckpointIndex]}. Once all the learning objectives in the given checkpoint are completed, ask student to continue with next checkpoint.";
      // conversationItemCreationForUser(contentText);
      sendConversationItemToGemini(contentText);
    } else {
      String contentText = "Start from where we have left";

      // conversationItemCreationForUser(contentText);
      sendConversationItemToGemini(contentText);
    }
  }

  void movingToQuestionConversation() {
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
    // if (currentCheckpointIndex == 0 && !showContinuationButtons) {
    //   String contentText =
    //       "Now there are 3 available options to continue from here. 1.Continue learning with Tutor \n 2.Proceed with story mode \n 3.Jump to questions. Ask user to choose one of the option";

    //   // conversationItemCreationForUser(contentText);
    //   sendConversationItemToGemini(contentText);
    //   setState(() {
    //     showContinuationButtons = true;
    //   });
    // } else if (currentCheckpointIndex == conceptCheckpoints.length - 1) {
    //   setState(() {
    //     xpGained += 45;
    //     allCheckpointsCompleted = true;
    //   });
    //   movingToQuestionConversation();
    // } else {
    //   moveToNextCheckpoint();
    // }

    if (currentCheckpointIndex == conceptCheckpoints.length - 1) {
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
    // conversationItemCreationForUser(contentText);
    sendConversationItemToGemini(contentText);
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
    String contentText =
        "Now the student has completed the questions and corrected their mistakes too, associated with the concept. Congratulate the student, and ask them to check their result.";
    setState(() {
      showMistakeCorrectionButton = false;
      showCheckResultButton = true;
    });
    // conversationItemCreationForUser(contentText);
    sendConversationItemToGemini(contentText);
  }

  void startSessionForRealTimeTranscription() {
    final startMessage = {
      "event_id": "event_1234_greeting",
      "type": "session.update",
      "session": {
        "instructions":
            "You are a world class transcript writer who generate text transcripts in english for various types of audios. I am streaming an audio response, and as the response get streamed, I would be giving you chunks of that audio, and you have to provide me  the text transcript of it, nothing else."
        // "You are a teacher guiding a student to deeply understand a concept. Begin with a warm greeting and a very small introduction to what we are studying, just the topic. Never end your conversation with a question or you will die. Keep the intro very short and crisp, and dont explain anything at all. Keep all our conversation short so that the discussion can be mnore engaging."
        // "You are a Socratic teacher teaching a concept to a student. Follow these steps: \n 1. Begin with a warm greeting, just like a teacher starting a class. \n2. Wait for the student to respond to the greeting. \n3. Provide a very brief introduction (20-30 words) about the concept you are going to teach, and dont ask any questions while introducing the topic. \n4. Do not end the introduction with a question. \n5. Use the student's name and the concept name (which will be provided) while introducing the topic.",
      }
    };

    webSocketForRealTimeTranscription.sendMessage(startMessage);

    // String contentText =
    //     "Student's name:$studentName \n Concept to teach: ${widget.conceptName}.";

    // conversationItemCreationForUser(contentText);
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

  void sessionConnect() {
    final sessionCreateMessage = {
      "setup": {
        // "model": "models/gemini-2.0-flash-live-preview-04-09",

        "model": "models/gemini-2.0-flash-live-001",
        "generationConfig": {
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

  void sessionConnectForLEssonStart() {
    final sessionCreateMessage = {
      "setup": {
        "model": "models/gemini-2.0-flash-live-001",
        "generationConfig": {
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
            {"text": aiTutorPrompt}
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

  void resumeSession(String handle) {
    sessionResumed = true;
    final sessionCreateMessage = {
      "setup": {
        "model": "models/gemini-2.0-flash-live-001",
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
    startWebsocket();
    sessionResumed = true;
    final sessionCreateMessage = {
      "setup": {
        "model": "models/gemini-2.0-flash-live-001",
        "generationConfig": {
          "responseModalities": ["AUDIO"],
          "speechConfig": {"languageCode": selectedLanguage}
        },
        "systemInstruction": {
          "parts": [
            {"text": aiTutorPrompt}
          ]
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

  void greetingAndIntroConversationForGemini() {
    String contentText =
        "Student's name:$studentName \n Concept to teach: ${widget.conceptName}.";

    sendConversationItemToGemini(contentText);
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

  void startConversationWithGemini() {
    String contentText =
        " Concept being taught: ${widget.conceptName}. Checkpoint 1: ${conceptCheckpoints[0]}. Once all the learning objectives in the given checkpoint are completed, ask student to continue with next checkpoint.";
    logAITutorCheckpointStart(conceptCheckpoints[0]['id'], widget.conceptId, 1);
    sendConversationItemToGemini(contentText);
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
        sendAudioResponseForGemini(base64Audio);

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

  void sendAudioResponseForGemini(String base64Audio) async {
    setState(() {
      originalConversation = true;
      _isLoading = true;
      lastMessageAudio = base64Audio;
    });
    // final audioMessage = {
    //   "realtimeInput": {
    //     "mediaChunks": [
    //       {
    //         "mimeType": "audio/pcm;rate=24000",
    //         "data": base64Audio,
    //       }
    //     ]
    //   }
    // };
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

    final textMessage = {
      "realtimeInput": {
        "text":
            "If the audio is empty, or you are not able to understand it, ask user to repeat what they said. These are the completed learning objectives : $completedObjectives . And these learning objectives are left $leftObjectives . Focus on the left objectives only, and try to complete them."
      }
    };

    // final textMessage = {
    //   "realtimeInput": {
    //     "text":
    //         "Current completion status of learning objectives: $checkpointLearningObjectiveStatus"
    //   }
    // };

    webSocketService.sendMessage(textMessage);

    // final textMessage = {
    //   "clientContent": {
    //     "turns": {
    //       "role": "user",
    //       "parts": [
    //         {"text": "Current completion status of learning objectives: $checkpointLearningObjectiveStatus"}
    //       ]
    //     },
    //     "turn_complete": true
    //   }
    // };
    // await Future.delayed(Duration(milliseconds: 500));

    final activityEndMessage = {
      "realtimeInput": {"activityEnd": {}}
    };
    webSocketService.sendMessage(activityEndMessage);

    // final audioMessage = {
    //   "type": "conversation.item.create",
    //   "item": {
    //     "type": "message",
    //     "role": "user",
    //     "content": [
    //       {
    //         "type": "input_audio",
    //         "audio": base64Audio,
    //       },
    //       {
    //         "type": "input_text",
    //         "text":
    //             "Current completion status of learning objectives: $checkpointLearningObjectiveStatus"
    //       }
    //     ]
    //   }
    // };

    // webSocketService.sendMessage(audioMessage);

    // Future.delayed(Duration(seconds: 15), () {
    //   if (!responseStreaming && !responseCompleted && !responseStarted) {
    //     print("message sent again as response generation didnt start");
    //     lastResponseTime = DateTime.now();
    //     sendAudioResponseForGemini(base64Audio);
    //   }
    // });
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
        startWebsocket();
        sessionConnect();
      }
    });
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
                        if (!(showMistakeCorrectionButton ||
                            showCheckResultButton ||
                            showJumpToQuestionsButton))
                          if (!greetingDone)
                            GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  logAITutorMenuButtonClick(widget.conceptId);
                                  showLanguageAndVoiceSelectionSheet(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        languageOptions[selectedLanguage] ??
                                            "English",
                                        style: GoogleFonts.raleway(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color.fromRGBO(255, 217, 0, 1),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down,
                                          color:
                                              Color.fromRGBO(255, 217, 0, 1)),
                                    ],
                                  ),
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
                                            child: othersMessage(
                                                displayedConversations
                                                    .last["text"]),
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 20,
                                      ),
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
                                      xpGained =
                                          questionsAttemptedDetails['totalXp'] +
                                              xpGained +
                                              xpPerQuestion * value;
                                      final Map<String, dynamic>
                                          lessonCompletionResponse =
                                          await markLessonCompletion(
                                              lessonId: widget.conceptId,
                                              attemptTime:
                                                  questionsAttemptedDetails[
                                                      'attemptTime'],
                                              timeToComplete:
                                                  questionsAttemptedDetails[
                                                          'timeToComplete'] +
                                                      timeTakenToCompleteLessonWithAiTutor,
                                              xpGained: questionsAttemptedDetails[
                                                      'totalXp'] +
                                                  xpGained +
                                                  3 * value,
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
                                            totalXp: xpGained,
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
                                      startWebsocket();
                                      sessionConnectForLEssonStart();
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
