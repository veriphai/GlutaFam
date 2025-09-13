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
                onConceptTap: _onTapSearchConcept,
                onTopicTap: (topic) {
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
                onChapterTap: (chapter) {
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
                onClose: () => setState(() => _viewAll = null),
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
    if (continueChapters.isEmpty) return [];

    return [
      SectionHeader(
        icon: Icons.list_alt,
        title: "Continue chapters",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("continue_chapters");
          setState(() => _viewAll = "continue_chapters");
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterContinueChapters,
        onChanged: (value) => setState(() => _filterContinueChapters = value),
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
    if (continueLessons.isEmpty) return [];

    return [
      SectionHeader(
        icon: Icons.school,
        title: "Continue learning",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("continue_learning");
          setState(() => _viewAll = "continue");
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterContinue,
        onChanged: (value) => setState(() => _filterContinue = value),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.play_arrow,
          title: "Recommended for you",
          actionLabel: "View all",
          onAction: () {
            logViewAllClicked("recommended_for_you");
            setState(() => _viewAll = "recommended");
          },
        ),
        const SizedBox(height: 12),
        SubjectFilterBar(
          value: _filterRecommended,
          onChanged: (value) => setState(() => _filterRecommended = value),
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
    if (parentsLessons.isEmpty) return [];

    return [
      SectionHeader(
        icon: Icons.book_outlined,
        title: "From parents",
        actionLabel: "View all",
        onAction: () {
          logViewAllClicked("from_parents");
          setState(() => _viewAll = "parents");
        },
      ),
      const SizedBox(height: 12),
      SubjectFilterBar(
        value: _filterParents,
        onChanged: (value) => setState(() => _filterParents = value),
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
