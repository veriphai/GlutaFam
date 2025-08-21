import 'package:eureka_app/screens/home/models/discussion.dart';
import 'package:eureka_app/screens/home/models/lesson.dart';
import 'package:eureka_app/screens/home/models/period.dart';
import 'package:eureka_app/screens/home/models/recommendedTab.dart';
import 'package:eureka_app/screens/home/models/subjectChipData.dart';
import 'package:eureka_app/screens/home/widgets/common/notebookScaffold.dart';
import 'package:eureka_app/screens/home/widgets/continueLearning/continueLearningCard.dart';
import 'package:eureka_app/screens/home/widgets/continueLearning/lessonItemLarge.dart';
import 'package:eureka_app/screens/home/widgets/continueLearning/rightEdgeSubjectTabs.dart';
import 'package:eureka_app/screens/home/widgets/headerBar.dart';
import 'package:eureka_app/screens/home/widgets/recommended/recommendedSection.dart';
import 'package:eureka_app/screens/home/widgets/recommended/recommendedTabsBar.dart';
import 'package:eureka_app/screens/home/widgets/searchBar.dart';
import 'package:eureka_app/screens/home/widgets/subjects/subjectChipsRow.dart';
import 'package:eureka_app/screens/home/widgets/timetable/periodList.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableEmptyBody.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableFooter.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableHeader.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableWeekStrip.dart';
import 'package:flutter/material.dart';
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

class HomeScreenV2 extends StatelessWidget {
  HomeScreenV2({super.key});

  final now = DateTime.now(); // or inject
  final double kTimeRail = 45;

  @override
  Widget build(BuildContext context) {
    return NotebookScaffold(
      child: CustomScrollView(
        slivers: [
          // const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: HeaderBar(
                userName: "Aanya",
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
                onSubmit: (q) {},
                onMic: () {},
                onCamera: () {},
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // // Subject shortcuts
          SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SubjectChipsRow(
                  subjects: _subjectMocks,
                  onSelect: (id) {
                    // setState(() => _selectedSubjectId = id);
                  },
                )),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),

          // Continue Learning
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ContinueLearningCard(
                lessons: _continueLessons, // your mock list
                subjectTabs: _subjectTabs, // 5–6 tabs
                selectedSubjectId: _selectedSubjectId,
                onSelectSubject: (id) {
                  // setState(() => _selectedSubjectId = id);
                  // Optionally filter lessons by subject here.
                },
                onTapLesson: (id) {},
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
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
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
      ),
    );
  }
}
