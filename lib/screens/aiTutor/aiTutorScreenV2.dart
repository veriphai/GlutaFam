import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:confetti/confetti.dart';
import 'package:eureka_app/apis/fetchConceptDetails.dart';
import 'package:eureka_app/apis/fetchLanguagesAndVoices.dart';
import 'package:eureka_app/apis/fetchLessonHistory.dart';
import 'package:eureka_app/apis/generateTutorResponse.dart';
import 'package:eureka_app/apis/resolveGap.dart';
import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
import 'package:eureka_app/screens/aiTutor/components/compact_feedback_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:eureka_app/screens/checkpointFeedbackScreen.dart';
import 'package:eureka_app/screens/aiTutor/allCheckpointFeedbackScreen.dart';
import 'package:eureka_app/services/checkpointFeedbackService.dart';

import 'components/ai_tutor_types.dart';
import 'components/ai_tutor_helpers.dart';
import 'components/ai_tutor_error_manager.dart';
import 'components/error_ui_components.dart';

import 'components/input_island.dart';
import 'components/message_bubbles.dart';
import 'components/feedback_cards.dart';
import 'components/lesson_start_components.dart';
import 'components/common_ui_components.dart';

class AITutorScreenV2 extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final String chapterName;
  final int maxXP;
  final String name;
  final String subject;
  final int standard;
  final String? selectedLanguage;
  final String? selectedVoice;
  final Map<String, dynamic>? tutorSelected;
  final Map<String, dynamic>? dataToResume;
  final bool? resumeLesson;
  final bool? viewLessonHistory;

  const AITutorScreenV2(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.chapterName,
      required this.maxXP,
      required this.name,
      required this.subject,
      required this.standard,
      this.selectedLanguage,
      this.selectedVoice,
      this.tutorSelected,
      this.dataToResume,
      this.resumeLesson,
      this.viewLessonHistory})
      : super(key: key);

  @override
  State<AITutorScreenV2> createState() => _AITutorScreenV2State();
}

class _AITutorScreenV2State extends State<AITutorScreenV2> {
  // Core controllers and state
  final TextEditingController _messageController = TextEditingController();
  final AITutorState _state = AITutorState();
  late ScrollController _scrollController;

  // Audio components
  FlutterSoundRecorder? _recorder;
  late FlutterSoundPlayer player;
  String? _audioPath;
  Timer? _recordingTimer;
  Timer? _timer;

  // Preferences and WebSocket
  late SharedPreferences prefs;
  late ConfettiController _confettiController;
  late StompClient stompClient;

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _scrollController = ScrollController();

    _state.studentName = widget.name;
    _state.selectedTutor = widget.tutorSelected ?? _state.selectedTutor;
    if (_state.selectedTutor.isNotEmpty &&
        _state.selectedTutor['name'] != null) {
      _state.tutorName = _state.selectedTutor['name'];
    }

    _state.conceptConversationsKey =
        "${widget.name}_${widget.conceptId}_${DateTime.now().millisecondsSinceEpoch}";

    if (widget.resumeLesson == true || widget.viewLessonHistory == true) {
      _state.conceptConversationsKey =
          widget.dataToResume?["conceptConversationsKey"];
    }
    _subscribeToTopic(_state.conceptConversationsKey);

    player = FlutterSoundPlayer();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    _initPlayer();

    // Add listener to text controller for send button state
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
    _state.resumeLesson = widget.resumeLesson ?? false;
    _state.viewLessonHistory = widget.viewLessonHistory ?? false;

    // Initialize network monitoring
    _startNetworkMonitoring();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPrefsAndOptions();
    await _getConceptDetails();
    await _loadLanguageAndVoiceOptions();

    if (widget.resumeLesson == true) {
      _state.conceptConversationsKey =
          widget.dataToResume?["conceptConversationsKey"];
      _state.currentCheckpointIndex = widget.dataToResume?["checkpointNo"] ?? 0;
      _state.greetingDone = true;
      _state.timeLeftSeconds =
          widget.dataToResume?["remainingTime"] ?? _state.timeLeftSeconds;
      _startCountdown();

      setState(() {
        _state.showLessonStart = false;
      });
      await _followUpConversation(null, null,
          newCheckpointStarted: widget.dataToResume?["newCheckpointStarted"],
          resumeLesson: true,
          learningObjectivesStatus:
              widget.dataToResume?["learningObjectivesStatus"]);
    } else if (widget.viewLessonHistory == true) {
      _state.conceptConversationsKey =
          widget.dataToResume?["conceptConversationsKey"];
      // await fetchConceptConversations();
      setState(() {
        _state.showLessonStart = false;
      });
    } else {
      await _initializeSession();
    }
  }

  Future<void> fetchConceptConversations() async {
    try {
      Map<String, dynamic> conceptDetails = await fetchLessonHistory(
          conceptConversationKey:
              widget.dataToResume?["conceptConversationsKey"]);

      final raw = conceptDetails['conceptConversations']?['conversations'];
      final conversationsList = (raw is List)
          ? raw
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map),
              )
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _mergeConversationsPreservingFeedback(conversationsList);
        _state.showDots = false;
        _state.isLoading = false;
        _state.showLessonStart = false;
        _state.showAfterGreetingContinueButton = true;
        _state.resumeLesson = false;
      });

      _state.conversations = [];
    } catch (error) {
      print("Error fetching lesson history: $error");
    }
  }

  // ---------- Backend integrations ----------
  void _subscribeToTopic(String conversationKey) {
    try {
      stompClient = StompClient(
        config: StompConfig(
          url: 'wss://glutaclass.com:8080/gluta/ws',
          onConnect: (frame) {
            debugPrint('WebSocket connected successfully');
            setState(() {
              _state.hasNetworkConnection = true;
            });
            
            stompClient.subscribe(
              destination: '/topic/$conversationKey',
              callback: (message) async {
                try {
                  final payload = json.decode(message.body!);
                  await _handleWebSocketMessage(payload, conversationKey);
                } catch (e) {
                  final error = AITutorErrorManager.createError(
                    type: ErrorType.websocket,
                    context: 'message_processing',
                    technicalDetails: e.toString(),
                    originalError: e,
                  );
                  _showError(error);
                }
              },
            );
          },
          onWebSocketError: (error) {
            debugPrint('WebSocket error: $error');
            final errorState = AITutorErrorManager.createError(
              type: ErrorType.websocket,
              context: 'connection_error',
              technicalDetails: error.toString(),
              originalError: error,
            );
            _showError(errorState, isGlobal: true);
            
            setState(() {
              _state.hasNetworkConnection = false;
            });
            
            // Attempt to reconnect after delay
            _scheduleWebSocketReconnect(conversationKey);
          },
          onDisconnect: (frame) {
            debugPrint('WebSocket disconnected');
            setState(() {
              _state.hasNetworkConnection = false;
            });
            
            // Attempt to reconnect
            _scheduleWebSocketReconnect(conversationKey);
          },
        ),
      );
      
      stompClient.activate();
    } catch (e) {
      final error = AITutorErrorManager.createError(
        type: ErrorType.websocket,
        context: 'connection_setup',
        technicalDetails: e.toString(),
        originalError: e,
      );
      _showError(error, isGlobal: true);
    }
  }

  // Schedule WebSocket reconnection
  void _scheduleWebSocketReconnect(String conversationKey) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_state.hasNetworkConnection) {
        debugPrint('Attempting WebSocket reconnection...');
        _subscribeToTopic(conversationKey);
      }
    });
  }

  Future<void> _handleWebSocketMessage(
      Map<String, dynamic> payload, String conversationKey) async {
    try {
      if (payload['type'] == 'transcription_complete') {
        final transcribed_text = payload['payload']['transcribed_text'];
        if (transcribed_text != null && transcribed_text.isNotEmpty) {
          _updateTranscription(transcribed_text);
        } else {
          // Handle empty transcription as an error
          _handleTranscriptionError();
        }
      } else if (payload['type'] == 'transcription_failed') {
        // Handle explicit transcription failure
        _handleTranscriptionError();
      } else if (payload['type'] == 'audio') {
      final base64Audio = payload['payload']['audio'];
      if (base64Audio != null) {
        await _playBase64Audio(base64Audio, conversationKey);
      }
    } else if (payload['type'] == 'question_extracted') {
      final question = payload['payload']?['question'];
      if (question != null) {
        _updateExtractedQuestion(question);
      }
    } else if (payload['type'] == 'cpFeedback') {
      final cpFeedback = payload['payload']?['cpFeedback'];
      if (cpFeedback != null) {
        setState(() {
          _state.cpFeedback = cpFeedback;
          _processCpFeedbackResolvedGaps(cpFeedback);
        });
      }
    } else if (payload['type'] == 'keywords_extracted') {
      final keywords = payload['payload']?['keywords'];
      final phrases = payload['payload']?['phrases'];
      final definitions = payload['payload']?['definitions'];
      _updateKeywordsAndPhrases(keywords, phrases, definitions);
    }
  }

  void _updateTranscription(String transcribedText) {
    setState(() {
      for (int i = 0; i < _state.conversations.length; i++) {
        if (_state.conversations[i]['role'] == 'user' &&
            _state.conversations[i]['isTranscribing'] == true) {
          _state.conversations[i] = {
            'role': 'user',
            'content': '',
            'text': transcribedText,
            'latest': true,
            'greeting': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          break;
        }
      }
      _scrollToBottom();
    });
  }

  void _updateExtractedQuestion(String question) {
    setState(() {
      int targetAssistantIndex = -1;
      for (int i = _state.conversations.length - 1; i >= 0; i--) {
        if (_state.conversations[i]['role'] == 'assistant' &&
            _state.conversations[i]['greeting'] == false &&
            _state.conversations[i]['extractedQuestion'] == null) {
          targetAssistantIndex = i;
          break;
        }
      }

      if (targetAssistantIndex != -1) {
        _state.conversations[targetAssistantIndex]['extractedQuestion'] =
            question;
        final originalText =
            _state.conversations[targetAssistantIndex]['text'] ?? '';
        final cleanedText =
            AITutorHelpers.removeQuestionFromText(originalText, question);
        _state.conversations[targetAssistantIndex]['text'] = cleanedText;
      }
    });
  }

  void _updateKeywordsAndPhrases(
      dynamic keywords, dynamic phrases, dynamic definitions) {
    setState(() {
      int targetAssistantIndex = -1;
      for (int i = _state.conversations.length - 1; i >= 0; i--) {
        if (_state.conversations[i]['role'] == 'assistant' &&
            _state.conversations[i]['keywords'] == null &&
            _state.conversations[i]['phrases'] == null &&
            _state.conversations[i]['definitions'] == null) {
          targetAssistantIndex = i;
          break;
        }
      }

      if (targetAssistantIndex != -1) {
        if (keywords != null && keywords.toString().isNotEmpty) {
          _state.conversations[targetAssistantIndex]['keywords'] = keywords
              .toString()
              .split(',')
              .map((k) => k.trim())
              .where((k) => k.isNotEmpty)
              .toList();
        }
        if (phrases != null && phrases.toString().isNotEmpty) {
          _state.conversations[targetAssistantIndex]['phrases'] = phrases
              .toString()
              .split(',')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
        }
        if (definitions != null && definitions.toString().isNotEmpty) {
          _state.conversations[targetAssistantIndex]['definitions'] =
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

  // Process extracted content for all conversations from backend
  void _processExtractedContentForAllConversations() {
    for (int i = 0; i < _state.conversations.length; i++) {
      final conversation = _state.conversations[i];
      if (conversation['role'] == 'assistant' &&
          conversation['extractedContent'] != null) {
        _processExtractedContentForConversation(
            i, conversation['extractedContent']);
      }
    }
  }

  // Process extracted content for a specific conversation
  void _processExtractedContentForConversation(
      int conversationIndex, dynamic extractedContent) {
    if (extractedContent == null) return;

    try {
      final Map<String, dynamic> extractedMap =
          extractedContent is Map<String, dynamic>
              ? extractedContent
              : Map<String, dynamic>.from(extractedContent as Map);

      // Process keywords
      if (extractedMap.containsKey('keywords') &&
          extractedMap['keywords'] is List) {
        final List<dynamic> keywordsList = extractedMap['keywords'] as List;
        _state.conversations[conversationIndex]['keywords'] = keywordsList
            .map((k) => k.toString().trim())
            .where((k) => k.isNotEmpty)
            .toList();
      }

      // Process phrases
      if (extractedMap.containsKey('phrases') &&
          extractedMap['phrases'] is List) {
        final List<dynamic> phrasesList = extractedMap['phrases'] as List;
        _state.conversations[conversationIndex]['phrases'] = phrasesList
            .map((p) => p.toString().trim())
            .where((p) => p.isNotEmpty)
            .toList();
      }

      // Process definitions
      if (extractedMap.containsKey('definitions') &&
          extractedMap['definitions'] is List) {
        final List<dynamic> definitionsList =
            extractedMap['definitions'] as List;
        _state.conversations[conversationIndex]['definitions'] = definitionsList
            .map((d) => d.toString().trim())
            .where((d) => d.isNotEmpty)
            .toList();
      }

      // Process extracted question
      if (extractedMap.containsKey('extractedQuestion') &&
          extractedMap['extractedQuestion'] != null &&
          extractedMap['extractedQuestion'].toString().isNotEmpty) {
        _state.conversations[conversationIndex]['extractedQuestion'] =
            extractedMap['extractedQuestion'].toString().trim();
      }
    } catch (e) {
      debugPrint(
          'Error processing extracted content for conversation $conversationIndex: $e');
    }
  }

  void _processCpFeedbackResolvedGaps(Map<String, dynamic> cpFeedback) {
    try {
      // Extract resolved gaps from cpFeedback
      final resolvedGapsList = cpFeedback['resolvedGaps'] as List<dynamic>?;

      if (resolvedGapsList != null && resolvedGapsList.isNotEmpty) {
        // Process each resolved gap object
        for (final resolvedGapObj in resolvedGapsList) {
          if (resolvedGapObj is Map<String, dynamic>) {
            final gapId = resolvedGapObj['id'] as String?;
            final text = resolvedGapObj['text'] as String?;
            final firstSeenTurn = resolvedGapObj['firstSeenTurn'] as int?;
            final resolvedAtTurn = resolvedGapObj['resolvedAtTurn'] as int?;
            final evidenceSubstring =
                resolvedGapObj['evidenceSubstring'] as String?;
            final resolutionQuality =
                resolvedGapObj['resolutionQuality'] as String?;
            final confidence = resolvedGapObj['confidence'] as double?;

            if (gapId != null && gapId.isNotEmpty) {
              // Add the gap ID to resolved gaps set
              _state.resolvedGaps.add(gapId);

              debugPrint('Resolved gap: $gapId');
              debugPrint('  Text: $text');
              debugPrint('  First seen at turn: $firstSeenTurn');
              debugPrint('  Resolved at turn: $resolvedAtTurn');
              debugPrint('  Resolution quality: $resolutionQuality');
              debugPrint('  Evidence: $evidenceSubstring');
              debugPrint('  Confidence: $confidence');
            }
          }
        }

        // Remove resolved gaps from wsEvents to update the UI
        _state.wsEvents.removeWhere((event) {
          if (event['role'] == 'gap') {
            final gap = event['data'] as Map<String, dynamic>;
            return AITutorHelpers.isGapResolved(gap, _state.resolvedGaps);
          }
          return false;
        });

        debugPrint(
            'Processed ${resolvedGapsList.length} resolved gaps from cpFeedback');
      }
    } catch (e) {
      debugPrint('Error processing cpFeedback resolved gaps: $e');
    }
  }

  // Helper method to merge backend conversations while preserving feedback markers
  void _mergeConversationsPreservingFeedback(
      List<Map<String, dynamic>> backendConversations,
      {bool isHintResponse = false}) {
    if (_state.conversations.isEmpty) {
      _state.conversations = backendConversations
          .map((conv) => Map<String, dynamic>.from(conv))
          .toList();
      _processAllConversationFeedback();
      _processExtractedContentForAllConversations();
      return;
    }

    // Check if we need to replace the loading assistant bubble
    final loadingIndex = _state.conversations.indexWhere(
        (conv) => conv['role'] == 'assistant' && conv['isLoading'] == true);

    if (loadingIndex != -1 && backendConversations.isNotEmpty) {
      final lastBackendMessage = backendConversations.last;
      if (lastBackendMessage['role'] == 'assistant') {
        _state.conversations[loadingIndex] =
            Map<String, dynamic>.from(lastBackendMessage);
        if (isHintResponse) {
          _state.conversations[loadingIndex]['isHint'] = true;
        }
        // Store tutor notes permanently for this new message
        AITutorHelpers.storeTutorNotesInMessage(
            _state.conversations[loadingIndex]);
        // Process extracted content for this new message
        if (lastBackendMessage['extractedContent'] != null) {
          _processExtractedContentForConversation(
              loadingIndex, lastBackendMessage['extractedContent']);
        }
      }
    } else {
      // Handle other merge scenarios
      if (backendConversations.length > _state.conversations.length) {
        final newMessagesStartIndex = _state.conversations.length;
        for (int i = newMessagesStartIndex;
            i < backendConversations.length;
            i++) {
          final newMessage = Map<String, dynamic>.from(backendConversations[i]);
          if (isHintResponse && newMessage['role'] == 'assistant') {
            newMessage['isHint'] = true;
          }
          // Store tutor notes permanently for new assistant messages
          AITutorHelpers.storeTutorNotesInMessage(newMessage);
          _state.conversations.add(newMessage);
          // Process extracted content for new assistant messages
          if (newMessage['role'] == 'assistant' &&
              newMessage['extractedContent'] != null) {
            _processExtractedContentForConversation(
                _state.conversations.length - 1,
                newMessage['extractedContent']);
          }
        }
      } else {
        // Update messages while preserving evidence, accounting for checkpoint_feedback conversations
        int backendIndex = 0;
        for (int i = 0;
            i < _state.conversations.length &&
                backendIndex < backendConversations.length;
            i++) {
          final localMsg = _state.conversations[i];

          // Skip checkpoint_feedback conversations as they don't exist in backend
          if (localMsg['role'] == 'checkpoint_feedback') {
            continue;
          }

          final backendMsg = backendConversations[backendIndex];

          if (backendMsg['text'] != localMsg['text'] ||
              backendMsg['content'] != localMsg['content']) {
            final correctEvidence = localMsg['correctEvidence'];
            final incorrectEvidence = localMsg['incorrectEvidence'];
            final existingTutorNotes = localMsg['tutorNotes'];

            _state.conversations[i] = Map<String, dynamic>.from(backendMsg);

            if (correctEvidence != null) {
              _state.conversations[i]['correctEvidence'] = correctEvidence;
            }
            if (incorrectEvidence != null) {
              _state.conversations[i]['incorrectEvidence'] = incorrectEvidence;
            }

            // Preserve existing tutor notes or store new ones
            if (existingTutorNotes != null) {
              _state.conversations[i]['tutorNotes'] = existingTutorNotes;
            } else {
              AITutorHelpers.storeTutorNotesInMessage(_state.conversations[i]);
            }

            if (isHintResponse && backendMsg['role'] == 'assistant') {
              _state.conversations[i]['isHint'] = true;
            }

            // Process extracted content for updated assistant messages
            if (backendMsg['role'] == 'assistant' &&
                backendMsg['extractedContent'] != null) {
              _processExtractedContentForConversation(
                  i, backendMsg['extractedContent']);
            }
          }

          backendIndex++;
        }
      }
    }

    // Update all user messages with fresh feedback from backend
    int backendIndex = 0;
    for (int i = 0;
        i < _state.conversations.length &&
            backendIndex < backendConversations.length;
        i++) {
      final localConversation = _state.conversations[i];

      // Skip checkpoint_feedback conversations as they don't exist in backend
      if (localConversation['role'] == 'checkpoint_feedback') {
        continue;
      }

      final backendMsg = backendConversations[backendIndex];
      if (backendMsg['role'] == 'user' &&
          backendMsg['conversationFeedback'] != null) {
        _state.conversations[i]['conversationFeedback'] =
            backendMsg['conversationFeedback'];
      }

      backendIndex++;
    }

    _processAllConversationFeedback();
    _processExtractedContentForAllConversations();
    _scrollToBottom();
  }

  // Process feedback for all conversations that have conversationFeedback
  void _processAllConversationFeedback() {
    for (int i = 0; i < _state.conversations.length; i++) {
      final conversation = _state.conversations[i];

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
            AITutorHelpers.storeGapsForTurn(
                i, gapsList, _state.conversationGaps);

            // Only update _wsEvents for the latest user message to avoid duplicates
            final isLatestUserMessage = i ==
                _state.conversations.lastIndexWhere((c) =>
                    c['role'] == 'user' && c['conversationFeedback'] != null);

            if (isLatestUserMessage) {
              _state.wsEvents.removeWhere((event) => event['role'] == 'gap');
              for (final gap in gapsList) {
                if (!AITutorHelpers.isGapResolved(gap, _state.resolvedGaps)) {
                  _state.wsEvents.add({
                    'role': 'gap',
                    'data': gap,
                    'turnIndex': i,
                    'ts': DateTime.now().millisecondsSinceEpoch,
                  });
                }
              }
            }
          }

          // Process correct/incorrect evidence
          final correct = highlights['correct'] as List<dynamic>?;
          final incorrect = highlights['incorrect'] as List<dynamic>?;
          if (correct != null && correct.isNotEmpty) {
            _state.conversations[i]['correctEvidence'] = correct
                .map((evidence) => Map<String, dynamic>.from(evidence as Map))
                .toList();
          } else {
            _state.conversations[i]['correctEvidence'] = null;
          }
          if (incorrect != null && incorrect.isNotEmpty) {
            _state.conversations[i]['incorrectEvidence'] = incorrect
                .map((evidence) => Map<String, dynamic>.from(evidence as Map))
                .toList();
          } else {
            _state.conversations[i]['incorrectEvidence'] = null;
          }
        }
      }
    }
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
        _state.selectedLanguage = defaultLang['id'];
        await prefs.setString("aiTutorLanguage", _state.selectedLanguage);
      }

      final defaultVoice = voices.firstWhere(
        (voice) => voice['defaultVoice'] == true,
        orElse: () => null,
      );
      if (defaultVoice != null) {
        _state.selectedVoice = defaultVoice['id'];
        await prefs.setString("aiTutorVoice", _state.selectedVoice);
      }
    } catch (e) {
      debugPrint("Error loading prefs/options: $e");
    }
  }

  Future<void> _initializeSession() async {
    final result = await _safeApiCall(
      () => generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: _state.studentName,
          checkpointNo: 0,
          conceptConversationsKey: _state.conceptConversationsKey,
          language: _state.selectedLanguage,
          voice: _state.selectedVoice,
          remainingTime: _state.timeLeftSeconds,
          greeting: true),
      'initialize_session',
      isCritical: true,
    );

    if (result != null) {
      final List<Map<String, dynamic>> conversationsList =
          (result["conversations"] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [];

      setState(() {
        _mergeConversationsPreservingFeedback(conversationsList);
        _state.showDots = false;
        _state.showAfterGreetingContinueButton = true;
      });
    } else {
      // Handle initialization failure
      setState(() {
        _state.showDots = false;
      });
    }
  }

  Future<void> _fetchNewGreeting() async {
    try {
      final tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: _state.studentName,
          checkpointNo: 0,
          conceptConversationsKey: _state.conceptConversationsKey,
          language: _state.selectedLanguage,
          voice: _state.selectedVoice,
          remainingTime: _state.timeLeftSeconds,
          greeting: true);

      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [];

      setState(() {
        if (conversationsList.isNotEmpty &&
            conversationsList[0]['role'] == 'assistant') {
          if (_state.conversations.isEmpty) {
            _state.conversations
                .add(Map<String, dynamic>.from(conversationsList[0]));
          } else {
            _state.conversations[0] =
                Map<String, dynamic>.from(conversationsList.last);
          }
        }
        _state.showDots = false;
        _state.showAfterGreetingContinueButton = true;
      });
    } catch (e) {
      debugPrint("Error fetchNewGreeting: $e");
      setState(() {
        _state.showDots = false;
      });
    }
  }

  Future<void> _getConceptDetails() async {
    final result = await _safeApiCall(
      () => fetchConceptDetails(conceptId: widget.conceptId),
      'get_concept_details',
      isCritical: true,
    );

    if (result != null) {
      setState(() {
        _state.conceptDetails = result;
        _state.conceptCheckpoints = (result["conceptCheckpoints"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _state.timeLeftSeconds = ((result["expectedCompletionTime"] ??
                _state.conceptCheckpoints.length * 5) as int) *
            60;
      });
    } else {
      // Critical error loading concept details
      final error = AITutorErrorManager.createError(
        type: ErrorType.network,
        context: 'concept_loading_failed',
        customActions: [
          ErrorAction(
            label: 'Retry',
            icon: Icons.refresh,
            onTap: () {
              _dismissError('concept_loading_failed');
              _getConceptDetails();
            },
            isPrimary: true,
          ),
          ErrorAction(
            label: 'Go Back',
            icon: Icons.arrow_back,
            onTap: () => _navigateBack(),
          ),
        ],
      );
      _handleCriticalError(error);
    }
  }

  Future<void> _startLessonWithTutor() async {
    try {
      _startCountdown();
      setState(() => _state.showDots = true);
      logAITutorCheckpointStart(
          _state.conceptCheckpoints[_state.currentCheckpointIndex]['id'],
          widget.conceptId,
          _state.currentCheckpointIndex + 1);

      final tutorResponse = await generateTutorResponse(
          conceptId: widget.conceptId,
          studentName: _state.studentName,
          checkpointNo: 0,
          conceptConversationsKey: _state.conceptConversationsKey,
          conversations: _state.conversations,
          language: _state.selectedLanguage,
          voice: _state.selectedVoice,
          remainingTime: _state.timeLeftSeconds,
          firstConversation: true);

      _state.latestTutorResponse = tutorResponse;

      final List<Map<String, dynamic>> conversationsList =
          (tutorResponse["conversations"] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [];
      setState(() {
        _mergeConversationsPreservingFeedback(conversationsList);
        _state.showDots = false;
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
      // If userPromptText is provided, add it as a user message first
      if (userPromptText != null && userPromptText.isNotEmpty) {
        setState(() {
          _state.conversations.add({
            'role': 'user',
            'content': userPromptText,
            'text': userPromptText,
            'latest': true,
            'greeting': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          if (_state.conversations.length >= 2) {
            _state.conversations[_state.conversations.length - 2]['latest'] =
                false;
          }

          // Remove checkpoint feedback notification cards when user sends a message
          _state.wsEvents.removeWhere(
              (event) => event['role'] == 'checkpoint_feedback_notification');
          _scrollToBottom();
        });
      }

      setState(() {
        _state.showDots = true;
        _state.conversations.add({
          'role': 'assistant',
          'content': '',
          'text': '',
          'latest': true,
          'greeting': false,
          'isLoading': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        if (_state.conversations.length >= 2) {
          _state.conversations[_state.conversations.length - 2]['latest'] =
              false;
        }
        _scrollToBottom();
      });

      final tutorResponse = await _safeApiCall(
        () => generateTutorResponse(
            conceptId: widget.conceptId,
            studentName: _state.studentName,
            checkpointNo: _state.currentCheckpointIndex,
            conversations: _state.conversations,
            audioFile: audioFile,
            newCheckpointStarted: newCheckpointStarted,
            allCheckpointCompleted: allCheckpointCompleted,
            studentResponse: text,
            conceptConversationsKey: _state.conceptConversationsKey,
            questionsData: questionsData,
            language: _state.selectedLanguage,
            learningObjectivesStatus: learningObjectivesStatus,
            resumeLesson: resumeLesson,
            remainingTime: _state.timeLeftSeconds,
            voice: _state.selectedVoice,
            hintRequest: hintRequest,
            userPromptType: userPromptType),
        'follow_up_conversation',
      );

      if (tutorResponse != null) {
        _state.latestTutorResponse = tutorResponse;

        final bool currentCheckpointCompletionStatus =
            tutorResponse['currentCheckpointCompleted'] ?? false;
        final bool skipAhead = tutorResponse['enableCheckpointContinueButton'] ?? false;
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
            _state.completedCheckpointIndexes.add(_state.currentCheckpointIndex);
            _state.attemptedCheckpointIndexes.add(_state.currentCheckpointIndex);
            logAITutorCheckpointEnd(
                _state.conceptCheckpoints[_state.currentCheckpointIndex]['id'],
                widget.conceptId,
                _state.currentCheckpointIndex + 1);
          } else if (skipAhead) {
            _state.attemptedCheckpointIndexes.add(_state.currentCheckpointIndex);
            logAITutorCheckpointSkippedOnUserIntent(
                _state.conceptCheckpoints[_state.currentCheckpointIndex]['id'],
                widget.conceptId,
                _state.currentCheckpointIndex + 1);
          }
          setState(() {
            _state.showCheckpointContinueButton = true;
            _state.showDots = false;
            _state.showTextBox = false;
          });
        }

        setState(() {
          _mergeConversationsPreservingFeedback(conversationsList,
              isHintResponse: hintRequest == true);
          _state.showDots = false;
          _state.isLoading = false;
        });
      } else {
        // Handle API call failure
        setState(() {
          // Remove the loading message
          if (_state.conversations.isNotEmpty &&
              _state.conversations.last['isLoading'] == true) {
            _state.conversations.removeLast();
          }
          
          _state.showDots = false;
          _state.isLoading = false;
        });
      }
  }

  Future<void> _playBase64Audio(String base64Audio, String uniqueKey) async {
    final result = await _safeApiCall(
      () async {
        final audioBytes = base64Decode(base64Audio);
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/${uniqueKey}_response_audio.wav');
        await audioFile.writeAsBytes(audioBytes);
        
        if (!player.isInited) {
          await player.openPlayer();
        }
        
        await player.startPlayer(fromURI: audioFile.path);
        return true;
      },
      'play_audio',
      showErrorUI: false, // Don't show UI error for audio playback failures
    );

    if (result == null) {
      // Audio playback failed - show a subtle error
      final error = AITutorErrorManager.createError(
        type: ErrorType.audio,
        context: 'audio_playback_failed',
        customActions: [
          ErrorAction(
            label: 'Continue without audio',
            icon: Icons.volume_off,
            onTap: () => _dismissError('audio_playback_failed'),
            isPrimary: true,
          ),
        ],
      );
      _showError(error);
    }
  }

  Future<void> _initializeRecorder() async {
    final result = await _safeApiCall(
      () async {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw Exception('Microphone permission denied');
        }
        
        await _recorder!.openRecorder();
        _recorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
        return true;
      },
      'initialize_recorder',
    );

    if (result == null) {
      // Recording initialization failed
      final error = AITutorErrorManager.createError(
        type: ErrorType.device,
        context: 'microphone_initialization_failed',
        customActions: [
          ErrorAction(
            label: 'Try Again',
            icon: Icons.refresh,
            onTap: () {
              _dismissError('microphone_initialization_failed');
              _initializeRecorder();
            },
            isPrimary: true,
          ),
          ErrorAction(
            label: 'Use Text Only',
            icon: Icons.keyboard,
            onTap: () {
              _dismissError('microphone_initialization_failed');
              setState(() {
                _state.inputMode = InputMode.typing;
              });
            },
          ),
        ],
      );
      _showError(error);
    }
  }

  Future<void> _initPlayer() async {
    await player.openPlayer();
    await player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 24000,
      bufferSize: 8192,
      interleaved: false,
    );
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.timeLeftSeconds > 0) {
        setState(() => _state.timeLeftSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadLanguageAndVoiceOptions() async {
    try {
      final data = await fetchLanguagesAndVoices();
      final List<dynamic> languages = data['languages'] ?? [];
      final List<dynamic> voices = data['voices'] ?? [];

      _state.languageOptions = {
        for (var lang in languages) lang['id']: lang['name']
      };
      _state.voiceOptions = {
        for (var voice in voices) voice['id']: voice['name']
      };

      final defaultLang = languages.firstWhere(
        (lang) => lang['defaultLanguage'] == true,
        orElse: () => null,
      );

      if (defaultLang != null && _state.selectedLanguage.isEmpty) {
        _state.selectedLanguage = defaultLang['id'];
      }

      final defaultVoice = voices.firstWhere(
        (voice) => voice['defaultVoice'] == true,
        orElse: () => null,
      );
      if (defaultVoice != null && _state.selectedVoice.isEmpty) {
        _state.selectedVoice = defaultVoice['id'];
      }

      setState(() {
        _state.isLoadingLanguageVoice = false;
      });
    } catch (e) {
      print("Error loading language and voice options: $e");
      setState(() {
        _state.isLoadingLanguageVoice = false;
      });
    }
  }

  // Audio recording methods
  Future<void> _startRecording() async {
    if (_state.isLoading) return;

    final result = await _safeApiCall(
      () async {
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
        return true;
      },
      'start_recording',
    );

    if (result != null) {
      setState(() {
        _state.isRecording = true;
        _state.inputMode = InputMode.recording;
        _state.recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _state.recordingSeconds++);
      });
    } else {
      // Recording start failed
      final error = AITutorErrorManager.createError(
        type: ErrorType.audio,
        context: 'recording_start_failed',
        customActions: [
          ErrorAction(
            label: 'Try Again',
            icon: Icons.mic,
            onTap: () {
              _dismissError('recording_start_failed');
              _startRecording();
            },
            isPrimary: true,
          ),
          ErrorAction(
            label: 'Type Instead',
            icon: Icons.keyboard,
            onTap: () {
              _dismissError('recording_start_failed');
              setState(() {
                _state.inputMode = InputMode.typing;
              });
            },
          ),
        ],
      );
      _showError(error);
    }
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    _recordingTimer?.cancel();
    setState(() {
      _state.isRecording = false;
      _state.inputMode = InputMode.compact;
      _state.recordingSeconds = 0;
    });
  }

  Future<void> _sendRecording() async {
    await _stopRecording();
    if (_audioPath != null && _audioPath!.isNotEmpty) {
      setState(() {
        _state.wsEvents.removeWhere((event) => event['role'] == 'gap');
        _state.wsEvents.removeWhere(
            (event) => event['role'] == 'checkpoint_feedback_notification');
        _state.conversations.add({
          'role': 'user',
          'content': '',
          'text': '',
          'latest': true,
          'greeting': false,
          'isTranscribing': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        if (_state.conversations.length >= 2) {
          _state.conversations[_state.conversations.length - 2]['latest'] =
              false;
        }
        _scrollToBottom();
      });

      await _followUpConversation(File(_audioPath!), null);
    }
  }

  void _cancelRecording() async {
    await _stopRecording();
  }

  void _switchToTyping() {
    setState(() {
      _state.inputMode = InputMode.typing;
    });
  }

  void _switchToCompact() {
    setState(() {
      _state.inputMode = InputMode.compact;
    });
  }

  void _onSendText() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Validate message length
    if (text.length > 1000) {
      final error = AITutorErrorManager.createError(
        type: ErrorType.validation,
        context: 'message_too_long',
        customActions: [
          ErrorAction(
            label: 'Shorten Message',
            icon: Icons.edit,
            onTap: () => _dismissError('message_too_long'),
            isPrimary: true,
          ),
        ],
      );
      _showError(error);
      return;
    }

    setState(() {
      _state.inputMode = InputMode.compact;
      _state.wsEvents.removeWhere((event) => event['role'] == 'gap');
      _state.wsEvents.removeWhere(
          (event) => event['role'] == 'checkpoint_feedback_notification');
      _state.conversations.add({
        'role': 'user',
        'content': text,
        'text': text,
        'latest': true,
        'greeting': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      if (_state.conversations.length >= 2) {
        _state.conversations[_state.conversations.length - 2]['latest'] = false;
      }
      _scrollToBottom();
    });

    player.stopPlayer();
    _messageController.clear();
    _followUpConversation(null, text);
  }

  void _continueFlow() async {
    await player.stopPlayer();
    _state.wsEvents.removeWhere((event) => event['role'] == 'gap');

    if (_state.showAfterGreetingContinueButton) {
      setState(() {
        _state.greetingDone = true;
        _state.showAfterGreetingContinueButton = false;
      });
      _startLessonWithTutor();
    } else if (_state.showCheckpointContinueButton) {
      // Check if this is the last checkpoint
      if (_state.currentCheckpointIndex ==
          _state.conceptCheckpoints.length - 1) {
        // This is the last checkpoint - navigate to all feedback screen
        setState(() {
          _state.xpGained += 45;
          _state.showCheckpointContinueButton = false;
        });
        logAITutorCheckpointsCompleted(
            widget.conceptId, _state.completedCheckpointIndexes.length);

        // Navigate to all checkpoint feedback screen
        _showAllCheckpointFeedback();
      } else {
        // Start loading feedback for current checkpoint
        _addCheckpointFeedbackCard(_state.currentCheckpointIndex);

        // Move to next checkpoint immediately while feedback loads in background
        _moveToNextCheckpoint();

        // Load feedback for the completed checkpoint
        _loadCheckpointFeedback(_state.currentCheckpointIndex - 1);
      }
    }
  }

  void _moveToNextCheckpoint() async {
    setState(() {
      _state.showDots = true;
      _state.showCheckpointContinueButton = false;
    });
    _state.currentCheckpointIndex += 1;
    await _followUpConversation(null, null, newCheckpointStarted: true);
    logAITutorCheckpointStart(
        _state.conceptCheckpoints[_state.currentCheckpointIndex]['id'],
        widget.conceptId,
        _state.currentCheckpointIndex + 1);
  }

  void _skipToNextCheckpoint() async {
    setState(() {
      _state.showDots = true;
      _state.showCheckpointContinueButton = false;
    });
    _state.attemptedCheckpointIndexes.add(_state.currentCheckpointIndex);
    logAITutorCheckpointSkipped(
        _state.conceptCheckpoints[_state.currentCheckpointIndex]['id'],
        widget.conceptId,
        _state.currentCheckpointIndex + 1);
    _state.currentCheckpointIndex += 1;
    await _followUpConversation(null, null, newCheckpointStarted: true);
    logAITutorCheckpointStart(
        _state.conceptCheckpoints[_state.currentCheckpointIndex]['id'],
        widget.conceptId,
        _state.currentCheckpointIndex + 1);
  }

  // DEPRECATED: No longer used as we end lessons after the last checkpoint
  void _moveToQuestionsPhase() async {
    setState(() => _state.showDots = true);
    await _followUpConversation(null, null, allCheckpointCompleted: true);
  }

  void _startDiscussion() {
    setState(() {
      _state.showLessonStart = false;
      _state.showAfterGreetingContinueButton = true;
      _state.resumeLesson = false;
    });

    _state.conversations = [];
    _continueFlow();
  }

  // Event handlers
  void _onLanguageSelected(String languageId) async {
    if (_state.selectedLanguage != languageId) {
      setState(() {
        _state.selectedLanguage = languageId;
        _state.showDots = true;
        _state.showAfterGreetingContinueButton = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("aiTutorLanguage", languageId);
      await _fetchNewGreeting();
    }
  }

  void _onVoiceSelected(String voiceId) async {
    if (_state.selectedVoice != voiceId) {
      setState(() {
        _state.selectedVoice = voiceId;
        _state.showDots = true;
        _state.showAfterGreetingContinueButton = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("aiTutorVoice", voiceId);
      await _fetchNewGreeting();
    }
  }

  void _onTutorAudioToggle() async {
    setState(() {
      _state.tutorAudioEnabled = !_state.tutorAudioEnabled;
    });
  }

  void _onToggleNotes(int index, String action) {
    setState(() {
      _state.conversations[index]['notesOpen'] = action == 'show';
    });
  }

  void _onToggleBoard(int index, String action) {
    setState(() {
      _state.conversations[index]['boardOpen'] = action == 'show';
    });
  }

  void _onToggleFeedback(int index) {
    setState(() {
      _state.conversations[index]['feedbackExpanded'] =
          !(_state.conversations[index]['feedbackExpanded'] == true);
    });
  }

  void _onResolveGap(Map<String, dynamic> gap) {
    // This method is now handled by _onToggleGapExpansion
    final gapId = AITutorHelpers.getGapId(gap);
    _onToggleGapExpansion(gapId);
  }

  void _onDismissGap(Map<String, dynamic> gap) {
    setState(() {
      _state.resolvedGaps.add(AITutorHelpers.getGapId(gap));
      _state.wsEvents.removeWhere(
          (event) => event['role'] == 'gap' && event['data'] == gap);
    });
  }

  void _onResolveTurnFeedback(Map<String, dynamic> fb) {
    final List missingPts = (fb['missingPoints'] ?? []) as List;
    final String gapDescription = missingPts.take(2).join(' ');
    setState(() {
      _state.conversations.add({
        'role': 'assistant',
        'text': 'Let me help you with that: $gapDescription',
      });
    });
  }

  void _onDismissTurnFeedback(Map<String, dynamic> fb) {
    setState(() {
      _state.wsEvents.removeWhere(
          (event) => event['role'] == 'turn_feedback' && event['data'] == fb);
    });
  }

  void _onResolveCumulativeFeedback(Map<String, dynamic> cp) {
    final List unresolved = (cp['unresolvedGaps'] ?? []) as List;
    final String gapDescription = unresolved
        .take(2)
        .map((g) => '${g['summary'] ?? g['text'] ?? g}')
        .join(' ');
    setState(() {
      _state.conversations.add({
        'role': 'assistant',
        'text': 'Let me help you understand this better: $gapDescription',
      });
    });
  }

  void _onDismissCumulativeFeedback(Map<String, dynamic> cp) {
    setState(() {
      _state.wsEvents.removeWhere(
          (event) => event['role'] == 'cp_feedback' && event['data'] == cp);
    });
  }

  // Gap conversation methods
  void _onToggleGapExpansion(String gapId) {
    setState(() {
      _state.expandedGaps[gapId] = !(_state.expandedGaps[gapId] ?? false);

      // Initialize text controller if not exists
      if (!_state.gapTextControllers.containsKey(gapId)) {
        _state.gapTextControllers[gapId] = TextEditingController();
      }

      // Initialize gap conversations if first time expanding
      if (_state.expandedGaps[gapId]! &&
          !_state.gapConversations.containsKey(gapId)) {
        _state.gapConversations[gapId] = [];
        _startGapConversation(gapId);
      }
    });
  }

  void _startGapConversation(String gapId) async {
    // Find the gap data
    Map<String, dynamic>? gapData;
    for (final event in _state.wsEvents) {
      if (event['role'] == 'gap') {
        final gap = event['data'] as Map<String, dynamic>;
        if (AITutorHelpers.getGapId(gap) == gapId) {
          gapData = gap;
          break;
        }
      }
    }

    if (gapData == null) return;

    setState(() {
      _state.gapLoadingStates[gapId] = true;
      _state.gapConversations[gapId]!.add({
        'role': 'assistant',
        'text': '',
        'isLoading': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    try {
      final response = await resolveGap(
        conceptId: widget.conceptId,
        studentName: _state.studentName,
        checkpointNo: _state.currentCheckpointIndex,
        conceptConversationsKey: _state.conceptConversationsKey,
        remainingTime: _state.timeLeftSeconds,
        gapId: gapId,
        gapData: gapData,
        gapConversations: _state.gapConversations[gapId],
        language: _state.selectedLanguage,
        voice: _state.selectedVoice,
        firstGapConversation: true,
      );

      setState(() {
        _state.gapLoadingStates[gapId] = false;

        // Update the loading message with the actual response
        if (_state.gapConversations[gapId]!.isNotEmpty) {
          _state.gapConversations[gapId]!.last = {
            'role': 'assistant',
            'text': response['text'] ??
                'I\'m here to help you understand this gap better. What would you like to know?',
            'isLoading': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
      });
    } catch (e) {
      setState(() {
        _state.gapLoadingStates[gapId] = false;

        // Update with error message
        if (_state.gapConversations[gapId]!.isNotEmpty) {
          _state.gapConversations[gapId]!.last = {
            'role': 'assistant',
            'text':
                'I\'m here to help you understand this gap better. What would you like to know?',
            'isLoading': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
      });
      debugPrint('Error starting gap conversation: $e');
    }
  }

  void _onSendGapMessage(String gapId, String message) async {
    // Find the gap data
    Map<String, dynamic>? gapData;
    for (final event in _state.wsEvents) {
      if (event['role'] == 'gap') {
        final gap = event['data'] as Map<String, dynamic>;
        if (AITutorHelpers.getGapId(gap) == gapId) {
          gapData = gap;
          break;
        }
      }
    }

    if (gapData == null) return;

    setState(() {
      _state.gapLoadingStates[gapId] = true;

      // Add user message
      _state.gapConversations[gapId]!.add({
        'role': 'user',
        'text': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Add loading assistant message
      _state.gapConversations[gapId]!.add({
        'role': 'assistant',
        'text': '',
        'isLoading': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    try {
      final response = await resolveGap(
        conceptId: widget.conceptId,
        studentName: _state.studentName,
        checkpointNo: _state.currentCheckpointIndex,
        conceptConversationsKey: _state.conceptConversationsKey,
        remainingTime: _state.timeLeftSeconds,
        gapId: gapId,
        gapData: gapData,
        gapConversations: _state.gapConversations[gapId],
        studentResponse: message,
        language: _state.selectedLanguage,
        voice: _state.selectedVoice,
        firstGapConversation: false,
      );

      setState(() {
        _state.gapLoadingStates[gapId] = false;

        // Update the loading message with the actual response
        if (_state.gapConversations[gapId]!.isNotEmpty) {
          _state.gapConversations[gapId]!.last = {
            'role': 'assistant',
            'text': response['message'] ??
                'I understand. Let me help you with that.',
            'isLoading': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
      });
    } catch (e) {
      setState(() {
        _state.gapLoadingStates[gapId] = false;

        // Update with error message
        if (_state.gapConversations[gapId]!.isNotEmpty) {
          _state.gapConversations[gapId]!.last = {
            'role': 'assistant',
            'text': 'I understand. Let me help you with that.',
            'isLoading': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
      });
      debugPrint('Error sending gap message: $e');
    }
  }

  void _onSendGapAudio(String gapId, File audioFile) async {
    // Find the gap data
    Map<String, dynamic>? gapData;
    for (final event in _state.wsEvents) {
      if (event['role'] == 'gap') {
        final gap = event['data'] as Map<String, dynamic>;
        if (AITutorHelpers.getGapId(gap) == gapId) {
          gapData = gap;
          break;
        }
      }
    }

    if (gapData == null) return;

    setState(() {
      _state.gapLoadingStates[gapId] = true;

      // Add user message (transcribing)
      _state.gapConversations[gapId]!.add({
        'role': 'user',
        'text': 'Transcribing...',
        'isTranscribing': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Add loading assistant message
      _state.gapConversations[gapId]!.add({
        'role': 'assistant',
        'text': '',
        'isLoading': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    try {
      final response = await resolveGap(
        conceptId: widget.conceptId,
        studentName: _state.studentName,
        checkpointNo: _state.currentCheckpointIndex,
        conceptConversationsKey: _state.conceptConversationsKey,
        remainingTime: _state.timeLeftSeconds,
        gapId: gapId,
        gapData: gapData,
        gapConversations: _state.gapConversations[gapId],
        audioFile: audioFile,
        language: _state.selectedLanguage,
        voice: _state.selectedVoice,
        firstGapConversation: false,
      );

      setState(() {
        _state.gapLoadingStates[gapId] = false;

        // Update user message with transcription
        if (_state.gapConversations[gapId]!.length >= 2) {
          _state.gapConversations[gapId]![
              _state.gapConversations[gapId]!.length - 2] = {
            'role': 'user',
            'text': response['transcription'] ?? 'Audio message',
            'isTranscribing': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }

        // Update the loading message with the actual response
        if (_state.gapConversations[gapId]!.isNotEmpty) {
          _state.gapConversations[gapId]!.last = {
            'role': 'assistant',
            'text':
                response['text'] ?? 'I understand. Let me help you with that.',
            'isLoading': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
      });
    } catch (e) {
      setState(() {
        _state.gapLoadingStates[gapId] = false;

        // Update user message
        if (_state.gapConversations[gapId]!.length >= 2) {
          _state.gapConversations[gapId]![
              _state.gapConversations[gapId]!.length - 2] = {
            'role': 'user',
            'text': 'Audio message',
            'isTranscribing': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }

        // Update with error message
        if (_state.gapConversations[gapId]!.isNotEmpty) {
          _state.gapConversations[gapId]!.last = {
            'role': 'assistant',
            'text': 'I understand. Let me help you with that.',
            'isLoading': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
      });
      debugPrint('Error sending gap audio: $e');
    }
  }

  void _onPromptSelected(String type, String label) {
    logAITutorPromptSelected(
        widget.conceptId, type, _state.currentCheckpointIndex + 1);
    _followUpConversation(null, null,
        userPromptType: type, userPromptText: label);
  }

  // Add checkpoint feedback card to conversations at current position
  void _addCheckpointFeedbackCard(int checkpointIndex) {
    setState(() {
      _state.checkpointFeedbackStates[checkpointIndex] = 'loading';

      // Insert feedback card right after the current last message
      _state.conversations.add({
        'role': 'checkpoint_feedback',
        'checkpointIndex': checkpointIndex,
        'state': 'loading',
        'data': null,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'greeting': false,
      });
    });
  }

  // Load checkpoint feedback asynchronously
  void _loadCheckpointFeedback(int checkpointIndex) async {
    try {
      final feedbackData =
          await CheckpointFeedbackService.getCheckpointFeedback(
        conceptConversations: _state.conceptConversationsKey,
        checkpointNumber: checkpointIndex,
      );

      setState(() {
        _state.checkpointFeedbackStates[checkpointIndex] = 'ready';
        _state.checkpointFeedbackData[checkpointIndex] = feedbackData;

        // Update the corresponding conversation item
        for (int i = 0; i < _state.conversations.length; i++) {
          if (_state.conversations[i]['role'] == 'checkpoint_feedback' &&
              _state.conversations[i]['checkpointIndex'] == checkpointIndex) {
            _state.conversations[i]['state'] = 'ready';
            _state.conversations[i]['data'] = feedbackData;
            break;
          }
        }

        // Add a notification card to wsEvents (current conversation position)
        _state.wsEvents.add({
          'role': 'checkpoint_feedback_notification',
          'checkpointIndex': checkpointIndex,
          'state': 'ready',
          'data': feedbackData,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
      });
    } catch (e) {
      debugPrint('Error loading checkpoint feedback: $e');
      setState(() {
        _state.checkpointFeedbackStates[checkpointIndex] = 'error';

        // Update the corresponding conversation item
        for (int i = 0; i < _state.conversations.length; i++) {
          if (_state.conversations[i]['role'] == 'checkpoint_feedback' &&
              _state.conversations[i]['checkpointIndex'] == checkpointIndex) {
            _state.conversations[i]['state'] = 'error';
            break;
          }
        }
      });
    }
  }

  // View checkpoint feedback
  void _viewCheckpointFeedback(int checkpointIndex) async {
    final feedbackData = _state.checkpointFeedbackData[checkpointIndex];
    if (feedbackData != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckpointFeedbackScreen(
            conceptConversations: _state.conceptConversationsKey,
            checkpointNumber: checkpointIndex,
            initialReport: feedbackData,
          ),
        ),
      );

      // If this was the last checkpoint and user clicked continue, navigate home
      if (result == 'continue' &&
          checkpointIndex == _state.conceptCheckpoints.length - 1) {
        _navigateBack();
      }
    }
  }

  // Dismiss checkpoint feedback notification
  void _dismissCheckpointFeedbackNotification(int checkpointIndex) {
    setState(() {
      _state.wsEvents.removeWhere((event) =>
          event['role'] == 'checkpoint_feedback_notification' &&
          event['checkpointIndex'] == checkpointIndex);
    });
  }

  // Show all checkpoint feedback screen
  void _showAllCheckpointFeedback() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => AllCheckpointFeedbackScreen(
          conceptConversationsKey: _state.conceptConversationsKey,
          totalCheckpoints: _state.conceptCheckpoints.length,
          checkpointFeedbackStates: _state.checkpointFeedbackStates,
          checkpointFeedbackData: _state.checkpointFeedbackData,
          conceptId: widget.conceptId,
        ),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  void _showCheckpointFeedback() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckpointFeedbackScreen(
          conceptConversations: _state.conceptConversationsKey,
          checkpointNumber: _state.currentCheckpointIndex,
        ),
      ),
    );

    // If user clicked continue from feedback screen, proceed to next checkpoint or end lesson
    if (result == 'continue') {
      if (_state.currentCheckpointIndex ==
          _state.conceptCheckpoints.length - 1) {
        // This is the last checkpoint - end the lesson and redirect back
        setState(() {
          _state.xpGained += 45;
        });
        logAITutorCheckpointsCompleted(
            widget.conceptId, _state.completedCheckpointIndexes.length);

        // Lesson is complete, redirect back to home screen
        _navigateBack();
      } else {
        _moveToNextCheckpoint();
      }
    }
  }

  void _onJumpToNext() {
    // Skip to next checkpoint directly (old functionality)
    if (_state.currentCheckpointIndex == _state.conceptCheckpoints.length - 1) {
      setState(() {
        _state.xpGained += 45;
      });
      logAITutorCheckpointsCompleted(
          widget.conceptId, _state.completedCheckpointIndexes.length);
      // End the lesson and redirect back to home screen
      _navigateBack();
    } else {
      _skipToNextCheckpoint();
    }
  }

  void _onStartQuestions() {
    // End the lesson and redirect back to home screen
    _navigateBack();
  }

  void _navigateBack() {
    // Navigate back to the previous screen with checkpoint completion data
    final completionData = {
      'conceptId': widget.conceptId,
      'checkpointsCompleted': _state.currentCheckpointIndex,
      'completedIndexes': _state.completedCheckpointIndexes,
      'attemptedIndexes': _state.attemptedCheckpointIndexes,
      'currentCheckpointIndex': _state.currentCheckpointIndex,
      'xpGained': _state.xpGained,
    };
    Navigator.pop(context, completionData);
  }

  void _onShowGaps() {
    CommonUIComponents.showGapsSheet(
      context,
      _state.conversationGaps,
      _state.resolvedGaps,
      _state.gapConversations,
      _state.expandedGaps,
      _state.gapTextControllers,
      _state.gapLoadingStates,
      _onToggleGapExpansion,
      _onSendGapMessage,
      _onSendGapAudio,
      _onDismissGap,
      widget.conceptId,
      _state.studentName,
      _state.currentCheckpointIndex,
      _state.conceptConversationsKey,
      _state.timeLeftSeconds,
      _state.selectedLanguage,
      _state.selectedVoice,
    );
  }

  void _onShowCpFeedback() {
    CommonUIComponents.showCpFeedbackSheet(
      context,
      _state.cpFeedback,
    );
  }

  String _generateSummary() {
    final gapCount = _state.conversationGaps.values
        .expand((gaps) => gaps)
        .where((gap) => !AITutorHelpers.isGapResolved(gap, _state.resolvedGaps))
        .length;

    if (gapCount == 0) {
      return 'Excellent understanding demonstrated. All key concepts covered successfully.';
    } else if (gapCount <= 2) {
      return 'Good progress made with some areas for improvement identified.';
    } else {
      return 'Several learning opportunities identified. Review recommended concepts.';
    }
  }

  // ========== ERROR HANDLING METHODS ==========

  // Safe API call wrapper with automatic retry and error handling
  Future<T?> _safeApiCall<T>(
    Future<T> Function() apiCall,
    String operation, {
    bool showErrorUI = true,
    int maxRetries = 3,
    bool isCritical = false,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // Check network connection before making call
        if (!_state.hasNetworkConnection && !_isNetworkIndependentOperation(operation)) {
          throw Exception('No network connection');
        }
        
        final result = await apiCall();
        
        // Reset error counters on success
        if (_state.consecutiveErrors > 0) {
          setState(() {
            _state.consecutiveErrors = 0;
            _state.lastErrorTime = null;
          });
        }
        
        return result;
      } catch (e) {
        attempts++;
        
        final errorType = _getErrorTypeFromException(e);
        final errorState = AITutorErrorManager.createError(
          type: errorType,
          context: operation,
          technicalDetails: e.toString(),
          originalError: e,
        );

        // Update error statistics
        setState(() {
          _state.consecutiveErrors++;
          _state.lastErrorTime = DateTime.now();
        });

        if (attempts >= maxRetries) {
          if (showErrorUI) {
            _showError(errorState, isGlobal: isCritical);
          }
          
          // Log error for analytics
          _logError(errorState, operation);
          return null;
        }

        // Wait before retry with exponential backoff
        final delay = AITutorErrorManager.getRetryDelay(
          errorState.copyWith(retryCount: attempts - 1)
        );
        await Future.delayed(delay);
      }
    }

    return null;
  }

  // Determine error type from exception
  ErrorType _getErrorTypeFromException(dynamic exception) {
    final errorString = exception.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup')) {
      return ErrorType.network;
    } else if (errorString.contains('websocket') || 
               errorString.contains('stomp')) {
      return ErrorType.websocket;
    } else if (errorString.contains('audio') || 
               errorString.contains('transcription')) {
      return ErrorType.transcription;
    } else if (errorString.contains('unauthorized') || 
               errorString.contains('authentication')) {
      return ErrorType.authentication;
    } else if (errorString.contains('validation') || 
               errorString.contains('invalid')) {
      return ErrorType.validation;
    } else if (errorString.contains('storage') || 
               errorString.contains('preferences')) {
      return ErrorType.storage;
    } else if (errorString.contains('permission') || 
               errorString.contains('device')) {
      return ErrorType.device;
    } else if (errorString.contains('timeout')) {
      return ErrorType.timeout;
    } else if (errorString.contains('500') || 
               errorString.contains('502') || 
               errorString.contains('503') || 
               errorString.contains('server')) {
      return ErrorType.serverError;
    }
    
    return ErrorType.unknown;
  }

  // Check if operation can work without network
  bool _isNetworkIndependentOperation(String operation) {
    const networkIndependentOps = [
      'save_preferences',
      'load_preferences',
      'validate_input',
      'format_time',
      'calculate_progress',
    ];
    return networkIndependentOps.contains(operation);
  }

  // Show error in UI
  void _showError(ErrorState error, {bool isGlobal = false}) {
    // Create default actions if none provided
    ErrorState errorWithActions = error;
    if (error.actions.isEmpty) {
      errorWithActions = error.copyWith(
        actions: _getDefaultActionsForError(error),
      );
    }
    
    if (error.severity == ErrorSeverity.critical || isGlobal) {
      setState(() {
        _state.currentCriticalError = errorWithActions;
        _state.showConnectionErrorOverlay = true;
      });
    } else {
      setState(() {
        _state.errorStates[errorWithActions.id] = errorWithActions;
        
        // Add error to conversations for inline display
        if (error.type == ErrorType.transcription) {
          // Handle transcription errors specially
          _handleTranscriptionError();
        } else {
          // Add general error message
          _state.wsEvents.add({
            'role': 'error',
            'data': errorWithActions,
            'ts': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });
    }
  }

  // Get default actions for errors with proper callbacks
  List<ErrorAction> _getDefaultActionsForError(ErrorState error) {
    switch (error.type) {
      case ErrorType.transcription:
        return [
          ErrorAction(
            label: 'Try Again',
            icon: Icons.mic,
            onTap: () => _retryTranscription(),
            isPrimary: true,
          ),
          ErrorAction(
            label: 'Type Instead',
            icon: Icons.keyboard,
            onTap: () {
              _dismissError(error.id);
              setState(() => _state.inputMode = InputMode.typing);
            },
          ),
        ];
      case ErrorType.network:
      case ErrorType.websocket:
      case ErrorType.timeout:
      case ErrorType.serverError:
        return [
          ErrorAction(
            label: 'Retry',
            icon: Icons.refresh,
            onTap: () => _retryOperation(error),
            isPrimary: true,
          ),
        ];
      case ErrorType.audio:
        return [
          ErrorAction(
            label: 'Continue without audio',
            icon: Icons.volume_off,
            onTap: () => _dismissError(error.id),
            isPrimary: true,
          ),
        ];
      case ErrorType.device:
        return [
          ErrorAction(
            label: 'Try Again',
            icon: Icons.refresh,
            onTap: () => _retryOperation(error),
            isPrimary: true,
          ),
          ErrorAction(
            label: 'Use Text Only',
            icon: Icons.keyboard,
            onTap: () {
              _dismissError(error.id);
              setState(() => _state.inputMode = InputMode.typing);
            },
          ),
        ];
      case ErrorType.validation:
        return [
          ErrorAction(
            label: 'Dismiss',
            icon: Icons.close,
            onTap: () => _dismissError(error.id),
            isPrimary: true,
          ),
        ];
      default:
        return [
          ErrorAction(
            label: 'Dismiss',
            icon: Icons.close,
            onTap: () => _dismissError(error.id),
            isPrimary: true,
          ),
        ];
    }
  }

  // Handle transcription specific errors
  void _handleTranscriptionError() {
    setState(() {
      // Find and update the transcribing message
      for (int i = 0; i < _state.conversations.length; i++) {
        if (_state.conversations[i]['role'] == 'user' &&
            _state.conversations[i]['isTranscribing'] == true) {
          _state.conversations[i] = {
            'role': 'user',
            'content': '',
            'text': '',
            'transcriptionFailed': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'retryRecording': () => _retryRecording(i),
            'switchToText': () => _switchToTextInput(i),
          };
          break;
        }
      }
    });
  }

  // Retry recording after transcription error
  void _retryRecording(int messageIndex) {
    setState(() {
      _state.conversations.removeAt(messageIndex);
    });
    _startRecording();
  }

  // Switch to text input after transcription error
  void _switchToTextInput(int messageIndex) {
    setState(() {
      _state.conversations.removeAt(messageIndex);
      _state.inputMode = InputMode.typing;
    });
  }

  // Dismiss error
  void _dismissError(String errorId) {
    setState(() {
      _state.errorStates.remove(errorId);
      _state.dismissedErrors[errorId] = true;
      _state.wsEvents.removeWhere((event) => 
          event['role'] == 'error' && event['data'].id == errorId);
    });
  }

  // Retry failed operation
  void _retryOperation(ErrorState error) {
    _dismissError(error.id);
    
    // Find and retry the operation based on context
    switch (error.id.split('_').first) {
      case ErrorType.network.toString():
        _retryNetworkOperation();
        break;
      case ErrorType.transcription.toString():
        _retryTranscription();
        break;
      case ErrorType.websocket.toString():
        _retryWebSocketConnection();
        break;
      default:
        // Generic retry - refresh the current state
        _refreshCurrentState();
        break;
    }
  }

  // Retry network operations
  void _retryNetworkOperation() {
    // Retry the last failed network operation
    if (_state.conversations.isNotEmpty) {
      final lastMessage = _state.conversations.last;
      if (lastMessage['role'] == 'assistant' && lastMessage['isLoading'] == true) {
        // Retry getting tutor response
        _followUpConversation(null, null);
      }
    }
  }

  // Retry transcription
  void _retryTranscription() {
    _startRecording();
  }

  // Retry WebSocket connection
  void _retryWebSocketConnection() {
    _subscribeToTopic(_state.conceptConversationsKey);
  }

  // Refresh current state
  void _refreshCurrentState() {
    // Reload current checkpoint state
    setState(() {
      _state.showDots = true;
    });
    _followUpConversation(null, null);
  }

  // Log error for analytics
  void _logError(ErrorState error, String operation) {
    // Add your analytics logging here
    debugPrint('AI Tutor Error: ${error.type} in $operation - ${error.message}');
    
    // You can extend this to send to your analytics service
    // logEvent('ai_tutor_error', {
    //   'error_type': error.type.toString(),
    //   'error_severity': error.severity.toString(),
    //   'error_message': error.message,
    //   'operation': operation,
    //   'concept_id': widget.conceptId,
    //   'checkpoint_index': _state.currentCheckpointIndex,
    //   'consecutive_errors': _state.consecutiveErrors,
    // });
  }

  // Network connection monitoring
  void _startNetworkMonitoring() {
    // You can implement connectivity monitoring here
    // For now, we'll assume network is available
    setState(() {
      _state.hasNetworkConnection = true;
    });
  }

  // Handle critical errors that require lesson exit
  void _handleCriticalError(ErrorState error) {
    setState(() {
      _state.currentCriticalError = error;
      _state.showConnectionErrorOverlay = true;
    });
  }

  // Recovery from overlay errors
  void _recoverFromOverlayError() {
    setState(() {
      _state.showConnectionErrorOverlay = false;
      _state.currentCriticalError = null;
    });
  }


  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use a small delay to ensure the new message is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _recorder?.closeRecorder();
    if (player.isPlaying) {
      player.stopPlayer();
    }
    player.closePlayer();
    _confettiController.dispose();
    _timer?.cancel();
    _recordingTimer?.cancel();

    // Dispose gap text controllers
    for (final controller in _state.gapTextControllers.values) {
      controller.dispose();
    }
    _messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state.showLessonStart ||
        _state.resumeLesson == true ||
        _state.viewLessonHistory) {
      return _buildLessonStartScreen();
    }

    return _buildChatScreen();
  }

  Widget _buildLessonStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EDDA),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            logAITutorExit(
                _state.conceptCheckpoints[_state.currentCheckpointIndex]['id'],
                widget.conceptId,
                _state.currentCheckpointIndex + 1);
            _navigateBack();
          },
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
              '${widget.subject} · ${widget.chapterName}',
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  child: Column(
                    children: [
                      LessonStartComponents.buildGreetingBubble(
                        _state.conversations,
                        _state.showDots,
                        widget.resumeLesson == true,
                      ),
                      const SizedBox(height: 12),
                      LessonStartComponents.buildLessonInfoCard(
                          _state.conceptCheckpoints,
                          _state.conceptDetails,
                          widget.resumeLesson == true
                              ? (widget.dataToResume?["checkpointNo"] as int? ?? 0)
                              : _state.viewLessonHistory == true
                                  ? _state.conceptCheckpoints.length
                                  : 0),
                      const SizedBox(height: 12),
                      LessonStartComponents.buildLearningObjectivesCard(
                        _state.conceptCheckpoints,
                        _state.objectivesExpanded,
                        _state.expandedObjectives,
                        () => setState(() =>
                            _state.objectivesExpanded = !_state.objectivesExpanded),
                        (expand) => setState(() {
                          for (final checkpoint in _state.conceptCheckpoints) {
                            _state.expandedObjectives[checkpoint['id']] = expand;
                          }
                        }),
                        (id, expanded) => setState(
                            () => _state.expandedObjectives[id] = expanded),
                      ),
                      const SizedBox(height: 12),
                      LessonStartComponents.buildTutorControlsCard(
                          _state.isLoadingLanguageVoice,
                          _state.languageOptions,
                          _state.voiceOptions,
                          _state.selectedLanguage,
                          _state.selectedVoice,
                          _state.tutorAudioEnabled,
                          () => CommonUIComponents.showLanguageBottomSheet(
                                context,
                                _state.languageOptions,
                                _state.selectedLanguage,
                                _onLanguageSelected,
                              ),
                          () => CommonUIComponents.showVoiceBottomSheet(
                                context,
                                _state.voiceOptions,
                                _state.selectedVoice,
                                _onVoiceSelected,
                              ),
                          () => _onTutorAudioToggle),
                      const SizedBox(height: 12),
                      LessonStartComponents.buildBestPracticesCard(),
                    ],
                  ),
                ),
              ),
              !_state.viewLessonHistory
                  ? LessonStartComponents.buildStartButton(
                      widget.resumeLesson == true,
                      _startDiscussion,
                    )
                  : Row(
                      children: [
                        LessonStartComponents.buildButtonsForLessonHistory(
                            false, fetchConceptConversations),
                        LessonStartComponents.buildButtonsForLessonHistory(
                            false, fetchConceptConversations)
                      ],
                    )
            ],
          ),
          // Connection Error Overlay for lesson start screen
          if (_state.showConnectionErrorOverlay && _state.currentCriticalError != null)
            ConnectionErrorOverlay(
              onRetry: () {
                _recoverFromOverlayError();
                _retryOperation(_state.currentCriticalError!);
              },
              onOfflineMode: () {
                _recoverFromOverlayError();
                // Handle offline mode if needed
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
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
                    IconButton(
                      onPressed: () {
                        logAITutorExit(
                            _state.conceptCheckpoints[
                                _state.currentCheckpointIndex]['id'],
                            widget.conceptId,
                            _state.currentCheckpointIndex + 1);
                        _navigateBack();
                      },
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Time to complete",
                              style: GoogleFonts.raleway(
                                  fontSize: 12,
                                  color: const Color(0xFF70695B))),
                          const SizedBox(height: 2),
                          Text(
                              AITutorHelpers.formatTime(_state.timeLeftSeconds),
                              style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0B1220))),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Network status indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _state.hasNetworkConnection 
                                ? Colors.green 
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            logAITutorMenuButtonClick(widget.conceptId);
                            CommonUIComponents.showMenuSheet(
                              context,
                              _onJumpToNext,
                              _onStartQuestions,
                              _onShowGaps,
                              _onShowCpFeedback,
                            );
                          },
                          icon: const Icon(Icons.more_vert),
                          color: const Color(0xFF0B1220),
                        ),
                      ],
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
                      final w = c.maxWidth *
                          AITutorHelpers.calculateProgress(
                              _state.currentCheckpointIndex,
                              _state.conceptCheckpoints.length);
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
                        Text(_state.tutorName,
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
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 140),
                  itemCount:
                      _state.conversations.length + _state.wsEvents.length,
                  itemBuilder: (context, index) {
                    if (index < _state.conversations.length) {
                      final convo = _state.conversations[index];
                      if (convo['greeting']) return const SizedBox.shrink();
                      final role = convo['role'];
                      if (role == 'assistant') {
                        return MessageBubbles.assistantBubble(
                          convo['text'] ?? "",
                          index,
                          _state.conversations,
                          _state.conceptCheckpoints,
                          _state.currentCheckpointIndex,
                          _state.latestTutorResponse,
                          _state.selectedTutor,
                          _onToggleNotes,
                          _onToggleBoard,
                        );
                      } else if (role == 'user') {
                        // Handle transcription failed user messages
                        if (convo['transcriptionFailed'] == true) {
                          return TranscriptionErrorBubble(
                            onRetry: convo['retryRecording'] ?? () {},
                            onSwitchToText: convo['switchToText'] ?? () {},
                          );
                        }
                        return MessageBubbles.userBubble(convo['text'] ?? "",
                            convo, _onToggleFeedback, index);
                      } else if (role == 'checkpoint_feedback') {
                        // return FeedbackCards.checkpointFeedbackCard(
                        //   convo['checkpointIndex'] as int,
                        //   convo['state'] as String,
                        //   convo['data'],
                        //   () => _viewCheckpointFeedback(
                        //       convo['checkpointIndex'] as int),
                        //   showDismissButton:
                        //       false, // No dismiss button for conversation cards
                        // );
                        final feedbackData = _state.checkpointFeedbackData[
                            convo['checkpointIndex'] as int];
                        return convo['state'] as String == 'ready' &&
                                feedbackData != null
                            ? CompactFeedbackCard(
                                report: feedbackData,
                                checkpointNumber:
                                    convo['checkpointIndex'] as int,
                                onTap: () => _viewCheckpointFeedback(
                                    convo['checkpointIndex'] as int),
                              )
                            : FeedbackCards.checkpointFeedbackCard(
                                convo['checkpointIndex'] as int,
                                convo['state'] as String,
                                feedbackData,
                                () => _viewCheckpointFeedback(
                                    convo['checkpointIndex'] as int),
                                showDismissButton:
                                    false, // No dismiss button in this screen
                              );
                      }
                      return const SizedBox.shrink();
                    } else {
                      final event =
                          _state.wsEvents[index - _state.conversations.length];
                      final role = event['role'];
                      if (role == 'gap') {
                        return FeedbackCards.gapCard(
                          event['data'] as Map<String, dynamic>,
                          event['turnIndex'] as int,
                          _state.resolvedGaps,
                          _onResolveGap,
                          _onDismissGap,
                          gapConversations: _state.gapConversations,
                          expandedGaps: _state.expandedGaps,
                          gapTextControllers: _state.gapTextControllers,
                          gapLoadingStates: _state.gapLoadingStates,
                          onSendGapMessage: _onSendGapMessage,
                          onSendGapAudio: _onSendGapAudio,
                          onToggleGapExpansion: _onToggleGapExpansion,
                          conceptId: widget.conceptId,
                          studentName: _state.studentName,
                          checkpointNo: _state.currentCheckpointIndex,
                          conceptConversationsKey:
                              _state.conceptConversationsKey,
                          remainingTime: _state.timeLeftSeconds,
                          language: _state.selectedLanguage,
                          voice: _state.selectedVoice,
                        );
                      } else if (role == 'turn_feedback') {
                        return FeedbackCards.turnFeedbackCard(
                          event['data'] as Map<String, dynamic>,
                          _onResolveTurnFeedback,
                          _onDismissTurnFeedback,
                        );
                      } else if (role == 'cp_feedback') {
                        return FeedbackCards.cumulativeFeedbackCard(
                          event['data'] as Map<String, dynamic>,
                          _onResolveCumulativeFeedback,
                          _onDismissCumulativeFeedback,
                        );
                      } else if (role == 'checkpoint_feedback_notification') {
                        final feedbackData = _state.checkpointFeedbackData[
                            event['checkpointIndex'] as int];

                        return CompactFeedbackCard(
                          report: feedbackData,
                          checkpointNumber: event['checkpointIndex'] as int,
                          showDismissButton:
                              true, // Show dismiss button for notification cards
                          onDismiss: () =>
                              _dismissCheckpointFeedbackNotification(
                                  event['checkpointIndex'] as int),
                          onTap: () => _viewCheckpointFeedback(
                              event['checkpointIndex'] as int),
                        );
                      } else if (role == 'error') {
                        final errorState = event['data'] as ErrorState;
                        return ErrorMessageBubble(
                          error: errorState,
                          onRetry: () => _retryOperation(errorState),
                          isAssistant: errorState.type != ErrorType.transcription,
                        );
                        // return FeedbackCards.checkpointFeedbackCard(
                        //   event['checkpointIndex'] as int,
                        //   event['state'] as String,
                        //   event['data'],
                        //   () => _viewCheckpointFeedback(
                        //       event['checkpointIndex'] as int),
                        //   showDismissButton:
                        //       true, // Show dismiss button for notification cards
                        //   onDismiss: () =>
                        //       _dismissCheckpointFeedbackNotification(
                        //           event['checkpointIndex'] as int),
                        // );
                      }
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          ),

          // Floating hint/simplify buttons
          if (!_state.viewLessonHistory)
            Positioned(
              right: 12,
              bottom: 120,
              child: Column(
                children: [
                  CommonUIComponents.circleAction(
                    icon: Icons.lightbulb_outline,
                    onTap: () {
                      logAITutorHintRequested(
                          widget.conceptId, _state.currentCheckpointIndex + 1);
                      _followUpConversation(null, null, hintRequest: true);
                    },
                  ),
                  const SizedBox(height: 10),
                  CommonUIComponents.circleAction(
                    icon: Icons.auto_fix_high_outlined,
                    onTap: () => CommonUIComponents.showPromptSheet(
                        context, _onPromptSelected),
                  ),
                ],
              ),
            ),

          // Interactive Island Input UI
          if (!_state.viewLessonHistory)
            Positioned(
              left: 0,
              right: 0,
              bottom: (_state.showAfterGreetingContinueButton ||
                          _state.showCheckpointContinueButton) &&
                      !_state.showDots
                  ? 90
                  : 12,
              child: InputIsland(
                inputMode: _state.inputMode,
                isLoading: _state.isLoading,
                recordingSeconds: _state.recordingSeconds,
                messageController: _messageController,
                onStartRecording: _startRecording,
                onSendRecording: _sendRecording,
                onCancelRecording: _cancelRecording,
                onSwitchToTyping: _switchToTyping,
                onSwitchToCompact: _switchToCompact,
                onSendText: _onSendText,
              ),
            ),

          // Continue CTA (at the very bottom)
          if ((_state.showAfterGreetingContinueButton ||
                  _state.showCheckpointContinueButton) &&
              !_state.showDots)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
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
                    _state.showAfterGreetingContinueButton
                        ? "CONTINUE"
                        : "CONTINUE",
                    style: GoogleFonts.raleway(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

          // Connection Error Overlay
          if (_state.showConnectionErrorOverlay && _state.currentCriticalError != null)
            ConnectionErrorOverlay(
              onRetry: () {
                _recoverFromOverlayError();
                _retryOperation(_state.currentCriticalError!);
              },
              onOfflineMode: () {
                _recoverFromOverlayError();
                // Handle offline mode if needed
              },
            ),
        ],
      ),
    );
  }
}
