import 'package:eureka_app/parentDashboard/models.dart';
import 'package:intl/intl.dart';

String friendlyDay(DateTime d) => DateFormat('EEE, MMM d').format(d);

List<FeedGroup> filterAndGroupByDate(
  List<FeedGroup> feed, {
  required String subject,
  required DateTime? start,
  required DateTime? end,
}) {
  bool inRange(DateTime day) {
    if (start == null && end == null) return true;
    final d = DateTime(day.year, day.month, day.day);
    final sOk = start == null ||
        d.isAtSameMomentAs(DateTime(start!.year, start!.month, start!.day)) ||
        d.isAfter(start!);
    final eOk = end == null ||
        d.isAtSameMomentAs(DateTime(end!.year, end!.month, end!.day)) ||
        d.isBefore(end!);
    return sOk && eOk;
  }

  final out = <FeedGroup>[];
  for (final g in feed) {
    if (!inRange(g.date)) continue;
    final filtered = g.items
        .where((it) => subject == 'All' || it.subject == subject)
        .toList();
    if (filtered.isNotEmpty) out.add(FeedGroup(date: g.date, items: filtered));
  }
  out.sort((a, b) => b.date.compareTo(a.date));
  return out;
}
