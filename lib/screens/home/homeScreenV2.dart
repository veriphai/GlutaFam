import 'package:eureka_app/apis/fetchCompletedConcepts.dart';
import 'package:eureka_app/apis/fetchLessonHistoryList.dart';
import 'package:eureka_app/apis/fetchRecommendedLessons.dart';
import 'package:eureka_app/apis/fetchChaptersToResume.dart';
import 'package:eureka_app/apis/fetchTodayConcepts.dart';
import 'package:eureka_app/apis/updateTaskStatus.dart';
import 'package:eureka_app/apis/resumeConcept.dart';
import 'package:eureka_app/screens/aiTutor/aiTutorScreenV2.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/cachingUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eureka_app/apis/fetchAllChaptersPerStandard.dart';
import 'package:eureka_app/models/searchableConcept.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:eureka_app/newEvents/homeScreenEvents.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/getAppVersionDetails.dart';
import 'package:eureka_app/apis/saveAppVersion.dart';
import 'package:eureka_app/screens/loginScreen.dart';

// Import the modular components
import 'models/app_colors.dart';
import 'models/home_data_models.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_button.dart';
import 'widgets/section_header.dart';
import 'widgets/subjects_section.dart';
import 'widgets/subject_filter_bar.dart';
import 'widgets/lesson_list.dart';
import 'widgets/chapter_list.dart';
import 'widgets/search_overlay.dart';
import 'widgets/view_all_overlay.dart';
import 'widgets/subject_chapters_overlay.dart';
import 'widgets/chapter_overlay.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2>
    with TickerProviderStateMixin {
  // State variables for API data
  bool isLoading = true;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> chapters = [];
  List<String> completedConcepts = [];
  String selectedBookId = "";
  String _selectedSubject = "";
  String conceptToStartFrom = "";
  late SharedPreferences prefs;

  // New API data
  Map<String, dynamic> recommendedLessonsData = {};
  List<Map<String, dynamic>> chaptersToResumeData = [];
  List<Map<String, dynamic>> lessonHistoryData = [];
  Map<String, dynamic> parentConceptsData = {};

  // UI state
  bool _isSearchOpen = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _filterContinue = "all";
  String _filterRecommended = "all";
  String _filterParents = "all";
  String _filterContinueChapters = "all";

  // Search tracking
  DateTime? _searchOpenTime;

  // Overlay tracking
  DateTime? _viewAllOpenTime;
  DateTime? _subjectOverlayOpenTime;
  DateTime? _chapterOverlayOpenTime;

  // Session tracking
  DateTime? _sessionStartTime;
  int _lessonsViewed = 0;
  int _chaptersViewed = 0;
  int _searchesPerformed = 0;
  Set<String> _sectionsVisited = {};

  // Search state
  List<SearchableChapter> _searchableChapters = [];
  List<SearchableTopic> _searchableTopics = [];
  List<SearchableConcept> _searchableConcepts = [];

  late Fuzzy<SearchableChapter> _chapterFuzzy;
  late Fuzzy<SearchableTopic> _topicFuzzy;
  late Fuzzy<SearchableConcept> _conceptFuzzy;

  List<SearchableChapter> _matchedChapters = [];
  List<SearchableTopic> _matchedTopics = [];
  List<SearchableConcept> _matchedConcepts = [];

  // View states
  String? _viewAll;
  String? _subjectView;
  Map<String, String>? _chapterView;

  // Animation controllers
  late AnimationController _searchAnimationController;
  late Animation<double> _searchSlideAnimation;
  late Animation<double> _searchFadeAnimation;

  // Data
  List<Subject> subjects = [];
  List<LessonData> recommendedLessons = [];
  List<LessonData> continueLearningLessons = [];
  List<LessonData> parentLessons = [];
  List<ChapterData> chapterStats = [];
  List<dynamic> allChapters = [];

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _initializeAnimations();
    _initializeData();
    logHomeScreenView();
    checkForAppUpdate(context);
    saveCurrentAppVersion();
  }

  void _initializeAnimations() {
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchSlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOut,
    ));

    _searchFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    // Log session duration before disposing
    if (_sessionStartTime != null) {
      final sessionDuration =
          DateTime.now().difference(_sessionStartTime!).inMilliseconds;
      logSessionDuration(
        timeSpentMs: sessionDuration,
        lessonsViewed: _lessonsViewed,
        chaptersViewed: _chaptersViewed,
        searchesPerformed: _searchesPerformed,
        sectionsVisited: _sectionsVisited.toList(),
      );
    }

    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final startTime = DateTime.now();
    try {
      await _fetchProfile();
      await _fetchSubjectsAndChapters();
      await Future.wait([
        _fetchRecommendedLessons(),
        _fetchChaptersToResume(),
        _fetchLessonHistory(),
        _fetchAllChapters(),
        _fetchParentConcepts(),
      ]);
      _buildUIData();

      // Log successful screen load
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      logHomeScreenLoaded(
        totalLessons: recommendedLessons.length +
            continueLearningLessons.length +
            parentLessons.length,
        totalChapters: chapterStats.length,
        availableSubjects: subjects.map((s) => s.name).toList(),
        loadTimeMs: loadTime,
      );
    } catch (error) {
      print("Error initializing data: $error");

      // Log screen error
      logHomeScreenError(
        errorType: 'initialization_error',
        errorMessage: error.toString(),
        failedOperation: 'initialize_data',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    final startTime = DateTime.now();
    try {
      // Log refresh action
      logHomeScreenRefresh(triggerSource: 'pull_to_refresh');

      // Clear existing data to show fresh content
      setState(() {
        recommendedLessonsData = {};
        chaptersToResumeData = [];
        lessonHistoryData = [];
        parentConceptsData = {};
        recommendedLessons.clear();
        continueLearningLessons.clear();
        parentLessons.clear();
        chapterStats.clear();
      });

      // Re-fetch all data
      await _fetchSubjectsAndChapters();
      await Future.wait([
        _fetchRecommendedLessons(),
        _fetchChaptersToResume(),
        _fetchLessonHistory(),
        _fetchAllChapters(),
        _fetchParentConcepts(),
      ]);
      _buildUIData();

      // Log successful refresh
      final refreshTime = DateTime.now().difference(startTime).inMilliseconds;
      print("Home screen refreshed successfully in ${refreshTime}ms");

      // Log completion using existing method
      logHomeScreenLoaded(
        totalLessons: recommendedLessons.length +
            continueLearningLessons.length +
            parentLessons.length,
        totalChapters: chapterStats.length,
        availableSubjects: subjects.map((s) => s.name).toList(),
        loadTimeMs: refreshTime,
      );
    } catch (error) {
      print("Error refreshing data: $error");

      // Log refresh error
      logHomeScreenError(
        errorType: 'refresh_error',
        errorMessage: error.toString(),
        failedOperation: 'handle_refresh',
      );
    }
  }

  Future<void> _fetchProfile() async {
    final startTime = DateTime.now();
    try {
      logAPICallStarted(
        apiName: 'fetchProfile',
        parameters: {},
      );

      final profileData = await refreshProfile();
      prefs = await SharedPreferences.getInstance();

      setState(() {
        userProfile = profileData;
      });

      logAPICallCompleted(
        apiName: 'fetchProfile',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
      );
    } catch (error) {
      print("Error fetching userProfile: $error");

      logAPICallCompleted(
        apiName: 'fetchProfile',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        errorMessage: error.toString(),
      );

      logHomeScreenError(
        errorType: 'api_failure',
        errorMessage: error.toString(),
        failedOperation: 'fetch_profile',
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _fetchSubjectsAndChapters() async {
    if (userProfile == null) return;

    final startTime = DateTime.now();
    try {
      logAPICallStarted(
        apiName: 'fetchSubjectsAndChapters',
        parameters: {
          'standard': userProfile!["standard"],
          'stream': userProfile!["stream"],
        },
      );

      final booksData = await getBooksWithCache(
          standard: userProfile!["standard"], stream: userProfile!["stream"]);

      selectedBookId = prefs.getString("bookId") ?? "";
      _selectedSubject = prefs.getString("subject") ?? "";

      final scienceBook = booksData.firstWhere(
        (book) => book["subject"]?.toLowerCase() == "science",
        orElse: () => <String, dynamic>{},
      );

      String defaultReason = '';
      if (selectedBookId.isEmpty) {
        if (scienceBook.isNotEmpty) {
          selectedBookId = scienceBook["id"];
          _selectedSubject = scienceBook["subject"];
          defaultReason = 'science_preferred';
        } else {
          selectedBookId = booksData[0]["id"];
          _selectedSubject = booksData[0]["subject"];
          defaultReason = 'fallback_first';
        }
        await prefs.setString("bookId", selectedBookId);
        await prefs.setString("subject", _selectedSubject);

        // Log default subject selection
        logDefaultSubjectSet(
          subjectName: _selectedSubject,
          subjectId: selectedBookId,
          reason: defaultReason,
          availableSubjects: booksData
              .map<String>((book) => book["subject"].toString())
              .toList(),
        );
      }

      final chapterData = await getChaptersWithCache(
          standard: userProfile!["standard"], subject: _selectedSubject);

      final completedConceptsData = await fetchCompletedConcepts(
          bookId: selectedBookId, subject: _selectedSubject);

      setState(() {
        books = booksData;
        chapters = chapterData;
        chapters.sort((a, b) => a["chapterNo"].compareTo(b["chapterNo"]));
        completedConcepts =
            (completedConceptsData["completedConcepts"] as List<dynamic>)
                .cast<String>();
        conceptToStartFrom = completedConceptsData["conceptToStartFrom"];
      });

      logAPICallCompleted(
        apiName: 'fetchSubjectsAndChapters',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
        responseSize: booksData.length + chapterData.length,
      );
    } catch (error) {
      print("Error fetching subjects and chapters: $error");

      logAPICallCompleted(
        apiName: 'fetchSubjectsAndChapters',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        errorMessage: error.toString(),
      );

      logHomeScreenError(
        errorType: 'api_failure',
        errorMessage: error.toString(),
        failedOperation: 'fetch_subjects_chapters',
      );

      rethrow;
    }
  }

  Future<void> _fetchRecommendedLessons() async {
    final startTime = DateTime.now();
    try {
      logAPICallStarted(
        apiName: 'fetchRecommendedLessons',
        parameters: {},
      );

      final data = await fetchRecommendedLessons();
      setState(() {
        recommendedLessonsData = data;
      });

      logAPICallCompleted(
        apiName: 'fetchRecommendedLessons',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
        responseSize: data.toString().length,
      );
    } catch (error) {
      print("Error fetching recommended lessons: $error");

      logAPICallCompleted(
        apiName: 'fetchRecommendedLessons',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        errorMessage: error.toString(),
      );

      logHomeScreenError(
        errorType: 'api_failure',
        errorMessage: error.toString(),
        failedOperation: 'fetch_recommended_lessons',
      );
    }
  }

  Future<void> _fetchChaptersToResume() async {
    final startTime = DateTime.now();
    try {
      logAPICallStarted(
        apiName: 'fetchChaptersToResume',
        parameters: {},
      );

      final data = await fetchChaptersToResume();
      setState(() {
        chaptersToResumeData = data;
      });

      logAPICallCompleted(
        apiName: 'fetchChaptersToResume',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
        responseSize: data.length,
      );
    } catch (error) {
      print("Error fetching chapters to resume: $error");

      logAPICallCompleted(
        apiName: 'fetchChaptersToResume',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        errorMessage: error.toString(),
      );

      logHomeScreenError(
        errorType: 'api_failure',
        errorMessage: error.toString(),
        failedOperation: 'fetch_chapters_to_resume',
      );
    }
  }

  Future<void> _fetchAllChapters() async {
    final startTime = DateTime.now();
    try {
      logAPICallStarted(
        apiName: 'fetchAllChapters',
        parameters: {
          'standard': userProfile!["standard"],
        },
      );

      final data =
          await fetchAllChaptersPerStandard(standard: userProfile!["standard"]);
      setState(() {
        allChapters = data;
        _initializeSearchData();
      });

      logAPICallCompleted(
        apiName: 'fetchAllChapters',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
        responseSize: data.length,
      );
    } catch (error) {
      print("Error fetching all chapters: $error");

      logAPICallCompleted(
        apiName: 'fetchAllChapters',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        errorMessage: error.toString(),
      );

      logHomeScreenError(
        errorType: 'api_failure',
        errorMessage: error.toString(),
        failedOperation: 'fetch_all_chapters',
      );
    }
  }

  void _initializeSearchData() {
    final chapters = <SearchableChapter>{};
    final topics = <SearchableTopic>{};
    final concepts = <SearchableConcept>[];

    for (final chapter in allChapters) {
      final chapterName = chapter['name'] ?? '';
      final subject = chapter['subject'] ?? '';
      final standard = int.tryParse(chapter['standard'].toString()) ?? 0;

      chapters.add(SearchableChapter(
        chapterName: chapterName,
        subject: subject,
        standard: standard,
      ));

      if (chapter['topics'] != null) {
        for (final topic in chapter['topics']) {
          final topicName = topic['name'] ?? '';

          topics.add(SearchableTopic(
            topicName: topicName,
            chapterName: chapterName,
            subject: subject,
            standard: standard,
          ));

          if (topic['lessons'] != null) {
            for (final lesson in topic['lessons']) {
              concepts.add(SearchableConcept(
                conceptName: lesson['name'] ?? '',
                topicName: topicName,
                chapterName: chapterName,
                subject: subject,
                standard: standard,
              ));
            }
          }
        }
      }
    }

    _searchableChapters = chapters.toList();
    _searchableTopics = topics.toList();
    _searchableConcepts = concepts;

    _initializeFuzzySearch();
  }

  void _initializeFuzzySearch() {
    _chapterFuzzy = Fuzzy(
      _searchableChapters,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'chapterName',
            getter: (item) => item.chapterName,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'subject',
            getter: (item) => item.subject,
            weight: 0.4,
          ),
        ],
        threshold: 0.2,
      ),
    );

    _topicFuzzy = Fuzzy(
      _searchableTopics,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'topicName',
            getter: (item) => item.topicName,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'chapterName',
            getter: (item) => item.chapterName,
            weight: 0.6,
          ),
          WeightedKey(
            name: 'subject',
            getter: (item) => item.subject,
            weight: 0.4,
          ),
        ],
        threshold: 0.2,
      ),
    );

    _conceptFuzzy = Fuzzy(
      _searchableConcepts,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'conceptName',
            getter: (item) => item.conceptName,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'topicName',
            getter: (item) => item.topicName,
            weight: 0.7,
          ),
          WeightedKey(
            name: 'chapterName',
            getter: (item) => item.chapterName,
            weight: 0.6,
          ),
        ],
        threshold: 0.4,
      ),
    );
  }

  Future<void> _fetchLessonHistory() async {
    final startTime = DateTime.now();
    try {
      logAPICallStarted(
        apiName: 'fetchLessonHistory',
        parameters: {
          'onlyIncompleteLessons': true,
        },
      );

      final data =
          await fetchLessonHistoryList(onlyIncompleteLessons: true.toString());
      setState(() {
        lessonHistoryData = data;
      });

      logAPICallCompleted(
        apiName: 'fetchLessonHistory',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
        responseSize: data.length,
      );
    } catch (error) {
      print("Error fetching lesson history: $error");

      logAPICallCompleted(
        apiName: 'fetchLessonHistory',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        errorMessage: error.toString(),
      );

      logHomeScreenError(
        errorType: 'api_failure',
        errorMessage: error.toString(),
        failedOperation: 'fetch_lesson_history',
      );
    }
  }

  Future<void> _fetchParentConcepts() async {
    final startTime = DateTime.now();
    try {
      logAPICallStarted(
        apiName: 'fetchTodayConcepts',
        parameters: {},
      );

      final data = await fetchTodayConcepts();
      setState(() {
        parentConceptsData = data;
      });

      logAPICallCompleted(
        apiName: 'fetchTodayConcepts',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: true,
        responseSize: data.toString().length,
      );
    } catch (error) {
      print("Error fetching parent concepts: $error");

      logAPICallCompleted(
        apiName: 'fetchTodayConcepts',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        success: false,
        errorMessage: error.toString(),
      );

      logHomeScreenError(
        errorType: 'api_failure',
        errorMessage: error.toString(),
        failedOperation: 'fetch_parent_concepts',
      );
    }
  }

  void _buildUIData() {
    // Build subjects from books data
    subjects = books
        .map((book) => Subject(
              id: book["id"],
              name: book["subject"],
              emoji: _getSubjectEmoji(book["subject"]),
            ))
        .toList();

    // Build lessons from API data
    chapterStats = [];

    // Build recommended lessons from API
    if (recommendedLessonsData.isNotEmpty) {
      // Process overall recommendations (top 5 across all subjects)
      final overallRecommendations =
          recommendedLessonsData['overallRecommendations'] as List<dynamic>? ??
              [];
      for (final lessonData in overallRecommendations) {
        recommendedLessons.add(LessonData(
          id: lessonData['conceptId'] ?? '',
          name: lessonData['conceptName'] ?? '',
          subjectId: _getSubjectIdByName(lessonData['subject'] ?? ''),
          subject: lessonData['subject'] ?? '',
          chapter: lessonData['chapterName'] ?? '',
          topic: lessonData['topicName'] ?? '',
          minutes: lessonData['expectedCompletionTime'] ?? 15,
          recommended: true,
          fromParent: false,
          progress: (lessonData['isStarted'] == true)
              ? 0.1
              : 0.0, // Small progress if started
          recommendationReason: lessonData['recommendationReason'],
          priorityScore: (lessonData['priorityScore'] as num?)?.toDouble(),
          taskId: null, // Recommended lessons don't have task IDs
        ));
      }

      // Process subject-wise recommendations
      final subjectWiseRecommendations =
          recommendedLessonsData['subjectWiseRecommendations']
                  as Map<String, dynamic>? ??
              {};
      for (final subject in subjectWiseRecommendations.keys) {
        final subjectLessons =
            subjectWiseRecommendations[subject] as List<dynamic>? ?? [];
        for (final lessonData in subjectLessons) {
          // Avoid duplicates from overall recommendations
          final conceptId = lessonData['conceptId'] ?? '';
          final alreadyExists =
              recommendedLessons.any((lesson) => lesson.id == conceptId);

          if (!alreadyExists) {
            recommendedLessons.add(LessonData(
              id: conceptId,
              name: lessonData['conceptName'] ?? '',
              subjectId: _getSubjectIdByName(lessonData['subject'] ?? ''),
              subject: lessonData['subject'] ?? '',
              chapter: lessonData['chapterName'] ?? '',
              topic: lessonData['topicName'] ?? '',
              minutes: lessonData['expectedCompletionTime'] ?? 15,
              recommended: true,
              fromParent: false,
              progress: (lessonData['isStarted'] == true) ? 0.1 : 0.0,
              recommendationReason: lessonData['recommendationReason'],
              priorityScore: (lessonData['priorityScore'] as num?)?.toDouble(),
              taskId: null, // Recommended lessons don't have task IDs
            ));
          }
        }
      }
    }

    // Build resumable chapters from API (for Continue Chapters section)
    final Map<String, ChapterData> chapterMap = {};
    for (final chapterData in chaptersToResumeData) {
      final chapterKey = chapterData['id'];

      // Add to chapter stats
      chapterMap[chapterKey] = ChapterData(
        key: chapterKey,
        subjectId: chapterData['bookId'] ?? '',
        subject: chapterData['subject'] ?? '',
        chapter: chapterData['name'] ?? '',
        total: chapterData['totalLessons'] ?? 0,
        completed: chapterData['completedLessons'] ?? 0,
        inProgress: chapterData['inProgressLessons'] ?? 0,
      );
    }

    // Build resumable lessons from lesson history API (for Continue Learning section)
    for (final lessonData in lessonHistoryData) {
      continueLearningLessons.add(LessonData(
        id: lessonData['conceptId'] ?? '',
        name: lessonData['conceptName'] ?? '',
        subjectId: _getSubjectIdByName(lessonData['subject'] ?? ''),
        subject: lessonData['subject'] ?? '',
        chapter: lessonData['chapterName'] ?? '',
        topic: lessonData['topicName'] ?? '',
        minutes: lessonData['expectedCompletionTime'] ?? 15,
        recommended: false,
        fromParent: false,
        progress: _calculateProgress(
            lessonData['checkpointsCompleted'], lessonData['totalCheckpoints']),
        recommendationReason: null,
        priorityScore: null,
        checkpointsCompleted: lessonData['checkpointsCompleted'] ?? 0,
        conceptConversationKey: lessonData['conceptConversationKey'] ?? '',
        checkpointNo: lessonData['checkpointNo'] ?? 0,
        learningObjectivesStatus: lessonData['learningObjectivesStatus'] ?? {},
        newCheckpointStarted: lessonData['newCheckpointStarted'] ?? false,
        timeRemaining: lessonData['timeRemaining'] ?? 0,
        resumeLesson: true,
        taskId: null, // Continue learning lessons don't have task IDs
      ));
    }

    // Build parent lessons from API (for From Parents section)
    parentLessons.clear();
    if (parentConceptsData.isNotEmpty &&
        parentConceptsData['success'] == true &&
        parentConceptsData['data'] != null) {
      final journeys =
          parentConceptsData['data']['journeys'] as List<dynamic>? ?? [];

      for (final journey in journeys) {
        final concepts = journey['concepts'] as List<dynamic>? ?? [];
        final journeyId = journey['journeyId'] as String? ?? '';

        for (final concept in concepts) {
          final conceptDetails = concept['conceptDetails'];
          final tasks = concept['tasks'] as List<dynamic>? ?? [];

          if (conceptDetails != null) {
            // Extract task ID from the first task (assuming one task per concept)
            String? taskId;
            if (tasks.isNotEmpty) {
              taskId = tasks[0]['id'] as String?;
            }

            parentLessons.add(LessonData(
              id: conceptDetails['id'] ?? '',
              name: conceptDetails['name'] ?? '',
              subjectId: _getSubjectIdByName(conceptDetails['subject'] ?? ''),
              subject: conceptDetails['subject'] ?? '',
              chapter: conceptDetails['chapterName'] ?? '',
              topic: conceptDetails['topicName'] ?? '',
              minutes: conceptDetails['expectedCompletionTime'] ?? 15,
              recommended: false,
              fromParent: true,
              progress: 0.0, // Parent assigned tasks start fresh
              recommendationReason: 'Assigned by parent',
              priorityScore: concept['priority'] == 'HIGH'
                  ? 3.0
                  : concept['priority'] == 'MEDIUM'
                      ? 2.0
                      : 1.0,
              taskId: taskId,
              journeyId: journeyId,
            ));
          }
        }
      }
    }

    chapterStats = chapterMap.values.toList();

    // Sort recommended lessons by priority score (higher first)
    final recommendedLessonsList =
        recommendedLessons.where((l) => l.recommended).toList();
    recommendedLessonsList.sort((a, b) {
      final scoreA = a.priorityScore ?? 0.0;
      final scoreB = b.priorityScore ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    // Log recommendations shown
    for (int i = 0; i < recommendedLessons.length; i++) {
      final lesson = recommendedLessons[i];
      logRecommendationShown(
        lessonId: lesson.id,
        lessonName: lesson.name,
        recommendationReason: lesson.recommendationReason,
        priorityScore: lesson.priorityScore,
        positionInList: i + 1,
        subject: lesson.subject,
      );
    }
  }

  String _getSubjectIdByName(String subjectName) {
    // Find the subject ID by matching the subject name
    for (final book in books) {
      if (book["subject"]?.toLowerCase() == subjectName.toLowerCase()) {
        return book["id"] ?? "";
      }
    }
    // Return current selected book ID as fallback
    return selectedBookId;
  }

  double _calculateProgress(
      dynamic checkpointsCompleted, dynamic totalCheckpoints) {
    // Handle null values
    if (checkpointsCompleted == null || totalCheckpoints == null) {
      return 0.0;
    }

    // Convert to numbers
    final completed =
        (checkpointsCompleted is num) ? checkpointsCompleted.toDouble() : 0.0;
    final total = (totalCheckpoints is num) ? totalCheckpoints.toDouble() : 0.0;

    // Avoid division by zero and ensure valid range
    if (total <= 0) {
      return 0.0;
    }

    final progress = completed / total;

    // Clamp between 0.0 and 1.0 to ensure valid widthFactor
    return progress.clamp(0.0, 1.0);
  }

  String _getSubjectEmoji(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'maths':
        return "🧮";
      case 'physics':
        return "🧲";
      case 'chemistry':
        return "⚗️";
      case 'biology':
        return "🧬";
      case 'science':
        return "🔬";
      case 'history':
        return "🏺";
      case 'geography':
        return "🗺️";
      case 'english':
        return "📚";
      default:
        return "📘";
    }
  }

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
      _searchOpenTime = DateTime.now();
    });

    // Start animation and request focus when animation completes
    _searchAnimationController.forward().then((_) {
      _showKeyboardForSearch();
    });

    logSearchOpened();
  }

  void _showKeyboardForSearch() {
    // For iOS, we need to be more careful about timing
    if (Platform.isIOS) {
      // Give the animation and layout time to settle
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _isSearchOpen) {
          // First ensure the field can actually receive focus
          _searchFocusNode.requestFocus();

          // Then trigger a tap simulation after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _searchFocusNode.hasFocus) {
              // Force show keyboard via system channels
              SystemChannels.textInput.invokeMethod('TextInput.show');
            }
          });
        }
      });
    } else {
      // Android - use original approach
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();

    // Log search cancellation
    if (_searchOpenTime != null) {
      final timeSpent =
          DateTime.now().difference(_searchOpenTime!).inMilliseconds;
      final hadResults = _matchedChapters.isNotEmpty ||
          _matchedTopics.isNotEmpty ||
          _matchedConcepts.isNotEmpty;

      logSearchCancelled(
        searchQuery: _searchQuery,
        timeSpentMs: timeSpent,
        hadResults: hadResults,
      );
    }

    _searchAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isSearchOpen = false;
          _searchQuery = "";
          _matchedChapters = [];
          _matchedTopics = [];
          _matchedConcepts = [];
          _searchOpenTime = null;
        });
        _searchController.clear();
      }
    });
  }

  void _performSearch(String query) {
    final searchStartTime = DateTime.now();
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _searchQuery = query;
        _matchedChapters = [];
        _matchedTopics = [];
        _matchedConcepts = [];
      });
      return;
    }

    // Chapter search
    final exactChapters = _searchableChapters
        .where((c) => c.chapterName.toLowerCase().contains(q))
        .toList();
    final fuzzyChapters = _chapterFuzzy.search(q).map((r) => r.item).toList();
    final allChapters = {
      for (var c in [...exactChapters, ...fuzzyChapters]) c.chapterName: c
    }.values.toList();

    // Topic search
    final exactTopics = _searchableTopics
        .where((t) => t.topicName.toLowerCase().contains(q))
        .toList();
    final fuzzyTopics = _topicFuzzy.search(q).map((r) => r.item).toList();
    final allTopics = {
      for (var t in [...exactTopics, ...fuzzyTopics]) t.topicName: t
    }.values.toList();

    // Concept search
    final exactConcepts = _searchableConcepts
        .where((c) => c.conceptName.toLowerCase().contains(q))
        .toList();
    final fuzzyConcepts = _conceptFuzzy.search(q).map((r) => r.item).toList();
    final allConcepts = {
      for (var c in [...exactConcepts, ...fuzzyConcepts]) c.conceptName: c
    }.values.toList();

    setState(() {
      _searchQuery = query;
      _matchedChapters = allChapters;
      _matchedTopics = allTopics;
      _matchedConcepts = allConcepts;
    });

    final searchTime =
        DateTime.now().difference(searchStartTime).inMilliseconds;

    // Log search query and increment counter
    logSearchQueryEntered(
      query: query,
      chaptersFound: allChapters.length,
      topicsFound: allTopics.length,
      conceptsFound: allConcepts.length,
      queryLength: query.length,
      searchTimeMs: searchTime,
    );

    _searchesPerformed++;

    // Log if no results found
    if (allChapters.isEmpty && allTopics.isEmpty && allConcepts.isEmpty) {
      logSearchNoResults(
        query: query,
        queryLength: query.length,
      );
    }
  }

  Future<void> _onTapLesson(LessonData lesson) async {
    // Log lesson viewing and increment counter
    final sectionType = lesson.recommended
        ? (lesson.fromParent ? 'parents' : 'recommended')
        : 'continue';
    logLessonViewed(
      lessonId: lesson.id,
      lessonName: lesson.name,
      sectionType: sectionType,
      subject: lesson.subject,
      chapter: lesson.chapter,
      currentProgress: lesson.progress,
      estimatedMinutes: lesson.minutes,
    );

    _lessonsViewed++;

    // Mark task as started if it's a parent lesson with task ID
    if (lesson.taskId != null && lesson.fromParent) {
      try {
        print(
            'Marking task ${lesson.taskId} as STARTED for lesson ${lesson.name}');
        final taskUpdateResult = await updateTaskStatus(
            lesson.taskId!, 'STARTED', lesson.journeyId!);

        if (taskUpdateResult['success'] == true) {
          print('Successfully marked task ${lesson.taskId} as STARTED');
        } else {
          print('Failed to mark task as started: ${taskUpdateResult['error']}');
          // Continue with navigation even if task update fails
        }
      } catch (e) {
        print('Error updating task status: $e');
        // Continue with navigation even if task update fails
      }
    }

    // Navigate to concept learning screen
    if (mounted) {
      if (lesson.resumeLesson == true) {
        logLessonResumed(lesson.id);
        final datatoResumeConcept = await resumeConcept(
            conceptId: lesson.id,
            checkpointsCompleted: lesson.checkpointsCompleted ?? 0,
            conceptConversationsKey: lesson.conceptConversationKey ?? "",
            checkpointNo: lesson.checkpointNo ?? 0,
            learningObjectivesStatus: lesson.learningObjectivesStatus,
            newCheckpointStarted: lesson.newCheckpointStarted ?? false,
            remainingTime: lesson.timeRemaining ?? 0);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AITutorScreenV2(
              conceptId: lesson.id,
              conceptName: lesson.name,
              chapterName: lesson.chapter,
              maxXP: 45,
              name: userProfile?['firstName'] ?? 'Student',
              subject: lesson.subject,
              standard: userProfile?['standard'] ?? 8,
              resumeLesson: true,
              dataToResume: datatoResumeConcept,
            ),
          ),
        );

        // Handle the returned checkpoint completion data
        if (result != null && mounted) {
          _updateLessonProgress(lesson, result as Map<String, dynamic>);
        }
      } else {
        logConceptStart(lesson.id);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AITutorScreenV2(
              conceptId: lesson.id,
              conceptName: lesson.name,
              chapterName: lesson.chapter,
              maxXP: 45,
              name: userProfile?['firstName'] ?? 'Student',
              subject: lesson.subject,
              standard: userProfile?['standard'] ?? 8,
            ),
          ),
        );

        // Handle the returned checkpoint completion data
        if (result != null && mounted) {
          _updateLessonProgress(lesson, result as Map<String, dynamic>);
        }
      }
    }
  }

  Future<void> _onTapSearchConcept(SearchableConcept concept) async {
    // Navigate to concept learning screen for search results
    if (mounted) {
      logConceptStart(concept.conceptName);
      // Try to find the concept ID from allChapters data
      String conceptId = '';
      for (final chapter in allChapters) {
        if (chapter['name'] == concept.chapterName &&
            chapter['subject'] == concept.subject &&
            chapter['topics'] != null) {
          for (final topic in chapter['topics']) {
            if (topic['name'] == concept.topicName &&
                topic['lessons'] != null) {
              for (final lesson in topic['lessons']) {
                if (lesson['name'] == concept.conceptName) {
                  conceptId = lesson['id']?.toString() ?? '';
                  break;
                }
              }
              if (conceptId.isNotEmpty) break;
            }
          }
          if (conceptId.isNotEmpty) break;
        }
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AITutorScreenV2(
            conceptId: conceptId,
            conceptName: concept.conceptName,
            chapterName: concept.chapterName,
            maxXP: 45,
            name: userProfile?['firstName'] ?? 'Student',
            subject: concept.subject,
            standard: userProfile?['standard'] ?? 8,
          ),
        ),
      );

      // Handle the returned checkpoint completion data for search concepts
      if (result != null && mounted) {
        // For search concepts, we need to refresh the data since we don't have a direct lesson reference
        _initializeData();
      }
    }
  }

  void _updateLessonProgress(
      LessonData originalLesson, Map<String, dynamic> completionData) {
    final conceptId = completionData['conceptId'] as String;
    final checkpointsCompleted = completionData['checkpointsCompleted'] as int;
    final currentCheckpointIndex =
        completionData['currentCheckpointIndex'] as int;
    final totalCheckpoints = completionData['totalCheckpoints'] as int;
    final conceptConversationsKey =
        completionData['conceptConversationsKey'] as String;

    // Determine if lesson is completed (assuming 3 checkpoints total based on user's requirement)
    // const totalCheckpoints = 3;
    final isCompleted = checkpointsCompleted >= totalCheckpoints;
    final progress = checkpointsCompleted / totalCheckpoints;

    // Log lesson progress update
    logLessonProgressUpdated(
      lessonId: conceptId,
      oldProgress: originalLesson.progress,
      newProgress: progress,
      checkpointsCompleted: checkpointsCompleted,
      totalCheckpoints: totalCheckpoints,
      isCompleted: isCompleted,
    );

    // Update the lesson in both recommended and continue learning lists
    setState(() {
      // Update in recommended lessons
      for (int i = 0; i < recommendedLessons.length; i++) {
        if (recommendedLessons[i].id == conceptId) {
          recommendedLessons[i] = LessonData(
            id: recommendedLessons[i].id,
            name: recommendedLessons[i].name,
            subjectId: recommendedLessons[i].subjectId,
            subject: recommendedLessons[i].subject,
            chapter: recommendedLessons[i].chapter,
            topic: recommendedLessons[i].topic,
            minutes: recommendedLessons[i].minutes,
            recommended: recommendedLessons[i].recommended,
            fromParent: recommendedLessons[i].fromParent,
            progress: progress.clamp(0.0, 1.0),
            recommendationReason: recommendedLessons[i].recommendationReason,
            priorityScore: recommendedLessons[i].priorityScore,
            checkpointsCompleted: checkpointsCompleted,
            conceptConversationKey: completionData['conceptConversationKey'],
            checkpointNo: currentCheckpointIndex,
            learningObjectivesStatus:
                recommendedLessons[i].learningObjectivesStatus,
            newCheckpointStarted: false,
            timeRemaining: recommendedLessons[i].timeRemaining,
            resumeLesson: !isCompleted && checkpointsCompleted > 0,
            completed: isCompleted,
            taskId: recommendedLessons[i].taskId,
          );
          break;
        }
      }

      // Update in continue learning lessons
      for (int i = 0; i < continueLearningLessons.length; i++) {
        if (continueLearningLessons[i].id == conceptId) {
          continueLearningLessons[i] = LessonData(
            id: continueLearningLessons[i].id,
            name: continueLearningLessons[i].name,
            subjectId: continueLearningLessons[i].subjectId,
            subject: continueLearningLessons[i].subject,
            chapter: continueLearningLessons[i].chapter,
            topic: continueLearningLessons[i].topic,
            minutes: continueLearningLessons[i].minutes,
            recommended: continueLearningLessons[i].recommended,
            fromParent: continueLearningLessons[i].fromParent,
            progress: progress.clamp(0.0, 1.0),
            recommendationReason:
                continueLearningLessons[i].recommendationReason,
            priorityScore: continueLearningLessons[i].priorityScore,
            checkpointsCompleted: checkpointsCompleted,
            conceptConversationKey: completionData['conceptConversationKey'],
            checkpointNo: currentCheckpointIndex,
            learningObjectivesStatus:
                continueLearningLessons[i].learningObjectivesStatus,
            newCheckpointStarted: false,
            timeRemaining: continueLearningLessons[i].timeRemaining,
            resumeLesson: !isCompleted && checkpointsCompleted > 0,
            completed: isCompleted,
            taskId: continueLearningLessons[i].taskId,
          );
          break;
        }
      }

      // Update in allChapters structure
      for (int i = 0; i < allChapters.length; i++) {
        if (allChapters[i]['topics'] != null) {
          for (int j = 0; j < allChapters[i]['topics'].length; j++) {
            if (allChapters[i]['topics'][j]['lessons'] != null) {
              for (int k = 0;
                  k < allChapters[i]['topics'][j]['lessons'].length;
                  k++) {
                if (allChapters[i]['topics'][j]['lessons'][k]['id']
                        ?.toString() ==
                    conceptId) {
                  // Update lesson progress data in allChapters
                  allChapters[i]['topics'][j]['lessons'][k]['progress'] =
                      progress.clamp(0.0, 1.0);
                  allChapters[i]['topics'][j]['lessons'][k]
                      ['checkpointsCompleted'] = checkpointsCompleted;
                  allChapters[i]['topics'][j]['lessons'][k]['checkpointNo'] =
                      currentCheckpointIndex;
                  allChapters[i]['topics'][j]['lessons'][k]
                          ['conceptConversationKey'] =
                      completionData['conceptConversationKey'];
                  allChapters[i]['topics'][j]['lessons'][k]['canResume'] =
                      !isCompleted && checkpointsCompleted > 0;
                  allChapters[i]['topics'][j]['lessons'][k]['completed'] =
                      isCompleted;
                  allChapters[i]['topics'][j]['lessons'][k]
                      ['conceptConversationsKey'] = conceptConversationsKey;
                  allChapters[i]['topics'][j]['lessons'][k]
                      ['totalCheckpoints'] = totalCheckpoints;
                  break;
                }
              }
            }
          }
        }
      }

      // If lesson is completed, remove it from continue learning (it should not be resumable anymore)
      if (isCompleted) {
        continueLearningLessons.removeWhere((lesson) => lesson.id == conceptId);

        // Log lesson completion
        logLessonCompleted(
          lessonId: conceptId,
          timeSpentMs: 0, // We don't have time spent data here
          checkpointsCompleted: checkpointsCompleted,
          subject: originalLesson.subject,
          chapter: originalLesson.chapter,
          completionSource: 'home_screen',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            // Main content
            SafeArea(
              child: _buildMainContent(),
            ),

            // Search overlay
            if (_isSearchOpen)
              SearchOverlay(
                animationController: _searchAnimationController,
                slideAnimation: _searchSlideAnimation,
                fadeAnimation: _searchFadeAnimation,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchQuery: _searchQuery,
                matchedChapters: _matchedChapters,
                matchedTopics: _matchedTopics,
                matchedConcepts: _matchedConcepts,
                onSearchChanged: _performSearch,
                onClose: _closeSearch,
                onConceptTap: (concept) {
                  // Log search result click
                  final position = _matchedConcepts.indexOf(concept) + 1;
                  logSearchResultClicked(
                    resultType: 'concept',
                    itemName: concept.conceptName,
                    itemId: '', // We'll find the ID in _onTapSearchConcept
                    subject: concept.subject,
                    resultPosition: position,
                    searchQuery: _searchQuery,
                  );
                  _onTapSearchConcept(concept);
                },
                onTopicTap: (topic) {
                  logTopicButtonClick(topic.topicName);

                  // Log search result click
                  final position = _matchedTopics.indexOf(topic) + 1;
                  logSearchResultClicked(
                    resultType: 'topic',
                    itemName: topic.topicName,
                    itemId: topic.topicName,
                    subject: topic.subject,
                    resultPosition: position,
                    searchQuery: _searchQuery,
                  );

                  setState(() {
                    _chapterView = {
                      'subjectId': _getSubjectIdByName(topic.subject),
                      'subject': topic.subject,
                      'chapter': topic.chapterName,
                    };
                  });
                  _closeSearch();
                },
                onChapterTap: (chapter) {
                  logChapterSelected(chapter.chapterName);

                  // Log search result click
                  final position = _matchedChapters.indexOf(chapter) + 1;
                  logSearchResultClicked(
                    resultType: 'chapter',
                    itemName: chapter.chapterName,
                    itemId: chapter.chapterName,
                    subject: chapter.subject,
                    resultPosition: position,
                    searchQuery: _searchQuery,
                  );

                  setState(() {
                    _chapterView = {
                      'subjectId': _getSubjectIdByName(chapter.subject),
                      'subject': chapter.subject,
                      'chapter': chapter.chapterName,
                    };
                  });
                  _closeSearch();
                },
              ),

            // View-all overlay
            if (_viewAll != null)
              ViewAllOverlay(
                section: _viewAll!,
                lessons: _viewAll == 'continue'
                    ? continueLearningLessons
                    : _viewAll == 'recommended'
                        ? recommendedLessons
                        : _viewAll == 'parents'
                            ? parentLessons
                            : recommendedLessons,
                chapters: chapterStats,
                subjects: subjects,
                onLessonTap: _onTapLesson,
                onChapterTap: (chapter) {
                  logChapterSelected(chapter.key);

                  logChapterOverlayOpened(
                    chapterName: chapter.chapter,
                    subject: chapter.subject,
                    chapterId: chapter.key,
                    totalLessons: chapter.total,
                    completedLessons: chapter.completed,
                  );

                  setState(() {
                    _chapterView = {
                      'subjectId': chapter.subjectId,
                      'subject': chapter.subject,
                      'chapter': chapter.chapter,
                    };
                  });
                },
                onClose: () {
                  // Log overlay closure
                  if (_viewAllOpenTime != null) {
                    final timeSpent = DateTime.now()
                        .difference(_viewAllOpenTime!)
                        .inMilliseconds;
                    logViewAllOverlayClosed(
                      sectionType: _viewAll!,
                      timeSpentMs: timeSpent,
                      itemSelected:
                          false, // Assuming no item was selected on close
                    );
                  }
                  setState(() {
                    _viewAll = null;
                    _viewAllOpenTime = null;
                  });
                },
                onFilterClicked: logSubjectFilterClicked,
              ),

            // Subject chapters overlay
            if (_subjectView != null)
              SubjectChaptersOverlay(
                subjectId: _subjectView!,
                subjects: subjects,
                allChapters: allChapters,
                onChapterTap: (chapter) {
                  logChapterSelected(chapter.key);

                  logChapterOverlayOpened(
                    chapterName: chapter.chapter,
                    subject: chapter.subject,
                    chapterId: chapter.key,
                    totalLessons: chapter.total,
                    completedLessons: chapter.completed,
                  );

                  setState(() {
                    _chapterView = {
                      'subjectId': chapter.subjectId,
                      'subject': chapter.subject,
                      'chapter': chapter.chapter,
                    };
                  });
                },
                onClose: () => setState(() {
                  _subjectView = null;
                  _subjectOverlayOpenTime = null;
                }),
              ),

            // Chapter overlay
            if (_chapterView != null)
              ChapterOverlay(
                chapterView: _chapterView!,
                subjects: subjects,
                allChapters: allChapters,
                onLessonTap: _onTapLesson,
                onClose: () => setState(() {
                  _chapterView = null;
                  _chapterOverlayOpenTime = null;
                }),
                getSubjectIdByName: _getSubjectIdByName,
                calculateProgress: _calculateProgress,
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() {
    if (_isSearchOpen) {
      _closeSearch();
      return Future.value(false);
    }
    if (_viewAll != null) {
      // Log view all overlay closure
      if (_viewAllOpenTime != null) {
        final timeSpent =
            DateTime.now().difference(_viewAllOpenTime!).inMilliseconds;
        logViewAllOverlayClosed(
          sectionType: _viewAll!,
          timeSpentMs: timeSpent,
          itemSelected: false, // Back press means no item was selected
        );
      }
      setState(() {
        _viewAll = null;
        _viewAllOpenTime = null;
      });
      return Future.value(false);
    }
    if (_subjectView != null) {
      setState(() {
        _subjectView = null;
        _subjectOverlayOpenTime = null;
      });
      return Future.value(false);
    }
    if (_chapterView != null) {
      setState(() {
        _chapterView = null;
        _chapterOverlayOpenTime = null;
      });
      return Future.value(false);
    }
    return Future.value(true);
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      backgroundColor: AppColors.bg,
      color: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(firstName: userProfile?['firstName']),
            const SizedBox(height: 16),
            HomeSearchButton(
              onTap: _openSearch,
              searchFocusNode: _searchFocusNode,
            ),
            const SizedBox(height: 28),
            SubjectsSection(
              subjects: subjects,
              onSubjectTap: (subjectId) {
                final subject = subjects.firstWhere((s) => s.id == subjectId);
                logSubjectSelected(subject.name);

                // Count chapters for this subject
                final subjectChapters = allChapters
                    .where((chapter) =>
                        chapter['subject']?.toString().toLowerCase() ==
                        subject.name.toLowerCase())
                    .length;

                logSubjectChaptersOpened(
                  subjectName: subject.name,
                  subjectId: subjectId,
                  totalChapters: subjectChapters,
                );

                setState(() {
                  _subjectView = subjectId;
                  _subjectOverlayOpenTime = DateTime.now();
                });
              },
            ),
            const SizedBox(height: 32),
            ..._buildContinueChapters(),
            ..._buildContinueLearning(),
            _buildRecommendedSection(),
            ..._buildFromParentsSection(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContinueChapters() {
    final continueChapters = chapterStats;
    if (continueChapters.isEmpty) {
      logEmptySectionShown(
        sectionName: "continue_chapters",
        emptyReason: "no_data",
      );
      return [];
    }

    // Log section viewed and track visit
    logSectionViewed(
      sectionName: "continue_chapters",
      itemCount: continueChapters.length,
      isEmpty: false,
      scrollPosition: 0, // We don't have scroll tracking implemented
    );
    _sectionsVisited.add("continue_chapters");

    return [
      SectionHeader(
        icon: Icons.list_alt,
        title: "Continue chapters",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("continue_chapters");
          logViewAllOverlayOpened(
            sectionType: "continue_chapters",
            totalItems: chapterStats.length,
          );
          setState(() {
            _viewAll = "continue_chapters";
            _viewAllOpenTime = DateTime.now();
          });
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterContinueChapters,
        onChanged: (value) {
          final previousFilter = _filterContinueChapters;
          final filteredItemCount = value == "all"
              ? chapterStats.length
              : chapterStats.where((c) => c.subjectId == value).length;

          if (value == "all" && previousFilter != "all") {
            logFilterCleared(
              sectionType: "continue_chapters",
              previousFilter: previousFilter,
              totalItemCount: chapterStats.length,
            );
          } else if (value != "all") {
            logSubjectFilterApplied(
              sectionType: "continue_chapters",
              selectedSubject: value,
              previousFilter: previousFilter,
              filteredItemCount: filteredItemCount,
            );
          }

          setState(() => _filterContinueChapters = value);
        },
        allowedSubjectIds:
            continueChapters.map((c) => c.subjectId).toSet().toList(),
        subjects: subjects,
        onFilterClicked: logSubjectFilterClicked,
      ),
      const SizedBox(height: 12),
      ChapterList(
        chapters: continueChapters
            .where((c) =>
                _filterContinueChapters == "all" ||
                c.subjectId == _filterContinueChapters)
            .take(2)
            .toList(),
        onChapterTap: (chapter) {
          logChapterSelected(chapter.key);

          logChapterOverlayOpened(
            chapterName: chapter.chapter,
            subject: chapter.subject,
            chapterId: chapter.key,
            totalLessons: chapter.total,
            completedLessons: chapter.completed,
          );

          setState(() {
            _chapterView = {
              'subjectId': chapter.subjectId,
              'subject': chapter.subject,
              'chapter': chapter.chapter,
            };
            _chapterOverlayOpenTime = DateTime.now();
          });
        },
      ),
      const SizedBox(height: 32),
    ];
  }

  List<Widget> _buildContinueLearning() {
    final continueLessons = continueLearningLessons.toList();
    if (continueLessons.isEmpty) {
      logEmptySectionShown(
        sectionName: "continue_learning",
        emptyReason: "no_data",
      );
      return [];
    }

    // Log section viewed and track visit
    logSectionViewed(
      sectionName: "continue_learning",
      itemCount: continueLessons.length,
      isEmpty: false,
      scrollPosition: 0, // We don't have scroll tracking implemented
    );
    _sectionsVisited.add("continue_learning");

    return [
      SectionHeader(
        icon: Icons.school,
        title: "Continue learning",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("continue_learning");
          logViewAllOverlayOpened(
            sectionType: "continue",
            totalItems: continueLearningLessons.length,
          );
          setState(() {
            _viewAll = "continue";
            _viewAllOpenTime = DateTime.now();
          });
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterContinue,
        onChanged: (value) {
          final previousFilter = _filterContinue;
          final filteredItemCount = value == "all"
              ? continueLearningLessons.length
              : continueLearningLessons
                  .where((l) => l.subjectId == value)
                  .length;

          if (value == "all" && previousFilter != "all") {
            logFilterCleared(
              sectionType: "continue",
              previousFilter: previousFilter,
              totalItemCount: continueLearningLessons.length,
            );
          } else if (value != "all") {
            logSubjectFilterApplied(
              sectionType: "continue",
              selectedSubject: value,
              previousFilter: previousFilter,
              filteredItemCount: filteredItemCount,
            );
          }

          setState(() => _filterContinue = value);
        },
        allowedSubjectIds:
            continueLessons.map((l) => l.subjectId).toSet().toList(),
        subjects: subjects,
        onFilterClicked: logSubjectFilterClicked,
      ),
      const SizedBox(height: 12),
      LessonList(
        lessons: continueLessons
            .where((l) =>
                _filterContinue == "all" || l.subjectId == _filterContinue)
            .take(2)
            .toList(),
        showProgress: true,
        onLessonTap: _onTapLesson,
      ),
      const SizedBox(height: 32),
    ];
  }

  Widget _buildRecommendedSection() {
    // Log section viewed and track visit
    logSectionViewed(
      sectionName: "recommended",
      itemCount: recommendedLessons.length,
      isEmpty: recommendedLessons.isEmpty,
      scrollPosition: 0, // We don't have scroll tracking implemented
    );
    _sectionsVisited.add("recommended");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.play_arrow,
          title: "Recommended for you",
          actionLabel: "View all",
          onAction: () {
            logViewAllClicked("recommended_for_you");
            logViewAllOverlayOpened(
              sectionType: "recommended",
              totalItems: recommendedLessons.length,
            );
            setState(() {
              _viewAll = "recommended";
              _viewAllOpenTime = DateTime.now();
            });
          },
        ),
        const SizedBox(height: 12),
        SubjectFilterBar(
          value: _filterRecommended,
          onChanged: (value) {
            final previousFilter = _filterRecommended;
            final filteredItemCount = value == "all"
                ? recommendedLessons.length
                : recommendedLessons.where((l) => l.subjectId == value).length;

            if (value == "all" && previousFilter != "all") {
              logFilterCleared(
                sectionType: "recommended",
                previousFilter: previousFilter,
                totalItemCount: recommendedLessons.length,
              );
            } else if (value != "all") {
              logSubjectFilterApplied(
                sectionType: "recommended",
                selectedSubject: value,
                previousFilter: previousFilter,
                filteredItemCount: filteredItemCount,
              );
            }

            setState(() => _filterRecommended = value);
          },
          allowedSubjectIds:
              recommendedLessons.map((l) => l.subjectId).toSet().toList(),
          subjects: subjects,
          onFilterClicked: logSubjectFilterClicked,
        ),
        const SizedBox(height: 12),
        LessonList(
          lessons: recommendedLessons
              .where((l) =>
                  _filterRecommended == "all" ||
                  l.subjectId == _filterRecommended)
              .take(2)
              .toList(),
          showProgress: true,
          onLessonTap: _onTapLesson,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  List<Widget> _buildFromParentsSection() {
    if (parentLessons.isEmpty) {
      logEmptySectionShown(
        sectionName: "from_parents",
        emptyReason: "no_data",
      );
      return [];
    }

    // Log section viewed and track visit
    logSectionViewed(
      sectionName: "from_parents",
      itemCount: parentLessons.length,
      isEmpty: false,
      scrollPosition: 0, // We don't have scroll tracking implemented
    );
    _sectionsVisited.add("from_parents");

    return [
      SectionHeader(
        icon: Icons.book_outlined,
        title: "From parents",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("from_parents");
          logViewAllOverlayOpened(
            sectionType: "parents",
            totalItems: parentLessons.length,
          );
          setState(() {
            _viewAll = "parents";
            _viewAllOpenTime = DateTime.now();
          });
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterParents,
        onChanged: (value) {
          final previousFilter = _filterParents;
          final filteredItemCount = value == "all"
              ? parentLessons.length
              : parentLessons.where((l) => l.subjectId == value).length;

          if (value == "all" && previousFilter != "all") {
            logFilterCleared(
              sectionType: "parents",
              previousFilter: previousFilter,
              totalItemCount: parentLessons.length,
            );
          } else if (value != "all") {
            logSubjectFilterApplied(
              sectionType: "parents",
              selectedSubject: value,
              previousFilter: previousFilter,
              filteredItemCount: filteredItemCount,
            );
          }

          setState(() => _filterParents = value);
        },
        allowedSubjectIds:
            parentLessons.map((l) => l.subjectId).toSet().toList(),
        subjects: subjects,
        onFilterClicked: logSubjectFilterClicked,
      ),
      const SizedBox(height: 12),
      LessonList(
        lessons: parentLessons
            .where(
                (l) => _filterParents == "all" || l.subjectId == _filterParents)
            .toList(),
        showProgress: false,
        onLessonTap: _onTapLesson,
      ),
    ];
  }

  // App update methods (keeping the original functionality)
  Future<String> getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool isVersionLower(String current, String latest) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> l = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < c.length; i++) {
      if (c[i] < l[i]) return true;
      if (c[i] > l[i]) return false;
    }
    return false;
  }

  void launchAppStore() async {
    final url = Platform.isAndroid
        ? Uri.parse(
            'https://play.google.com/store/apps/details?id=com.gluta.glutafam')
        : Uri.parse(
            'https://apps.apple.com/us/app/tuto-ai-tutor-for-class-6-12/id6736943726');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch app store URL");
    }
  }

  void checkForAppUpdate(BuildContext context) async {
    try {
      final currentVersion = await getCurrentAppVersion();
      final versionInfo = await getLatestAppVersinDetails();

      // Platform detection
      final bool isAndroid = Platform.isAndroid;

      final String latestVersion = isAndroid
          ? versionInfo['latestVersionAndroid']
          : versionInfo['latestVersionIOS'];
      final String minimumVersion = versionInfo['minimumVersion'];
      final bool forceUpdate = versionInfo['forceUpdate'];
      final String message = versionInfo['message'];
      final List<String> notes =
          List<String>.from(versionInfo['updateNotes'] ?? []);

      if (isVersionLower(currentVersion, minimumVersion)) {
        // Force update
        logUpdatePromptShown(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          isForced: true,
          platform: isAndroid ? 'android' : 'ios',
          updateNotes: notes,
        );

        showUpdateSheet(
          context,
          message: message,
          updateNotes: notes,
          forceUpdate: true,
          onUpdate: () {
            logUpdateAccepted(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              wasForced: true,
            );
            launchAppStore();
          },
        );
      } else if (isVersionLower(currentVersion, latestVersion)) {
        logUpdatePromptShown(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          isForced: forceUpdate,
          platform: isAndroid ? 'android' : 'ios',
          updateNotes: notes,
        );

        showUpdateSheet(
          context,
          message: message,
          updateNotes: notes,
          forceUpdate: forceUpdate,
          onUpdate: () {
            logUpdateAccepted(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              wasForced: forceUpdate,
            );
            launchAppStore();
          },
        );
      }
    } catch (e) {
      final currentVersion = await getCurrentAppVersion();
      logUpdateCheckFailed(
        error: e.toString(),
        currentVersion: currentVersion,
      );
      // Handle error or skip update check
    }
  }

  void showUpdateSheet(
    BuildContext context, {
    required String message,
    required List<String> updateNotes,
    required bool forceUpdate,
    required VoidCallback onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: !forceUpdate,
      enableDrag: !forceUpdate,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      barrierColor: forceUpdate ? Colors.black.withOpacity(0.7) : null,
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update, size: 40, color: Colors.blueAccent),
              SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),
              ...updateNotes.map(
                (note) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          size: 12, color: Color.fromRGBO(255, 217, 0, 1)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              ChicletAnimatedButton(
                onPressed: onUpdate,
                buttonType: ChicletButtonTypes.roundedRectangle,
                width: double.infinity,
                height: 50,
                buttonColor: Color.fromRGBO(187, 160, 2, 1),
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                child: Text(
                  "UPDATE NOW",
                  style: GoogleFonts.raleway(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!forceUpdate)
                ChicletOutlinedAnimatedButton(
                  onPressed: () {
                    // We need to get version info here - this is a limitation of the current structure
                    // In a real implementation, we'd pass this data or access it differently
                    logUpdateDismissed(
                      currentVersion: 'unknown', // Would need to be passed in
                      latestVersion: 'unknown', // Would need to be passed in
                      wasForced: forceUpdate,
                    );
                    Navigator.of(context).pop();
                  },
                  buttonType: ChicletButtonTypes.roundedRectangle,
                  width: double.infinity,
                  height: 50,
                  borderColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    "MAYBE LATER",
                    style: GoogleFonts.raleway(
                      color: Color.fromRGBO(255, 217, 0, 1),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveCurrentAppVersion() async {
    final currentAppVersion = await getCurrentAppVersion();
    saveAppVersion(appVersion: currentAppVersion);
  }
}
