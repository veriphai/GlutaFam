import 'package:eureka_app/apis/fetchCompletedConcepts.dart';
import 'package:eureka_app/apis/fetchLessonHistoryList.dart';
import 'package:eureka_app/apis/fetchRecommendedLessons.dart';
import 'package:eureka_app/apis/fetchChaptersToResume.dart';
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

  // UI state
  bool _isSearchOpen = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _filterContinue = "all";
  String _filterRecommended = "all";
  String _filterParents = "all";
  String _filterContinueChapters = "all";

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
  List<ChapterData> chapterStats = [];
  List<dynamic> allChapters = [];

  // Analytics tracking variables
  late DateTime _screenStartTime;
  DateTime? _searchStartTime;
  Map<String, DateTime> _overlayStartTimes = {};
  Map<String, int> _sessionMetrics = {
    'lessonsViewed': 0,
    'chaptersViewed': 0,
    'searchesPerformed': 0,
  };
  Set<String> _sectionsVisited = {};

  @override
  void initState() {
    super.initState();
    _screenStartTime = DateTime.now();
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
    final sessionDuration = DateTime.now().difference(_screenStartTime).inMilliseconds;
    logSessionDuration(
      timeSpentMs: sessionDuration,
      lessonsViewed: _sessionMetrics['lessonsViewed'] ?? 0,
      chaptersViewed: _sessionMetrics['chaptersViewed'] ?? 0,
      searchesPerformed: _sessionMetrics['searchesPerformed'] ?? 0,
      sectionsVisited: _sectionsVisited.toList(),
    );
    
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
      ]);
      _buildUIData();
      
      // Log successful screen load
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      logHomeScreenLoaded(
        totalLessons: recommendedLessons.length + continueLearningLessons.length,
        totalChapters: chapterStats.length,
        availableSubjects: subjects.map((s) => s.name).toList(),
        loadTimeMs: loadTime,
      );
      
    } catch (error) {
      print("Error initializing data: $error");
      logHomeScreenError(
        errorType: "initialization_error",
        errorMessage: error.toString(),
        failedOperation: "initialize_data",
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProfile() async {
    final startTime = DateTime.now();
    logAPICallStarted(apiName: "fetchProfile", parameters: {});
    
    try {
      final profileData = await refreshProfile();
      prefs = await SharedPreferences.getInstance();

      setState(() {
        userProfile = profileData;
      });
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      logAPICallCompleted(
        apiName: "fetchProfile",
        durationMs: duration,
        success: true,
      );
      
    } catch (error) {
      print("Error fetching userProfile: $error");
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      logAPICallCompleted(
        apiName: "fetchProfile",
        durationMs: duration,
        success: false,
        errorMessage: error.toString(),
      );
      
      logHomeScreenError(
        errorType: "api_failure",
        errorMessage: error.toString(),
        failedOperation: "fetch_profile",
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

    try {
      final booksData = await getBooksWithCache(
          standard: userProfile!["standard"], stream: userProfile!["stream"]);

      selectedBookId = prefs.getString("bookId") ?? "";
      _selectedSubject = prefs.getString("subject") ?? "";

      final scienceBook = booksData.firstWhere(
        (book) => book["subject"]?.toLowerCase() == "science",
        orElse: () => <String, dynamic>{},
      );

      if (selectedBookId.isEmpty) {
        String reason;
        if (scienceBook.isNotEmpty) {
          selectedBookId = scienceBook["id"];
          _selectedSubject = scienceBook["subject"];
          reason = "science_preferred";
        } else {
          selectedBookId = booksData[0]["id"];
          _selectedSubject = booksData[0]["subject"];
          reason = "fallback_first";
        }
        await prefs.setString("bookId", selectedBookId);
        await prefs.setString("subject", _selectedSubject);
        
        // Log default subject setting
        logDefaultSubjectSet(
          subjectName: _selectedSubject,
          subjectId: selectedBookId,
          reason: reason,
          availableSubjects: booksData.map<String>((book) => book["subject"].toString()).toList(),
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
    } catch (error) {
      print("Error fetching subjects and chapters: $error");
      logHomeScreenError(
        errorType: "api_failure",
        errorMessage: error.toString(),
        failedOperation: "fetch_subjects_and_chapters",
      );
      rethrow;
    }
  }

  Future<void> _fetchRecommendedLessons() async {
    try {
      final data = await fetchRecommendedLessons();
      setState(() {
        recommendedLessonsData = data;
      });
    } catch (error) {
      print("Error fetching recommended lessons: $error");
      logHomeScreenError(
        errorType: "api_failure",
        errorMessage: error.toString(),
        failedOperation: "fetch_recommended_lessons",
      );
    }
  }

  Future<void> _fetchChaptersToResume() async {
    try {
      final data = await fetchChaptersToResume();
      setState(() {
        chaptersToResumeData = data;
      });
    } catch (error) {
      print("Error fetching chapters to resume: $error");
      logHomeScreenError(
        errorType: "api_failure",
        errorMessage: error.toString(),
        failedOperation: "fetch_chapters_to_resume",
      );
    }
  }

  Future<void> _fetchAllChapters() async {
    try {
      final data =
          await fetchAllChaptersPerStandard(standard: userProfile!["standard"]);
      setState(() {
        allChapters = data;
        _initializeSearchData();
      });
    } catch (error) {
      print("Error fetching all chapters: $error");
      logHomeScreenError(
        errorType: "api_failure",
        errorMessage: error.toString(),
        failedOperation: "fetch_all_chapters",
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
    try {
      final data =
          await fetchLessonHistoryList(onlyIncompleteLessons: true.toString());
      setState(() {
        lessonHistoryData = data;
      });
    } catch (error) {
      print("Error fetching lesson history: $error");
      logHomeScreenError(
        errorType: "api_failure",
        errorMessage: error.toString(),
        failedOperation: "fetch_lesson_history",
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
      ));
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
    _searchStartTime = DateTime.now();
    setState(() {
      _isSearchOpen = true;
    });

    // Start animation and request focus when animation completes
    _searchAnimationController.forward().then((_) {
      _showKeyboardForSearch();
    });

    logSearchOpened();
    _sessionMetrics['searchesPerformed'] = (_sessionMetrics['searchesPerformed'] ?? 0) + 1;
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
    // Log search cancellation
    if (_searchStartTime != null) {
      final timeSpent = DateTime.now().difference(_searchStartTime!).inMilliseconds;
      final hadResults = _matchedChapters.isNotEmpty || _matchedTopics.isNotEmpty || _matchedConcepts.isNotEmpty;
      
      logSearchCancelled(
        searchQuery: _searchQuery,
        timeSpentMs: timeSpent,
        hadResults: hadResults,
      );
    }
    
    _searchFocusNode.unfocus();
    _searchAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isSearchOpen = false;
          _searchQuery = "";
          _matchedChapters = [];
          _matchedTopics = [];
          _matchedConcepts = [];
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

    final searchDuration = DateTime.now().difference(searchStartTime).inMilliseconds;
    
    // Log search query performance
    logSearchQueryEntered(
      query: query,
      chaptersFound: allChapters.length,
      topicsFound: allTopics.length,
      conceptsFound: allConcepts.length,
      queryLength: query.length,
      searchTimeMs: searchDuration,
    );
    
    // Log no results if nothing found
    if (allChapters.isEmpty && allTopics.isEmpty && allConcepts.isEmpty) {
      logSearchNoResults(
        query: query,
        queryLength: query.length,
      );
    }

    setState(() {
      _searchQuery = query;
      _matchedChapters = allChapters;
      _matchedTopics = allTopics;
      _matchedConcepts = allConcepts;
    });
  }

  Future<void> _onTapLesson(LessonData lesson) async {
    // Navigate to concept learning screen
    if (mounted) {
      // Track lesson viewed
      _sessionMetrics['lessonsViewed'] = (_sessionMetrics['lessonsViewed'] ?? 0) + 1;
      
      logLessonViewed(
        lessonId: lesson.id,
        lessonName: lesson.name,
        sectionType: lesson.recommended ? 'recommended' : (lesson.resumeLesson == true ? 'continue' : 'other'),
        subject: lesson.subject,
        chapter: lesson.chapter,
        currentProgress: lesson.progress,
        estimatedMinutes: lesson.minutes,
      );
      
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

    // Determine if lesson is completed (assuming 3 checkpoints total based on user's requirement)
    const totalCheckpoints = 3;
    final isCompleted = checkpointsCompleted >= totalCheckpoints;
    final progress = checkpointsCompleted / totalCheckpoints;
    
    // Log lesson progress update
    logLessonProgressUpdated(
      lessonId: conceptId,
      oldProgress: originalLesson.progress,
      newProgress: progress.clamp(0.0, 1.0),
      checkpointsCompleted: checkpointsCompleted,
      totalCheckpoints: totalCheckpoints,
      isCompleted: isCompleted,
    );
    
    // Log lesson completion if applicable
    if (isCompleted) {
      logLessonCompleted(
        lessonId: conceptId,
        timeSpentMs: completionData['timeSpentMs'] ?? 0,
        checkpointsCompleted: checkpointsCompleted,
        subject: originalLesson.subject,
        chapter: originalLesson.chapter,
        completionSource: 'home_screen',
      );
    }

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
          );
          break;
        }
      }

      // If lesson is completed, remove it from continue learning (it should not be resumable anymore)
      if (isCompleted) {
        continueLearningLessons.removeWhere((lesson) => lesson.id == conceptId);
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
                    resultType: "concept",
                    itemName: concept.conceptName,
                    itemId: concept.conceptName, // Using name as ID since we may not have the actual ID
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
                    resultType: "topic",
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
                    resultType: "chapter",
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
                            ? recommendedLessons
                                .where((l) => l.fromParent)
                                .toList()
                            : recommendedLessons,
                chapters: chapterStats,
                subjects: subjects,
                onLessonTap: _onTapLesson,
                onChapterTap: (chapter) {
                  logChapterSelected(chapter.key);
                  setState(() {
                    _chapterView = {
                      'subjectId': chapter.subjectId,
                      'subject': chapter.subject,
                      'chapter': chapter.chapter,
                    };
                  });
                },
                onClose: () {
                  // Log overlay closed with timing
                  final sectionKey = _viewAll ?? 'unknown';
                  if (_overlayStartTimes.containsKey(sectionKey)) {
                    final timeSpent = DateTime.now().difference(_overlayStartTimes[sectionKey]!).inMilliseconds;
                    logViewAllOverlayClosed(
                      sectionType: sectionKey,
                      timeSpentMs: timeSpent,
                      itemSelected: false,
                    );
                    _overlayStartTimes.remove(sectionKey);
                  }
                  setState(() => _viewAll = null);
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
                  setState(() {
                    _chapterView = {
                      'subjectId': chapter.subjectId,
                      'subject': chapter.subject,
                      'chapter': chapter.chapter,
                    };
                  });
                },
                onClose: () => setState(() => _subjectView = null),
              ),

            // Chapter overlay
            if (_chapterView != null)
              ChapterOverlay(
                chapterView: _chapterView!,
                subjects: subjects,
                allChapters: allChapters,
                onLessonTap: _onTapLesson,
                onClose: () => setState(() => _chapterView = null),
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
      setState(() {
        _viewAll = null;
      });
      return Future.value(false);
    }
    if (_subjectView != null) {
      setState(() {
        _subjectView = null;
      });
      return Future.value(false);
    }
    if (_chapterView != null) {
      setState(() {
        _chapterView = null;
      });
      return Future.value(false);
    }
    return Future.value(true);
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
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
              
              // Track section visited
              _sectionsVisited.add('subjects');
              
              // Log subject chapters opened
              final subjectChapters = allChapters.where((ch) => 
                ch['subject']?.toLowerCase() == subject.name.toLowerCase()).length;
              logSubjectChaptersOpened(
                subjectName: subject.name,
                subjectId: subjectId,
                totalChapters: subjectChapters,
              );
              
              setState(() {
                _subjectView = subjectId;
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
    );
  }

  List<Widget> _buildContinueChapters() {
    final continueChapters = chapterStats;
    if (continueChapters.isEmpty) {
      // Log empty section
      logEmptySectionShown(
        sectionName: "continue_chapters",
        emptyReason: "no_data",
      );
      return [];
    }

    // Track section visited
    _sectionsVisited.add('continue_chapters');
    
    // Log section viewed
    logSectionViewed(
      sectionName: "continue_chapters",
      itemCount: continueChapters.length,
      isEmpty: false,
      scrollPosition: 0,
    );

    return [
      SectionHeader(
        icon: Icons.list_alt,
        title: "Continue chapters",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("continue_chapters");
          
          // Log view all overlay opened
          logViewAllOverlayOpened(
            sectionType: "continue_chapters",
            totalItems: continueChapters.length,
          );
          
          _overlayStartTimes["continue_chapters"] = DateTime.now();
          setState(() => _viewAll = "continue_chapters");
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterContinueChapters,
        onChanged: (value) {
          final previousFilter = _filterContinueChapters;
          setState(() => _filterContinueChapters = value);
          
          // Log filter application
          final filteredCount = continueChapters.where((c) => 
            value == "all" || c.subjectId == value).length;
          
          if (value == "all" && previousFilter != "all") {
            logFilterCleared(
              sectionType: "continue_chapters",
              previousFilter: previousFilter,
              totalItemCount: continueChapters.length,
            );
          } else if (value != "all") {
            logSubjectFilterApplied(
              sectionType: "continue_chapters",
              selectedSubject: value,
              previousFilter: previousFilter,
              filteredItemCount: filteredCount,
            );
          }
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
          
          // Track chapter viewed
          _sessionMetrics['chaptersViewed'] = (_sessionMetrics['chaptersViewed'] ?? 0) + 1;
          
          // Log chapter interactions
          final completionPercentage = chapter.total > 0 
              ? (chapter.completed / chapter.total) * 100 
              : 0.0;
          
          logChapterViewed(
            chapterId: chapter.key,
            chapterName: chapter.chapter,
            subject: chapter.subject,
            totalLessons: chapter.total,
            completedLessons: chapter.completed,
            inProgressLessons: chapter.inProgress,
            completionPercentage: completionPercentage,
          );
          
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

    // Track section visited
    _sectionsVisited.add('continue_learning');
    
    // Log section viewed
    logSectionViewed(
      sectionName: "continue_learning",
      itemCount: continueLessons.length,
      isEmpty: false,
      scrollPosition: 0,
    );

    return [
      SectionHeader(
        icon: Icons.school,
        title: "Continue learning",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("continue_learning");
          
          logViewAllOverlayOpened(
            sectionType: "continue",
            totalItems: continueLessons.length,
          );
          
          _overlayStartTimes["continue"] = DateTime.now();
          setState(() => _viewAll = "continue");
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterContinue,
        onChanged: (value) {
          final previousFilter = _filterContinue;
          setState(() => _filterContinue = value);
          
          // Log filter application
          final filteredCount = continueLessons.where((l) => 
            value == "all" || l.subjectId == value).length;
          
          if (value == "all" && previousFilter != "all") {
            logFilterCleared(
              sectionType: "continue_learning",
              previousFilter: previousFilter,
              totalItemCount: continueLessons.length,
            );
          } else if (value != "all") {
            logSubjectFilterApplied(
              sectionType: "continue_learning",
              selectedSubject: value,
              previousFilter: previousFilter,
              filteredItemCount: filteredCount,
            );
          }
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
    // Track section visited
    _sectionsVisited.add('recommended');
    
    // Log section viewed
    logSectionViewed(
      sectionName: "recommended",
      itemCount: recommendedLessons.length,
      isEmpty: recommendedLessons.isEmpty,
      scrollPosition: 0,
    );
    
    // Log recommendations shown
    for (int i = 0; i < recommendedLessons.take(2).length; i++) {
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
            
            _overlayStartTimes["recommended"] = DateTime.now();
            setState(() => _viewAll = "recommended");
          },
        ),
        const SizedBox(height: 12),
        SubjectFilterBar(
          value: _filterRecommended,
          onChanged: (value) {
            final previousFilter = _filterRecommended;
            setState(() => _filterRecommended = value);
            
            // Log filter application
            final filteredCount = recommendedLessons.where((l) => 
              value == "all" || l.subjectId == value).length;
            
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
                filteredItemCount: filteredCount,
              );
            }
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
    final parentsLessons =
        recommendedLessons.where((l) => l.fromParent).toList();
    if (parentsLessons.isEmpty) {
      logEmptySectionShown(
        sectionName: "from_parents",
        emptyReason: "no_data",
      );
      return [];
    }

    // Track section visited
    _sectionsVisited.add('from_parents');
    
    // Log section viewed
    logSectionViewed(
      sectionName: "from_parents",
      itemCount: parentsLessons.length,
      isEmpty: false,
      scrollPosition: 0,
    );
    
    // Log parent recommendations viewed
    for (int i = 0; i < parentsLessons.length; i++) {
      final lesson = parentsLessons[i];
      logParentRecommendationViewed(
        lessonId: lesson.id,
        lessonName: lesson.name,
        subject: lesson.subject,
        positionInList: i + 1,
      );
    }

    return [
      SectionHeader(
        icon: Icons.book_outlined,
        title: "From parents",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("from_parents");
          
          logViewAllOverlayOpened(
            sectionType: "parents",
            totalItems: parentsLessons.length,
          );
          
          _overlayStartTimes["parents"] = DateTime.now();
          setState(() => _viewAll = "parents");
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterParents,
        onChanged: (value) {
          final previousFilter = _filterParents;
          setState(() => _filterParents = value);
          
          // Log filter application
          final filteredCount = parentsLessons.where((l) => 
            value == "all" || l.subjectId == value).length;
          
          if (value == "all" && previousFilter != "all") {
            logFilterCleared(
              sectionType: "parents",
              previousFilter: previousFilter,
              totalItemCount: parentsLessons.length,
            );
          } else if (value != "all") {
            logSubjectFilterApplied(
              sectionType: "parents",
              selectedSubject: value,
              previousFilter: previousFilter,
              filteredItemCount: filteredCount,
            );
          }
        },
        allowedSubjectIds:
            parentsLessons.map((l) => l.subjectId).toSet().toList(),
        subjects: subjects,
        onFilterClicked: logSubjectFilterClicked,
      ),
      const SizedBox(height: 12),
      LessonList(
        lessons: parentsLessons
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
        // Log and show force update
        logUpdatePromptShown(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          isForced: true,
          platform: Platform.isAndroid ? 'android' : 'ios',
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
        // Log and show optional update
        logUpdatePromptShown(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          isForced: forceUpdate,
          platform: Platform.isAndroid ? 'android' : 'ios',
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
          onDismiss: () {
            logUpdateDismissed(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              wasForced: forceUpdate,
            );
          },
        );
      }
    } catch (e) {
      // Log update check failure
      final currentVersion = await getCurrentAppVersion();
      logUpdateCheckFailed(
        error: e.toString(),
        currentVersion: currentVersion,
      );
    }
  }

  void showUpdateSheet(
    BuildContext context, {
    required String message,
    required List<String> updateNotes,
    required bool forceUpdate,
    required VoidCallback onUpdate,
    VoidCallback? onDismiss,
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
                    Navigator.of(context).pop();
                    if (onDismiss != null) onDismiss();
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
