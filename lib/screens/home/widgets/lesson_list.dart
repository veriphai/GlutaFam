import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';

class LessonList extends StatelessWidget {
  final List<LessonData> lessons;
  final bool showProgress;
  final Function(LessonData) onLessonTap;

  const LessonList({
    super.key,
    required this.lessons,
    required this.showProgress,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildLessonListItem(lessons[i]),
    );
  }

  Widget _buildLessonListItem(LessonData lesson) {
    final color = _getSubjectColor(lesson.subject);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getSubjectEmoji(lesson.subject),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${lesson.subject} • ${lesson.chapter} • ${lesson.topic}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text("${lesson.minutes} mins",
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.ink)),
                        const Spacer(),
                        // Start discussion pill
                        GestureDetector(
                          onTap: () => onLessonTap(lesson),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                lesson.resumeLesson == true
                                    ? 'Resume discussion'
                                    : lesson.completed == true
                                        ? 'View discussion'
                                        : 'Start discussion',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showProgress) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: lesson.progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (lesson.progress > 0)
                        Text(
                          "${(lesson.progress * 100).round()}% complete",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.sub),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    const colors = {
      'mathematics': Color(0xFF1D4ED8),
      'physics': Color(0xFF0EA5E9),
      'chemistry': Color(0xFF10B981),
      'biology': Color(0xFF84CC16),
      'history': Color(0xFFF59E0B),
      'geography': Color(0xFF8B5CF6),
      'english': Color(0xFFEC4899),
      'science': Color(0xFF10B981),
      'maths': Color(0xFF1D4ED8),
    };
    return colors[subject.toLowerCase()] ?? AppColors.accent;
  }

  String _getSubjectEmoji(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'maths':
        return "🧮";
      case 'physics':
        return "🧲";
      case 'chemistry':
        return "⚗️";
      case 'biology':
        return "🧬";
      case 'science':
        return "🔬";
      case 'history':
        return "🏺";
      case 'geography':
        return "🗺️";
      case 'english':
        return "📚";
      default:
        return "📘";
    }
  }
}
