import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';
import 'lesson_list.dart';
import 'chapter_list.dart';
import 'subject_filter_bar.dart';

class ViewAllOverlay extends StatefulWidget {
  final String section;
  final List<LessonData> lessons;
  final List<ChapterData> chapters;
  final List<Subject> subjects;
  final Function(LessonData) onLessonTap;
  final Function(ChapterData) onChapterTap;
  final VoidCallback onClose;
  final Function(String) onFilterClicked;

  const ViewAllOverlay({
    super.key,
    required this.section,
    required this.lessons,
    required this.chapters,
    required this.subjects,
    required this.onLessonTap,
    required this.onChapterTap,
    required this.onClose,
    required this.onFilterClicked,
  });

  @override
  State<ViewAllOverlay> createState() => _ViewAllOverlayState();
}

class _ViewAllOverlayState extends State<ViewAllOverlay> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    // Handle chapters separately
    if (widget.section == 'continue_chapters') {
      return _buildViewAllChaptersOverlay();
    }

    List<LessonData> all;
    if (widget.section == 'continue') {
      all = widget.lessons
          .where((l) => l.progress > 0 && l.progress < 1)
          .toList();
    } else if (widget.section == 'recommended') {
      all = widget.lessons.where((l) => l.recommended).toList();
    } else if (widget.section == 'parents') {
      all = widget.lessons.where((l) => l.fromParent).toList();
    } else {
      all = widget.lessons;
    }

    final allowedIds = all.map((l) => l.subjectId).toSet().toList();

    final title = widget.section == 'continue'
        ? 'Continue learning'
        : widget.section == 'recommended'
            ? 'Recommended for you'
            : widget.section == 'parents'
                ? 'From parents'
                : 'All lessons';

    final list = filter == 'all'
        ? all
        : all.where((l) => l.subjectId == filter).toList();
    final bool showProg = widget.section != 'parents';

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
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SubjectFilterBar(
                  value: filter,
                  onChanged: (v) => setState(() => filter = v),
                  allowedSubjectIds: allowedIds,
                  subjects: widget.subjects,
                  onFilterClicked: widget.onFilterClicked,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: LessonList(
                    lessons: list,
                    showProgress: showProg,
                    onLessonTap: widget.onLessonTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllChaptersOverlay() {
    final allChapters = widget.chapters;
    final allowedIds = allChapters.map((c) => c.subjectId).toSet().toList();

    final list = filter == 'all'
        ? allChapters
        : allChapters.where((c) => c.subjectId == filter).toList();

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
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Continue chapters',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SubjectFilterBar(
                  value: filter,
                  onChanged: (v) => setState(() => filter = v),
                  allowedSubjectIds: allowedIds,
                  subjects: widget.subjects,
                  onFilterClicked: widget.onFilterClicked,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: ChapterList(
                    chapters: list,
                    onChapterTap: widget.onChapterTap,
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
