import 'package:eureka_app/apis/fetchCompletedConcepts.dart';
import 'package:eureka_app/apis/fetchLessonHistoryList.dart';
import 'package:eureka_app/apis/resumeConcept.dart';
import 'package:eureka_app/models/searchableConcept.dart';
import 'package:eureka_app/screens/conceptLearningV4.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:eureka_app/screens/home/models/discussion.dart';
import 'package:eureka_app/screens/home/models/lesson.dart';
import 'package:eureka_app/screens/home/models/period.dart';
import 'package:eureka_app/screens/home/models/recommendedTab.dart';
import 'package:eureka_app/screens/home/models/subjectChipData.dart';
import 'package:eureka_app/screens/home/widgets/common/notebookScaffold.dart';
import 'package:eureka_app/screens/home/widgets/continueLearning/continueLearningCard.dart';
import 'package:eureka_app/screens/home/widgets/continueLearning/rightEdgeSubjectTabs.dart';
import 'package:eureka_app/screens/home/widgets/headerBar.dart';
import 'package:eureka_app/screens/home/widgets/recommended/recommendedSection.dart';
import 'package:eureka_app/screens/home/widgets/searchBar.dart';
import 'package:eureka_app/screens/home/widgets/subjects/subjectChipsRow.dart';
import 'package:eureka_app/screens/home/widgets/timetable/periodList.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableEmptyBody.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableFooter.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableHeader.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableWeekStrip.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/cachingUtils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'widgets/header/header_bar.dart';
// import 'widgets/search/search_bar.dart';
// import 'widgets/subjects/subject_chips_row.dart';
// import 'widgets/continue_learning/section_tab_label.dart';
// import 'widgets/continue_learning/continue_learning_card.dart';
// import 'widgets/discussions/section_header.dart';
// import 'widgets/discussions/featured_discussion_card.dart';
// import 'widgets/discussions/discussion_row.dart';
// import 'widgets/timetable/timetable_card.dart';

const _subjectMocks = [
  SubjectChipData(id: "chem", label: "Chemistry", icon: Icons.science_outlined),
  SubjectChipData(
      id: "phys",
      label: "Physics",
      icon: Icons.auto_awesome_motion), // placeholder
  SubjectChipData(id: "bio", label: "Biology", icon: Icons.biotech_outlined),
  SubjectChipData(
      id: "math", label: "Maths", icon: Icons.change_history), // triangle-ish
];

const _continueLessons = [
  Lesson(
    id: "l1",
    title: "Why does yeast make dough rise?",
    path: "Science → Microorganisms: Friend or Foe?",
    durationMin: 8,
    progress: 0.35,
  ),
  Lesson(
    id: "l2",
    title: "Differentiate speed vs velocity",
    path: "Physics → Motion",
    durationMin: 8,
    progress: 0.15,
  ),
  Lesson(
    id: "l3",
    title: "Name two climate zones of India",
    path: "Geo → Climate",
    durationMin: 6,
    progress: 0.55,
  ),
];

String? _selectedSubjectId = "phys"; // example

const _subjectTabs = [
  SubjectTabSpec(
      id: "chem",
      icon: Icons.science_outlined,
      fill: Color(0xFFF1E2B5),
      border: Color(0xFFB7A987)),
  SubjectTabSpec(
      id: "phys",
      icon: Icons.auto_awesome_motion,
      fill: Color(0xFFD6E6F7),
      border: Color(0xFF7FA8CF)),
  SubjectTabSpec(
      id: "bio",
      icon: Icons.arrow_back,
      fill: Color(0xFFF1E2B5),
      border: Color(0xFFB7A987)),
  SubjectTabSpec(
      id: "math",
      icon: Icons.change_history,
      fill: Color(0xFFF1E2B5),
      border: Color(0xFFB7A987)),
  SubjectTabSpec(
      id: "geo",
      icon: Icons.public_outlined,
      fill: Color(0xFFF1E2B5),
      border: Color(0xFFB7A987)),
];

final tabs = [
  RecommendedTab(
      id: 'chem',
      label: 'Chemistry',
      fill: Color.fromRGBO(223, 228, 200, 1),
      border: Color.fromRGBO(171, 185, 165, 1)),
  RecommendedTab(
      id: 'phys',
      label: 'Physics',
      border: Color.fromRGBO(228, 204, 109, 1),
      fill: Color.fromRGBO(253, 233, 137, 1)), // selected-ish yellow
  RecommendedTab(
      id: 'math',
      label: 'Maths',
      fill: Color.fromRGBO(244, 221, 168, 1),
      border: Color(0xFFBEA177)),
  RecommendedTab(
      id: 'bio',
      label: 'Bio',
      fill: Color.fromRGBO(223, 228, 200, 1),
      border: Color.fromRGBO(171, 185, 165, 1))
];

final recItems = [
  const Discussion(
      id: 'd1',
      title: 'Medicinal use of microorganisms',
      path: 'Chemistry → Microorganisms',
      durationMin: 5,
      badges: ['IN CLASS']),
  const Discussion(
      id: 'd2',
      title: 'Balancing equations',
      path: 'Chemistry → Stoichiometry',
      durationMin: 6,
      badges: ['TEST TUE']),
  const Discussion(
      id: 'd3',
      title: 'Motion: speed vs velocity',
      path: 'Physics → Motion',
      durationMin: 7,
      badges: ['GAP HIGH']),
];

final today = DateTime.now();
final todayIdx = today.weekday; // 1..7

final periods = <Period>[
  Period(
    id: 'p1',
    start: const TimeOfDay(hour: 8, minute: 30),
    end: const TimeOfDay(hour: 9, minute: 15),
    subject: 'Stoichiometry',
    topic: '(Balancing Equations)',
    icon: Icons.science_outlined,
    accent: const Color.fromRGBO(51, 97, 53, 1),
    weekdayIndex: todayIdx,
  ),
  Period(
    id: 'p2',
    start: const TimeOfDay(hour: 9, minute: 20),
    end: const TimeOfDay(hour: 10, minute: 10),
    subject: 'Physics',
    topic: 'Motion (Displacement vs Distance)',
    icon: Icons.access_time_filled, // swap to your glyphs
    accent: const Color.fromRGBO(51, 97, 53, 1),
    weekdayIndex: todayIdx,
  ),
  // ...more rows like in the PNG
];

String? selectedTabId = 'phys';

class HomeScreenV2Bkp extends StatefulWidget {
  const HomeScreenV2Bkp({super.key});

  @override
  State<HomeScreenV2Bkp> createState() => _HomeScreenV2BkpState();
}

class _HomeScreenV2BkpState extends State<HomeScreenV2Bkp> {
  final now = DateTime.now();
  final double kTimeRail = 45;

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

  // UI state
  String? _selectedSubjectId = "phys";
  List<Lesson> _continueLessons = [];
  List<SubjectChipData> _subjectMocks = [];
  List<SubjectTabSpec> _subjectTabs = [];
  List<Discussion> recItems = [];
  List<RecommendedTab> tabs = [];
  List<Period> periods = [];

  // Search functionality
  bool _isSearchActive = false;
  String _searchQuery = "";
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();

  // Search data
  List<SearchableChapter> chapterList = [];
  List<SearchableTopic> topicList = [];
  List<SearchableConcept> conceptList = [];

  // Fuzzy search engines
  late Fuzzy<SearchableChapter> chapterFuse;
  late Fuzzy<SearchableTopic> topicFuse;
  late Fuzzy<SearchableConcept> conceptFuse;

  // Search results
  List<SearchableChapter> matchedChapters = [];
  List<SearchableTopic> matchedTopics = [];
  List<SearchableConcept> matchedConcepts = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchProfile();
      await _fetchSubjectsAndChapters();
      await _fetchResumableLessons();
      _buildUIData();
      _prepareSearchData();
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
      rethrow;
    }
  }

  Future<void> _fetchSubjectsAndChapters() async {
    if (userProfile == null) return;

    try {
      final booksData = await getBooksWithCache(
          standard: userProfile!["standard"], stream: userProfile!["stream"]);

      // Get stored subject preference or default to Science
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

  Future<void> _fetchResumableLessons() async {
    try {
      final lessonHistoryData =
          await fetchLessonHistoryList(onlyIncompleteLessons: true.toString());

      // Convert to lesson format for continue learning
      List<Lesson> resumableLessons = [];
      for (var item in lessonHistoryData) {
        if (item['completionStatus'] == false) {
          final remainingMinutes = (item['remainingTime'] as int? ?? 0) ~/ 60;
          final progress = (item['checkpointsCompleted'] as int? ?? 0) /
              10.0; // Assuming 10 total checkpoints

          resumableLessons.add(Lesson(
            id: item['conceptId'],
            title: item['conceptName'],
            path: "${_selectedSubject} → In Progress",
            durationMin: remainingMinutes,
            progress: progress.clamp(0.0, 1.0),
          ));
        }
      }

      setState(() {
        _continueLessons = resumableLessons;
      });
    } catch (error) {
      print("Error fetching resumable lessons: $error");
      // Don't rethrow - this is optional data
    }
  }

  void _buildUIData() {
    // Build subject chips from books data
    _subjectMocks = books
        .map((book) => SubjectChipData(
              id: book["id"],
              label: book["subject"],
              icon: _getSubjectIcon(book["subject"]),
            ))
        .toList();

    // Build subject tabs for continue learning card
    _subjectTabs = books
        .map((book) => SubjectTabSpec(
              id: book["id"],
              icon: _getSubjectIcon(book["subject"]),
              fill: _getSubjectColor(book["subject"]),
              border: _getSubjectBorderColor(book["subject"]),
            ))
        .toList();

    // Build recommended tabs from subjects
    tabs = books
        .map((book) => RecommendedTab(
              id: book["id"],
              label: book["subject"],
              fill: _getSubjectColor(book["subject"]),
              border: _getSubjectBorderColor(book["subject"]),
            ))
        .toList();

    // Build mock discussions (could be replaced with real API later)
    recItems = [
      Discussion(
        id: 'd1',
        title: 'Recent Topics Discussion',
        path: '$_selectedSubject → Current Chapter',
        durationMin: 5,
        badges: ['IN PROGRESS'],
      ),
      Discussion(
        id: 'd2',
        title: 'Quick Revision',
        path: '$_selectedSubject → Review',
        durationMin: 3,
        badges: ['REVISION'],
      ),
    ];

    // Build periods from today's data (mock for now)
    final today = DateTime.now();
    final todayIdx = today.weekday;

    periods = [
      Period(
        id: 'p1',
        start: const TimeOfDay(hour: 8, minute: 30),
        end: const TimeOfDay(hour: 9, minute: 15),
        subject: _selectedSubject,
        topic: 'Current Chapter',
        icon: _getSubjectIcon(_selectedSubject),
        accent: const Color.fromRGBO(51, 97, 53, 1),
        weekdayIndex: todayIdx,
      ),
    ];
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'science':
      case 'chemistry':
        return Icons.science_outlined;
      case 'physics':
        return Icons.auto_awesome_motion;
      case 'biology':
        return Icons.biotech_outlined;
      case 'maths':
      case 'mathematics':
        return Icons.change_history;
      default:
        return Icons.book_outlined;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'science':
      case 'chemistry':
        return const Color.fromRGBO(223, 228, 200, 1);
      case 'physics':
        return const Color.fromRGBO(253, 233, 137, 1);
      case 'biology':
        return const Color.fromRGBO(244, 221, 168, 1);
      case 'maths':
      case 'mathematics':
        return const Color.fromRGBO(214, 234, 248, 1);
      default:
        return const Color.fromRGBO(230, 230, 230, 1);
    }
  }

  Color _getSubjectBorderColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'science':
      case 'chemistry':
        return const Color.fromRGBO(171, 185, 165, 1);
      case 'physics':
        return const Color.fromRGBO(228, 204, 109, 1);
      case 'biology':
        return const Color(0xFFBEA177);
      case 'maths':
      case 'mathematics':
        return const Color.fromRGBO(159, 201, 231, 1);
      default:
        return const Color.fromRGBO(180, 180, 180, 1);
    }
  }

  void _prepareSearchData() {
    if (chapters.isEmpty) return;

    final ch = <SearchableChapter>{};
    final tp = <SearchableTopic>{};
    final cp = <SearchableConcept>[];

    for (final chapter in chapters) {
      final chapterName = chapter['name'];
      final subject = _selectedSubject;
      final standard = userProfile?['standard'] ?? 8;

      ch.add(SearchableChapter(
        chapterName: chapterName,
        subject: subject,
        standard: standard,
      ));

      for (final topic in chapter['topics']) {
        final topicName = topic['name'];

        tp.add(SearchableTopic(
          topicName: topicName,
          chapterName: chapterName,
          subject: subject,
          standard: standard,
        ));

        for (final lesson in topic['lessons']) {
          cp.add(SearchableConcept(
            conceptName: lesson['name'],
            topicName: topicName,
            chapterName: chapterName,
            subject: subject,
            standard: standard,
          ));
        }
      }
    }

    chapterList = ch.toList();
    topicList = tp.toList();
    conceptList = cp;

    // Initialize fuzzy search engines
    chapterFuse = Fuzzy(
      chapterList,
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
          )
        ],
        threshold: 0.2,
      ),
    );

    topicFuse = Fuzzy(
      topicList,
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
          )
        ],
        threshold: 0.2,
      ),
    );

    conceptFuse = Fuzzy(
      conceptList,
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearchActive = query.isNotEmpty;
    });

    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        matchedChapters = [];
        matchedTopics = [];
        matchedConcepts = [];
      });
      return;
    }

    // Chapter search
    final exactChapters = chapterList
        .where((c) => c.chapterName.toLowerCase().contains(q))
        .toList();
    final fuzzyChapters = chapterFuse.search(q).map((r) => r.item).toList();
    final allChapters = {
      for (var c in [...exactChapters, ...fuzzyChapters]) c.chapterName: c
    }.values.toList();

    // Topic search
    final exactTopics =
        topicList.where((t) => t.topicName.toLowerCase().contains(q)).toList();
    final fuzzyTopics = topicFuse.search(q).map((r) => r.item).toList();
    final allTopics = {
      for (var t in [...exactTopics, ...fuzzyTopics]) t.topicName: t
    }.values.toList();

    // Concept search
    final exactConcepts = conceptList
        .where((c) => c.conceptName.toLowerCase().contains(q))
        .toList();
    final fuzzyConcepts = conceptFuse.search(q).map((r) => r.item).toList();
    final allConcepts = {
      for (var c in [...exactConcepts, ...fuzzyConcepts]) c.conceptName: c
    }.values.toList();

    setState(() {
      matchedChapters = allChapters;
      matchedTopics = allTopics;
      matchedConcepts = allConcepts;
    });
  }

  void _onSearchSubmitted(String query) {
    _onSearchChanged(query);
  }

  Future<void> _onConceptSelected(SearchableConcept concept) async {
    // Clear search
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchActive = false;
      _searchQuery = "";
      matchedChapters = [];
      matchedTopics = [];
      matchedConcepts = [];
    });

    // Find the concept ID from chapters data
    String? conceptId;
    for (var chapter in chapters) {
      for (var topic in chapter['topics']) {
        for (var lesson in topic['lessons']) {
          if (lesson['name'] == concept.conceptName) {
            conceptId = lesson['id'];
            break;
          }
        }
        if (conceptId != null) break;
      }
      if (conceptId != null) break;
    }

    if (conceptId != null) {
      await _onTapLesson(conceptId);
    } else {
      // If concept ID not found, start a new lesson with the concept name
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConceptLearningScreenV4(
              conceptId: 'search_${concept.conceptName.replaceAll(' ', '_')}',
              conceptName: concept.conceptName,
              maxXP: 45,
              name: userProfile?['firstName'] ?? 'Student',
              subject: concept.subject,
              standard: userProfile?['standard'] ?? 8,
              resumeLesson: false,
              dataToResume: null,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onTapLesson(String lessonId) async {
    // Check if this is a resumable lesson
    final lessonHistoryData =
        await fetchLessonHistoryList(onlyIncompleteLessons: false.toString());

    Map<String, dynamic>? resumableLesson;
    try {
      resumableLesson = lessonHistoryData.firstWhere(
        (item) => item['conceptId'] == lessonId,
      );
    } catch (e) {
      resumableLesson = null;
    }

    if (resumableLesson != null &&
        resumableLesson['completionStatus'] == false) {
      // Resume existing lesson
      final dataToResume = await resumeConcept(
        conceptId: resumableLesson['conceptId'],
        checkpointsCompleted: resumableLesson['checkpointsCompleted'],
        conceptConversationsKey:
            resumableLesson['conceptConversationKey'] ?? "",
        checkpointNo: resumableLesson['checkpointNo'],
        learningObjectivesStatus: resumableLesson['learningObjectivesStatus'],
        newCheckpointStarted: resumableLesson['newCheckpointStarted'],
        remainingTime: resumableLesson['remainingTime'],
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConceptLearningScreenV4(
              conceptId: lessonId,
              conceptName: resumableLesson!['conceptName'] ?? 'Unknown Concept',
              maxXP: 45, // Could be dynamic based on concept
              name: userProfile?['firstName'] ?? 'Student',
              subject: _selectedSubject,
              standard: userProfile?['standard'] ?? 8,
              resumeLesson: true,
              dataToResume: dataToResume,
            ),
          ),
        );
      }
    } else {
      // Start new lesson - find concept name from chapters
      String conceptName = 'Unknown Concept';
      for (var chapter in chapters) {
        for (var topic in chapter['topics']) {
          for (var lesson in topic['lessons']) {
            if (lesson['id'] == lessonId) {
              conceptName = lesson['name'];
              break;
            }
          }
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConceptLearningScreenV4(
              conceptId: lessonId,
              conceptName: conceptName,
              maxXP: 45,
              name: userProfile?['firstName'] ?? 'Student',
              subject: _selectedSubject,
              standard: userProfile?['standard'] ?? 8,
              resumeLesson: false,
              dataToResume: null,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return NotebookScaffold(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return NotebookScaffold(
      child: CustomScrollView(
        slivers: [
          // const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: HeaderBar(
                userName: userProfile?['firstName'] ?? 'Student',
                // dateString:
                //     "Tue, 12 Aug",
                // dayPart: DayPart.evening,
                onAvatarTap: () {}, // optional
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Search (with yellow highlight in its own widget)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NotebookSearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onSubmit: _onSearchSubmitted,
                onChanged: _onSearchChanged,
                onMic: () {},
                onCamera: () {},
                hintText: "Search any concept, topic, or chapter...",
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Conditional content: Search results or normal home content
          if (_isSearchActive && chapters.isNotEmpty)
            // Search Results with notebook styling
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchResults(),
              ),
            )
          else ...[
            // Normal Home Content

            // // Subject shortcuts
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SubjectChipsRow(
                    subjects: _subjectMocks,
                    onSelect: (id) {
                      setState(() => _selectedSubjectId = id);
                      // Could add logic to change selected subject here
                    },
                  )),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // Continue Learning
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ContinueLearningCard(
                  lessons: _continueLessons.isNotEmpty
                      ? _continueLessons
                      : [
                          // Fallback lessons if no resumable lessons
                          Lesson(
                            id: 'explore',
                            title: 'Start learning ${_selectedSubject}',
                            path: '$_selectedSubject → New Topic',
                            durationMin: 15,
                            progress: 0.0,
                          ),
                        ],
                  subjectTabs: _subjectTabs,
                  selectedSubjectId: _selectedSubjectId,
                  onSelectSubject: (id) {
                    setState(() => _selectedSubjectId = id);
                    // Optionally filter lessons by subject here.
                  },
                  onTapLesson: _onTapLesson,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            // // Recommended Discussions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: RecommendedSection(
                  tabs: tabs,
                  discussions: recItems,
                  initialTabId: selectedTabId,
                  onSelectTab: (id) {},
                  onStartDiscussion: (id) {},
                ),
              ),
            ),
            // // List of discussion rows (we'll feed data later)
            // SliverList.builder(
            //   itemBuilder: (context, index) => Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 16),
            //     child: DiscussionRow(
            //       item: null, // placeholder; will use mocks
            //       onStart: () {},
            //     ),
            //   ),
            //   itemCount: 0,
            // ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
                child: TimetableHeaderCard(
                  today: today,
                  showTape: true,
                  belowHeader: TimetableWeekStrip(todayIndex: todayIdx),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TimetablePeriodList(
                        periodsForToday: periods, // your list for today
                        timeRailWidth: kTimeRail,
                      ),
                      const SizedBox(height: 4),
                      TimetableFooter(
                        periodsForToday: periods,
                        now: now,
                        remindersOn: true,
                        onTapUpdatePack: () {}, // TODO: hook
                        onTapShare: () {}, // TODO: hook
                        onTapEdit: () {}, // TODO: hook
                        timeRailWidth: kTimeRail,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: TimetableHeaderCard(
                  today: today,
                  showTape: true,
                  belowHeader: null,
                  body: TimetableEmptyBody(
                    onAddTimetable: () {/* open form */},
                    onImportFromPhoto: () {/* open camera/gallery */},
                  ),
                ),
              ),
            ),

            // // Timetable
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 16),
            //     child: TimetableCard(
            //       periods: const [],
            //       next: null,
            //       autoRemindersOn: true,
            //       todayLabel: "Today Wed",
            //       onSelectDay: (_) {},
            //       selectedWeekday: 3,
            //     ),
            //   ),
            // ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (matchedChapters.isEmpty &&
        matchedTopics.isEmpty &&
        matchedConcepts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 247, 209, 1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB7A987), width: 1.5),
        ),
        child: const Center(
          child: Text(
            "No results found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E4B7A),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 247, 209, 1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7A987), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (matchedChapters.isNotEmpty) ...[
            _buildSearchSectionHeader("📘 Chapters"),
            const SizedBox(height: 8),
            ...matchedChapters.map((c) => _buildChapterResultCard(c)),
            const SizedBox(height: 16),
          ],
          if (matchedTopics.isNotEmpty) ...[
            _buildSearchSectionHeader("🧩 Topics"),
            const SizedBox(height: 8),
            ...matchedTopics.map((t) => _buildTopicResultCard(t)),
            const SizedBox(height: 16),
          ],
          if (matchedConcepts.isNotEmpty) ...[
            _buildSearchSectionHeader("🔬 Concepts"),
            const SizedBox(height: 8),
            ...matchedConcepts.map((c) => _buildConceptResultCard(c)),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 236, 201, 1),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          bottom: BorderSide(
            color: Color.fromRGBO(216, 203, 161, 1),
            width: 1.5,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E4B7A),
        ),
      ),
    );
  }

  Widget _buildChapterResultCard(SearchableChapter chapter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCBE9C), width: 1),
      ),
      child: ListTile(
        title: Text(
          chapter.chapterName,
          style: const TextStyle(
            color: Color(0xFF1E4B7A),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          chapter.subject,
          style: const TextStyle(
            color: Color(0xFF48524F),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF1E4B7A),
        ),
        onTap: () {
          // TODO: Navigate to chapter
        },
      ),
    );
  }

  Widget _buildTopicResultCard(SearchableTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCBE9C), width: 1),
      ),
      child: ListTile(
        title: Text(
          topic.topicName,
          style: const TextStyle(
            color: Color(0xFF1E4B7A),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "${topic.chapterName} • ${topic.subject}",
          style: const TextStyle(
            color: Color(0xFF48524F),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF1E4B7A),
        ),
        onTap: () {
          // TODO: Navigate to topic
        },
      ),
    );
  }

  Widget _buildConceptResultCard(SearchableConcept concept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCBE9C), width: 1),
      ),
      child: ListTile(
        title: Text(
          concept.conceptName,
          style: const TextStyle(
            color: Color(0xFF1E4B7A),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "${concept.topicName} • ${concept.chapterName} • ${concept.subject}",
          style: const TextStyle(
            color: Color(0xFF48524F),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.play_circle_outline,
          size: 20,
          color: Colors.green,
        ),
        onTap: () => _onConceptSelected(concept),
      ),
    );
  }
}
