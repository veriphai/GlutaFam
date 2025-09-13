import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';

class ChapterList extends StatelessWidget {
  final List<ChapterData> chapters;
  final Function(ChapterData) onChapterTap;

  const ChapterList({
    super.key,
    required this.chapters,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildChapterListItem(chapters[index]);
      },
    );
  }

  Widget _buildChapterListItem(ChapterData chapter) {
    final color = _getSubjectColor(chapter.subject);
    final progress =
        chapter.total == 0 ? 0.0 : chapter.completed / chapter.total;

    return GestureDetector(
      onTap: () => onChapterTap(chapter),
      child: Container(
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
                      _getSubjectEmoji(chapter.subject),
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
                        chapter.chapter,
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
                        "${chapter.subject} • ${chapter.completed}/${chapter.total} lessons completed",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.sub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (progress > 0)
                        Text(
                          "${(progress * 100).round()}% complete",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.sub,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
