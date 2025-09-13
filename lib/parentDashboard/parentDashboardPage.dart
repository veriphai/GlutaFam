import 'package:eureka_app/apis/fetchAllFeedbacks.dart';
import 'package:eureka_app/parentDashboard/backendMapper.dart';
import 'package:eureka_app/parentDashboard/conceptOverlay.dart';
import 'package:eureka_app/parentDashboard/conceptSummaryCard.dart';
import 'package:eureka_app/parentDashboard/dateGroup.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/parentDashboard/models.dart';
// import 'package:eureka_app/parentDashboard/sampleData.dart' as data;
import 'package:eureka_app/parentDashboard/dashboardData.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class HoverScale extends StatefulWidget {
  final Widget child;
  const HoverScale({super.key, required this.child});
  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Band {
  final String label;
  final Color ringColor;
  final Color chipFg;
  const _Band(this.label, this.ringColor, this.chipFg);
  Color get chipBg => chipFg.withOpacity(0.15);
}

Widget _sparklineFrom(Mastery? m) {
  final points = (m == null
          ? <double>[0, 0]
          : (m.checkpoints.isNotEmpty ? m.checkpoints : [m.start, m.end]))
      .map((e) => (e.clamp(0, 1) * 100).toDouble())
      .toList();
  return SizedBox(
    height: 48,
    width: double.infinity,
    child: CustomPaint(
      painter: _SparklinePainter(points: points),
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  _SparklinePainter({required this.points});
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path();
    final stroke = Paint()
      ..color = const Color(0xFF14B8A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final n = points.length;
    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * size.width;
      final y = size.height - (points[i] / 100.0) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) return true;
    }
    return false;
  }
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  final subjects = const ['All', 'Science', 'Math', 'English', 'SST'];
  String subject = 'All';
  String selectedTab = 'Today'; // 'Yesterday' or 'Today'
  DateTime selectedDate = DateTime.now();
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
    final d = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return (d, d);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final pickedDay = DateTime(picked.year, picked.month, picked.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        final yesterdayDay =
            DateTime(yesterday.year, yesterday.month, yesterday.day);

        if (pickedDay == todayDay) {
          selectedTab = 'Today';
        } else if (pickedDay == yesterdayDay) {
          selectedTab = 'Yesterday';
        } else {
          selectedTab = ''; // No tab is selected for custom dates
        }
      });
    }
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
          backgroundColor: const Color(0xFFF9FAFB),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSubjectFilters(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedTab == 'Today') ...[
                            _buildCriticalConceptCard(),
                            const SizedBox(height: 32),
                            _buildTodaysPlanSection(grouped, db),
                            const SizedBox(height: 32),
                            _buildTrendsSection(grouped, db),
                            const SizedBox(height: 32),
                            _buildAllLessonsSection(grouped, db),
                          ] else ...[
                            _buildYesterdaySection(grouped, db),
                          ],
                        ],
                      ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Parent Insights',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildTabButton('Yesterday'),
              _buildTabButton('Today'),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down,
                    size: 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String tab) {
    final isSelected = selectedTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = tab;
          if (tab == 'Today') {
            selectedDate = DateTime.now();
          } else if (tab == 'Yesterday') {
            selectedDate = DateTime.now().subtract(const Duration(days: 1));
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          tab,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectFilters() {
    return Row(
      children: subjects.map((subj) {
        final isSelected = subject == subj;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => subject = subj),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subj,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          'Save for Today',
          Icons.bookmark,
          Colors.teal,
          () {},
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          'Schedule',
          Icons.schedule,
          Colors.grey[600]!,
          () {},
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          'Select Concepts',
          Icons.tune,
          Colors.grey[600]!,
          () {},
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color == Colors.teal ? Colors.teal : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color == Colors.teal ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color == Colors.teal ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsSection(List<FeedGroup> grouped, DashboardData db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Last 7 days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTrendCard('Lessons Completed', '12'),
              const SizedBox(width: 16),
              _buildTrendCard('Avg Discussion', '74'),
              const SizedBox(width: 16),
              _buildTrendCard('Gaps Identified', '9'),
              const SizedBox(width: 16),
              _buildTrendCard('Gaps Rectified', '6'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard(String title, String value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllLessonsSection(List<FeedGroup> grouped, DashboardData db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Lessons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildLessonItem(
                'Seed Selection & Viability',
                'Crop Production & Management • Sowing — Science',
                '09:30',
              ),
              Divider(height: 1, color: Colors.grey[200]),
              _buildLessonItem(
                '√2 is Irrational (Proof)',
                'Number Systems • Irrational Numbers — Math',
                '08:00',
              ),
              Divider(height: 1, color: Colors.grey[200]),
              _buildLessonItem(
                'Finding Central Idea',
                'Reading Skills • Main Idea — English',
                '05:30',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonItem(String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYesterdaySection(List<FeedGroup> grouped, DashboardData db) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yesterday • 22 Aug 2025',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            'Shubham built momentum with 3 lessons. Discussion 72 (↑5 vs 7-day avg). 2 gaps fixed, 1 pending in Fractions; articulation dipped slightly.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child:
                  _buildYesterdayMetric('Gaps Identified', '3', Icons.search),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildYesterdayMetric(
                  'Gaps Rectified', '2', Icons.check_circle_outline),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildYesterdayMetric(
                  'Gaps Pending', '1', Icons.pending_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildYesterdayMetric(
                  'Shining Moments', '4', Icons.star_border),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildYesterdayMetric(
                  'Time Spent (min)', '28', Icons.access_time),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildYesterdayMetric(
                  'Unknown Competencies', '2', Icons.help_outline),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Yesterday\'s Lessons',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (grouped.isNotEmpty && grouped.first.items.isNotEmpty)
          _buildYesterdayLessons(grouped.first.items, db.conceptDetails)
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No lessons from yesterday.'),
            ),
          ),
      ],
    );
  }

  Widget _buildYesterdayLessons(List<ConceptSummary> items,
      Map<String, ConceptDetailsModel> conceptDetails) {
    final lessonCards = items.take(2).map((item) {
      final details = conceptDetails[item.id];
      final isFirst = items.indexOf(item) == 0;
      return Expanded(
        child: _buildYesterdayLessonCard(
          item: item,
          details: details,
          status: isFirst ? 'WATCH' : 'GOOD',
          backgroundColor:
              isFirst ? const Color(0xFFFFF9E8) : const Color(0xFFE8F5E9),
          statusColor:
              isFirst ? const Color(0xFFF9A825) : const Color(0xFF4CAF50),
        ),
      );
    }).toList();

    if (lessonCards.isEmpty) {
      return const SizedBox.shrink();
    }

    if (lessonCards.length == 1) {
      return Row(children: lessonCards);
    }

    return Row(
      children: [
        lessonCards[0],
        const SizedBox(width: 16),
        lessonCards[1],
      ],
    );
  }

  Widget _buildYesterdayMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'View details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYesterdayLessonCard({
    required ConceptSummary item,
    required ConceptDetailsModel? details,
    required String status,
    required Color backgroundColor,
    required Color statusColor,
  }) {
    final _Band band = _computeBand(item, details);
    final discussion = (item.mastery * 100).round();
    final articulation = (item.confidence * 100).round();
    final gapsIdentified = details?.gaps.length ?? item.gapsFound;
    final gapsPending = details?.gaps.length ?? item.gapsFound;
    final int gapsRectified = 0; // NOTE: No data for this in the model
    final shiningMoments = details?.shining.length ?? 0;
    // NOTE: No data for this, using a placeholder for visual consistency
    final unknownCompetencies = status == 'WATCH' ? 1 : 0;
    final srStatus = status == 'WATCH' ? 'DONE' : 'DUE';

    return HoverScale(
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: band.ringColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.subject.contains('Science')
                      ? Icons.science_outlined
                      : item.subject.contains('Number')
                          ? Icons.calculate_outlined
                          : Icons.menu_book_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: band.chipBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  band.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: band.chipFg,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Subject and Title
          Text(
            item.subject,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            item.concept,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),

          // Discussion and Articulation metrics
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discussion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$discussion',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Articulation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$articulation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "08:00", // Placeholder for time
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gaps metrics in a grid
          Row(
            children: [
              Expanded(
                child: _buildLessonMetric('Gaps Identified', '$gapsIdentified'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLessonMetric('Gaps Rectified', '$gapsRectified'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildLessonMetric('Gaps Pending', '$gapsPending'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        srStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              srStatus == 'DONE' ? Colors.teal : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildLessonMetric('Shining Moments', '$shiningMoments'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLessonMetric(
                    'Unknown Competencies', '$unknownCompetencies'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sparkline (trend) to mimic React chart
          _sparklineFrom(details?.mastery),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('See evidence'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey[800],
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to today'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  _Band _computeBand(ConceptSummary item, ConceptDetailsModel? details) {
    final discussion = (item.mastery * 100).round();
    final articulation = (item.confidence * 100).round();
    final gaps = details?.gaps.length ?? item.gapsFound;
    if (gaps > 0 && articulation < 55) {
      return const _Band('CRITICAL', Color(0xFFFDA4AF), Color(0xFFBE123C));
    }
    if (gaps > 0 || discussion < 65) {
      return const _Band('WATCH', Color(0xFFFCD34D), Color(0xFF92400E));
    }
    return const _Band('GOOD', Color(0xFF6EE7B7), Color(0xFF065F46));
  }

  Widget _buildLessonMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalConceptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Skills › Main Idea',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Finding Central Idea',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CRITICAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discussion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '55',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Articulation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '48',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '05:30',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLessonMetric('Gaps Identified', '1'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLessonMetric('Gaps Rectified', '0'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLessonMetric('Gaps Pending', '1'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLessonMetric('Unknown Competencies', '1'),
              ),
              SizedBox(width: 12),
              Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 6,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Expanded(flex: 45, child: Container()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('See evidence'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey[800],
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to today'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPlanSection(List<FeedGroup> grouped, DashboardData db) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Plan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No reps yet. 10 minutes with Tuto locks in yesterday\'s gains.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPlanItem(
                Icons.science_outlined,
                'Seed Selection & Viability',
                () {},
              ),
              _buildPlanItem(
                Icons.calculate_outlined,
                '√2 is Irrational (Proof)',
                () {},
              ),
              _buildPlanItem(
                Icons.menu_book_outlined,
                'Finding Central Idea',
                () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildActionButton(
                'Save for Today',
                Icons.bookmark_border,
                Colors.teal,
                () {},
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                'Schedule',
                Icons.schedule_outlined,
                Colors.grey[800]!,
                () {},
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                'Select Concepts',
                Icons.tune_outlined,
                Colors.grey[800]!,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[800]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.add, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')}/${months[date.month - 1]}/${date.year}';
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
