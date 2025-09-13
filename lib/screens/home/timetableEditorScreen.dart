import 'package:eureka_app/screens/home/widgets/common/notebookScaffold.dart';
import 'package:eureka_app/screens/home/widgets/timetable/timetableHeader.dart';
import 'package:eureka_app/screens/home/widgets/timetableEditor/dayStepper.dart';
import 'package:eureka_app/screens/home/widgets/timetableEditor/editorModels.dart';
import 'package:eureka_app/screens/home/widgets/timetableEditor/periodEditorRow.dart';
import 'package:eureka_app/screens/home/widgets/timetableEditor/replicateBanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetableEditorScreen extends StatefulWidget {
  const TimetableEditorScreen({super.key});

  @override
  State<TimetableEditorScreen> createState() => _TimetableEditorScreenState();
}

class _TimetableEditorScreenState extends State<TimetableEditorScreen> {
  // 1=Mon ... 7=Sun (same as DateTime.weekday)
  int _day = DateTime.now().weekday.clamp(1, 7);
  bool _includeWeekends = false;

  static const _inkBlue = Color(0xFF1E4B7A);

  void _prevDay() {
    setState(() {
      _day = (_day - 1) < 1 ? 7 : _day - 1;
      if (!_includeWeekends && (_day == 6 || _day == 7)) {
        _day = 5; // jump to Friday
      }
    });
    _ensureAtLeastOneRow();
  }

  void _nextDay() {
    setState(() {
      _day = (_day + 1) > 7 ? 1 : _day + 1;
      if (!_includeWeekends && (_day == 6 || _day == 7)) {
        _day = 1; // jump to Monday
      }
    });
    _ensureAtLeastOneRow();
  }

  final _subjects = <Subject>[
    const Subject(
        id: 'phy',
        name: 'Physics',
        icon: Icons.science_outlined,
        color: Color(0xFF2E7D57)),
    const Subject(
        id: 'chem',
        name: 'Chemistry',
        icon: Icons.biotech_outlined,
        color: Color(0xFF1F63C3)),
    const Subject(
        id: 'math',
        name: 'Maths',
        icon: Icons.calculate_outlined,
        color: Color(0xFF8E4EC6)),
  ];

  final _chapters = <Chapter>[
    const Chapter(id: 'c1', subjectId: 'phy', name: 'Motion'),
    const Chapter(id: 'c2', subjectId: 'phy', name: 'Laws of Motion'),
    const Chapter(id: 'c3', subjectId: 'chem', name: 'Stoichiometry'),
    const Chapter(id: 'c4', subjectId: 'math', name: 'Quadratic Equations'),
  ];

  // 1..7 => Mon..Sun
  final Map<int, List<PeriodDraft>> _byDay = {
    for (int d = 1; d <= 7; d++) d: <PeriodDraft>[],
  };

// remember dismissals so banner doesn’t nag again
  final Set<int> _replicateDismissedForDay = {};

  List<PeriodDraft> get _currentList => _byDay[_day]!;
  void _ensureAtLeastOneRow() {
    if (_currentList.isEmpty) {
      _currentList.add(PeriodDraft(index: 1));
    }
  }

  String _dayName(int i) => const [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ][(i - 1).clamp(0, 6)];

  List<PeriodDraft> _cloneWithReindex(List<PeriodDraft> rows) {
    return [
      for (int k = 0; k < rows.length; k++)
        PeriodDraft(
          index: k + 1,
          subjectId: rows[k].subjectId,
          chapterId: rows[k].chapterId,
        ),
    ];
  }

  bool _shouldOfferReplicate() {
    // Only if current day is a weekday and has at least 1 row
    if (!(_day >= 1 && _day <= 5)) return false;
    if (_currentList.isEmpty) return false;
    if (_replicateDismissedForDay.contains(_day)) return false;

    // Offer if Tue–Fri (excluding current) are empty
    for (final d in const [1, 2, 3, 4, 5]) {
      if (d == _day) continue;
      if (_byDay[d]!.isNotEmpty) return false;
    }
    return true;
  }

  void _addPeriod() {
    setState(() {
      final next = _currentList.length + 1;
      _currentList.add(PeriodDraft(index: next));
    });
  }

  void _updatePeriod(int i, PeriodDraft updated) {
    setState(() {
      _currentList[i] = updated;
    });
  }

  void _removePeriod(int i) {
    if (_currentList.length == 1) return; // keep one row minimum
    setState(() {
      _currentList.removeAt(i);
      // reindex
      for (int k = 0; k < _currentList.length; k++) {
        _currentList[k] = _currentList[k].copyWith(index: k + 1);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureAtLeastOneRow();
  }

  void _replicateToWeekdays() {
    setState(() {
      final src = _cloneWithReindex(_currentList);
      for (final d in const [1, 2, 3, 4, 5]) {
        if (d == _day) continue;
        _byDay[d] = _cloneWithReindex(src); // deep-ish copy with new indices
      }
      _replicateDismissedForDay.add(_day); // don’t show again for this day
    });
  }

  void _skipReplicate() {
    setState(() {
      _replicateDismissedForDay.add(_day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScaffold(
      // use the scaffold we built earlier
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TimetableHeaderCard(
          today: DateTime.now(),
          showTape: true,
          // Day stepper lives UNDER the title, above the beige rule
          belowHeader: DayStepper(
            dayIndex: _day,
            includeWeekends: _includeWeekends,
            onPrev: _prevDay,
            onNext: _nextDay,
            onToggleWeekends: () =>
                setState(() => _includeWeekends = !_includeWeekends),
          ),
          // Empty state body for now
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // rows
              for (int i = 0; i < _currentList.length; i++)
                PeriodEditorRow(
                  key: ValueKey('row_${_day}_$i'),
                  draft: _currentList[i],
                  subjects: _subjects,
                  chapters: _chapters,
                  onChanged: (d) => _updatePeriod(i, d),
                  onDelete: () => _removePeriod(i),
                  canDelete: _currentList.length > 1,
                ),

              const SizedBox(height: 10),

              // Add period CTA
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: const Color.fromRGBO(253, 233, 137, 1),
                  shape: const StadiumBorder(
                    side: BorderSide(
                        color: Color.fromRGBO(228, 204, 109, 1), width: 1.2),
                  ),
                  child: InkWell(
                    onTap: _addPeriod,
                    customBorder: const StadiumBorder(),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18, color: Color(0xFF3B2F2A)),
                          SizedBox(width: 6),
                          Text('Add period',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF3B2F2A))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Replicate banner (conditionally)
              if (_shouldOfferReplicate())
                ReplicateBanner(
                  fromDay: _dayName(_day),
                  onReplicate: _replicateToWeekdays,
                  onSkip: _skipReplicate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDayPlaceholder extends StatelessWidget {
  const _EmptyDayPlaceholder();

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trayLine, width: 1),
      ),
      child: Column(
        children: [
          Text(
            "No periods added yet",
            style: GoogleFonts.kalam(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _inkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap “Add period” (next step) to start building your day.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.2,
              color: _inkBlue.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
