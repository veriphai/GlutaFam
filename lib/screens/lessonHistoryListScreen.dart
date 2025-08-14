// lib/screens/resume_lessons_page.dart
import 'dart:convert';
import 'package:eureka_app/apis/fetchLessonHistoryList.dart';
import 'package:eureka_app/apis/resumeConcept.dart';
import 'package:eureka_app/screens/conceptLearningV4.dart';
import 'package:eureka_app/screens/viewLessonHistoryScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/authTokenService.dart';

class LessonHistory {
  final String conceptId;
  final String conceptName;
  final bool completionStatus; // false => resumable
  final int checkpointsCompleted;
  final int timeRemaining; // assume seconds or minutes from API
  final String? conceptConversationKey;
  final int checkpointNo;
  final Map<String, dynamic>? learningObjectivesStatus;
  final bool newCheckpointStarted;

  LessonHistory(
      {required this.conceptId,
      required this.conceptName,
      required this.completionStatus,
      required this.checkpointsCompleted,
      required this.timeRemaining,
      this.conceptConversationKey,
      required this.checkpointNo,
      required this.learningObjectivesStatus,
      required this.newCheckpointStarted});

  factory LessonHistory.fromJson(Map<String, dynamic> j) => LessonHistory(
      conceptId: j['conceptId'] as String,
      conceptName: j['conceptName'] as String,
      completionStatus: (j['completionStatus'] as bool?) ?? false,
      checkpointsCompleted: (j['checkpointsCompleted'] as num?)?.toInt() ?? 0,
      timeRemaining: (j['remainingTime'] as num?)?.toInt() ?? 0,
      conceptConversationKey: j['conceptConversationKey'] as String?,
      newCheckpointStarted: (j['newCheckpointStarted'] as bool?) ?? false,
      checkpointNo: (j['checkpointNo'] as num?)?.toInt() ?? 0,
      learningObjectivesStatus: (j['learningObjectivesStatus'] is Map)
          ? Map<String, dynamic>.from(j['learningObjectivesStatus'])
          : null);
}

class ResumeLessonsPage extends StatefulWidget {
  const ResumeLessonsPage({super.key});

  @override
  State<ResumeLessonsPage> createState() => _ResumeLessonsPageState();
}

class _ResumeLessonsPageState extends State<ResumeLessonsPage> {
  late Future<List<LessonHistory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchResumableLessons();
  }

  Future<List<LessonHistory>> _fetchResumableLessons() async {
    final data =
        await fetchLessonHistoryList(onlyIncompleteLessons: false.toString());
    return data
        .map((e) => LessonHistory.fromJson(e as Map<String, dynamic>))
        // .where((l) => !l.completionStatus) // extra safety
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchResumableLessons());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume your lessons')),
      body: FutureBuilder<List<LessonHistory>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}'),
            );
          }
          final lessons = snap.data ?? const [];
          if (lessons.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No resumable lessons 🎉')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final l = lessons[i];

                // If `timeRemaining` is seconds on server, convert to min here.
                final mins = l.timeRemaining ~/ 60; // adapt if needed
                final subtitle =
                    'Checkpoints: ${l.checkpointsCompleted} • ~${mins} min left';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.conceptName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              if (l.completionStatus) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewLessonHistory(
                                      conceptId: l.conceptId,
                                      conceptName: l.conceptName,
                                      conceptConversationsKey:
                                          l.conceptConversationKey ?? "",
                                    ),
                                  ),
                                );
                              } else {
                                final datatoResumeConcept = await resumeConcept(
                                    conceptId: l.conceptId,
                                    checkpointsCompleted:
                                        l.checkpointsCompleted,
                                    conceptConversationsKey:
                                        l.conceptConversationKey ?? "",
                                    checkpointNo: l.checkpointNo,
                                    learningObjectivesStatus:
                                        l.learningObjectivesStatus,
                                    newCheckpointStarted:
                                        l.newCheckpointStarted,
                                    remainingTime: l.timeRemaining);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ConceptLearningScreenV4(
                                      conceptId: l.conceptId,
                                      conceptName: l.conceptName,
                                      maxXP: 45,
                                      name: "Shubham",
                                      subject: "Science",
                                      standard: 8,
                                      resumeLesson: true,
                                      dataToResume: datatoResumeConcept,
                                    ),
                                  ),
                                );
                              }
                              // Navigator.pushNamed(context, '/lesson', arguments: {...});
                            },
                            child: Text(
                                l.completionStatus ? 'view history' : 'Resume'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
