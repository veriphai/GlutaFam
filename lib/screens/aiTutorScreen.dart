import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:confetti/confetti.dart';
import 'package:eureka_app/apis/fetchConceptDetails.dart';
import 'package:eureka_app/apis/fetchLanguagesAndVoices.dart';
import 'package:eureka_app/apis/generateTutorResponse.dart';
import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
import 'package:eureka_app/utils/tutorAvatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:eureka_app/screens/checkpointFeedbackScreen.dart';
import 'package:lottie/lottie.dart';

enum InputMode { compact, recording, typing }

class AITutorScreen extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;
  final String name;
  final String subject;
  final int standard;
  final String? selectedLanguage;
  final String? selectedVoice;
  final Map<String, dynamic>? tutorSelected;
  final Map<String, dynamic>? dataToResume;
  final bool? resumeLesson;

  const AITutorScreen({
    Key? key,
    required this.conceptId,
    required this.conceptName,
    required this.maxXP,
    required this.name,
    required this.subject,
    required this.standard,
    this.selectedLanguage,
    this.selectedVoice,
    this.tutorSelected,
    this.dataToResume,
    this.resumeLesson,
  }) : super(key: key);

  @override
  State<AITutorScreen> createState() => _AITutorScreenState();
}

class _AITutorScreenState extends State<AITutorScreen> {
  // Core conversation + audio state (reused from ConceptLearningV4)
  final TextEditingController _messageController = TextEditingController();

  bool isRecording = false;
  FlutterSoundRecorder? _recorder;
  late FlutterSoundPlayer player;
  String? _audioPath;

  // Input UI state
  InputMode _inputMode = InputMode.compact;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // Lesson start state
  bool _showLessonStart = true;
  bool _objectivesExpanded = false;
  Map<String, bool> _expandedObjectives = {};

  // Language and voice options
  Map<String, String> languageOptions = {};
  Map<String, String> voiceOptions = {};
  bool _isLoadingLanguageVoice = true;

  bool _isLoading = false;
  bool greetingDone = false;
  bool showAfterGreetingContinueButton = false;
  bool showCheckpointContinueButton = false;
  bool showTextBox = false;
  bool showDots = true;

  int currentCheckpointIndex = 0;
  late List<Map<String, dynamic>> conceptCheckpoints = [];
  List<int> completedCheckpointIndexes = [];
  List<int> attemptedCheckpointIndexes = [];
  Map<String, dynamic> conceptDetails = {}; // Store complete concept details

  // Conversations as returned by backend
  List<Map<String, dynamic>> conversations = [];
  late Map<String, dynamic> latestTutorResponse = {};
  // Websocket side events (feedback, etc.) kept separate from conversations to avoid backend payload issues
  final List<Map<String, dynamic>> _wsEvents = [];

  // Gap tracking system - maps conversation turn index to list of gaps
  final Map<int, List<Map<String, dynamic>>> _conversationGaps = {};
  final Set<String> _resolvedGaps =
      {}; // Track resolved gaps by their text+severity combo

  // Timer + progress
  int _timeLeftSeconds = 0;
  Timer? _timer;

  // Helper method to merge backend conversations with frontend state
  // void _mergeConversations(List<Map<String, dynamic>> backendConversations,
  //     {bool isHintResponse = false}) {
  //   if (conversations.isEmpty) {
  //     // If no existing conversations, just use backend conversations
  //     conversations = backendConversations
  //         .map((conv) => Map<String, dynamic>.from(conv))
  //         .toList();
  //     return;
  //   }

  //   // Get the last 1-2 messages from backend to add to frontend
  //   List<Map<String, dynamic>> newMessages = [];

  //   if (backendConversations.length >= 2) {
  //     final secondLast = backendConversations[backendConversations.length - 2];
  //     final last = backendConversations[backendConversations.length - 1];

  //     // If second last is user and last is assistant, add both
  //     if (secondLast['role'] == 'user' && last['role'] == 'assistant') {
  //       newMessages = [secondLast, last];
  //     }
  //     // If second last is assistant too, add only the last one
  //     else if (secondLast['role'] == 'assistant' &&
  //         last['role'] == 'assistant') {
  //       newMessages = [last];
  //     }
  //     // Other cases, add the last message
  //     else {
  //       newMessages = [last];
  //     }
  //   } else if (backendConversations.length == 1) {
  //     // Only one message from backend, add it
  //     newMessages = [backendConversations.last];
  //   }

  //   // Add new messages to existing conversations
  //   for (final newMessage in newMessages) {
  //     // Check for transcribing bubble that needs to be replaced
  //     final transcribingIndex = conversations.indexWhere(
  //         (conv) => conv['role'] == 'user' && conv['isTranscribing'] == true);

  //     if (transcribingIndex != -1 && newMessage['role'] == 'user') {
  //       // Replace transcribing bubble with actual transcribed text
  //       conversations[transcribingIndex] =
  //           Map<String, dynamic>.from(newMessage);
  //       continue;
  //     }

  //     // Check for loading assistant bubble that needs to be replaced
  //     final loadingIndex = conversations.indexWhere(
  //         (conv) => conv['role'] == 'assistant' && conv['isLoading'] == true);

  //     if (loadingIndex != -1 && newMessage['role'] == 'assistant') {
  //       // Replace loading bubble with actual assistant response
  //       conversations[loadingIndex] = Map<String, dynamic>.from(newMessage);
  //       // Mark assistant messages as hints if this is a hint response
  //       if (isHintResponse) {
  //         conversations[loadingIndex]['isHint'] = true;
  //       }
  //       continue;
  //     }

  //     // Check if this message already exists (avoid duplicates)
  //     final existingIndex = conversations.indexWhere((conv) =>
  //         conv['role'] == newMessage['role'] &&
  //         conv['text'] == newMessage['text']);

  //     if (existingIndex == -1) {
  //       // Message doesn't exist, add it
  //       final messageToAdd = Map<String, dynamic>.from(newMessage);

  //       // Mark assistant messages as hints if this is a hint response
  //       if (isHintResponse && messageToAdd['role'] == 'assistant') {
  //         messageToAdd['isHint'] = true;
  //       }

  //       conversations.add(messageToAdd);
  //     }
  //   }
  // }

  // Helper method to merge backend conversations while preserving feedback markers
  void _mergeConversationsPreservingFeedback(
      List<Map<String, dynamic>> backendConversations,
      {bool isHintResponse = false}) {
    if (conversations.isEmpty) {
      // If no existing conversations, just use backend conversations and process all feedback
      conversations = backendConversations
          .map((conv) => Map<String, dynamic>.from(conv))
          .toList();
      _processAllConversationFeedback();
      return;
    }

    // Check if we need to replace the loading assistant bubble
    final loadingIndex = conversations.indexWhere(
        (conv) => conv['role'] == 'assistant' && conv['isLoading'] == true);

    if (loadingIndex != -1 && backendConversations.isNotEmpty) {
      final lastBackendMessage = backendConversations.last;
      if (lastBackendMessage['role'] == 'assistant') {
        // Replace loading bubble with actual assistant response
        conversations[loadingIndex] =
            Map<String, dynamic>.from(lastBackendMessage);
        if (isHintResponse) {
          conversations[loadingIndex]['isHint'] = true;
        }
      }
    } else {
      // No loading bubble to replace, check if we need to add new messages
      // Compare lengths to determine if new messages were added
      if (backendConversations.length > conversations.length) {
        // Add only the new messages from backend
        final newMessagesStartIndex = conversations.length;
        for (int i = newMessagesStartIndex;
            i < backendConversations.length;
            i++) {
          final newMessage = Map<String, dynamic>.from(backendConversations[i]);
          if (isHintResponse && newMessage['role'] == 'assistant') {
            newMessage['isHint'] = true;
          }
          conversations.add(newMessage);
        }
      } else if (backendConversations.length == conversations.length) {
        // Same length, update messages with fresh content while preserving evidence
        for (int i = 0; i < backendConversations.length; i++) {
          final backendMsg = backendConversations[i];
          final localMsg = conversations[i];

          // Update content if different
          if (backendMsg['text'] != localMsg['text'] ||
              backendMsg['content'] != localMsg['content']) {
            // Preserve existing feedback markers
            final correctEvidence = localMsg['correctEvidence'];
            final incorrectEvidence = localMsg['incorrectEvidence'];

            conversations[i] = Map<String, dynamic>.from(backendMsg);

            // Restore preserved feedback markers
            if (correctEvidence != null) {
              conversations[i]['correctEvidence'] = correctEvidence;
            }
            if (incorrectEvidence != null) {
              conversations[i]['incorrectEvidence'] = incorrectEvidence;
            }

            if (isHintResponse && backendMsg['role'] == 'assistant') {
              conversations[i]['isHint'] = true;
            }
          }
        }
      }
    }

    // Update all user messages with fresh feedback from backend
    for (int i = 0;
        i < backendConversations.length && i < conversations.length;
        i++) {
      final backendMsg = backendConversations[i];
      if (backendMsg['role'] == 'user' &&
          backendMsg['conversationFeedback'] != null) {
        // Update the conversation feedback with fresh data from backend
        conversations[i]['conversationFeedback'] =
            backendMsg['conversationFeedback'];
      }
    }

    // Process feedback for all conversations that have it but haven't been processed yet
    _processAllConversationFeedback();
  }

  // Process feedback for all conversations that have conversationFeedback
  void _processAllConversationFeedback() {
    for (int i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];

      if (conversation['role'] == 'user' &&
          conversation['conversationFeedback'] != null) {
        final feedback = conversation['conversationFeedback'];
        final highlights = feedback['highlights'] as Map<String, dynamic>?;

        if (highlights != null) {
          // Process Gaps
          final gaps = highlights['gaps'] as List<dynamic>?;
          if (gaps != null && gaps.isNotEmpty) {
            final gapsList = gaps
                .map((gap) => Map<String, dynamic>.from(gap as Map))
                .toList();
            _storeGapsForTurn(i, gapsList);

            // Only update _wsEvents for the latest user message to avoid duplicates
            final isLatestUserMessage = i ==
                conversations.lastIndexWhere((c) =>
                    c['role'] == 'user' && c['conversationFeedback'] != null);

            if (isLatestUserMessage) {
              _wsEvents.removeWhere((event) => event['role'] == 'gap');
              for (final gap in gapsList) {
                if (!_isGapResolved(gap)) {
                  _wsEvents.add({
                    'role': 'gap',
                    'data': gap,
                    'turnIndex': i,
                    'ts': DateTime.now().millisecondsSinceEpoch,
                  });
                }
              }
            }
          }

          // Process correct/incorrect evidence - always update with fresh feedback
          final correct = highlights['correct'] as List<dynamic>?;
          final incorrect = highlights['incorrect'] as List<dynamic>?;
          if (correct != null && correct.isNotEmpty) {
            conversations[i]['correctEvidence'] = correct
                .map((evidence) => Map<String, dynamic>.from(evidence as Map))
                .toList();
          } else {
            // Clear previous evidence if no correct evidence in current feedback
            conversations[i]['correctEvidence'] = null;
          }
          if (incorrect != null && incorrect.isNotEmpty) {
            conversations[i]['incorrectEvidence'] = incorrect
                .map((evidence) => Map<String, dynamic>.from(evidence as Map))
                .toList();
          } else {
            // Clear previous evidence if no incorrect evidence in current feedback
            conversations[i]['incorrectEvidence'] = null;
          }
        }
      }
    }
  }

  // Preferences / selections
  late SharedPreferences prefs;
  String selectedLanguage = "en-US";
  String selectedVoice = "alloy";
  late Map<String, dynamic> selectedTutor = {'id': "persona-1"};
  String tutorName = "Tuto Prime";

  // Misc
  late ConfettiController _confettiController;
  String conceptConversationsKey = "";
  String studentName = "";

  // Websocket for audio stream
  late StompClient stompClient;

  // XP and lesson tracking
  int xpGained = 0;
  DateTime lessonStartTime = DateTime.now();
  int timeTakenToCompleteLessonWithAiTutor = 0;

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    studentName = widget.name;
    selectedTutor = widget.tutorSelected ?? selectedTutor;
    if (selectedTutor.isNotEmpty && selectedTutor['name'] != null) {
      tutorName = selectedTutor['name'];
    }

    conceptConversationsKey =
        "${widget.name}_${widget.conceptId}_${DateTime.now().millisecondsSinceEpoch}";
    _subscribeToTopic(conceptConversationsKey);

    player = FlutterSoundPlayer();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    _initPlayer();

    // Add listener to text controller for send button state
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPrefsAndOptions();
    await _getConceptDetails();
    await _loadLanguageAndVoiceOptions();

    if (widget.resumeLesson == true) {
      final resumedConversations =
          (widget.dataToResume?["conversations"] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];
      // _mergeConversations(resumedConversations);
      conceptConversationsKey = widget.dataToResume?["conceptConversationsKey"];
      currentCheckpointIndex = widget.dataToResume?["checkpointNo"] ?? 0;
      greetingDone = true;
      _timeLeftSeconds =
          widget.dataToResume?["remainingTime"] ?? _timeLeftSeconds;
      _startCountdown();
      // If resuming, don't show lesson start screen
      setState(() {
        _showLessonStart = false;
      });
      await _followUpConversation(null, null,
          newCheckpointStarted: widget.dataToResume?["newCheckpointStarted"],
          resumeLesson: true,
          learningObjectivesStatus:
              widget.dataToResume?["learningObjectivesStatus"]);
    } else {
      // For new lessons, fetch greeting message for lesson start screen
      // await _loadLanguageAndVoiceOptions();
      await _initializeSession();
    }
  }

  // ---------- Backend integrations (mostly copied from V4) ----------

  void _subscribeToTopic(String conversationKey) {
    stompClient = StompClient(
      config: StompConfig(
        url: 'wss://glutaclass.com:8080/gluta/ws',
        onConnect: (frame) {
          stompClient.subscribe(
            destination: '/topic/$conversationKey',
            callback: (message) async {
              final payload = json.decode(message.body!);
              if (payload['type'] == 'transcription_complete') {
                final transcribed_text = payload['payload']['transcribed_text'];

                for (final newMessage in conversations) {
                  // Check for transcribing bubble that needs to be replaced
                  final transcribingIndex = conversations.indexWhere((conv) =>
                      conv['role'] == 'user' && conv['isTranscribing'] == true);

                  if (transcribingIndex != -1 && newMessage['role'] == 'user') {
                    // Replace transcribing bubble with actual transcribed text
                    final transcribedConversation = {
                      'role': 'user',
                      'content': '',
                      'text': transcribed_text,
                      'latest': true,
                      'greeting': false,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                    };
                    conversations[transcribingIndex] =
                        Map<String, dynamic>.from(transcribedConversation);
                    continue;
                  }
                }
              } else if (payload['type'] == 'audio') {
                final base64Audio = payload['payload']['audio'];
                if (base64Audio != null) {
                  await _playBase64Audio(base64Audio, conversationKey);
                }
              } else if (payload['type'] == 'question_extracted') {
                final question = payload['payload']?['question'];
                if (question != null) {
                  setState(() {
                    // Find the assistant conversation that doesn't already have an extracted question
                    // This should be the most recent assistant message that needs question extraction
                    int targetAssistantIndex = -1;
                    for (int i = conversations.length - 1; i >= 0; i--) {
                      if (conversations[i]['role'] == 'assistant' &&
                          conversations[i]['greeting'] == false) {
                        // Check if this assistant message already has an extracted question
                        if (conversations[i]['extractedQuestion'] == null) {
                          targetAssistantIndex = i;
                          break;
                        }
                      }
                    }

                    // If no assistant message without extracted question found, fall back to latest
                    if (targetAssistantIndex == -1) {
                      for (int i = conversations.length - 1; i >= 0; i--) {
                        if (conversations[i]['role'] == 'assistant') {
                          targetAssistantIndex = i;
                          break;
                        }
                      }
                    }

                    if (targetAssistantIndex != -1) {
                      conversations[targetAssistantIndex]['extractedQuestion'] =
                          question;

                      // Remove the extracted question from the original message text to avoid duplication
                      final originalText =
                          conversations[targetAssistantIndex]['text'] ?? '';
                      final cleanedText =
                          _removeQuestionFromText(originalText, question);
                      conversations[targetAssistantIndex]['text'] = cleanedText;
                    }
                  });
                }
              } else if (payload['type'] == 'keywords_extracted') {
                final keywords = payload['payload']?['keywords'];
                final phrases = payload['payload']?['phrases'];
                final definitions = payload['payload']?['definitions'];

                if (keywords != null ||
                    phrases != null ||
                    definitions != null) {
                  setState(() {
                    // Find the assistant conversation that doesn't already have keywords/phrases/definitions
                    // This should be the most recent assistant message that needs keyword extraction
                    int targetAssistantIndex = -1;
                    for (int i = conversations.length - 1; i >= 0; i--) {
                      if (conversations[i]['role'] == 'assistant') {
                        // Check if this assistant message already has keywords/phrases/definitions
                        if (conversations[i]['keywords'] == null &&
                            conversations[i]['phrases'] == null &&
                            conversations[i]['definitions'] == null) {
                          targetAssistantIndex = i;
                          break;
                        }
                      }
                    }

                    // If no assistant message without keywords found, fall back to latest
                    if (targetAssistantIndex == -1) {
                      for (int i = conversations.length - 1; i >= 0; i--) {
                        if (conversations[i]['role'] == 'assistant') {
                          targetAssistantIndex = i;
                          break;
                        }
                      }
                    }

                    if (targetAssistantIndex != -1) {
                      // Split comma-separated strings into lists
                      if (keywords != null && keywords.toString().isNotEmpty) {
                        conversations[targetAssistantIndex]['keywords'] =
                            keywords
                                .toString()
                                .split(',')
                                .map((k) => k.trim())
                                .where((k) => k.isNotEmpty)
                                .toList();
                      }
                      if (phrases != null && phrases.toString().isNotEmpty) {
                        conversations[targetAssistantIndex]['phrases'] = phrases
                            .toString()
                            .split(',')
                            .map((p) => p.trim())
                            .where((p) => p.isNotEmpty)
                            .toList();
                      }
                      if (definitions != null &&
                          definitions.toString().isNotEmpty) {
                        conversations[targetAssistantIndex]['definitions'] =
                            definitions
                                .toString()
                                .split(',')
                                .map((d) => d.trim())
                                .where((d) => d.isNotEmpty)
                                .toList();
                      }
                    }
                  });
                }
              }
            },
          );
        },
        onWebSocketError: (error) => debugPrint('WS error: $error'),
      ),
    );
    stompClient.activate();
  }

  Future<void> _loadPrefsAndOptions() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final data = await fetchLanguagesAndVoices();
      final List<dynamic> languages = data['languages'] ?? [];
      final List<dynamic> voices = data['voices'] ?? [];
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
    } catch (e) {
      debugPrint("Error loading prefs/options: $e");
    }
  }

  Future<void> _initializeSession() async {
    try {
      final tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: studentName,
          checkpointNo: 0,
          conceptConversationsKey: conceptConversationsKey,
          language: selectedLanguage,
          voice: selectedVoice,
          remainingTime: _timeLeftSeconds,
          greeting: true);

      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [];

      setState(() {
        // Use merge function for consistency, though this is initial setup
        _mergeConversationsPreservingFeedback(conversationsList);
        showDots = false;
        showAfterGreetingContinueButton = true;
      });
    } catch (e) {
      debugPrint("Error initializeSession: $e");
    }
  }

  Future<void> _fetchNewGreeting() async {
    try {
      final tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: studentName,
          checkpointNo: 0,
          conceptConversationsKey: conceptConversationsKey,
          language: selectedLanguage,
          voice: selectedVoice,
          remainingTime: _timeLeftSeconds,
          greeting: true);

      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [];

      setState(() {
        // Update only the first greeting message, keep rest of conversation intact
        if (conversationsList.isNotEmpty &&
            conversationsList[0]['role'] == 'assistant') {
          if (conversations.isEmpty) {
            // If no conversations yet, add the new greeting
            conversations.add(Map<String, dynamic>.from(conversationsList[0]));
          } else {
            // Update the first conversation (greeting) with new message
            conversations[0] =
                Map<String, dynamic>.from(conversationsList.last);
          }
        }
        showDots = false;
        showAfterGreetingContinueButton = true;
      });
    } catch (e) {
      debugPrint("Error fetchNewGreeting: $e");
      setState(() {
        showDots = false;
      });
    }
  }

  Future<void> _getConceptDetails() async {
    try {
      final details = await fetchConceptDetails(conceptId: widget.conceptId);
      setState(() {
        conceptDetails = details; // Store complete details
        conceptCheckpoints = (details["conceptCheckpoints"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _timeLeftSeconds = ((details["expectedCompletionTime"] ??
                conceptCheckpoints.length * 5) as int) *
            60;
      });
    } catch (e) {
      debugPrint("Error fetching concept details: $e");
    }
  }

  Future<void> _startLessonWithTutor() async {
    try {
      _startCountdown();
      setState(() => showDots = true);
      logAITutorCheckpointStart(
          conceptCheckpoints[currentCheckpointIndex]['id'],
          widget.conceptId,
          currentCheckpointIndex + 1);
      final tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: studentName,
          checkpointNo: 0,
          conceptConversationsKey: conceptConversationsKey,
          conversations: conversations,
          language: selectedLanguage,
          voice: selectedVoice,
          remainingTime: _timeLeftSeconds,
          firstConversation: true);

      latestTutorResponse = tutorResponse;

      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [];
      setState(() {
        // Use merge function for consistency, though this is lesson start
        _mergeConversationsPreservingFeedback(conversationsList);
        showDots = false;
      });
    } catch (e) {
      debugPrint("Error startLessonWithTutor: $e");
    }
  }

  Future<void> _followUpConversation(File? audioFile, String? text,
      {bool newCheckpointStarted = false,
      bool allCheckpointCompleted = false,
      bool resumeLesson = false,
      Map<String, dynamic>? questionsData,
      Map<String, dynamic>? learningObjectivesStatus,
      bool? hintRequest,
      String? userPromptType,
      String? userPromptText}) async {
    try {
      // If userPromptText is provided, add it as a user message first
      if (userPromptText != null && userPromptText.isNotEmpty) {
        setState(() {
          conversations.add({
            'role': 'user',
            'content': userPromptText,
            'text': userPromptText,
            'latest': true,
            'greeting': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          // Mark previous message as not latest
          if (conversations.length >= 2) {
            conversations[conversations.length - 2]['latest'] = false;
          }
        });
      }

      setState(() {
        showDots = true;
        // Add a temporary loading assistant bubble
        conversations.add({
          'role': 'assistant',
          'content': '',
          'text': '',
          'latest': true,
          'greeting': false,
          'isLoading': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // Mark previous message as not latest
        if (conversations.length >= 2) {
          conversations[conversations.length - 2]['latest'] = false;
        }
      });

      final tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: studentName,
          checkpointNo: currentCheckpointIndex,
          conversations: conversations,
          audioFile: audioFile,
          newCheckpointStarted: newCheckpointStarted,
          allCheckpointCompleted: allCheckpointCompleted,
          studentResponse: text,
          conceptConversationsKey: conceptConversationsKey,
          questionsData: questionsData,
          language: selectedLanguage,
          learningObjectivesStatus: learningObjectivesStatus,
          resumeLesson: resumeLesson,
          remainingTime: _timeLeftSeconds,
          voice: selectedVoice,
          hintRequest: hintRequest,
          userPromptType: userPromptType);

      latestTutorResponse = tutorResponse;

      final bool currentCheckpointCompletionStatus =
          tutorResponse['currentCheckpointCompleted'];
      final bool skipAhead = tutorResponse['enableCheckpointContinueButton'];
      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [];

      if (conversationsList.isNotEmpty &&
          conversationsList.length >= 2 &&
          conversationsList[conversationsList.length - 2]['role'] == 'user') {
        conversationsList[conversationsList.length - 2]['latest'] = false;
      }

      if (currentCheckpointCompletionStatus || skipAhead) {
        if (currentCheckpointCompletionStatus) {
          completedCheckpointIndexes.add(currentCheckpointIndex);
          attemptedCheckpointIndexes.add(currentCheckpointIndex);
          logAITutorCheckpointEnd(
              conceptCheckpoints[currentCheckpointIndex]['id'],
              widget.conceptId,
              currentCheckpointIndex + 1);
        } else if (skipAhead) {
          attemptedCheckpointIndexes.add(currentCheckpointIndex);
          logAITutorCheckpointSkippedOnUserIntent(
              conceptCheckpoints[currentCheckpointIndex]['id'],
              widget.conceptId,
              currentCheckpointIndex + 1);
        }
        setState(() {
          showCheckpointContinueButton = true;
          showDots = false;
          showTextBox = false;
        });
      }

      setState(() {
        // Merge conversations incrementally to preserve feedback markers
        _mergeConversationsPreservingFeedback(conversationsList,
            isHintResponse: hintRequest == true);
        showDots = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error followUp: $e");
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
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await _recorder!.openRecorder();
    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
  }

  Future<void> _initPlayer() async {
    await player.openPlayer();
    await player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 24000,
    );
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        setState(() => _timeLeftSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  // ---------- UI helpers ----------

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }

  double _progress() {
    if (conceptCheckpoints.isEmpty) return 0.0;
    return (currentCheckpointIndex + 1) / conceptCheckpoints.length;
  }

  String _makeHint() {
    return "Start from what you already know → define terms in your own words → make one small prediction. If unsure, compare two tiny examples.";
  }

  // Helper method to remove extracted question from original message text
  String _removeQuestionFromText(String originalText, String questionToRemove) {
    if (originalText.isEmpty || questionToRemove.isEmpty) {
      return originalText;
    }

    // Try exact match removal first
    String cleanedText = originalText.replaceAll(questionToRemove, '').trim();

    // If exact match didn't work, try fuzzy matching
    if (cleanedText == originalText) {
      // Split question into words and try to find and remove the longest matching substring
      final questionWords =
          questionToRemove.toLowerCase().split(RegExp(r'\s+'));
      final originalWords = originalText.toLowerCase().split(RegExp(r'\s+'));

      // Find the longest consecutive match
      int bestStart = -1;
      int bestLength = 0;

      for (int i = 0; i <= originalWords.length - questionWords.length; i++) {
        int matchLength = 0;
        for (int j = 0;
            j < questionWords.length && i + j < originalWords.length;
            j++) {
          if (originalWords[i + j].contains(questionWords[j]) ||
              questionWords[j].contains(originalWords[i + j])) {
            matchLength++;
          } else {
            break;
          }
        }

        if (matchLength > bestLength &&
            matchLength >= questionWords.length * 0.7) {
          bestStart = i;
          bestLength = matchLength;
        }
      }

      if (bestStart != -1) {
        final originalWordsList = originalText.split(RegExp(r'\s+'));
        originalWordsList.removeRange(bestStart, bestStart + bestLength);
        cleanedText = originalWordsList.join(' ').trim();
      }
    }

    // Clean up any double spaces or punctuation issues
    cleanedText = cleanedText
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+([.!?])'), r'$1')
        .trim();

    // If we removed too much text (more than 70% of original), return original
    // if (cleanedText.length < originalText.length * 0.3) {
    //   return originalText;
    // }

    return cleanedText.isNotEmpty ? cleanedText : originalText;
  }

  // Helper method to build highlighted text spans
  List<TextSpan> _buildHighlightedText(
      String text, Map<String, dynamic> conversation) {
    final List<String> keywords =
        (conversation['keywords'] as List?)?.cast<String>() ?? [];
    final List<String> phrases =
        (conversation['phrases'] as List?)?.cast<String>() ?? [];
    final List<String> definitions =
        (conversation['definitions'] as List?)?.cast<String>() ?? [];

    // Combine all terms to highlight, with their respective colors
    final Map<String, Color> highlightTerms = {};

    // Add keywords with blue highlighting
    for (final keyword in keywords) {
      if (keyword.trim().isNotEmpty) {
        highlightTerms[keyword.trim().toLowerCase()] = const Color(0xFF1D4ED8);
      }
    }

    // Add phrases with green highlighting
    for (final phrase in phrases) {
      if (phrase.trim().isNotEmpty) {
        highlightTerms[phrase.trim().toLowerCase()] = const Color(0xFF059669);
      }
    }

    // Add definitions with purple highlighting
    for (final definition in definitions) {
      if (definition.trim().isNotEmpty) {
        highlightTerms[definition.trim().toLowerCase()] =
            const Color(0xFF7C3AED);
      }
    }

    if (highlightTerms.isEmpty) {
      // No highlighting needed
      return [
        TextSpan(
            text: text,
            style: GoogleFonts.raleway(
                fontSize: 15, height: 1.4, color: const Color(0xFF0B1220)))
      ];
    }

    // Sort terms by length (longest first) to handle overlapping matches correctly
    final sortedTerms = highlightTerms.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      bool foundMatch = false;

      // Try to find a match at the current position
      for (final term in sortedTerms) {
        final lowerText = text.toLowerCase();
        final matchIndex = lowerText.indexOf(term, currentIndex);

        if (matchIndex == currentIndex) {
          // Found a match at current position
          final originalTerm =
              text.substring(matchIndex, matchIndex + term.length);

          spans.add(TextSpan(
            text: originalTerm,
            style: GoogleFonts.raleway(
              fontSize: 15,
              height: 1.0, // Tight height to reduce background coverage
              color: Colors.white,
              fontWeight: FontWeight.w600,
              backgroundColor: highlightTerms[term]!.withOpacity(0.8),
              // letterSpacing: 0.5,
            ),
          ));

          currentIndex = matchIndex + term.length;
          foundMatch = true;
          break;
        }
      }

      if (!foundMatch) {
        // No match found, add the current character and move on
        final nextMatchIndex = _findNextMatch(text, currentIndex, sortedTerms);
        final endIndex = nextMatchIndex != -1 ? nextMatchIndex : text.length;

        if (endIndex > currentIndex) {
          spans.add(TextSpan(
              text: text.substring(currentIndex, endIndex),
              style: GoogleFonts.raleway(
                  fontSize: 15, height: 1.4, color: const Color(0xFF0B1220))));
          currentIndex = endIndex;
        }
      }
    }

    return spans;
  }

  // Helper method to find the next match position
  int _findNextMatch(String text, int startIndex, List<String> terms) {
    int nearestMatch = -1;
    final lowerText = text.toLowerCase();

    for (final term in terms) {
      final matchIndex = lowerText.indexOf(term, startIndex);
      if (matchIndex != -1) {
        if (nearestMatch == -1 || matchIndex < nearestMatch) {
          nearestMatch = matchIndex;
        }
      }
    }

    return nearestMatch;
  }

  // Helper method to build highlighted text spans for user messages with feedback
  List<TextSpan> _buildUserFeedbackHighlightedText(
      String text, Map<String, dynamic> conversation) {
    final List<Map<String, dynamic>> correctEvidence =
        (conversation['correctEvidence'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
    final List<Map<String, dynamic>> incorrectEvidence =
        (conversation['incorrectEvidence'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

    // Combine all evidence to highlight with their respective colors
    final Map<String, Color> highlightTerms = {};

    // Add correct evidence with green highlighting
    for (final evidence in correctEvidence) {
      final text = evidence['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        highlightTerms[text.toLowerCase()] = const Color(0xFF059669);
      }
    }

    // Add incorrect evidence with red highlighting
    for (final evidence in incorrectEvidence) {
      final text = evidence['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        highlightTerms[text.toLowerCase()] = const Color(0xFFDC2626);
      }
    }

    if (highlightTerms.isEmpty) {
      // No highlighting needed
      return [
        TextSpan(
            text: text,
            style: GoogleFonts.raleway(
                fontSize: 15, height: 1.4, color: const Color(0xFF0B1220)))
      ];
    }

    // Sort terms by length (longest first) to handle overlapping matches correctly
    final sortedTerms = highlightTerms.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      bool foundMatch = false;

      // Try to find a match at the current position
      for (final term in sortedTerms) {
        final lowerText = text.toLowerCase();
        final matchIndex = lowerText.indexOf(term, currentIndex);

        if (matchIndex == currentIndex) {
          // Found a match at current position
          final originalTerm =
              text.substring(matchIndex, matchIndex + term.length);

          spans.add(TextSpan(
            text: originalTerm,
            style: GoogleFonts.raleway(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.0,
              backgroundColor: highlightTerms[term]!.withOpacity(0.8),
            ),
          ));

          currentIndex = matchIndex + term.length;
          foundMatch = true;
          break;
        }
      }

      if (!foundMatch) {
        // No match found, add the current character and move on
        final nextMatchIndex =
            _findNextUserMatch(text, currentIndex, sortedTerms);
        final endIndex = nextMatchIndex != -1 ? nextMatchIndex : text.length;

        if (endIndex > currentIndex) {
          spans.add(TextSpan(
              text: text.substring(currentIndex, endIndex),
              style: GoogleFonts.raleway(
                  fontSize: 15, height: 1.4, color: const Color(0xFF0B1220))));
          currentIndex = endIndex;
        }
      }
    }

    return spans;
  }

  // Helper method to find the next match position for user feedback
  int _findNextUserMatch(String text, int startIndex, List<String> terms) {
    int nearestMatch = -1;
    final lowerText = text.toLowerCase();

    for (final term in terms) {
      final matchIndex = lowerText.indexOf(term, startIndex);
      if (matchIndex != -1) {
        if (nearestMatch == -1 || matchIndex < nearestMatch) {
          nearestMatch = matchIndex;
        }
      }
    }

    return nearestMatch;
  }

  // Helper method to get unique gap ID
  String _getGapId(Map<String, dynamic> gap) {
    final text = gap['text'] ?? '';
    final severity = gap['severity'] ?? 0;
    return '${text}_$severity';
  }

  // Helper method to check if gap is resolved
  bool _isGapResolved(Map<String, dynamic> gap) {
    return _resolvedGaps.contains(_getGapId(gap));
  }

  // Helper method to mark gap as resolved
  void _markGapResolved(Map<String, dynamic> gap) {
    _resolvedGaps.add(_getGapId(gap));
  }

  // Helper method to get gaps for current conversation turn
  List<Map<String, dynamic>> _getActiveGapsForTurn(int turnIndex) {
    final gaps = _conversationGaps[turnIndex] ?? [];
    return gaps.where((gap) => !_isGapResolved(gap)).toList();
  }

  // Helper method to store gaps for a conversation turn
  void _storeGapsForTurn(int turnIndex, List<Map<String, dynamic>> gaps) {
    if (gaps.isNotEmpty) {
      _conversationGaps[turnIndex] = gaps;
    }
  }

  Future<void> _startRecording() async {
    if (_isLoading) return;

    await player.stopPlayer();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidWillPauseWhenDucked: false,
    ));
    final tempDir = await getTemporaryDirectory();
    _audioPath = '${tempDir.path}/audio_record.wav';
    await _recorder!.startRecorder(
        toFile: _audioPath, codec: Codec.pcm16WAV, sampleRate: 24000);

    setState(() {
      isRecording = true;
      _inputMode = InputMode.recording;
      _recordingSeconds = 0;
    });

    // Start recording timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    _recordingTimer?.cancel();
    setState(() {
      isRecording = false;
      _inputMode = InputMode.compact;
      _recordingSeconds = 0;
    });
  }

  Future<void> _sendRecording() async {
    await _stopRecording();
    if (_audioPath != null && _audioPath!.isNotEmpty) {
      setState(() {
        // Clear old gap events when user sends audio message
        _wsEvents.removeWhere((event) => event['role'] == 'gap');

        // Add a temporary transcribing user bubble
        conversations.add({
          'role': 'user',
          'content': '',
          'text': '',
          'latest': true,
          'greeting': false,
          'isTranscribing': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        // Mark previous message as not latest
        if (conversations.length >= 2) {
          conversations[conversations.length - 2]['latest'] = false;
        }
      });

      await _followUpConversation(File(_audioPath!), null);
    }
  }

  void _cancelRecording() async {
    await _stopRecording();
  }

  void _switchToTyping() {
    setState(() {
      _inputMode = InputMode.typing;
    });
  }

  void _switchToCompact() {
    setState(() {
      _inputMode = InputMode.compact;
    });
  }

  void _onSendText() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message immediately
    setState(() {
      _inputMode = InputMode.compact;
      // Clear old gap events when user sends a new message
      _wsEvents.removeWhere((event) => event['role'] == 'gap');

      // Add the user message immediately
      conversations.add({
        'role': 'user',
        'content': text,
        'text': text,
        'latest': true,
        'greeting': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      // Mark previous message as not latest
      if (conversations.length >= 2) {
        conversations[conversations.length - 2]['latest'] = false;
      }
    });

    player.stopPlayer();
    _messageController.clear();
    _followUpConversation(null, text);
  }

  void _continueFlow() async {
    await player.stopPlayer();
    if (showAfterGreetingContinueButton) {
      setState(() {
        greetingDone = true;
        showAfterGreetingContinueButton = false;
      });
      _startLessonWithTutor();
    } else if (showCheckpointContinueButton) {
      if (currentCheckpointIndex == conceptCheckpoints.length - 1) {
        setState(() {
          xpGained += 45;
        });
        _moveToQuestionsPhase();
      } else {
        _moveToNextCheckpoint();
      }
    }
  }

  void _moveToNextCheckpoint() async {
    setState(() {
      showDots = true;
      showCheckpointContinueButton = false;
    });
    currentCheckpointIndex += 1;
    await _followUpConversation(null, null, newCheckpointStarted: true);
    logAITutorCheckpointStart(conceptCheckpoints[currentCheckpointIndex]['id'],
        widget.conceptId, currentCheckpointIndex + 1);
  }

  void _skipToNextCheckpoint() async {
    setState(() {
      showDots = true;
      showCheckpointContinueButton = false;
    });
    attemptedCheckpointIndexes.add(currentCheckpointIndex);
    logAITutorCheckpointSkipped(
        conceptCheckpoints[currentCheckpointIndex]['id'],
        widget.conceptId,
        currentCheckpointIndex + 1);
    currentCheckpointIndex += 1;
    await _followUpConversation(null, null, newCheckpointStarted: true);
    logAITutorCheckpointStart(conceptCheckpoints[currentCheckpointIndex]['id'],
        widget.conceptId, currentCheckpointIndex + 1);
  }

  void _moveToQuestionsPhase() async {
    setState(() => showDots = true);
    await _followUpConversation(null, null, allCheckpointCompleted: true);
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    if (player.isPlaying) {
      player.stopPlayer();
    }
    player.closePlayer();
    _confettiController.dispose();
    _timer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLessonStart || widget.resumeLesson == true) {
      return _buildLessonStartScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6EDDA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Time to complete",
                              style: GoogleFonts.raleway(
                                  fontSize: 12,
                                  color: const Color(0xFF70695B))),
                          const SizedBox(height: 2),
                          Text(_formatTime(_timeLeftSeconds),
                              style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0B1220))),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _openMenuSheet(context);
                      },
                      icon: const Icon(Icons.more_vert),
                      color: const Color(0xFF0B1220),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEADFC8),
                      borderRadius: BorderRadius.circular(999)),
                  clipBehavior: Clip.antiAlias,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(builder: (context, c) {
                      final w = c.maxWidth * _progress();
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: w,
                        decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8),
                            borderRadius: BorderRadius.circular(999)),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE7DEC9)),
                          borderRadius: BorderRadius.circular(999)),
                      child: Row(children: [
                        Text("Studying with ",
                            style: GoogleFonts.raleway(
                                fontSize: 12, color: const Color(0xFF70695B))),
                        Text(tutorName,
                            style: GoogleFonts.raleway(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0B1220))),
                      ]),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 140),
                  itemCount: conversations.length + _wsEvents.length,
                  itemBuilder: (context, index) {
                    if (index < conversations.length) {
                      final convo = conversations[index];
                      if (convo['greeting']) return const SizedBox.shrink();
                      final role = convo['role'];
                      if (role == 'assistant') {
                        return _assistantBubble(convo['text'] ?? "", index);
                      } else if (role == 'user') {
                        return _userBubble(convo['text'] ?? "", convo);
                      }
                      return const SizedBox.shrink();
                    } else {
                      final event = _wsEvents[index - conversations.length];
                      final role = event['role'];
                      if (role == 'gap') {
                        return _gapCard(event['data'] as Map<String, dynamic>,
                            event['turnIndex'] as int);
                      } else if (role == 'turn_feedback') {
                        return _turnFeedbackCard(
                            event['data'] as Map<String, dynamic>);
                      } else if (role == 'cp_feedback') {
                        return _cumulativeFeedbackCard(
                            event['data'] as Map<String, dynamic>);
                      }
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          ),

          // Floating hint/simplify buttons
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                _circleAction(
                  icon: Icons.lightbulb_outline,
                  onTap: () {
                    _followUpConversation(null, null, hintRequest: true);
                  },
                ),
                const SizedBox(height: 10),
                _circleAction(
                  icon: Icons.auto_fix_high_outlined,
                  onTap: () {
                    _openPromptSheet(context);
                  },
                ),
              ],
            ),
          ),

          // Interactive Island Input UI
          Positioned(
            left: 0,
            right: 0,
            bottom: (showAfterGreetingContinueButton ||
                        showCheckpointContinueButton) &&
                    !showDots
                ? 90
                : 12,
            child: _buildInputIsland(),
          ),

          // Continue CTA (at the very bottom)
          if ((showAfterGreetingContinueButton ||
                  showCheckpointContinueButton) &&
              !showDots)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _continueFlow,
                  child: Text(
                    showAfterGreetingContinueButton
                        ? "CONTINUE"
                        : "CONTINUE WITH AI TUTOR  ·  +45 XP",
                    style: GoogleFonts.raleway(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EDDA),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7DEC9)),
            ),
            child: const Icon(Icons.chevron_left,
                color: Color(0xFF0B1220), size: 18),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conceptName,
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0B1220),
              ),
            ),
            Text(
              '${widget.subject} · Ratios & Proportions',
              style: GoogleFonts.raleway(
                fontSize: 13,
                color: const Color(0xFF70695B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7DEC9)),
              ),
              child: const Icon(Icons.info_outline,
                  color: Color(0xFF0B1220), size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              child: Column(
                children: [
                  _buildGreetingBubble(),
                  const SizedBox(height: 12),
                  _buildLessonInfoCard(),
                  const SizedBox(height: 12),
                  _buildLearningObjectivesCard(),
                  const SizedBox(height: 12),
                  _buildTutorControlsCard(),
                  const SizedBox(height: 12),
                  _buildBestPracticesCard(),
                ],
              ),
            ),
          ),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildGreetingBubble() {
    // Get the first assistant message if it exists
    var greetingMessage =
        conversations.isNotEmpty && conversations[0]['role'] == 'assistant'
            ? conversations[0]['text'] ?? ''
            : '';
    if (widget.resumeLesson == true) {
      greetingMessage =
          conversations.isNotEmpty && conversations.last['role'] == 'assistant'
              ? conversations.last['text'] ?? ''
              : '';
    }

    // Show loading when conversations are empty or when dots are showing
    final isLoading = conversations.isEmpty || showDots;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF22D3EE), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF0B1220),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7DEC9)),
              ),
              child: isLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF70695B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading greeting...',
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            color: const Color(0xFF70695B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      greetingMessage,
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        color: const Color(0xFF0B1220),
                        height: 1.4,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfoCard() {
    final checkpointCount = conceptCheckpoints.length;
    final estimatedTime = _getEstimatedTime();
    final currentLevel = _getCurrentDifficultyLevel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoTile('Checkpoints', '$checkpointCount'),
              const SizedBox(width: 12),
              _buildInfoTile('Time', '$estimatedTime min',
                  icon: Icons.schedule),
              const SizedBox(width: 12),
              _buildInfoTile('Level', currentLevel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLevelButton('Easy'),
              const SizedBox(width: 8),
              _buildLevelButton('Medium'),
              const SizedBox(width: 8),
              _buildLevelButton('Hard'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Level adjusts time & objectives',
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    color: const Color(0xFF70695B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7DEC9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 11,
                color: const Color(0xFF70695B),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: const Color(0xFF0B1220)),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B1220),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(String level) {
    final currentLevel = _getCurrentDifficultyLevel();
    final isSelected = level == currentLevel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE7DEC9),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(
        level,
        style: GoogleFonts.raleway(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: const Color(0xFF0B1220),
        ),
      ),
    );
  }

  int _getEstimatedTime() {
    // Use actual expectedCompletionTime from concept details
    final expectedTime = conceptDetails["expectedCompletionTime"];
    if (expectedTime != null && expectedTime is int) {
      return expectedTime; // Already in minutes
    }

    // Fallback calculation if no expected time
    if (conceptCheckpoints.isEmpty) return 15;
    return conceptCheckpoints.length * 5; // 5 minutes per checkpoint
  }

  String _getCurrentDifficultyLevel() {
    // For now, default to Medium. You can implement level selection logic here
    return 'Medium';
  }

  Widget _buildLearningObjectivesCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _objectivesExpanded = !_objectivesExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.flag, size: 16, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Learning objectives',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE7DEC9)),
                    ),
                    child: Text(
                      '${_getTotalObjectivesCount()}',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        color: const Color(0xFF70695B),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _objectivesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: const Color(0xFF70695B),
                  ),
                ],
              ),
            ),
          ),
          if (_objectivesExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildToggleButton(
                          'Expand all', () => _toggleAllObjectives(true)),
                      const SizedBox(width: 8),
                      _buildToggleButton(
                          'Collapse all', () => _toggleAllObjectives(false)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...conceptCheckpoints.asMap().entries.map((entry) {
                    final index = entry.key;
                    final checkpoint = entry.value;
                    return _buildObjectiveItem(index, checkpoint);
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7DEC9)),
        ),
        child: Text(
          text,
          style: GoogleFonts.raleway(
            fontSize: 11,
            color: const Color(0xFF0B1220),
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveItem(int index, Map<String, dynamic> checkpoint) {
    final isExpanded = _expandedObjectives[checkpoint['id']] ?? false;
    final objectives = _getObjectivesForCheckpoint(checkpoint);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7DEC9)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
                () => _expandedObjectives[checkpoint['id']] = !isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      checkpoint['name'] ?? 'Checkpoint ${index + 1}',
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        color: const Color(0xFF0B1220),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${objectives.length}',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        color: const Color(0xFF0B1220),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: const Color(0xFF70695B),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: objectives
                    .map(
                      (objective) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ',
                                style: GoogleFonts.raleway(
                                    fontSize: 14,
                                    color: const Color(0xFF0B1220))),
                            Expanded(
                              child: Text(
                                objective,
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  color: const Color(0xFF0B1220),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getObjectivesForCheckpoint(Map<String, dynamic> checkpoint) {
    // First try checkpoint-specific learning objectives
    final checkpointObjectives =
        checkpoint['learningObjective'] as List<dynamic>?;
    if (checkpointObjectives != null && checkpointObjectives.isNotEmpty) {
      return checkpointObjectives
          .map((obj) => obj.toString())
          .where((obj) => obj.isNotEmpty)
          .toList();
    }

    // Then try checkpoint's learning objective properties
    final List<String> objectives = [];

    // Check for specific learning objective fields in the checkpoint
    final fields = ['learningObjective', 'objective', 'description', 'summary'];
    for (final field in fields) {
      final value = checkpoint[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        objectives.add(value.toString().trim());
      }
    }

    if (objectives.isNotEmpty) {
      return objectives;
    }

    // Fallback to checkpoint name
    final name = checkpoint['name'] ?? '';
    if (name.isNotEmpty) {
      return [name];
    }

    // Default objectives if no data available
    return ['Complete this checkpoint successfully'];
  }

  int _getTotalObjectivesCount() {
    int total = 0;
    for (var checkpoint in conceptCheckpoints) {
      total += _getObjectivesForCheckpoint(checkpoint).length;
    }
    return total;
  }

  Future<void> _loadLanguageAndVoiceOptions() async {
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

      if (defaultLang != null && selectedLanguage.isEmpty) {
        selectedLanguage = defaultLang['id'];
      }

      final defaultVoice = voices.firstWhere(
        (voice) => voice['defaultVoice'] == true,
        orElse: () => null,
      );
      if (defaultVoice != null && selectedVoice.isEmpty) {
        selectedVoice = defaultVoice['id'];
      }

      setState(() {
        _isLoadingLanguageVoice = false;
      });
    } catch (e) {
      print("Error loading language and voice options: $e");
      setState(() {
        _isLoadingLanguageVoice = false;
      });
    }
  }

  void _toggleAllObjectives(bool expand) {
    setState(() {
      for (final checkpoint in conceptCheckpoints) {
        _expandedObjectives[checkpoint['id']] = expand;
      }
    });
  }

  Widget _buildTutorControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.translate, size: 18, color: const Color(0xFF1D4ED8)),
              const SizedBox(width: 8),
              Text(
                'Tutor controls',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B1220),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildControlTile(
                  'Language',
                  _isLoadingLanguageVoice
                      ? 'Loading...'
                      : (languageOptions[selectedLanguage] ?? selectedLanguage),
                  onTap: _isLoadingLanguageVoice
                      ? null
                      : () => _showLanguageBottomSheet()),
              const SizedBox(width: 8),
              _buildControlTile(
                  'Voice',
                  _isLoadingLanguageVoice
                      ? 'Loading...'
                      : (voiceOptions[selectedVoice] ?? selectedVoice),
                  onTap: _isLoadingLanguageVoice
                      ? null
                      : () => _showVoiceBottomSheet()),
              const SizedBox(width: 8),
              _buildControlTile('Tutor voice', 'On', icon: Icons.volume_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile(String label, String value,
      {IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7DEC9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.raleway(
                  fontSize: 11,
                  color: const Color(0xFF70695B),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: const Color(0xFF0B1220)),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B1220),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestPracticesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best practices with Tuto',
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B1220),
            ),
          ),
          const SizedBox(height: 8),
          ...const [
            'Speak your first guess; we improve it together.',
            'Change one thing → predict the effect.',
            'Prefer voice; switch to text if it helps.',
          ].map((practice) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: GoogleFonts.raleway(
                            fontSize: 14, color: const Color(0xFF0B1220))),
                    Expanded(
                      child: Text(
                        practice,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EDDA),
        border: Border(
          top: BorderSide(color: const Color(0xFFE7DEC9)),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _startDiscussion,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shadowColor: const Color(0x401D4ED8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.resumeLesson == true
                    ? 'Resume discussion'
                    : 'Start discussion',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startDiscussion() {
    setState(() {
      _showLessonStart = false;
      showAfterGreetingContinueButton = true;
    });

    conversations = [];
    _continueFlow();
    // The lesson is already initialized, just transition to chat interface
    // The greeting is already in conversations[0]
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7DEC9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose language',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF70695B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...languageOptions.entries.map(
                      (entry) => _buildLanguageOption(entry.key, entry.value)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7DEC9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose voice',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF70695B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...voiceOptions.entries.map(
                      (entry) => _buildVoiceOption(entry.key, entry.value)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String id, String name) {
    final isSelected = selectedLanguage == id;
    return InkWell(
      onTap: () => _onLanguageSelected(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE7DEC9),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  Text(
                    id,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: const Color(0xFF70695B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1D4ED8)),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceOption(String id, String name) {
    final isSelected = selectedVoice == id;
    return InkWell(
      onTap: () => _onVoiceSelected(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE7DEC9),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  Text(
                    id,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: const Color(0xFF70695B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1D4ED8)),
          ],
        ),
      ),
    );
  }

  void _onLanguageSelected(String languageId) async {
    Navigator.pop(context);
    if (selectedLanguage != languageId) {
      setState(() {
        selectedLanguage = languageId;
        showDots = true;
        showAfterGreetingContinueButton = false;
      });

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("aiTutorLanguage", languageId);

      // Fetch new greeting in the selected language
      await _fetchNewGreeting();
    }
  }

  void _onVoiceSelected(String voiceId) async {
    Navigator.pop(context);
    if (selectedVoice != voiceId) {
      setState(() {
        selectedVoice = voiceId;
        showDots = true;
        showAfterGreetingContinueButton = false;
      });

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("aiTutorVoice", voiceId);

      // Fetch new greeting in the selected voice
      await _fetchNewGreeting();
    }
  }

  Widget _buildInputIsland() {
    switch (_inputMode) {
      case InputMode.compact:
        return _buildCompactIsland();
      case InputMode.recording:
        return _buildRecordingIsland();
      case InputMode.typing:
        return _buildTypingIsland();
    }
  }

  Widget _buildCompactIsland() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE7DEC9)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 14,
                    offset: Offset(0, 4))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary mic button (larger)
                GestureDetector(
                  onTap: _isLoading ? null : _startRecording,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x401D4ED8),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Secondary keyboard button (smaller)
                GestureDetector(
                  onTap: _isLoading ? null : _switchToTyping,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.keyboard,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIsland() {
    String formattedTime =
        '${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7DEC9)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Recording mic button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x40DC2626),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Two rows of content side by side
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First row: Recording indicator and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recording...',
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: _sendRecording,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Send',
                            style: GoogleFonts.raleway(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: _cancelRecording,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Icon(Icons.close,
                              color: const Color(0xFF6B7280), size: 16),
                          // Text(
                          //   'Cancel',
                          //   style: GoogleFonts.raleway(
                          //     fontSize: 11,
                          //     fontWeight: FontWeight.w600,
                          //     color: const Color(0xFF6B7280),
                          //   ),
                          // ),
                        ),
                      ),
                      // Small send button
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Second row: Send and cancel buttons
                  // Row(
                  //   children: [
                  //     // Small cancel button
                  //     GestureDetector(
                  //       onTap: _cancelRecording,
                  //       child: Container(
                  //         padding: const EdgeInsets.symmetric(
                  //             horizontal: 12, vertical: 4),
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFFF3F4F6),
                  //           borderRadius: BorderRadius.circular(12),
                  //           border: Border.all(color: const Color(0xFFE5E7EB)),
                  //         ),
                  //         child: Text(
                  //           'Cancel',
                  //           style: GoogleFonts.raleway(
                  //             fontSize: 11,
                  //             fontWeight: FontWeight.w600,
                  //             color: const Color(0xFF6B7280),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     // Small send button
                  //     GestureDetector(
                  //       onTap: _sendRecording,
                  //       child: Container(
                  //         padding: const EdgeInsets.symmetric(
                  //             horizontal: 12, vertical: 4),
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFF1D4ED8),
                  //           borderRadius: BorderRadius.circular(12),
                  //         ),
                  //         child: Text(
                  //           'Send',
                  //           style: GoogleFonts.raleway(
                  //             fontSize: 11,
                  //             fontWeight: FontWeight.w600,
                  //             color: Colors.white,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIsland() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7DEC9)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Switch back to mic button
            GestureDetector(
              onTap: _isLoading ? null : _switchToCompact,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(
                  Icons.mic,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                enabled: !_isLoading,
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type your message…",
                  hintStyle: GoogleFonts.raleway(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  color: const Color(0xFF0B1220),
                ),
                onSubmitted: (_) => _onSendText(),
                autofocus: true,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : _onSendText,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _messageController.text.trim().isNotEmpty
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _messageController.text.trim().isNotEmpty
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Hint Card Widget
  Widget _buildHintCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 1.0],
            colors: [
              Color(0xFFFDFCFB), // #FDFCFB
              Color(0xFFE2F6FF), // #E2F6FF
              Color(0xFFE5ECFF), // #E5ECFF
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7EAFE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: const Color(0xFF1D4ED8), // Accent color
                ),
                const SizedBox(width: 8),
                Text(
                  'Hint',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D4ED8), // Accent color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151), // Ink color
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assistantBubble(String text, int index) {
    // Check if this is a hint message
    final isHint = conversations[index]['isHint'] == true;
    final isLoading = conversations[index]['isLoading'] == true;

    if (isHint) {
      return _buildHintCard(text);
    }

    final notesOpen = conversations[index]['notesOpen'] == true;
    final boardOpen = conversations[index]['boardOpen'] == true;
    final Map<String, dynamic> notes = _extractTutorNotesFromLatest();
    final String boardText = conceptCheckpoints.isNotEmpty
        ? (conceptCheckpoints[currentCheckpointIndex]['blackboardText'] ?? '')
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(right: 8, left: 2),
              child: Image.asset(
                getTutorAvatar("tutoprime")["imagePath"]!,
                height: 32,
              )
              // Image.asset(
              //   selectedTutor.isNotEmpty
              //       ? getTutorAvatar(selectedTutor['avatar'])["imagePath"]!
              //       : getTutorAvatar("tutoprime")["imagePath"]!,
              //   height: 32,
              // ),
              ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7DEC9)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: Lottie.asset(
                          "lib/assets/animations/3-dots.json",
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    RichText(
                      text: TextSpan(
                        children:
                            _buildHighlightedText(text, conversations[index]),
                      ),
                    ),
                  if (!isLoading) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0x1A1D4ED8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1D4ED8)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your turn',
                              style: GoogleFonts.raleway(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D4ED8))),
                          if (conversations[index]['extractedQuestion'] != null)
                            Text(conversations[index]['extractedQuestion'],
                                style: GoogleFonts.raleway(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  // Show color legend if there are highlighted terms
                  if (!isLoading &&
                      ((conversations[index]['keywords'] as List?)
                                  ?.isNotEmpty ==
                              true ||
                          (conversations[index]['phrases'] as List?)
                                  ?.isNotEmpty ==
                              true ||
                          (conversations[index]['definitions'] as List?)
                                  ?.isNotEmpty ==
                              true)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: const Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text('Highlights: ',
                              style: GoogleFonts.raleway(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280))),
                          if ((conversations[index]['keywords'] as List?)
                                  ?.isNotEmpty ==
                              true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Keywords',
                                  style: GoogleFonts.raleway(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if ((conversations[index]['phrases'] as List?)
                                  ?.isNotEmpty ==
                              true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Phrases',
                                  style: GoogleFonts.raleway(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if ((conversations[index]['definitions'] as List?)
                                  ?.isNotEmpty ==
                              true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Definitions',
                                  style: GoogleFonts.raleway(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (!isLoading) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (notes.isNotEmpty)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE7DEC9)),
                              foregroundColor: const Color(0xFF70695B),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () {
                              setState(() {
                                conversations[index]['notesOpen'] = !notesOpen;
                              });
                            },
                            child: Text(
                                notesOpen ? 'Hide notes' : 'Show tutor notes',
                                style: GoogleFonts.raleway(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(width: 8),
                        if (boardText.isNotEmpty)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE7DEC9)),
                              foregroundColor: const Color(0xFF70695B),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () {
                              setState(() {
                                conversations[index]['boardOpen'] = !boardOpen;
                              });
                            },
                            child: Text(boardOpen ? 'Hide board' : 'Show board',
                                style: GoogleFonts.raleway(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    if (notesOpen && notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((notes['correct'] ?? '').toString().isNotEmpty)
                              Row(children: [
                                const Icon(Icons.check_circle,
                                    size: 16, color: Color(0xFF065F46)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text('Correct: ${notes['correct']}',
                                        style: GoogleFonts.raleway(
                                            fontSize: 13,
                                            color: const Color(0xFF065F46))))
                              ]),
                            if ((notes['partiallyCorrect'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(
                                        'Partially correct: ${notes['partiallyCorrect']}',
                                        style: GoogleFonts.raleway(
                                            fontSize: 13,
                                            color: Color(0xFF1D4ED8))))
                              ]),
                            ],
                            if ((notes['wrong'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 16, color: Color(0xFFB91C1C)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text('Needs fix: ${notes['wrong']}',
                                        style: GoogleFonts.raleway(
                                            fontSize: 13,
                                            color: const Color(0xFFB91C1C))))
                              ]),
                            ],
                            if ((notes['doubt'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 22),
                                child: Text('Doubt: ${notes['doubt']}',
                                    style: GoogleFonts.raleway(
                                        fontSize: 13,
                                        color: const Color(0xFF0B1220))),
                              ),
                            ],
                            if ((notes['misconception'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 22),
                                child: Text(
                                    'Misconception: ${notes['misconception']}',
                                    style: GoogleFonts.raleway(
                                        fontSize: 13,
                                        color: const Color(0xFF0B1220))),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (boardOpen && boardText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7DEC9)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: MarkdownBody(
                          selectable: false,
                          data: boardText,
                          builders: {
                            'latex': LatexElementBuilder(
                              textStyle: GoogleFonts.raleway(
                                color: const Color(0xFF0B1220),
                                fontSize: 14,
                              ),
                            ),
                          },
                          extensionSet: md.ExtensionSet(
                            [LatexBlockSyntax()],
                            [LatexInlineSyntax()],
                          ),
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.raleway(
                              color: const Color(0xFF0B1220),
                              fontSize: 14,
                            ),
                            h1: GoogleFonts.raleway(
                              color: const Color(0xFF0B1220),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            h2: GoogleFonts.raleway(
                              color: const Color(0xFF0B1220),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            listBullet: GoogleFonts.raleway(
                              color: const Color(0xFF0B1220),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gapCard(Map<String, dynamic> gap, int turnIndex) {
    final String text = gap['text'] ?? '';
    final int severity = gap['severity'] ?? 0;
    final double confidence = (gap['confidence'] ?? 0.0) is num
        ? (gap['confidence'] as num).toDouble()
        : double.tryParse('${gap['confidence']}') ?? 0.0;

    // Return empty if gap is resolved
    if (_isGapResolved(gap)) {
      return const SizedBox.shrink();
    }

    // Color coding based on severity
    Color cardColor, borderColor, iconBgColor, titleColor;
    if (severity == 1) {
      // Yellow theme for severity 1
      cardColor = const Color(0xFFFFFBEB); // Light yellow
      borderColor = const Color(0xFFFDE047); // Yellow border
      iconBgColor = const Color(0xFFEAB308); // Yellow background for icon
      titleColor = const Color(0xFFCA8A04); // Darker yellow for text
    } else {
      // Red theme for severity 2+
      cardColor = const Color(0xFFFDF2F8); // Light pink
      borderColor = const Color(0xFFFDA4AF); // Pink border
      iconBgColor = const Color(0xFFDC2626); // Red background for icon
      titleColor = const Color(0xFFDC2626); // Red for text
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon and "Gap identified"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    severity == 1 ? Icons.info : Icons.warning,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gap identified',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                // Severity indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level $severity',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gap description
            Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),

            // Confidence indicator
            if (confidence > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Resolve now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Mark gap as resolved and add helpful message
                      setState(() {
                        _markGapResolved(gap);
                        _wsEvents.removeWhere((event) =>
                            event['role'] == 'gap' && event['data'] == gap);
                        conversations.add({
                          'role': 'assistant',
                          'text': 'Let me help you with that: $text',
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Resolve now',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Later button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Mark gap as resolved (dismissed) and hide card
                      setState(() {
                        _markGapResolved(gap);
                        _wsEvents.removeWhere((event) =>
                            event['role'] == 'gap' && event['data'] == gap);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnFeedbackCard(Map<String, dynamic> fb) {
    final List missingPts = (fb['missingPoints'] ?? []) as List;

    // Only show feedback if there are gaps (missing points)
    if (missingPts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Combine all missing points into a single gap description
    final String gapDescription = missingPts.take(2).join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F8), // Light pink background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDA4AF)), // Pink border
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon and "Gap identified"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // Red background for icon
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gap identified',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gap description
            Text(
              gapDescription,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Resolve now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add the gap as a hint or guidance message
                      setState(() {
                        conversations.add({
                          'role': 'assistant',
                          'text': 'Let me help you with that: $gapDescription',
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Resolve now',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Later button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Hide this feedback card
                      setState(() {
                        _wsEvents.removeWhere((event) =>
                            event['role'] == 'turn_feedback' &&
                            event['data'] == fb);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cumulativeFeedbackCard(Map<String, dynamic> cp) {
    final List unresolved = (cp['unresolvedGaps'] ?? []) as List;

    // Only show feedback if there are unresolved gaps
    if (unresolved.isEmpty) {
      return const SizedBox.shrink();
    }

    // Combine unresolved gaps into a single description
    final String gapDescription = unresolved
        .take(2)
        .map((g) => '${g['summary'] ?? g['text'] ?? g}')
        .join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F8), // Light pink background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDA4AF)), // Pink border
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon and "Gap identified"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // Red background for icon
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gap identified',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gap description
            Text(
              gapDescription,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Resolve now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add the gap as a hint or guidance message
                      setState(() {
                        conversations.add({
                          'role': 'assistant',
                          'text':
                              'Let me help you understand this better: $gapDescription',
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Resolve now',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Later button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Hide this feedback card
                      setState(() {
                        _wsEvents.removeWhere((event) =>
                            event['role'] == 'cp_feedback' &&
                            event['data'] == cp);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(text,
                style: GoogleFonts.raleway(
                    fontSize: 13, color: const Color(0xFF0B1220))),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _extractTutorNotesFromLatest() {
    final Map<String, dynamic> resp = latestTutorResponse;
    if (resp.isEmpty) return {};
    final correct = resp['correct'];
    final wrong = resp['wrong'];
    final partiallyCorrect = resp['partiallyCorrect'];
    final doubt = resp['doubt'];
    final misconception = resp['misconception'];
    final notes = <String, dynamic>{
      'correct': correct,
      'wrong': wrong,
      'partiallyCorrect': partiallyCorrect,
      'doubt': doubt,
      'misconception': misconception,
    };
    notes.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String) return value.trim().isEmpty;
      return false;
    });
    return notes;
  }

  Widget _userBubble(String text, [Map<String, dynamic>? conversation]) {
    final isTranscribing = conversation?['isTranscribing'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x1A1D4ED8), Color(0x291D4ED8)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1D4ED8)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x401D4ED8),
                      blurRadius: 18,
                      offset: Offset(0, 6))
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTranscribing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Transcribing',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color: const Color(0xFF0B1220).withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: Lottie.asset(
                            "lib/assets/animations/3-dots.json",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    )
                  else
                    RichText(
                      text: TextSpan(
                        children: conversation != null
                            ? _buildUserFeedbackHighlightedText(
                                text, conversation)
                            : [
                                TextSpan(
                                    text: text,
                                    style: GoogleFonts.raleway(
                                        fontSize: 15,
                                        color: const Color(0xFF0B1220)))
                              ],
                      ),
                    ),
                  // Show feedback legend if there are highlighted terms
                  if (conversation != null &&
                      (conversation['correctEvidence'] != null ||
                          conversation['incorrectEvidence'] != null)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: const Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text('Feedback: ',
                              style: GoogleFonts.raleway(
                                  fontSize: 11,
                                  color: const Color(0xFF6B7280))),
                          if (conversation['correctEvidence'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Correct',
                                  style: GoogleFonts.raleway(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (conversation['incorrectEvidence'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('Incorrect',
                                  style: GoogleFonts.raleway(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onTap,
    bool dense = false,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          height: dense ? 36 : 40,
          width: dense ? 36 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE7DEC9)),
          ),
          alignment: Alignment.center,
          child:
              Icon(icon, size: dense ? 18 : 20, color: const Color(0xFF0B1220)),
        ),
      ),
    );
  }

  void _openMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 60,
                decoration: BoxDecoration(
                    color: const Color(0xFFE7DEC9),
                    borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(height: 12),
              _menuItem(
                icon: Icons.skip_next,
                text: "Jump to next checkpoint",
                onTap: () {
                  Navigator.pop(context);
                  _skipToNextCheckpoint();
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => CheckpointFeedbackScreen(),
                  //   ),
                  // );
                },
              ),
              const SizedBox(height: 8),
              _menuItem(
                icon: Icons.checklist_rtl,
                text: "Start questions · +45 XP",
                onTap: () {
                  Navigator.pop(context);
                  _moveToQuestionsPhase();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7DEC9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0B1220), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B1220)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPromptSheet(BuildContext context) {
    final Map<String, String> promptTypeToDisplay = {
      'give_examples': 'Give me examples',
      'explain_simple': 'Explain in simple way',
      'go_deeper': 'Go deeper',
      'give_hint': 'Give me a hint',
      'clarify_doubt': 'Clarify my doubt',
      'provide_analogy': 'Give me an analogy',
      'show_real_world_application': 'Show real-world applications',
      'break_down_steps': 'Break it down step by step',
      'visual_explanation': 'Explain visually',
      'practice_questions': 'Give me practice questions',
      'summarize': 'Summarize this topic',
      'connect_to_previous': 'How does this connect to what we learned before?'
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ask it your way",
                  style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B1220))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: promptTypeToDisplay.entries.map((entry) {
                  final type = entry.key;
                  final label = entry.value;
                  return OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _followUpConversation(null, null,
                          userPromptType: type, userPromptText: label);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B1220),
                      side: const BorderSide(color: Color(0xFFE7DEC9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child:
                        Text(label, style: GoogleFonts.raleway(fontSize: 13)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
