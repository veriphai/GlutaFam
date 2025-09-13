import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';
import 'chapter_list.dart';

class SubjectChaptersOverlay extends StatelessWidget {
  final String subjectId;
  final List<Subject> subjects;
  final List<dynamic> allChapters;
  final Function(ChapterData) onChapterTap;
  final VoidCallback onClose;

  const SubjectChaptersOverlay({
    super.key,
    required this.subjectId,
    required this.subjects,
    required this.allChapters,
    required this.onChapterTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final subj = subjects.firstWhere((s) => s.id == subjectId,
        orElse: () => subjects.first);

    // Filter chapters from allChapters data by subject
    final subjectChapters = allChapters.where((chapter) {
      final chapterSubject = chapter['subject']?.toString().toLowerCase() ?? '';
      final targetSubject = subj.name.toLowerCase();
      // Handle common subject name variations
      return chapterSubject == targetSubject ||
          (targetSubject == 'maths' && chapterSubject == 'mathematics') ||
          (targetSubject == 'mathematics' && chapterSubject == 'maths');
    }).toList();

    // Convert to ChapterData objects
    final chapterList = subjectChapters.map((chapterData) {
      final totalLessons = _countTotalLessonsInChapter(chapterData);

      return ChapterData(
        key: '${subjectId}::${chapterData['name']}',
        subjectId: subjectId,
        subject: chapterData['subject'] ?? '',
        chapter: chapterData['name'] ?? '',
        total: totalLessons,
        completed: 0, // We don't have completion data from allChapters
        inProgress: 0, // We don't have progress data from allChapters
      );
    }).toList();

    return Positioned.fill(
      child: Material(
        color: AppColors.bg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text('${subj.emoji} ${subj.name}',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: ChapterList(
                    chapters: chapterList,
                    onChapterTap: onChapterTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countTotalLessonsInChapter(Map<String, dynamic> chapterData) {
    int totalLessons = 0;
    if (chapterData['topics'] != null) {
      for (final topic in chapterData['topics']) {
        if (topic['lessons'] != null) {
          totalLessons += (topic['lessons'] as List).length;
        }
      }
    }
    return totalLessons;
  }
}
