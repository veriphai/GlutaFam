import 'package:eureka_app/apis/fetchAllFeedbacks.dart';
import 'package:eureka_app/parentDashboard/backendMapper.dart';
import 'package:eureka_app/parentDashboard/conceptOverlay.dart';
import 'package:eureka_app/parentDashboard/conceptSummaryCard.dart';
import 'package:eureka_app/parentDashboard/dateGroup.dart';
import 'package:eureka_app/parentDashboard/filterBar.dart';
import 'package:eureka_app/parentDashboard/greetingBar.dart';
import 'package:eureka_app/parentDashboard/rightPanel.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/parentDashboard/models.dart';
// import 'package:eureka_app/parentDashboard/sampleData.dart' as data;
import 'package:eureka_app/parentDashboard/dashboardData.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  final subjects = const ['All', 'Math', 'Science', 'SST'];
  String subject = 'All';
  String datePreset = '7d';
  DateTime? customStart;
  DateTime? customEnd;

  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DashboardData> _load() async {
    final list = await fetchAllFeedbacks(); // <List<dynamic>>
    // Optional: if your student name comes elsewhere, pass fallbackStudentName
    final db = mapBackend(list, fallbackStudentName: 'Shubham');
    return db;
  }

  (DateTime?, DateTime?) _range() {
    final today = DateTime.now();
    if (datePreset == 'Today') {
      final d = DateTime(today.year, today.month, today.day);
      return (d, d);
    }
    if (datePreset == '7d') {
      final s = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 7));
      return (s, today);
    }
    if (datePreset == '30d') {
      final s = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 30));
      return (s, today);
    }
    return (customStart, customEnd);
  }

  double _masteryDelta(
      List<FeedGroup> groups, Map<String, ConceptDetailsModel> details) {
    double s = 0, c = 0;
    for (final g in groups) {
      for (final it in g.items) {
        final det = details[it.id];
        if (det != null) {
          s += det.mastery.end - det.mastery.start;
          c += 1;
        }
      }
    }
    return c == 0 ? 0 : s / c;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Failed to load',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('${snap.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () => setState(() => _future = _load()),
                    child: const Text('Retry')),
              ]),
            ),
          );
        }

        final db = snap.data!;
        final (start, end) = _range();
        final grouped = filterAndGroupByDate(db.feed,
            subject: subject, start: start, end: end);

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(builder: (context, box) {
              final isNarrow = box.maxWidth < 980;
              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12 : 32, vertical: 16),
                child: Column(
                  children: [
                    GreetingBar(name: db.student.name),
                    const SizedBox(height: 16),
                    FilterBar(
                      studentLabel:
                          '${db.student.name} • Class ${db.student.grade}',
                      subjects: db.subjects,
                      selectedSubject: subject,
                      onSubject: (s) => setState(() => subject = s),
                      datePreset: datePreset,
                      onPreset: (p) => setState(() => datePreset = p),
                      customStart: customStart,
                      customEnd: customEnd,
                      onCustomStart: (d) => setState(() => customStart = d),
                      onCustomEnd: (d) => setState(() => customEnd = d),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isNarrow
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  RightPanel(
                                    grouped: grouped,
                                    masteryDelta: _masteryDelta(
                                        grouped, db.conceptDetails),
                                    confidenceDelta: 0.08, // derive if you want
                                    conceptDetails: db.conceptDetails,
                                    studyStreak: db.studyStreak,
                                    parentPresenceStreak:
                                        db.parentPresenceStreak,
                                    bestWindow: db.bestWindow,
                                  ),
                                  const SizedBox(height: 16),
                                  _FeedList(
                                      grouped: grouped,
                                      conceptDetails: db.conceptDetails),
                                ],
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    child: _FeedList(
                                        grouped: grouped,
                                        conceptDetails: db.conceptDetails),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 360),
                                  child: RightPanel(
                                    grouped: grouped,
                                    masteryDelta: _masteryDelta(
                                        grouped, db.conceptDetails),
                                    confidenceDelta: 0.08,
                                    conceptDetails: db.conceptDetails,
                                    studyStreak: db.studyStreak,
                                    parentPresenceStreak:
                                        db.parentPresenceStreak,
                                    bestWindow: db.bestWindow,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Data private to your family • You control sharing • Delete anytime',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _FeedList extends StatelessWidget {
  final List<FeedGroup> grouped;
  final Map<String, ConceptDetailsModel> conceptDetails;
  const _FeedList({required this.grouped, required this.conceptDetails});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final g in grouped) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(friendlyDay(g.date),
                    style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ],
            ),
          ),
          ...g.items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ConceptSummaryCard(
                  item: it,
                  onOpen: () =>
                      ConceptOverlay.show(context, it.id, conceptDetails),
                ),
              )),
        ],
        if (grouped.isEmpty)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No items in this range/subject.',
                      style: TextStyle(color: Colors.grey[700])))),
        const SizedBox(height: 24),
      ],
    );
  }
}
