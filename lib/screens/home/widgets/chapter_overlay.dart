import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';
import 'lesson_list.dart';

class ChapterOverlay extends StatelessWidget {
  final Map<String, String> chapterView;
  final List<Subject> subjects;
  final List<dynamic> allChapters;
  final Function(LessonData) onLessonTap;
  final VoidCallback onClose;
  final String Function(String) getSubjectIdByName;
  final double Function(dynamic, dynamic) calculateProgress;

  const ChapterOverlay({
    super.key,
    required this.chapterView,
    required this.subjects,
    required this.allChapters,
    required this.onLessonTap,
    required this.onClose,
    required this.getSubjectIdByName,
    required this.calculateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final subjectId = chapterView['subjectId']!;
    final subjectName = chapterView['subject']!;
    final chapterName = chapterView['chapter']!;
    final subj = subjects.firstWhere((s) => s.id == subjectId,
        orElse: () => subjects.first);

    final Map<String, List<LessonData>> byTopic = {};

    // Find the matching chapter in allChapters
    final matchingChapter = allChapters.firstWhere(
      (chapter) =>
          chapter['name'] == chapterName && chapter['subject'] == subjectName,
      orElse: () => <String, dynamic>{},
    );

    if (matchingChapter.isNotEmpty && matchingChapter['topics'] != null) {
      for (final topic in matchingChapter['topics']) {
        final topicName = topic['name'] ?? '';
        final lessons = topic['lessons'] ?? [];
        if (lessons.isNotEmpty) {
          // Convert raw lesson data to LessonData objects
          final lessonDataList = lessons.map<LessonData>((lessonData) {
            return LessonData(
              id: lessonData['id']?.toString() ?? '',
              name: lessonData['name'] ?? '',
              subjectId: getSubjectIdByName(subjectName),
              subject: subjectName,
              chapter: chapterName,
              topic: topicName,
              minutes: int.tryParse(
                      lessonData['expectedCompletionTime']?.toString() ??
                          '15') ??
                  15,
              recommended: false,
              fromParent: false,
              progress: calculateProgress(lessonData['checkpointsCompleted'],
                  lessonData['totalCheckpoints']),
              recommendationReason: null,
              priorityScore: null,
              checkpointsCompleted: lessonData['checkpointsCompleted'] ?? 0,
              conceptConversationKey:
                  lessonData['conceptConversationKey'] ?? '',
              checkpointNo: lessonData['checkpointNo'] ?? 0,
              learningObjectivesStatus:
                  lessonData['learningObjectivesStatus'] ?? {},
              newCheckpointStarted: lessonData['newCheckpointStarted'] ?? false,
              timeRemaining: lessonData['timeRemaining'] ?? 0,
              resumeLesson: lessonData['canResume'] ?? false,
              completed: lessonData['completionStatus'] ?? false,
            );
          }).toList();
          byTopic[topicName] = lessonDataList;
        }
      }
    }

    return Positioned.fill(
      child: Material(
        color: AppColors.bg,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text('${subj.emoji} $subjectName',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(chapterName,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: AppColors.sub)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in byTopic.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(entry.key,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                        ),
                        LessonList(
                          lessons: entry.value,
                          showProgress: true,
                          onLessonTap: onLessonTap,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (byTopic.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                              child: Text('No lessons yet.',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: AppColors.sub))),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
