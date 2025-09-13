import 'dart:math';
import 'package:eureka_app/parentDashboard/dashboardData.dart';
import 'package:flutter/material.dart';
import 'models.dart';

DateTime _day(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime _dateFromId(Object? id) {
  // Looks for a 13-digit epoch ms at end of the id; falls back to today.
  final s = (id ?? '').toString();
  final m = RegExp(r'(\d{13})$').firstMatch(s);
  if (m != null) {
    final ms = int.tryParse(m.group(1)!);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  return DateTime.now();
}

int _pct(num? v) => max(0, min(100, (v ?? 0).round()));

double _to01(num? v) => (v == null) ? 0 : (v.toDouble().clamp(0.0, 1.0));

String _firstSentence(String? s, {int maxChars = 160}) {
  if (s == null || s.trim().isEmpty) return '';
  final cut = s.indexOf(RegExp(r'[.!?] '));
  String out = cut > 0 ? s.substring(0, cut + 1) : s;
  if (out.length > maxChars) out = out.substring(0, maxChars - 1) + '…';
  return out;
}

List<Gap> _gapsFromCheckpoint(Map cp) {
  final List<dynamic> unresolved = (cp['unresolvedGaps'] as List?) ?? const [];
  return unresolved.map((g) {
    final conversationFeedbacks = cp['conversationFeedbacks'] as List?;

    return Gap(
      id: 'gap_${g['text']}_${g['firstSeenTurn'] ?? 0}',
      type: 'Conceptual',
      severity: (g['severity'] as num?)?.toInt() ?? 1,
      why: (g['text'] ?? '').toString(),
      details: GapDetails(
        tutorAsk: conversationFeedbacks?.isNotEmpty == true
            ? ((conversationFeedbacks?[g['firstSeenTurn']]
                        as Map)['tutorQuestion'] ??
                    '')
                .toString()
            : '',
        studentText: conversationFeedbacks?.isNotEmpty == true
            ? ((conversationFeedbacks?[g['firstSeenTurn']]
                        as Map)['studentAnswer'] ??
                    '')
                .toString()
            : '',
        timeline: [
          TimelineEvent(t: '—', hint: null, verdict: null, text: null),
        ],
      ),
      resolvePlanId: 'auto',
    );
  }).toList();
}

List<ShiningMoment> _shiningFromDetailed(Map detailed) {
  final List<dynamic> list = (detailed['shiningMoments'] as List?) ?? const [];
  return list.map((m) {
    return ShiningMoment(
      id: 'shine_${m['evidence'] ?? m['wow'] ?? ''}',
      wow: (m['wow'] ?? '').toString(),
      quote: (m['evidence'] ?? '').toString(),
    );
  }).toList();
}

ConceptDetailsModel _buildConceptDetails(
  Map root, {
  required String conceptId,
  required String conceptName,
  required String subject,
  required String chapter,
  required List<Map> cpOrder, // from concept.conceptCheckpoints
  required Map<String, Map> cpByNo, // checkpointNo -> cpFeedback
}) {
  final complete =
      (root['feedback'] as Map?)?['completeLessonFeedback'] as Map? ?? const {};
  final detailed = (complete['detailed'] as Map?) ?? const {};
  final tonight = (detailed['tonightPlan'] as Map?) ?? const {};

  // Mastery: derive start/end from checkpoint masteries if available.
  final cpMasteries = <double>[];
  final gapsAll = <Gap>[];
  final cpCards = <CheckpointDetails>[];

  for (final cpMeta in cpOrder) {
    final order = (cpMeta['order'] as num?)?.toInt() ?? 0;
    final cp = cpByNo[order.toString()] ?? const {};
    final prog = (cp['progress'] as Map?)?['mastery'] as Map? ?? const {};
    final cur = _pct(prog['current']) / 100.0;
    if (cur > 0) cpMasteries.add(cur);

    final cpGaps = _gapsFromCheckpoint(cp);
    gapsAll.addAll(cpGaps);

    // Try to pick a “shining” from conversationFeedbacks correctPoints if present
    final shines = <ShiningMoment>[];
    final conv = (cp['conversationFeedbacks'] as List?) ?? const [];
    if (conv.isNotEmpty) {
      for (final c in conv.cast<Map>()) {
        final correct = (c['correctPoints'] as List?) ?? const [];
        if (correct.isNotEmpty) {
          shines.add(ShiningMoment(
              id: 'cpS_${order}_${correct.first}',
              wow: correct.first.toString(),
              quote: ''));
          break;
        }
      }
    }

    cpCards.add(CheckpointDetails(
      id: 'C${order + 1}',
      objectives: ((cpMeta['learningObjective'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      mastery: cur,
      gaps: cpGaps,
      shining: shines,
    ));
  }

  final start = cpMasteries.isEmpty ? 0.0 : cpMasteries.reduce(min);
  final end = cpMasteries.isEmpty ? 0.0 : cpMasteries.reduce(max);

  final shiningTop = _shiningFromDetailed(detailed);

  final desc = _firstSentence(
    ((root['concept'] as Map?)?['conceptCheckpoints'] as List?)
        ?.cast<Map>()
        .firstWhere((_) => true, orElse: () => const {})['theory']
        ?.toString(),
  );

  return ConceptDetailsModel(
    meta: ConceptMeta(
        subject: subject, chapter: chapter, concept: conceptName, desc: desc),
    gaps: gapsAll,
    shining: shiningTop,
    mastery: Mastery(
        start: start,
        end: end,
        checkpoints: cpMasteries.isNotEmpty ? cpMasteries : [start, end]),
    plan: ResolvePlan(
      talk: (tonight['steps'] is List && (tonight['steps'] as List).isNotEmpty)
          ? (((tonight['steps'] as List).first as Map)['text'] ?? '').toString()
          : (detailed['quickProgress'] ?? '').toString(),
      drillIds: (tonight['steps'] as List?)
              ?.skip(1)
              .map((e) => (e as Map)['text'].toString())
              .toList() ??
          const [],
      realLife: tonight['minutes'] != null ? '12-min tonight plan' : '',
    ),
    checkpointDetails: cpCards,
  );
}

DashboardData mapBackend(List<dynamic> payload, {String? fallbackStudentName}) {
  // Defaults if backend doesn’t provide
  final studyStreak = 5;
  final parentPresenceStreak = 3;
  const bestWindow = '7:30–7:45 PM';

  final conceptDetails = <String, ConceptDetailsModel>{};
  final byDay = <DateTime, List<ConceptSummary>>{};
  final subjectsSet = <String>{};

  // derive student/grade/subject from first record
  String studentName = fallbackStudentName ?? 'Student';
  String grade = '';
  for (final raw in payload.cast<Map>()) {
    final feedback = (raw['feedback'] as Map?) ?? const {};
    final concept = (raw['concept'] as Map?) ?? const {};

    final complete = (feedback['completeLessonFeedback'] as Map?) ?? const {};
    final meta = (complete['meta'] as Map?) ?? const {};
    grade = meta['grade']?.toString() ?? grade;

    final subj = meta['subject']?.toString() ?? 'General';
    final lesson = meta['lesson']?.toString() ?? '';
    final conceptId = (concept['id'] ?? feedback['id']).toString();
    final conceptName =
        concept['name']?.toString() ?? lesson.ifEmpty('Concept');
    final chapter =
        lesson.isEmpty ? '—' : lesson[0].toUpperCase() + lesson.substring(1);
    subjectsSet.add(subj);

    // Build checkpoints map by checkpointNo
    final cpFeedbacksMap =
        (feedback['checkpointFeedbacks'] as Map?) ?? const {};
    final cpByNo = <int, Map>{};
    for (final v in cpFeedbacksMap.values) {
      final m = v as Map;
      cpByNo[(m['checkpointNo'] as num?)?.toInt() ?? cpByNo.length] = m;
    }

    // order from concept.conceptCheckpoints
    final cpOrder = ((concept['conceptCheckpoints'] as List?) ?? const [])
        .cast<Map>()
        .toList()
      ..sort((a, b) =>
          ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));

    // Mastery/confidence estimates for the summary card
    final cpMasteries = cpByNo.values
        .map((m) =>
            _pct(((m['progress'] as Map?)?['mastery'] as Map?)?['current']))
        .where((v) => v > 0)
        .toList();
    final double masteryAvg = cpMasteries.isEmpty
        ? 0
        : (cpMasteries.reduce((a, b) => a + b) / cpMasteries.length) / 100.0;

    double confidenceAvg = 0;
    int confCount = 0;
    for (final m in cpByNo.values) {
      final conv = (m['conversationFeedbacks'] as List?) ?? const [];
      if (conv.isNotEmpty) {
        final last = conv.last as Map;
        final c = last['confidenceScore'] as num?;
        if (c != null) {
          confidenceAvg += c.toDouble();
          confCount++;
        }
      }
    }
    confidenceAvg = confCount == 0 ? 0.0 : (confidenceAvg / confCount);

    // Gaps count for the summary
    // final gapsFound = complete["detailed"]["stillBuilding"].length;
    final gapsFound = cpByNo.values.fold<int>(
        0, (sum, m) => sum + ((m['unresolvedGaps'] as List?)?.length ?? 0));

    // One-liner headline
    final headline = (((feedback['completeLessonFeedback'] as Map?)?['detailed']
            as Map?)?['parentSummary'] as Map?)?['headline']
        ?.toString();
    final oneLiner = (headline != null && headline.trim().isNotEmpty)
        ? headline
        : 'Review in progress.';

    // Date for grouping
    final date = _day(_dateFromId(feedback['id']));

    // Build summary card
    final summary = ConceptSummary(
      id: conceptId,
      subject: subj,
      chapter: chapter,
      concept: conceptName,
      gapsFound: gapsFound,
      oneLiner: oneLiner,
      mastery: masteryAvg,
      confidence: _to01(confidenceAvg),
    );

    (byDay[date] ??= <ConceptSummary>[]).add(summary);

    // Build full overlay model
    final details = _buildConceptDetails(
      raw,
      conceptId: conceptId,
      conceptName: conceptName,
      subject: subj,
      chapter: chapter,
      cpOrder: cpOrder,
      cpByNo: cpByNo.map((k, v) => MapEntry(k.toString(), v)),
    );
    conceptDetails[conceptId] = details;

    // Student name if you have it elsewhere, keep default otherwise
    studentName = studentName;
  }

  // Convert date map → feed groups sorted desc
  final feedGroups = byDay.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));
  final feed =
      feedGroups.map((e) => FeedGroup(date: e.key, items: e.value)).toList();

  final subjects = ['All', ...subjectsSet.toList()];

  return DashboardData(
    student: Student(name: studentName, grade: grade.ifEmpty('')),
    feed: feed,
    conceptDetails: conceptDetails,
    studyStreak: studyStreak,
    parentPresenceStreak: parentPresenceStreak,
    bestWindow: bestWindow,
    subjects: subjects,
  );
}

extension on String {
  String ifEmpty(String alt) => isEmpty ? alt : this;
}
