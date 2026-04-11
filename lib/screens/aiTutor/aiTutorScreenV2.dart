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
import 'package:eureka_app/apis/retryTranscription.dart';
import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
import 'package:eureka_app/screens/aiTutor/components/compact_feedback_card.dart';
import 'package:flutter/material.dart';
import 'package:taudio/taudio.dart';
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
  Timer? _transcriptionTimer;
  Timer? _assistantResponseTimer;
  Map<int, Timer?> _checkpointFeedbackTimers = {};

  // Preferences and WebSocket
  late SharedPreferences prefs;
  late ConfettiController _confettiController;
  StompClient? stompClient;

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);
    _scrollController = ScrollController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

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
    _initPlayer();

    // Add listener to text controller for send button state
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
    _state.resumeLesson = widget.resumeLesson ?? false;
    _state.viewLessonHistory = widget.viewLessonHistory ?? false;

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
    stompClient = StompClient(
      config: StompConfig(
        url: 'wss://glutaclass.com:8080/gluta/ws',
        // url: 'ws://localhost:8080/gluta/ws',

        onConnect: (frame) {
          stompClient?.subscribe(
            destination: '/topic/$conversationKey',
            callback: (message) async {
              final payload = json.decode(message.body!);
              await _handleWebSocketMessage(payload, conversationKey);
            },
          );
        },
        onWebSocketError: (error) => debugPrint('WS error: $error'),
      ),
    );
    stompClient?.activate();
  }

  Future<void> _handleWebSocketMessage(
      Map<String, dynamic> payload, String conversationKey) async {
    // Check if widget is still mounted before processing websocket messages
    if (!mounted) {
      debugPrint('Widget not mounted, ignoring websocket message');
      return;
    }
    
    if (payload['type'] == 'transcription_complete') {
      final transcribed_text = payload['payload']['transcribed_text'];
      final conversationId = payload['payload']
          ['conversationId']; // Get conversation ID from payload
      _updateTranscription(transcribed_text, conversationId);
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

  void _updateTranscription(String transcribedText, [String? conversationId]) {
    setState(() {
      for (int i = 0; i < _state.conversations.length; i++) {
        // If conversationId is provided, match by ID; otherwise match by isTranscribing status
        final shouldUpdate = conversationId != null
            ? (_state.conversations[i]['conversationId'] == conversationId &&
                _state.conversations[i]['role'] == 'user')
            : (_state.conversations[i]['role'] == 'user' &&
                _state.conversations[i]['isTranscribing'] == true);

        if (shouldUpdate) {
          final existingConversationId =
              _state.conversations[i]['conversationId'];
          final audioPath = _state.conversations[i]['audioPath'];
          _state.conversations[i] = {
            'role': 'user',
            'content': '',
            'text': transcribedText,
            'latest': true,
            'greeting': false,
            'feedbackExpanded':
                true, // Preserve expanded state for new transcription
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'conversationId':
                existingConversationId, // Preserve conversation ID
            'audioPath': audioPath, // Preserve audio path for potential retry
            'transcriptionFailed': false,
          };
          _transcriptionTimer?.cancel(); // Cancel timeout timer

          break;
        }
      }

      // Auto-scroll to bottom when transcription is updated
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
        // Store the original text for inline question positioning
        _state.conversations[targetAssistantIndex]['originalText'] =
            originalText;
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
      if (_state.conversations.length > 1) {
        AITutorHelpers.storeBoardTextInMessage(_state.conversations[1],
            _state.conceptCheckpoints, _state.currentCheckpointIndex);
      }
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
        AITutorHelpers.storeBoardTextInMessage(
            _state.conversations[loadingIndex],
            _state.conceptCheckpoints,
            _state.currentCheckpointIndex);
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
          // Store board text permanently for new assistant messages
          AITutorHelpers.storeBoardTextInMessage(newMessage,
              _state.conceptCheckpoints, _state.currentCheckpointIndex);
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

            // Store board text for assistant messages
            if (backendMsg['role'] == 'assistant') {
              AITutorHelpers.storeBoardTextInMessage(_state.conversations[i],
                  _state.conceptCheckpoints, _state.currentCheckpointIndex);
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

    // Auto-scroll to bottom when conversations are updated
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
        _mergeConversationsPreservingFeedback(conversationsList);
        _state.showDots = false;
        _state.showAfterGreetingContinueButton = true;
      });
    } catch (e) {
      debugPrint("Error initializeSession: $e");
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
    try {
      final details = await fetchConceptDetails(conceptId: widget.conceptId);
      setState(() {
        _state.conceptDetails = details;
        _state.conceptCheckpoints = (details["conceptCheckpoints"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _state.timeLeftSeconds = ((details["expectedCompletionTime"] ??
                _state.conceptCheckpoints.length * 5) as int) *
            60;
      });
    } catch (e) {
      debugPrint("Error fetching concept details: $e");
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
      String? userPromptText,
      String? conversationId}) async {
    try {
      // If userPromptText is provided, add it as a user message first
      if (userPromptText != null && userPromptText.isNotEmpty) {
        // Collapse all previous user message feedback before adding new message
        _collapseAllPreviousUserFeedback();

        setState(() {
          _state.conversations.add({
            'role': 'user',
            'content': userPromptText,
            'text': userPromptText,
            'latest': true,
            'greeting': false,
            'feedbackExpanded': true, // Set initial state to expanded
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          if (_state.conversations.length >= 2) {
            _state.conversations[_state.conversations.length - 2]['latest'] =
                false;
          }

          // Remove checkpoint feedback notification cards when user sends a message
          _state.wsEvents.removeWhere(
              (event) => event['role'] == 'checkpoint_feedback_notification');

          // Auto-scroll to bottom when user message is added
          _scrollToBottom();
        });
      }

      final assistantConversationId = conversationId != null
          ? "${conversationId}_assistant"
          : "${DateTime.now().millisecondsSinceEpoch}_assistant";

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
          'conversationId': assistantConversationId,
          'responseGenerationFailed': false,
        });
        if (_state.conversations.length >= 2) {
          _state.conversations[_state.conversations.length - 2]['latest'] =
              false;
        }

        // Auto-scroll to bottom when assistant loading message is added
        _scrollToBottom();
      });

      // Start assistant response timeout
      _startAssistantResponseTimeout(assistantConversationId);

      final tutorResponse = await generateTutorResponse(
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
          userPromptType: userPromptType,
          userConversationId: conversationId);

      _state.latestTutorResponse = tutorResponse;

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

      // Cancel assistant response timeout as we received a successful response
      _assistantResponseTimer?.cancel();

      setState(() {
        _mergeConversationsPreservingFeedback(conversationsList,
            isHintResponse: hintRequest == true);
        _state.showDots = false;
        _state.isLoading = false;
      });
    } catch (e) {
      debugPrint("Error followUp: $e");
    }
  }

  Future<void> _playBase64Audio(String base64Audio, String uniqueKey) async {
    // Check if widget is still mounted before playing audio
    if (!mounted) {
      debugPrint('Widget not mounted, skipping audio playback');
      return;
    }
    
    try {
      final audioBytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/${uniqueKey}_response_audio.wav');
      await audioFile.writeAsBytes(audioBytes);
      
      // Double check if still mounted after async operations
      if (!mounted) {
        debugPrint('Widget unmounted during audio preparation, skipping playback');
        return;
      }
      
      await player.openPlayer();
      await player.startPlayer(fromURI: audioFile.path);
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  /// Check if microphone permission is available before starting recording
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    debugPrint('🎤 Checking microphone permission: $status');

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      debugPrint('🎤 Permission denied, requesting permission...');
      // Request permission and let system show the native dialog
      final newStatus = await Permission.microphone.request();
      debugPrint('🎤 Permission request result: $newStatus');
      return newStatus.isGranted;
    } else if (status.isPermanentlyDenied) {
      debugPrint('🎤 Microphone permission permanently denied');
      return false;
    }

    return false;
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
        _showTimeUpBottomSheet();
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

    // Check and request microphone permission if needed
    if (!await _checkMicrophonePermission()) {
      debugPrint('Cannot start recording: microphone permission not granted');
      return;
    }

    // Initialize recorder if not already initialized (after permission is granted)
    try {
      if (!_recorder!.isRecording) {
        await _recorder!.openRecorder();
        _recorder!.setSubscriptionDuration(const Duration(milliseconds: 200));
        debugPrint(
            '🎤 Recorder initialized successfully after permission granted');
      }
    } catch (e) {
      debugPrint('🎤 Error initializing recorder: $e');
      return;
    }

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
      _state.isRecording = true;
      _state.inputMode = InputMode.recording;
      _state.recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _state.recordingSeconds++);
    });
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
      // Collapse all previous user message feedback before adding new message
      _collapseAllPreviousUserFeedback();

      final conversationId = DateTime.now().millisecondsSinceEpoch.toString();

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
          'feedbackExpanded': true, // Set initial state to expanded
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'conversationId': conversationId,
          'audioPath': _audioPath, // Store audio path for retry
          'transcriptionFailed': false,
        });
        if (_state.conversations.length >= 2) {
          _state.conversations[_state.conversations.length - 2]['latest'] =
              false;
        }

        // Auto-scroll to bottom when user recording is sent
        _scrollToBottom();
      });

      // Start transcription timeout timer (10 seconds)
      _startTranscriptionTimeout(conversationId);

      await _followUpConversation(File(_audioPath!), null,
          conversationId: conversationId);
    }
  }

  void _cancelRecording() async {
    await _stopRecording();
  }

  void _startTranscriptionTimeout(String conversationId) {
    _transcriptionTimer?.cancel();
    _transcriptionTimer = Timer(const Duration(seconds: 10), () {
      // Find the conversation with the matching ID and mark it as failed
      setState(() {
        for (int i = 0; i < _state.conversations.length; i++) {
          if (_state.conversations[i]['conversationId'] == conversationId &&
              _state.conversations[i]['isTranscribing'] == true) {
            _state.conversations[i]['isTranscribing'] = false;
            _state.conversations[i]['transcriptionFailed'] = true;
            _state.conversations[i]['text'] = 'Transcription failed';
            debugPrint(
                'Transcription timeout for conversation: $conversationId');
            break;
          }
        }
      });
    });
  }

  void _startAssistantResponseTimeout(String conversationId) {
    _assistantResponseTimer?.cancel();
    _assistantResponseTimer = Timer(const Duration(seconds: 15), () {
      // Find the assistant conversation with the matching ID and mark it as failed
      setState(() {
        for (int i = 0; i < _state.conversations.length; i++) {
          if (_state.conversations[i]['conversationId'] == conversationId &&
              _state.conversations[i]['role'] == 'assistant' &&
              _state.conversations[i]['isLoading'] == true) {
            _state.conversations[i]['isLoading'] = false;
            _state.conversations[i]['responseGenerationFailed'] = true;
            _state.conversations[i]['text'] = 'Response generation failed';
            debugPrint(
                'Assistant response timeout for conversation: $conversationId');
            break;
          }
        }
      });
    });
  }

  void _startCheckpointFeedbackTimeout(int checkpointIndex) {
    _checkpointFeedbackTimers[checkpointIndex]?.cancel();
    _checkpointFeedbackTimers[checkpointIndex] =
        Timer(const Duration(seconds: 30), () {
      // Mark checkpoint feedback as failed due to timeout
      setState(() {
        _state.checkpointFeedbackStates[checkpointIndex] = 'failed';

        // Update the corresponding conversation item
        for (int i = 0; i < _state.conversations.length; i++) {
          if (_state.conversations[i]['role'] == 'checkpoint_feedback' &&
              _state.conversations[i]['checkpointIndex'] == checkpointIndex) {
            _state.conversations[i]['state'] = 'failed';
            break;
          }
        }
      });
      debugPrint(
          'Checkpoint feedback timeout for checkpoint: $checkpointIndex');
    });
  }

  Future<void> _retryTranscription(String conversationId) async {
    // Find the conversation and retry transcription
    for (int i = 0; i < _state.conversations.length; i++) {
      if (_state.conversations[i]['conversationId'] == conversationId) {
        final audioPath = _state.conversations[i]['audioPath'] as String?;
        if (audioPath != null && File(audioPath).existsSync()) {
          setState(() {
            _state.conversations[i]['isTranscribing'] = true;
            _state.conversations[i]['transcriptionFailed'] = false;
            _state.conversations[i]['text'] = '';
          });

          // Start new timeout timer
          _startTranscriptionTimeout(conversationId);

          try {
            // Use the retry tutor response API for transcription retry
            final response = await retryTutorResponse(
              conceptId: widget.conceptId,
              studentName: _state.studentName,
              checkpointNo: _state.currentCheckpointIndex,
              conceptConversationsKey: _state.conceptConversationsKey,
              retryType: RetryType.transcribeText,
              remainingTime: _state.timeLeftSeconds,
              conversationItemId: conversationId,
              language: _state.selectedLanguage,
              voice: _state.selectedVoice,
              audioFile: File(audioPath), // Send the audio file for retry
            );

            // If response contains transcription, update it directly
            if (response.isNotEmpty && response['message'] != null) {
              _transcriptionTimer?.cancel(); // Cancel timeout timer
              _updateTranscription(response['message'], conversationId);

              // Also update conversations with feedback if present in the retry response
              if (response['conversations'] != null &&
                  response['conversations'] is List) {
                final List<Map<String, dynamic>> conversationsList =
                    (response['conversations'] as List)
                        .map((item) => Map<String, dynamic>.from(item as Map))
                        .toList();
                _mergeConversationsPreservingFeedback(conversationsList);
              }
            }
          } catch (e) {
            debugPrint('Error retrying transcription: $e');
            // If retry fails, mark as failed again
            setState(() {
              _state.conversations[i]['isTranscribing'] = false;
              _state.conversations[i]['transcriptionFailed'] = true;
              _state.conversations[i]['text'] = 'Transcription failed';
            });
          }
        }
        break;
      }
    }
  }

  Future<void> _retryAssistantMessage(String conversationId) async {
    // Find the assistant conversation and retry response generation
    for (int i = 0; i < _state.conversations.length; i++) {
      if (_state.conversations[i]['conversationId'] == conversationId &&
          _state.conversations[i]['role'] == 'assistant') {
        setState(() {
          _state.conversations[i]['isLoading'] = true;
          _state.conversations[i]['responseGenerationFailed'] = false;
          _state.conversations[i]['text'] = '';
        });

        // Start new timeout timer
        _startAssistantResponseTimeout(conversationId);

        try {
          // Use the retry tutor response API for assistant message retry
          final response = await retryTutorResponse(
            conceptId: widget.conceptId,
            studentName: _state.studentName,
            checkpointNo: _state.currentCheckpointIndex,
            conceptConversationsKey: _state.conceptConversationsKey,
            retryType: RetryType.tutorMessage,
            remainingTime: _state.timeLeftSeconds,
            conversationItemId: conversationId,
            language: _state.selectedLanguage,
            voice: _state.selectedVoice,
          );

          // If response contains the new message, update it directly
          if (response.isNotEmpty) {
            _assistantResponseTimer?.cancel(); // Cancel timeout timer

            // Update conversations with the retry response
            if (response['conversations'] != null &&
                response['conversations'] is List) {
              final List<Map<String, dynamic>> conversationsList =
                  (response['conversations'] as List)
                      .map((item) => Map<String, dynamic>.from(item as Map))
                      .toList();
              _mergeConversationsPreservingFeedback(conversationsList);
            } else if (response['message'] != null) {
              // If just a message is returned, update the specific conversation
              setState(() {
                _state.conversations[i]['isLoading'] = false;
                _state.conversations[i]['text'] = response['message'];
                _state.conversations[i]['responseGenerationFailed'] = false;
              });
            }
          }
        } catch (e) {
          debugPrint('Error retrying assistant message: $e');
          // If retry fails, mark as failed again
          setState(() {
            _state.conversations[i]['isLoading'] = false;
            _state.conversations[i]['responseGenerationFailed'] = true;
            _state.conversations[i]['text'] = 'Response generation failed';
          });
        }
        break;
      }
    }
  }

  Future<void> _retryCheckpointFeedback(int checkpointIndex) async {
    setState(() {
      _state.checkpointFeedbackStates[checkpointIndex] = 'loading';

      // Update the corresponding conversation item
      for (int i = 0; i < _state.conversations.length; i++) {
        if (_state.conversations[i]['role'] == 'checkpoint_feedback' &&
            _state.conversations[i]['checkpointIndex'] == checkpointIndex) {
          _state.conversations[i]['state'] = 'loading';
          break;
        }
      }
    });

    // Start timeout timer for retry
    _startCheckpointFeedbackTimeout(checkpointIndex);

    try {
      final feedbackData =
          await CheckpointFeedbackService.getCheckpointFeedback(
        conceptConversations: _state.conceptConversationsKey,
        checkpointNumber: checkpointIndex,
        retry: true,
      );

      // Cancel timeout timer on success
      _checkpointFeedbackTimers[checkpointIndex]?.cancel();

      // Check if feedback data is empty
      if (feedbackData.objectives.isEmpty &&
          feedbackData.gaps.isEmpty &&
          feedbackData.shining.isEmpty) {
        throw Exception('Empty feedback data received');
      }

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
      debugPrint('Error retrying checkpoint feedback: $e');
      setState(() {
        _state.checkpointFeedbackStates[checkpointIndex] = 'failed';

        // Update the corresponding conversation item
        for (int i = 0; i < _state.conversations.length; i++) {
          if (_state.conversations[i]['role'] == 'checkpoint_feedback' &&
              _state.conversations[i]['checkpointIndex'] == checkpointIndex) {
            _state.conversations[i]['state'] = 'failed';
            break;
          }
        }
      });
    }
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

    // Collapse all previous user message feedback before adding new message
    _collapseAllPreviousUserFeedback();

    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();

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
        'feedbackExpanded': true, // Set initial state to expanded
        'conversationId': conversationId,
      });
      if (_state.conversations.length >= 2) {
        _state.conversations[_state.conversations.length - 2]['latest'] = false;
      }

      // Auto-scroll to bottom when user text message is sent
      _scrollToBottom();
    });

    player.stopPlayer();
    _messageController.clear();
    _followUpConversation(null, text, conversationId: conversationId);
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
        // This is the last checkpoint
        final lastCheckpointIndex = _state.currentCheckpointIndex;
        final lastCheckpointState =
            _state.checkpointFeedbackStates[lastCheckpointIndex];

        setState(() {
          _state.xpGained += 45;
          _state.showCheckpointContinueButton = false;
        });
        logAITutorCheckpointsCompleted(
            widget.conceptId, _state.completedCheckpointIndexes.length);

        // Check if feedback for last checkpoint already exists
        if (lastCheckpointState == 'ready') {
          // Feedback already exists, directly navigate to all feedback screen
          _showAllCheckpointFeedback();
        } else {
          // Feedback doesn't exist, generate it first then navigate
          _addCheckpointFeedbackCard(lastCheckpointIndex);
          _loadCheckpointFeedback(lastCheckpointIndex);

          // Navigate to all feedback screen
          _showAllCheckpointFeedback();
        }
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

  void _collapseAllPreviousUserFeedback() {
    setState(() {
      for (int i = 0; i < _state.conversations.length; i++) {
        if (_state.conversations[i]['role'] == 'user' &&
            _state.conversations[i]['conversationFeedback'] != null) {
          _state.conversations[i]['feedbackExpanded'] = false;
        }
      }
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
    // Start timeout timer
    _startCheckpointFeedbackTimeout(checkpointIndex);

    try {
      final feedbackData =
          await CheckpointFeedbackService.getCheckpointFeedback(
        conceptConversations: _state.conceptConversationsKey,
        checkpointNumber: checkpointIndex,
      );

      // Cancel timeout timer on success
      _checkpointFeedbackTimers[checkpointIndex]?.cancel();

      // Check if feedback data is empty
      if (feedbackData.objectives.isEmpty &&
          feedbackData.gaps.isEmpty &&
          feedbackData.shining.isEmpty) {
        throw Exception('Empty feedback data received');
      }

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
        _state.checkpointFeedbackStates[checkpointIndex] = 'failed';

        // Update the corresponding conversation item
        for (int i = 0; i < _state.conversations.length; i++) {
          if (_state.conversations[i]['role'] == 'checkpoint_feedback' &&
              _state.conversations[i]['checkpointIndex'] == checkpointIndex) {
            _state.conversations[i]['state'] = 'failed';
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

      // Auto-dismiss the checkpoint feedback notification when user returns
      _dismissCheckpointFeedbackNotification(checkpointIndex);

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
  void _showAllCheckpointFeedback() async {
    final result = await Navigator.push(
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
    );

    // When user comes back from AllCheckpointFeedbackScreen
    if (result != null && result is Map) {
      // Update feedback states with the latest data from AllCheckpointFeedbackScreen
      setState(() {
        _state.checkpointFeedbackStates =
            Map<int, String>.from(result['feedbackStates'] ?? {});
        _state.checkpointFeedbackData =
            Map<int, dynamic>.from(result['feedbackData'] ?? {});

        // Always enable continue button when user comes back
        _state.showCheckpointContinueButton = true;
      });
    } else if (result == null) {
      // User pressed back or popped the screen without returning data
      setState(() {
        // Always enable continue button when user comes back
        _state.showCheckpointContinueButton = true;
      });
    }
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
      'totalCheckpoints': _state.conceptCheckpoints.length,
      'conceptConversationsKey': _state.conceptConversationsKey,
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
    
    // Stop and close audio player properly
    if (player.isPlaying) {
      player.stopPlayer();
    }
    player.closePlayer();
    
    // Disconnect websocket connection to prevent continued audio playback
    try {
      stompClient?.deactivate();
    } catch (e) {
      debugPrint('Error deactivating stomp client: $e');
    }
    
    _confettiController.dispose();
    _timer?.cancel();
    _recordingTimer?.cancel();
    _transcriptionTimer?.cancel();
    _assistantResponseTimer?.cancel();

    // Dispose checkpoint feedback timers
    for (final timer in _checkpointFeedbackTimers.values) {
      timer?.cancel();
    }
    _checkpointFeedbackTimers.clear();

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
      body: Column(
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
    );
  }

  void _showTimeUpBottomSheet() {
    final checkpointsLeft = _state.conceptCheckpoints.length -
        _state.completedCheckpointIndexes.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Taking longer than usual",
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  color: const Color(0xFF0B1220),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "This discussion is taking longer than usual.",
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: const Color(0xFF70695B),
                ),
              ),
              Text(
                checkpointsLeft > 1
                    ? "${checkpointsLeft} checkpoints left."
                    : "${checkpointsLeft} checkpoint left.",
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "CONTINUE",
                  style: GoogleFonts.raleway(
                    fontSize: 14,
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

  void _showBackButtonSheet() {
    bool hasNextCheckpoint =
        _state.currentCheckpointIndex < _state.conceptCheckpoints.length - 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎯 Image at the top
              Container(
                height: 200,
                width: 200,
                child: Center(
                  child: Image.asset(
                    "lib/assets/lesson-quit-new.png",
                    height: 200,
                  ),
                ),
              ),

              // ⚠️ Warning Text with reduced gap
              Transform.translate(
                offset: const Offset(0, -20),
                child: Text(
                  "Quit and you'll lose your mastery in this lesson!",
                  style: GoogleFonts.raleway(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(
                        0xFF2D3748), // Dark text for light background
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Jump to next checkpoint button (if available)
              hasNextCheckpoint
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _onJumpToNext();
                      },
                      child: Text(
                        "BORED? JUMP AHEAD",
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "KEEP GOING",
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

              const SizedBox(height: 24),

              // 🔄 Exit Text (centered)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  logAITutorExit(
                      _state.conceptCheckpoints[_state.currentCheckpointIndex]
                          ['id'],
                      widget.conceptId,
                      _state.currentCheckpointIndex + 1);
                  _navigateBack();
                },
                child: Center(
                  child: Text(
                    "EXIT",
                    style: GoogleFonts.raleway(
                      color: const Color(0xFF2D3748),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatScreen() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showBackButtonSheet();
        }
      },
      child: Scaffold(
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
                          _showBackButtonSheet();
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
                                AITutorHelpers.formatTime(
                                    _state.timeLeftSeconds),
                                style: GoogleFonts.raleway(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0B1220))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          logAITutorMenuButtonClick(widget.conceptId);
                          CommonUIComponents.showMenuSheet(
                            context,
                            _onJumpToNext,
                            _onStartQuestions,
                            _onShowGaps,
                            _onShowCpFeedback,
                            currentCheckpointIndex:
                                _state.currentCheckpointIndex,
                            totalCheckpoints: _state.conceptCheckpoints.length,
                          );
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
                                  fontSize: 12,
                                  color: const Color(0xFF70695B))),
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
                            _retryAssistantMessage,
                          );
                        } else if (role == 'user') {
                          return MessageBubbles.userBubble(
                              convo['text'] ?? "",
                              convo,
                              _onToggleFeedback,
                              index,
                              _retryTranscription);
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
                                  onRetryFeedback: _retryCheckpointFeedback,
                                );
                        }
                        return const SizedBox.shrink();
                      } else {
                        final event = _state
                            .wsEvents[index - _state.conversations.length];
                        final role = event['role'];
                        // if (role == 'gap') {
                        //   return FeedbackCards.gapCard(
                        //     event['data'] as Map<String, dynamic>,
                        //     event['turnIndex'] as int,
                        //     _state.resolvedGaps,
                        //     _onResolveGap,
                        //     _onDismissGap,
                        //     gapConversations: _state.gapConversations,
                        //     expandedGaps: _state.expandedGaps,
                        //     gapTextControllers: _state.gapTextControllers,
                        //     gapLoadingStates: _state.gapLoadingStates,
                        //     onSendGapMessage: _onSendGapMessage,
                        //     onSendGapAudio: _onSendGapAudio,
                        //     onToggleGapExpansion: _onToggleGapExpansion,
                        //     conceptId: widget.conceptId,
                        //     studentName: _state.studentName,
                        //     checkpointNo: _state.currentCheckpointIndex,
                        //     conceptConversationsKey:
                        //         _state.conceptConversationsKey,
                        //     remainingTime: _state.timeLeftSeconds,
                        //     language: _state.selectedLanguage,
                        //     voice: _state.selectedVoice,
                        //   );
                        // }
                        if (role == 'turn_feedback') {
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
            // if (!_state.viewLessonHistory)
            //   Positioned(
            //     right: 12,
            //     bottom: 120,
            //     child: Column(
            //       children: [
            //         CommonUIComponents.circleAction(
            //           icon: Icons.lightbulb_outline,
            //           onTap: () {
            //             logAITutorHintRequested(widget.conceptId,
            //                 _state.currentCheckpointIndex + 1);
            //             _followUpConversation(null, null, hintRequest: true);
            //           },
            //         ),
            //         const SizedBox(height: 10),
            //         CommonUIComponents.circleAction(
            //           icon: Icons.auto_fix_high_outlined,
            //           onTap: () => CommonUIComponents.showPromptSheet(
            //               context, _onPromptSelected),
            //         ),
            //       ],
            //     ),
            //   ),

            // Interactive Island Input UI
            if (!_state.viewLessonHistory)
              Positioned(
                left: 0,
                right: 0,
                bottom: (_state.showAfterGreetingContinueButton ||
                            _state.showCheckpointContinueButton) &&
                        !_state.showDots
                    ? 90
                    : 20,
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
          ],
        ),
      ),
    );
  }
}
