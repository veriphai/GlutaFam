import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';
import 'section_header.dart';

class SubjectsSection extends StatelessWidget {
  final List<Subject> subjects;
  final Function(String) onSubjectTap;

  const SubjectsSection({
    super.key,
    required this.subjects,
    required this.onSubjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          icon: Icons.book_outlined,
          title: "Subjects",
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              return _buildSubjectPill(subjects[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectPill(Subject subject) {
    final color = _getSubjectColor(subject.name);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onSubjectTap(subject.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    subject.emoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subject.name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
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
}
