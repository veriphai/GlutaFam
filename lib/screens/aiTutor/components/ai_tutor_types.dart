import 'package:flutter/material.dart';

enum InputMode { compact, recording, typing }

class AITutorState {
  bool isRecording = false;
  bool isLoading = false;
  bool greetingDone = false;
  bool showAfterGreetingContinueButton = false;
  bool showCheckpointContinueButton = false;
  bool showTextBox = false;
  bool showDots = true;
  bool showLessonStart = true;
  bool resumeLesson = false;
  bool viewLessonHistory = false;
  bool objectivesExpanded = false;
  bool isLoadingLanguageVoice = true;
  bool tutorAudioEnabled = true;

  InputMode inputMode = InputMode.compact;
  int recordingSeconds = 0;
  int currentCheckpointIndex = 0;
  int timeLeftSeconds = 0;
  int xpGained = 0;

  Map<String, bool> expandedObjectives = {};
  List<Map<String, dynamic>> conceptCheckpoints = [];
  List<int> completedCheckpointIndexes = [];
  List<int> attemptedCheckpointIndexes = [];
  Map<String, dynamic> conceptDetails = {};
  List<Map<String, dynamic>> conversations = [];
  Map<String, dynamic> latestTutorResponse = {};

  // Gap tracking system
  Map<int, List<Map<String, dynamic>>> conversationGaps = {};
  Set<String> resolvedGaps = {};
  List<Map<String, dynamic>> wsEvents = [];

  // Gap conversation system
  Map<String, List<Map<String, dynamic>>> gapConversations = {};
  Map<String, bool> expandedGaps = {};
  Map<String, TextEditingController> gapTextControllers = {};
  Map<String, bool> gapLoadingStates = {};

  // Language and voice options
  Map<String, String> languageOptions = {};
  Map<String, String> voiceOptions = {};
  String selectedLanguage = "en-US";
  String selectedVoice = "alloy";
  Map<String, dynamic> selectedTutor = {'id': "persona-1"};
  String tutorName = "Tuto Prime";
  String conceptConversationsKey = "";
  String studentName = "";

  DateTime lessonStartTime = DateTime.now();
  int timeTakenToCompleteLessonWithAiTutor = 0;

  // CP Feedback data
  Map<String, dynamic>? cpFeedback;

  // Checkpoint feedback loading state
  Map<int, String> checkpointFeedbackStates = {}; // 'loading', 'ready', 'error'
  Map<int, dynamic> checkpointFeedbackData = {};
}
