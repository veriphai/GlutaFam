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
import 'package:eureka_app/apis/generateTutorResponse.dart';
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
import 'package:eureka_app/widgets/tutorMessage.dart';
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

class ConceptLearningScreenV3 extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;
  final String name;
  final String subject;
  final int standard;
  final String? selectedLanguage;
  final String? selectedVoice;
  final Map<String, dynamic>? tutorSelected;

  const ConceptLearningScreenV3(
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
  _ConceptLearningScreenV3State createState() =>
      _ConceptLearningScreenV3State();
}

class _ConceptLearningScreenV3State extends State<ConceptLearningScreenV3> {
  // late WebSocketServiceForOpenai webSocketService;

  bool isRecording = false;
  FlutterSoundRecorder? _recorder;
  String? _audioPath;
  late FlutterSoundPlayer player;
  Queue<String> audioQueue = Queue<String>();
  bool isPlaying = false;
  String? fetchedImageUrl;
  bool originalConversation = true;
  int currentCheckpointIndex = 0;
  List<Map<String, dynamic>> conversations = [];
  String studentName = "";
  bool greetingDone = false;
  bool showContinuationButtons = false;
  bool showJumpToQuestionsButton = false;
  bool showMistakeCorrectionButton = false;
  bool showCheckResultButton = false;
  late ScrollController _scrollController;
  Map<String, bool> checkpointLearningObjectiveStatus = {};
  String userCurrentResponse = "";
  late Map<String, dynamic> questionsAttemptedDetails;
  bool _isLoading = false;
  bool showAfterGreetingContinueButton = false;
  bool showCheckpointContinueButton = false;
  bool isConceptCheckpointLoading = true;
  int xpGained = 0;
  bool allCheckpointsCompleted = false;
  List<int> completedCheckpointIndexes = [];
  List<int> attemptedCheckpointIndexes = [];
  bool isMuted = false;
  late List<Map<String, dynamic>> conceptCheckpoints;
  String selectedLanguage = "en-US";
  String selectedVoice = "alloy";
  late DateTime lessonStartTime;
  int timeTakenToCompleteLessonWithAiTutor = 0;
  late Map<String, dynamic> selectedTutor = {'id': "persona-1"};
  late Map<String, dynamic> additionalPrompts = {};
  bool firstLesson = true;
  bool wasFirstLesson = true;
  String tutorName = "Tuto Prime";
  bool showDots = true;
  late ConfettiController _confettiController;

  late Map<String, String> languageOptions = {};
  late Map<String, String> voiceOptions = {};
  bool showTextBox = false;

  Map<String, dynamic> usage = {};

  late String conceptConversationsKey = "";

  late final prefs;

  late int _timeLeftSeconds;
  Timer? _timer;

  late Map<String, dynamic> latestTutorResponse;

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    conceptConversationsKey =
        "${widget.name}_${widget.conceptId}_${DateTime.now().millisecondsSinceEpoch}";

    // WakelockPlus.enable();

    studentName = widget.name;
    _scrollController = ScrollController();
    lessonStartTime = DateTime.now();
    // startWebsocketForTranscription();
    getConceptDetails();

    loadLanguageAndVoiceOptions().then((_) {
      initializeSession();
    });

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
  }

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
        await prefs.setString("aiTutorLanguage", selectedLanguage);
      }

      final defaultVoice = voices.firstWhere(
        (voice) => voice['defaultVoice'] == true,
        orElse: () => null,
      );
      if (defaultVoice != null) {
        selectedVoice = defaultVoice['id'];
        await prefs.setString("aiTutorVoice", selectedVoice);
      }

      setState(() {
        // trigger UI update if needed
      });
    } catch (e) {
      print("Error loading language and voice options: $e");
    }
  }

  Future<void> initializeSession() async {
    try {
      Map<String, dynamic> tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: studentName,
          checkpointNo: 0,
          conceptConversationsKey: conceptConversationsKey,
          language: selectedLanguage,
          voice: selectedVoice,
          greeting: true);

      final message = tutorResponse['message'];
      final audioBase64 = tutorResponse['audio'];
      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) =>
                      Map<String, dynamic>.from(item as Map)) // safe cast
                  .toList() ??
              [];
      conversationsList.add({
        "text": message,
        "role": "assistant",
        "time": DateTime.now().millisecondsSinceEpoch ~/ 1000
      });

      setState(() {
        conversations = conversationsList;
        showDots = false;
        showAfterGreetingContinueButton = true;
      });

      if (audioBase64 != null) {
        await _playBase64Audio(audioBase64, conceptConversationsKey);
      }
    } catch (error) {
      print("Error fetching tutor response: $error");
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        setState(() {
          _timeLeftSeconds--;
        });
      } else {
        timer.cancel();
        _showTimeUpBottomSheet();
      }
    });
  }

  void _showTimeUpBottomSheet() {
    final checkpointsLeft =
        conceptCheckpoints.length - completedCheckpointIndexes.length;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center(
              //   child: Container(
              //     width: 40,
              //     height: 4,
              //     decoration: BoxDecoration(
              //       color: Colors.grey[700],
              //       borderRadius: BorderRadius.circular(2),
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              Text(
                "Taking longer than usual",
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "This discussion is taking longer than usual.",
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
              Text(
                checkpointsLeft > 1
                    ? "${checkpointsLeft} checkpoints left."
                    : "${checkpointsLeft} checkpoint left.",
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.green[300],
                ),
              ),
              SizedBox(height: 24),
              ChicletAnimatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                buttonType: ChicletButtonTypes.roundedRectangle,
                width: double.infinity,
                height: 50,
                buttonColor: Color.fromRGBO(187, 160, 2, 1),
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                child: Text(
                  "CONTINUE",
                  style: GoogleFonts.arOneSans(
                    color: Colors.black,
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

  Future<void> startLessonWithTutor() async {
    try {
      _startCountdown();

      setState(() {
        showDots = true;
      });
      logAITutorCheckpointStart(
          conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId,
          currentCheckpointIndex + 1);
      Map<String, dynamic> tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: studentName,
          checkpointNo: 0,
          conceptConversationsKey: conceptConversationsKey,
          conversations: conversations,
          language: selectedLanguage,
          voice: selectedVoice,
          firstConversation: true);

      latestTutorResponse = tutorResponse;

      final message = tutorResponse['message'];
      final audioBase64 = tutorResponse['audio'];
      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) =>
                      Map<String, dynamic>.from(item as Map)) // safe cast
                  .toList() ??
              [];
      conversationsList.add({
        "text": message,
        "role": "assistant",
        "time": DateTime.now().millisecondsSinceEpoch ~/ 1000
      });

      setState(() {
        conversations = conversationsList;
        showDots = false;
      });

      if (audioBase64 != null) {
        await _playBase64Audio(audioBase64, conceptConversationsKey);
      }
    } catch (error) {
      print("Error fetching tutor response: $error");
    }
  }

  Future<void> followUpConversationWithTutor(
      File? audioFile, String? studentResponseAsText,
      {bool newCheckpointStarted = false,
      bool allCheckpointCompleted = false,
      Map<String, dynamic>? questionsData}) async {
    try {
      setState(() {
        showDots = true;
      });
      Map<String, dynamic> tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: studentName,
          checkpointNo: currentCheckpointIndex,
          conversations: conversations,
          audioFile: audioFile,
          newCheckpointStarted: newCheckpointStarted,
          allCheckpointCompleted: allCheckpointCompleted,
          studentResponse: studentResponseAsText,
          conceptConversationsKey: conceptConversationsKey,
          questionsData: questionsData,
          language: selectedLanguage,
          voice: selectedVoice);

      latestTutorResponse = tutorResponse;

      final message = tutorResponse['message'];
      final audioBase64 = tutorResponse['audio'];
      final bool currentCheckpointCompletionStatus =
          tutorResponse['currentCheckpointCompleted'];
      final bool skipAhead = tutorResponse['enableCheckpointContinueButton'];
      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) =>
                      Map<String, dynamic>.from(item as Map)) // safe cast
                  .toList() ??
              [];
      conversationsList.add({
        "text": message,
        "role": "assistant",
        "time": DateTime.now().millisecondsSinceEpoch ~/ 1000
      });

      if (currentCheckpointCompletionStatus || skipAhead) {
        if (currentCheckpointCompletionStatus) {
          completedCheckpointIndexes.add(currentCheckpointIndex);
          attemptedCheckpointIndexes.add(currentCheckpointIndex);
        }
        if (skipAhead) {
          attemptedCheckpointIndexes.add(currentCheckpointIndex);
        }
        setState(() {
          showCheckpointContinueButton = true;
          showDots = false;
          showTextBox = false;
        });
      }

      setState(() {
        conversations = conversationsList;
        showDots = false;
        _isLoading = false;
      });
      if (audioBase64 != null) {
        await _playBase64Audio(audioBase64, conceptConversationsKey);
      }
    } catch (error) {
      print("Error fetching tutor response: $error");
    }
  }

  Future<void> _playBase64Audio(String base64Audio, String uniqueKey) async {
    try {
      final audioBytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/${uniqueKey}_response_audio.wav');
      await audioFile.writeAsBytes(audioBytes);

      await player.openPlayer();
      await player.startPlayer(fromURI: audioFile.path);
    } catch (e) {
      print('Error playing base64 audio: $e');
    }
  }

  Future<void> getConceptDetails() async {
    try {
      prefs = await SharedPreferences.getInstance();
      Map<String, dynamic>? conceptDetails =
          await fetchConceptDetails(conceptId: widget.conceptId);

      setState(() {
        conceptCheckpoints = (conceptDetails?["conceptCheckpoints"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _timeLeftSeconds = ((conceptDetails["expectedCompletionTime"] ??
                conceptCheckpoints.length * 5) as int) *
            60;

        // _timeLeftSeconds = 20;

        isConceptCheckpointLoading = false;
      });
    } catch (error) {
      print("Error fetching concept details: $error");
    }
  }

  void _showMenuToSwitch(BuildContext context) {
    bool atleastOneCheckpointLeft =
        conceptCheckpoints.length - attemptedCheckpointIndexes.length >= 1;
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
                  if (atleastOneCheckpointLeft)
                    ChicletAnimatedButton(
                      onPressed: () async {
                        await player.stopPlayer();
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        setState(() {
                          showContinuationButtons = false;
                        });
                        skipToNextCheckpoint(false);
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      width: double.infinity,
                      height: 50,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "JUMP TO NEXT CHECKPOINT",
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
                        afterQuestionsConversation(value);
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

    // setState(() {
    //   _isPlayerReady = true;
    // });
  }

  @override
  void dispose() {
    // WakelockPlus.disable();
    _recorder?.closeRecorder();
    if (player.isPlaying) {
      player.stopPlayer();
    }
    player.closePlayer();
    _confettiController.dispose();
    _timer?.cancel();

    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await _recorder!.openRecorder();
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
  }

  void moveToNextCheckpoint() async {
    if (completedCheckpointIndexes.contains(currentCheckpointIndex)) {
      setState(() {
        showDots = true;
        showCheckpointContinueButton = false;
      });
      logAITutorCheckpointEnd(conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId, currentCheckpointIndex + 1);

      currentCheckpointIndex += 1;

      await followUpConversationWithTutor(null, null,
          newCheckpointStarted: true);

      logAITutorCheckpointStart(
          conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId,
          currentCheckpointIndex + 1);
    } else {
      String contentText = "Start from where we have left";

      // conversationItemCreationForUser(contentText);
      // sendConversationItemToGemini(contentText);
    }
  }

  void skipToNextCheckpoint(bool fromExit) async {
    setState(() {
      showDots = true;
      showCheckpointContinueButton = false;
    });
    attemptedCheckpointIndexes.add(currentCheckpointIndex);
    fromExit
        ? logAITutorCheckpointSkippedOnExit(
            conceptCheckpoints[currentCheckpointIndex]['id'],
            widget.conceptId,
            currentCheckpointIndex + 1)
        : logAITutorCheckpointSkipped(
            conceptCheckpoints[currentCheckpointIndex]['id'],
            widget.conceptId,
            currentCheckpointIndex + 1);

    currentCheckpointIndex += 1;

    await followUpConversationWithTutor(null, null, newCheckpointStarted: true);

    logAITutorCheckpointStart(conceptCheckpoints[currentCheckpointIndex]['id'],
        widget.conceptId, currentCheckpointIndex + 1);
  }

  void movingToQuestionConversation() async {
    setState(() {
      showDots = true;
    });
    await followUpConversationWithTutor(null, null,
        allCheckpointCompleted: true);

    setState(() {
      showJumpToQuestionsButton = true;
    });
  }

  // void checkConceptCompleted() async {
  //   // final result = {'checkpointCompleted': true};

  //   final result = await checkConceptCheckpointCompleted(
  //       conversations: conversations,
  //       conceptName: widget.conceptName,
  //       greeting: !greetingDone,
  //       conceptCheckpoint: conceptCheckpoints[currentCheckpointIndex]);
  //   checkpointLearningObjectiveStatus = Map<String, bool>.from(result);
  //   bool conceptCompleted = checkpointLearningObjectiveStatus.values
  //       .every((value) => value == true);

  //   if (conceptCompleted) {
  //     setState(() {
  //       showCheckpointContinueButton = true;
  //     });
  //     completedCheckpointIndexes.add(currentCheckpointIndex);
  //     //  checkpointContinueButtonClick();
  //   }
  // }

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
      // saveConceptConversations(
      //     conversationsKey: conceptConversationsKey,
      //     conversations: conversations,
      //     conceptId: widget.conceptId,
      //     language: selectedLanguage);
      logAITutorCheckpointsCompleted(
          widget.conceptId, completedCheckpointIndexes.length);
      movingToQuestionConversation();
    } else {
      moveToNextCheckpoint();
    }
  }

  void afterQuestionsConversation(
      Map<String, dynamic> questionCompletion) async {
    setState(() {
      showDots = true;
    });
    if (questionCompletion['completed']) {
      final questionsData = {
        "completed": true,
        "incorrectQuestions": questionCompletion['incorrectQuestions'].length,
        "totalQuestions": questionCompletion['totalQuestions']
      };

      await followUpConversationWithTutor(null, null,
          questionsData: questionsData);
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
      final questionsData = {
        "completed": false,
      };

      await followUpConversationWithTutor(null, null,
          questionsData: questionsData);
      setState(() {
        showJumpToQuestionsButton = true;
        showContinuationButtons = false;
      });
    }
  }

  void afterMistakesCorrectionConversation() async {
    setState(() {
      showDots = true;
    });

    final questionsData = {"mistakesCorrected": true};

    await followUpConversationWithTutor(null, null,
        questionsData: questionsData);

    setState(() {
      showMistakeCorrectionButton = false;
      showCheckResultButton = true;
    });
    // conversationItemCreationForUser(contentText);
    // sendConversationItemToGemini(contentText);
  }

  Future<void> handleTextResponses() async {
    setState(() {
      _isLoading = true;
    });
    await followUpConversationWithTutor(null, userCurrentResponse);
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
        setState(() {
          firstLesson = false;
          _isLoading = true;
        });
        print('Audio path: $_audioPath');
        await followUpConversationWithTutor(File(_audioPath!), null);

        // await prefs.setBool("firstLesson", false);
      } else {
        print('Audio path is null or empty');
      }
    } else {
      await player.stopPlayer();
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

  Widget _buildRecordingButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
        // if (firstLesson) const SizedBox(height: 8),
        // if (firstLesson)
        //   Text(
        //     _isLoading ? "" : (isRecording ? 'Tap to send' : 'Tap to speak'),
        //     style: GoogleFonts.raleway(
        //       fontSize: 14,
        //       color: Colors.white,
        //     ),
        //     textAlign:
        //         TextAlign.center, // Center-align the microphone hint text
        //   ),
        // if (!showCheckpointContinueButton)
        SizedBox(
          width: 10,
        ),
        AbsorbPointer(
            absorbing: _isLoading,
            child: ChicletAnimatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  showTextBox = true;
                });
              },
              buttonType: ChicletButtonTypes.roundedRectangle,
              width: 50,
              height: 50,
              buttonColor: Color.fromRGBO(187, 160, 2, 1),
              backgroundColor: Color.fromRGBO(255, 217, 0, 1),
              child: Icon(
                Icons.keyboard,
                color: Color.fromRGBO(19, 31, 36, 1),
                size: 40,
              ),
            )),
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
    bool atleastOneCheckpointLeft =
        conceptCheckpoints.length - attemptedCheckpointIndexes.length >= 1;
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

              atleastOneCheckpointLeft
                  ? ChicletAnimatedButton(
                      onPressed: () async {
                        await player.stopPlayer();
                        Navigator.pop(context);
                        skipToNextCheckpoint(true);
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      width: double.infinity,
                      height: 50,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "BORED? JUMP AHEAD",
                        style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ChicletAnimatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // skipToNextCheckpoint(true);
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

  void _handleMessageSend(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      userCurrentResponse = message.trim();
    });
    player.stopPlayer();

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
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () => _handleMessageSend(_messageController.text),
            child: Icon(
              Icons.send,
              size: 24,
              color: _isLoading
                  ? Color.fromRGBO(63, 63, 62, 1)
                  : Color.fromRGBO(255, 217, 0, 1),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                showTextBox = false;
              });
            },
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    // final List<Map<String, dynamic>> displayedConversations =
    //     conversations.map((item) => Map<String, dynamic>.from(item)).toList();

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
                            child: greetingDone
                                ? Text(
                                    "Time to complete: ${_formatDuration(_timeLeftSeconds)}",
                                    style: GoogleFonts.arOneSans(
                                        color: Colors.white, fontSize: 18),
                                    overflow: TextOverflow
                                        .ellipsis, // Add ellipsis (...) when overflowing
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    widget.conceptName,
                                    style: GoogleFonts.raleway(
                                        color: Colors.white),
                                    overflow: TextOverflow
                                        .ellipsis, // Add ellipsis (...) when overflowing
                                    maxLines: 1, // Limit to a single line
                                  )),
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
                                      player.stopPlayer();
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
                                          }
                                          // webSocketService.disconnect();
                                          // webSocketService.connect();
                                          setState(() {
                                            showDots = true;
                                            showAfterGreetingContinueButton =
                                                false;
                                          });
                                          initializeSession();
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
                                GestureDetector(
                                  onTap: () {
                                    // Handle conversation click
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: showDots
                                        ? loadingMessage("")
                                        : othersMessage(
                                            conversations.last["text"]),
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

                                conversations.isNotEmpty
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
                                                  : TutorMessage(
                                                      tutorResponse:
                                                          latestTutorResponse,
                                                      messageBuilder:
                                                          othersMessage,
                                                      conceptId:
                                                          widget.conceptId,
                                                      checkpointNo:
                                                          currentCheckpointIndex +
                                                              1,
                                                    )),
                                        ),
                                      )
                                    : Spacer(),
                                if (!showContinuationButtons &&
                                    !showJumpToQuestionsButton &&
                                    !showMistakeCorrectionButton &&
                                    !showCheckResultButton &&
                                    !allCheckpointsCompleted)
                                  Divider(
                                    thickness: 0.5,
                                    color: Colors.grey.shade700,
                                  ),
                                if (!showContinuationButtons &&
                                    !showJumpToQuestionsButton &&
                                    !showMistakeCorrectionButton &&
                                    !showCheckResultButton &&
                                    !allCheckpointsCompleted)
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
                                    !showCheckResultButton &&
                                    !allCheckpointsCompleted)
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

                      if (showContinuationButtons)
                        Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                      afterQuestionsConversation(value);
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
                                      afterQuestionsConversation(value);
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
                                      afterMistakesCorrectionConversation();
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
                      // !responseStreaming &&
                      !showAfterGreetingContinueButton &&
                      !showCheckpointContinueButton)
                    Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Container(
                            color: Color.fromRGBO(19, 31, 36, 1),
                            child: showTextBox
                                ? renderMessageBar()
                                : _buildRecordingButton())),
                  if (!showContinuationButtons &&
                      !showJumpToQuestionsButton &&
                      !showMistakeCorrectionButton &&
                      !showCheckResultButton &&
                      !showDots &&
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
                                Expanded(
                                  // ⬅ gives it bounded width
                                  flex: showTextBox ? 3 : 1,

                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: showTextBox
                                        ? renderMessageBar()
                                        : _buildRecordingButton(),
                                  ),
                                ),
                              if (!showTextBox)
                                Expanded(
                                  flex: 2,
                                  child: ChicletAnimatedButton(
                                    onPressed: () async {
                                      await player.stopPlayer();
                                      if (showAfterGreetingContinueButton) {
                                        setState(() {
                                          greetingDone = true;
                                          showAfterGreetingContinueButton =
                                              false;
                                        });
                                        startLessonWithTutor();
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
