import 'package:eureka_app/parentDashboard/models.dart';
import 'package:eureka_app/parentDashboard/theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RightPanel extends StatelessWidget {
  final List<FeedGroup> grouped;
  final double masteryDelta;
  final double confidenceDelta;
  final Map<String, ConceptDetailsModel> conceptDetails;
  final int studyStreak;
  final int parentPresenceStreak;
  final String bestWindow;

  const RightPanel({
    super.key,
    required this.grouped,
    required this.masteryDelta,
    required this.confidenceDelta,
    required this.conceptDetails,
    required this.studyStreak,
    required this.parentPresenceStreak,
    required this.bestWindow,
  });

  Map<String, int> _totals() {
    int gaps = 0, resolved = 0;
    for (final g in grouped) {
      for (final it in g.items) {
        final d = conceptDetails[it.id];
        if (d != null) {
          gaps += d.gaps.length;
          resolved += (d.gaps.length ~/ 2);
        }
      }
    }
    return {'gaps': gaps, 'resolved': resolved};
  }

  List<_DayRow> _series7() {
    final now = DateTime.now();
    final out = <_DayRow>[];
    for (int i = 6; i >= 0; i--) {
      final d =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final label =
          ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7];
      int gaps = 0;
      for (final g in grouped) {
        if (g.date.year == d.year &&
            g.date.month == d.month &&
            g.date.day == d.day) {
          for (final it in g.items) {
            final cd = conceptDetails[it.id];
            if (cd != null) gaps += cd.gaps.length;
          }
        }
      }
      final resolved = gaps ~/ 2;
      final study = grouped.any((g) =>
              g.date.year == d.year &&
              g.date.month == d.month &&
              g.date.day == d.day)
          ? 1
          : 0;
      // Parent presence mock using global streak
      final parent = (7 - i) <= parentPresenceStreak ? 1 : 0;
      out.add(_DayRow(
          day: label,
          study: study,
          parent: parent,
          gaps: gaps,
          resolved: resolved));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals();
    final series = _series7();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).accentTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.bar_chart,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('This week at a glance',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),

          // Streaks: stacked bar micro chart
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Streaks',
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ),
          SizedBox(
            height: 80,
            child: BarChart(BarChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < series.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: 1,
                      rodStackItems: [
                        if (series[i].study == 1)
                          BarChartRodStackItem(
                              0, 1, Theme.of(context).colorScheme.primary),
                        if (series[i].study == 0)
                          BarChartRodStackItem(0, 0, Colors.transparent),
                        if (series[i].parent == 1)
                          BarChartRodStackItem(
                              0,
                              1,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4)),
                      ],
                      width: 10,
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.transparent,
                    ),
                  ]),
              ],
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(series[value.toInt()].day,
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(enabled: false),
            )),
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  'Study: ${studyStreak} days • Parent presence: ${parentPresenceStreak} days',
                  style: const TextStyle(fontSize: 12, color: Colors.grey))),

          const SizedBox(height: 16),
          // Gaps totals + area chart
          Row(
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gaps identified',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700])),
                      Text('${totals['gaps']}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                    ]),
              ),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Resolved',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700])),
                      Text('${totals['resolved']}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                    ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                            style: const TextStyle(fontSize: 10)))),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(series[v.toInt()].day,
                                style: const TextStyle(fontSize: 10))))),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(enabled: false),
              lineBarsData: [
                _areaSeries(series.map((e) => e.gaps.toDouble()).toList(),
                    Theme.of(context).colorScheme.primary,
                    fillOpacity: 0.6),
                _areaSeries(series.map((e) => e.resolved.toDouble()).toList(),
                    Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    fillOpacity: 0.25),
              ],
              minY: 0,
              maxY: (series
                          .map((e) => e.gaps)
                          .fold<int>(0, (a, b) => a > b ? a : b) +
                      1)
                  .toDouble(),
            )),
          ),

          const SizedBox(height: 16),
          // Mastery & Confidence Δ meters
          Row(children: [
            Expanded(child: _deltaMeter(context, 'Mastery Δ', masteryDelta)),
            const SizedBox(width: 12),
            Expanded(
                child: _deltaMeter(context, 'Confidence Δ', confidenceDelta)),
          ]),

          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.access_time, size: 14),
            const SizedBox(width: 6),
            Text('Best window ${bestWindow}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ],
      ),
    );
  }

  LineChartBarData _areaSeries(List<double> points, Color color,
      {double fillOpacity = 0.3}) {
    return LineChartBarData(
      isCurved: true,
      color: color,
      barWidth: 3,
      belowBarData:
          BarAreaData(show: true, color: color.withOpacity(fillOpacity)),
      spots: [
        for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i])
      ],
      dotData: const FlDotData(show: false),
    );
  }

  Widget _deltaMeter(BuildContext context, String label,
      double value /*0..1ish delta as points */) {
    final pct = (value * 100).round();
    final clamped = (value.clamp(0, 1) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('$pct pts', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              minHeight: 8,
              value: clamped / 100,
              backgroundColor: Colors.white,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _DayRow {
  final String day;
  final int study;
  final int parent;
  final int gaps;
  final int resolved;
  _DayRow(
      {required this.day,
      required this.study,
      required this.parent,
      required this.gaps,
      required this.resolved});
}
