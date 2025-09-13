import 'package:eureka_app/screens/home/widgets/timetable/periodRow.dart';
import 'package:flutter/material.dart';
import '../../models/period.dart';

class TimetablePeriodList extends StatelessWidget {
  const TimetablePeriodList(
      {super.key,
      required this.periodsForToday,
      this.now, // for testing; defaults to DateTime.now()
      this.timeRailWidth = 36, // NEW
      this.dividerColor = const Color(0xFFCCBE9C)});

  final List<Period> periodsForToday;
  final DateTime? now;
  final double timeRailWidth; // NEW
  final Color dividerColor;

  bool _isNowWithin(Period p, DateTime clock) {
    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
    final mins = clock.hour * 60 + clock.minute;
    return mins >= toMinutes(p.start) && mins < toMinutes(p.end);
  }

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    final currentId = periodsForToday
        .firstWhere((p) => _isNowWithin(p, clock),
            orElse: () => const Period(
                  id: '__none__',
                  start: TimeOfDay(hour: 0, minute: 0),
                  end: TimeOfDay(hour: 0, minute: 1),
                  subject: '',
                  topic: '',
                  icon: Icons.circle, // dummy
                  accent: Color(0xFF2E7D57),
                  weekdayIndex: 1,
                ))
        .id;

    return Stack(children: [
      // Vertical divider that spans the entire list height
      Positioned.fill(
        left: timeRailWidth, // aligns with start of subject cell
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(width: 1, color: dividerColor),
        ),
      ),

      // The rows on top
      Column(
        children: List.generate(periodsForToday.length, (i) {
          final p = periodsForToday[i];
          final isCurrent = p.id == currentId;
          return PeriodRow(
            period: p,
            isCurrent: isCurrent,
            showBottomRule: i != periodsForToday.length - 1,
            timeRailWidth: timeRailWidth, // NEW
          );
        }),
      ),
    ]);
  }
}
