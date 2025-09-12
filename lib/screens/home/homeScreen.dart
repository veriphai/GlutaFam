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
// import 'package:eureka_app/screens/aiTutor/ai_tutor_screen.dart';

// Color scheme constants matching the React design
class AppColors {
  static const Color bg = Color(0xFFF6EDDA);
  static const Color card = Color(0xFFFFFBF2);
  static const Color ink = Color(0xFF0B1220);
  static const Color sub = Color(0xFF70695B);
  static const Color border = Color(0xFFE7DEC9);
  static const Color accent = Color(0xFF1D4ED8);
  static const Color searchBg = Color(0xFFEAF6EE);
  static const Color searchBorder = Color(0xFFCFE9DE);
}

// Subject colors mapping
class SubjectColors {
  static const Map<String, Color> colors = {
    'mathematics': Color(0xFF1D4ED8),
    'physics': Color(0xFF0EA5E9),
    'chemistry': Color(0xFF10B981),
    'biology': Color(0xFF84CC16),
    'history': Color(0xFFF59E0B),
    'geography': Color(0xFF8B5CF6),
    'english': Color(0xFFEC4899),
    'science': Color(0xFF10B981),
    'maths': Color(0xFF1D4ED8),
  };

  static Color getColor(String subject) {
    return colors[subject.toLowerCase()] ?? AppColors.accent;
  }
}

// Subject data model
class Subject {
  final String id;
  final String name;
  final String emoji;

  const Subject({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

// Lesson data model
class LessonData {
  final String id;
  final String name;
  final String subjectId;
  final String subject;
  final String chapter;
  final String topic;
  final int minutes;
  final bool recommended;
  final bool fromParent;
  final double progress;
  final String? recommendationReason;
  final double? priorityScore;
  final int? checkpointsCompleted;
  final String? conceptConversationKey;
  final int? checkpointNo;
  final Map<String, dynamic>? learningObjectivesStatus;
  final bool? newCheckpointStarted;
  final int? timeRemaining;
  final bool? resumeLesson;
  final bool? completed;

  const LessonData({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.minutes,
    this.recommended = false,
    this.fromParent = false,
    this.progress = 0.0,
    this.recommendationReason,
    this.priorityScore,
    this.checkpointsCompleted,
    this.conceptConversationKey,
    this.checkpointNo,
    this.learningObjectivesStatus,
    this.newCheckpointStarted,
    this.timeRemaining,
    this.resumeLesson,
    this.completed,
  });
}

// Chapter data model
class ChapterData {
  final String key;
  final String subjectId;
  final String subject;
  final String chapter;
  final int total;
  final int completed;
  final int inProgress;

  const ChapterData({
    required this.key,
    required this.subjectId,
    required this.subject,
    required this.chapter,
    required this.total,
    required this.completed,
    required this.inProgress,
  });
}

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

  @override
  void initState() {
    super.initState();
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
    _searchAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
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
    } catch (error) {
      print("Error initializing data: $error");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final profileData = await refreshProfile();
      prefs = await SharedPreferences.getInstance();

      setState(() {
        userProfile = profileData;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
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
        if (scienceBook.isNotEmpty) {
          selectedBookId = scienceBook["id"];
          _selectedSubject = scienceBook["subject"];
        } else {
          selectedBookId = booksData[0]["id"];
          _selectedSubject = booksData[0]["subject"];
        }
        await prefs.setString("bookId", selectedBookId);
        await prefs.setString("subject", _selectedSubject);
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
      print("Error fetching chapters to resume: $error");
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

    // Replace recommended lessons with sorted ones
    // recommendedLessons =
    //     recommendedLessons.where((l) => !l.recommended).toList();
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

  int _countTotalLessonsInChapter(Map<String, dynamic> chapterData) {
    int totalLessons = 0;
    if (chapterData['topics'] != null) {
      for (final topic in chapterData['topics']) {
        if (topic['lessons'] != null) {
          totalLessons += (topic['lessons'] as List).length;
        }
      }
    }
    return totalLessons;
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = userProfile?['firstName'] ?? 'Student';
    if (hour < 12) return "Good morning, $name";
    if (hour < 17) return "Good afternoon, $name";
    return "Good evening, $name";
  }

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
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
  }

  Future<void> _onTapLesson(LessonData lesson) async {
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
      // _closeSearch(); // Close the search overlay first
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
            if (_isSearchOpen) _buildSearchOverlay(),
            // View-all overlay
            if (_viewAll != null) _buildViewAllOverlay(),
            // Subject chapters overlay
            if (_subjectView != null) _buildSubjectChaptersOverlay(),
            // Chapter overlay
            if (_chapterView != null) _buildChapterOverlay(),

            // Bottom navigation
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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearchButton(),
          const SizedBox(height: 28),
          _buildSubjectsSection(),
          const SizedBox(height: 32),
          ..._buildContinueChapters(),
          ..._buildContinueLearning(),
          _buildRecommendedSection(),
          ..._buildFromParentsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateTime.now().toString().split(' ')[0],
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.sub,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getGreeting(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //   decoration: BoxDecoration(
        //     color: AppColors.card,
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: AppColors.border),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Text(
        //         "Streak",
        //         style: GoogleFonts.inter(
        //           fontSize: 12,
        //           color: AppColors.sub,
        //         ),
        //       ),
        //       const SizedBox(width: 4),
        //       Text(
        //         "3🔥",
        //         style: GoogleFonts.inter(
        //           fontSize: 12,
        //           fontWeight: FontWeight.w600,
        //           color: AppColors.ink,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () {
        _openSearch();
        // For iOS, also try to request focus immediately after state change
        if (Platform.isIOS) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && _isSearchOpen) {
                _searchFocusNode.requestFocus();
              }
            });
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.searchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.searchBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 18,
              color: AppColors.sub,
            ),
            const SizedBox(width: 8),
            Text(
              "Search lessons, chapters, topics",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.sub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.book_outlined,
          title: "Subjects",
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              return _buildSubjectPill(subjects[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.sub,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppColors.sub,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectPill(Subject subject) {
    return Container(
      // width: 60,
      // height: 60,
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          logSubjectSelected(subject.name);
          setState(() {
            _subjectView = subject.id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: SubjectColors.getColor(subject.name),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    subject.emoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subject.name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContinueChapters() {
    final continueChapters = chapterStats;
    // final continueChapters =
    //     chapterStats.where((c) => c.inProgress > 0).toList();
    if (continueChapters.isEmpty) return [];

    return [
      _buildSectionHeader(
        icon: Icons.list_alt,
        title: "Continue chapters",
        actionLabel: "View all",
        onAction: () => {
          logViewAllClicked("continue_chapters"),
          setState(() => _viewAll = "continue_chapters")
        },
      ),
      const SizedBox(height: 12),
      _buildSubjectFilterBar(
        value: _filterContinueChapters,
        onChanged: (value) => setState(() => _filterContinueChapters = value),
        allowedSubjectIds:
            continueChapters.map((c) => c.subjectId).toSet().toList(),
      ),
      const SizedBox(height: 12),
      _buildChapterGrid(continueChapters
          .where((c) =>
              _filterContinueChapters == "all" ||
              c.subjectId == _filterContinueChapters)
          .take(2)
          .toList()),
      const SizedBox(height: 32),
    ];
  }

  List<Widget> _buildContinueLearning() {
    final continueLessons = continueLearningLessons.toList();

    // final continueLessons =
    //     lessons.where((l) => l.progress > 0 && l.progress < 1).toList();
    if (continueLessons.isEmpty) return [];

    return [
      _buildSectionHeader(
        icon: Icons.school,
        title: "Continue learning",
        actionLabel: "View all",
        onAction: () => {
          logViewAllClicked("continue_learning"),
          setState(() => _viewAll = "continue")
        },
      ),
      const SizedBox(height: 12),
      _buildSubjectFilterBar(
        value: _filterContinue,
        onChanged: (value) => setState(() => _filterContinue = value),
        allowedSubjectIds:
            continueLessons.map((l) => l.subjectId).toSet().toList(),
      ),
      const SizedBox(height: 12),
      _buildLessonList(
        continueLessons
            .where((l) =>
                _filterContinue == "all" || l.subjectId == _filterContinue)
            .take(2)
            .toList(),
        showProgress: true,
      ),
      const SizedBox(height: 32),
    ];
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.play_arrow,
          title: "Recommended for you",
          actionLabel: "View all",
          onAction: () => {
            logViewAllClicked("recommended_for_you"),
            setState(() => _viewAll = "recommended")
          },
        ),
        const SizedBox(height: 12),
        _buildSubjectFilterBar(
          value: _filterRecommended,
          onChanged: (value) => setState(() => _filterRecommended = value),
          allowedSubjectIds:
              recommendedLessons.map((l) => l.subjectId).toSet().toList(),
        ),
        const SizedBox(height: 12),
        _buildLessonList(
          recommendedLessons
              .where((l) =>
                  _filterRecommended == "all" ||
                  l.subjectId == _filterRecommended)
              .take(2)
              .toList(),
          showProgress: true,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  List<Widget> _buildFromParentsSection() {
    final parentsLessons =
        recommendedLessons.where((l) => l.fromParent).toList();
    if (parentsLessons.isEmpty) return [];

    return [
      _buildSectionHeader(
        icon: Icons.book_outlined,
        title: "From parents",
        actionLabel: "View all",
        onAction: () => {
          logViewAllClicked("from_parents"),
          setState(() => _viewAll = "parents")
        },
      ),
      const SizedBox(height: 12),
      _buildSubjectFilterBar(
        value: _filterParents,
        onChanged: (value) => setState(() => _filterParents = value),
        allowedSubjectIds:
            parentsLessons.map((l) => l.subjectId).toSet().toList(),
      ),
      const SizedBox(height: 12),
      _buildLessonList(
        parentsLessons
            .where(
                (l) => _filterParents == "all" || l.subjectId == _filterParents)
            .toList(),
        showProgress: false,
      ),
    ];
  }

  Widget _buildSubjectFilterBar({
    required String value,
    required ValueChanged<String> onChanged,
    required List<String> allowedSubjectIds,
  }) {
    final allowedSubjects =
        subjects.where((s) => allowedSubjectIds.contains(s.id)).toList();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: "All",
            isSelected: value == "all",
            onTap: () => {onChanged("all"), logSubjectFilterClicked("all")},
          ),
          ...allowedSubjects.map((subject) => _buildFilterChip(
                label: subject.name,
                isSelected: value == subject.id,
                onTap: () => {
                  onChanged(subject.id),
                  logSubjectFilterClicked(subject.name)
                },
                color: SubjectColors.getColor(subject.name),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? (color ?? AppColors.accent) : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonGrid(List<LessonData> lessons) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        return _buildLessonCard(lessons[index]);
      },
    );
  }

  // Mobile-first list layout (single column) matching the screenshots
  Widget _buildLessonList(List<LessonData> items, {bool showProgress = true}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildLessonListItem(items[i], showProgress),
    );
  }

  Widget _buildLessonListItem(LessonData lesson, bool showProgress) {
    final color = SubjectColors.getColor(lesson.subject);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getSubjectEmoji(lesson.subject),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${lesson.subject} • ${lesson.chapter} • ${lesson.topic}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text("${lesson.minutes} mins",
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.ink)),
                        const Spacer(),
                        // Start discussion pill
                        GestureDetector(
                          onTap: () => _onTapLesson(lesson),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                lesson.resumeLesson == true
                                    ? 'Resume discussion'
                                    : lesson.completed == true
                                        ? 'View discussion'
                                        : 'Start discussion',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showProgress) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: lesson.progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (lesson.progress > 0)
                        Text(
                          "${(lesson.progress * 100).round()}% complete",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.sub),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterGrid(List<ChapterData> chapters) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildChapterListItem(chapters[index]);
      },
    );
  }

  Widget _buildChapterListItem(ChapterData chapter) {
    final color = SubjectColors.getColor(chapter.subject);
    final progress =
        chapter.total == 0 ? 0.0 : chapter.completed / chapter.total;

    return GestureDetector(
      onTap: () {
        logChapterSelected(chapter.key);
        setState(() {
          _chapterView = {
            'subjectId': chapter.subjectId,
            'subject': chapter.subject,
            'chapter': chapter.chapter,
          };
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getSubjectEmoji(chapter.subject),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.chapter,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${chapter.subject} • ${chapter.completed}/${chapter.total} lessons completed",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.sub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (progress > 0)
                        Text(
                          "${(progress * 100).round()}% complete",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.sub,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(LessonData lesson) {
    final color = SubjectColors.getColor(lesson.subject);

    return GestureDetector(
      onTap: () => _onTapLesson(lesson),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getSubjectEmoji(lesson.subject),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${lesson.subject} • ${lesson.chapter} • ${lesson.topic}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.sub,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${lesson.minutes} mins",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Start",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (lesson.progress > 0) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: lesson.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${(lesson.progress * 100).round()}% complete",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.sub,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(ChapterData chapter) {
    final color = SubjectColors.getColor(chapter.subject);
    final progress =
        chapter.total == 0 ? 0.0 : chapter.completed / chapter.total;

    return GestureDetector(
      onTap: () {
        setState(() {
          _chapterView = {
            'subjectId': chapter.subjectId,
            'subject': chapter.subject,
            'chapter': chapter.chapter,
          };
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getSubjectEmoji(chapter.subject),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.list_alt,
                  size: 18,
                  color: AppColors.sub.withOpacity(0.6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.chapter,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${chapter.subject} • ${chapter.completed}/${chapter.total} lessons completed",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.sub,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return AnimatedBuilder(
      animation: _searchAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSearch,
                child: Container(
                  color: Colors.black
                      .withOpacity(0.35 * _searchFadeAnimation.value),
                ),
              ),
            ),
            // Search container
            Positioned(
              top: _searchSlideAnimation.value *
                  MediaQuery.of(context).size.height,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.card,
                child: SafeArea(
                  bottom:
                      false, // Don't add bottom padding to avoid keyboard issues
                  child: Column(
                    children: [
                      // Search header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _closeSearch,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Direct tap handling for iOS
                                  _searchFocusNode.requestFocus();
                                  if (Platform.isIOS) {
                                    Future.delayed(
                                        const Duration(milliseconds: 50), () {
                                      SystemChannels.textInput
                                          .invokeMethod('TextInput.show');
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 18,
                                        color: AppColors.sub,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocusNode,
                                          autofocus: false,
                                          enableInteractiveSelection: true,
                                          textInputAction:
                                              TextInputAction.search,
                                          decoration: InputDecoration(
                                            hintText:
                                                "Search chapters, topics, lessons…",
                                            border: InputBorder.none,
                                            hintStyle: GoogleFonts.inter(
                                              fontSize: 15,
                                              color: AppColors.sub,
                                            ),
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            color: AppColors.ink,
                                          ),
                                          onChanged: _performSearch,
                                          onTap: () {
                                            // Ensure focus is requested when tapped on iOS
                                            if (Platform.isIOS) {
                                              _searchFocusNode.requestFocus();
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 50), () {
                                                SystemChannels.textInput
                                                    .invokeMethod(
                                                        'TextInput.show');
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search results
                      Expanded(
                        child: _buildSearchResults(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.trim().length < 2) {
      return Center(
        child: Text(
          "Type at least 2 characters to search",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.sub,
          ),
        ),
      );
    }

    if (_matchedChapters.isEmpty &&
        _matchedTopics.isEmpty &&
        _matchedConcepts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "No matches found. Try a different keyword.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.sub,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_matchedChapters.isNotEmpty) ...[
            Text(
              "CHAPTERS",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sub,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ..._matchedChapters
                .take(5)
                .map((chapter) => _buildSearchChapterItem(chapter)),
            const SizedBox(height: 20),
          ],
          if (_matchedTopics.isNotEmpty) ...[
            Text(
              "TOPICS",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sub,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ..._matchedTopics
                .take(5)
                .map((topic) => _buildSearchTopicItem(topic)),
            const SizedBox(height: 20),
          ],
          if (_matchedConcepts.isNotEmpty) ...[
            Text(
              "CONCEPTS",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sub,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ..._matchedConcepts
                .take(5)
                .map((concept) => _buildSearchConceptItem(concept)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSearchConceptItem(SearchableConcept concept) {
    final color = SubjectColors.getColor(concept.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getSubjectEmoji(concept.subject),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept.conceptName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${concept.subject} • ${concept.chapterName} • ${concept.topicName}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text("15 mins", // Default time for concepts from search
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.ink)),
                        const Spacer(),
                        // Start discussion pill
                        GestureDetector(
                          onTap: () => _onTapSearchConcept(concept),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Start discussion',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Always show progress bar (empty for new concepts)
                    const SizedBox(height: 12),
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            0.0, // Always 0 for search results (new concepts)
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTopicItem(SearchableTopic topic) {
    final color = SubjectColors.getColor(topic.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getSubjectEmoji(topic.subject),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Text(
          topic.topicName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${topic.chapterName} • ${topic.subject}",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.sub,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.sub,
        ),
        onTap: () {
          // Navigate to chapter view and search for this topic
          logTopicButtonClick(topic.topicName);
          setState(() {
            _chapterView = {
              'subjectId': _getSubjectIdByName(topic.subject),
              'subject': topic.subject,
              'chapter': topic.chapterName,
            };
          });
          _closeSearch();
        },
      ),
    );
  }

  Widget _buildSearchChapterItem(SearchableChapter chapter) {
    final color = SubjectColors.getColor(chapter.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getSubjectEmoji(chapter.subject),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Text(
          chapter.chapterName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          chapter.subject,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.sub,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.sub,
        ),
        onTap: () {
          // Navigate to chapter view
          logChapterSelected(chapter.chapterName);
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
    );
  }

  // View All overlay
  Widget _buildViewAllOverlay() {
    final section = _viewAll!;

    // Handle chapters separately
    if (section == 'continue_chapters') {
      return _buildViewAllChaptersOverlay();
    }

    List<LessonData> all;
    if (section == 'continue') {
      all = continueLearningLessons;
    } else if (section == 'recommended') {
      all = recommendedLessons;
    } else if (section == 'parents') {
      all = recommendedLessons;
    } else {
      all = recommendedLessons;
    }
    final allowedIds = all.map((l) => l.subjectId).toSet().toList();
    String filter = 'all';

    final title = section == 'continue'
        ? 'Continue learning'
        : section == 'recommended'
            ? 'Recommended for you'
            : section == 'parents'
                ? 'From parents'
                : 'All lessons';

    return Positioned.fill(
      child: Material(
        color: AppColors.bg,
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setS) {
              final list = filter == 'all'
                  ? all
                  : all.where((l) => l.subjectId == filter).toList();
              final bool showProg = section != 'parents';
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _viewAll = null),
                          icon: const Icon(Icons.arrow_back, size: 20),
                        ),
                        const SizedBox(width: 6),
                        Text(title,
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildSubjectFilterBar(
                      value: filter,
                      onChanged: (v) => setS(() => filter = v),
                      allowedSubjectIds: allowedIds,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: _buildLessonList(list, showProgress: showProg),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // View All Chapters overlay
  Widget _buildViewAllChaptersOverlay() {
    final allChapters = chapterStats;
    final allowedIds = allChapters.map((c) => c.subjectId).toSet().toList();
    String filter = 'all';

    return Positioned.fill(
      child: Material(
        color: AppColors.bg,
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setS) {
              final list = filter == 'all'
                  ? allChapters
                  : allChapters.where((c) => c.subjectId == filter).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _viewAll = null),
                          icon: const Icon(Icons.arrow_back, size: 20),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Continue chapters',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildSubjectFilterBar(
                      value: filter,
                      onChanged: (v) => setS(() => filter = v),
                      allowedSubjectIds: allowedIds,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: _buildChapterGrid(list),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Subject Chapters overlay
  Widget _buildSubjectChaptersOverlay() {
    final subjectId = _subjectView!;
    final subj = subjects.firstWhere((s) => s.id == subjectId,
        orElse: () => subjects.first);

    // Filter chapters from allChapters data by subject
    final subjectChapters = allChapters.where((chapter) {
      final chapterSubject = chapter['subject']?.toString().toLowerCase() ?? '';
      final targetSubject = subj.name.toLowerCase();
      // Handle common subject name variations
      return chapterSubject == targetSubject ||
          (targetSubject == 'maths' && chapterSubject == 'mathematics') ||
          (targetSubject == 'mathematics' && chapterSubject == 'maths');
    }).toList();

    // Convert to ChapterData objects
    final chapterList = subjectChapters.map((chapterData) {
      final totalLessons = _countTotalLessonsInChapter(chapterData);

      return ChapterData(
        key: '${subjectId}::${chapterData['name']}',
        subjectId: subjectId,
        subject: chapterData['subject'] ?? '',
        chapter: chapterData['name'] ?? '',
        total: totalLessons,
        completed: 0, // We don't have completion data from allChapters
        inProgress: 0, // We don't have progress data from allChapters
      );
    }).toList();

    return Positioned.fill(
      child: Material(
        color: AppColors.bg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _subjectView = null),
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text('${subj.emoji} ${subj.name}',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _buildChapterGrid(chapterList),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chapter overlay listing topics with lessons
  Widget _buildChapterOverlay() {
    final info = _chapterView!;
    final subjectId = info['subjectId']!;
    final subjectName = info['subject']!;
    final chapterName = info['chapter']!;
    final subj = subjects.firstWhere((s) => s.id == subjectId,
        orElse: () => subjects.first);

    final Map<String, List<LessonData>> byTopic = {};

    // Find the matching chapter in allChapters
    final matchingChapter = allChapters.firstWhere(
      (chapter) =>
          chapter['name'] == chapterName && chapter['subject'] == subjectName,
      orElse: () => <String, dynamic>{},
    );

    if (matchingChapter.isNotEmpty && matchingChapter['topics'] != null) {
      for (final topic in matchingChapter['topics']) {
        final topicName = topic['name'] ?? '';
        final lessons = topic['lessons'] ?? [];
        if (lessons.isNotEmpty) {
          // Convert raw lesson data to LessonData objects
          final lessonDataList = lessons.map<LessonData>((lessonData) {
            return LessonData(
              id: lessonData['id']?.toString() ?? '',
              name: lessonData['name'] ?? '',
              subjectId: _getSubjectIdByName(subjectName),
              subject: subjectName,
              chapter: chapterName,
              topic: topicName,
              minutes: int.tryParse(
                      lessonData['expectedCompletionTime']?.toString() ??
                          '15') ??
                  15,
              recommended: false,
              fromParent: false,
              progress: _calculateProgress(lessonData['checkpointsCompleted'],
                  lessonData['totalCheckpoints']),
              recommendationReason: null,
              priorityScore: null,
              checkpointsCompleted: lessonData['checkpointsCompleted'] ?? 0,
              conceptConversationKey:
                  lessonData['conceptConversationKey'] ?? '',
              checkpointNo: lessonData['checkpointNo'] ?? 0,
              learningObjectivesStatus:
                  lessonData['learningObjectivesStatus'] ?? {},
              newCheckpointStarted: lessonData['newCheckpointStarted'] ?? false,
              timeRemaining: lessonData['timeRemaining'] ?? 0,
              resumeLesson: lessonData['canResume'] ?? false,
              completed: lessonData['completionStatus'] ?? false,
              // Default since we don't have progress data from allChapters
            );
          }).toList();
          byTopic[topicName] = lessonDataList;
        }
      }
    }

    return Positioned.fill(
      child: Material(
        color: AppColors.bg,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _chapterView = null),
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text('${subj.emoji} $subjectName',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(chapterName,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: AppColors.sub)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in byTopic.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(entry.key,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                        ),
                        _buildLessonList(entry.value, showProgress: true),
                        const SizedBox(height: 12),
                      ],
                      if (byTopic.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                              child: Text('No lessons yet.',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: AppColors.sub))),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.sub,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.sub,
          ),
        ),
      ],
    );
  }

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
        showUpdateSheet(
          context,
          message: message,
          updateNotes: notes,
          forceUpdate: true,
          onUpdate: () {
            launchAppStore();
          },
        );
      } else if (isVersionLower(currentVersion, latestVersion)) {
        showUpdateSheet(
          context,
          message: message,
          updateNotes: notes,
          forceUpdate: forceUpdate,
          onUpdate: () {
            launchAppStore();
          },
        );
      }
    } catch (e) {
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 2), // Adjust for less space
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
                  onPressed: () => Navigator.of(context).pop(),
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
