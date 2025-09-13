import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';

class SubjectFilterBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> allowedSubjectIds;
  final List<Subject> subjects;
  final Function(String) onFilterClicked;

  const SubjectFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.allowedSubjectIds,
    required this.subjects,
    required this.onFilterClicked,
  });

  @override
  Widget build(BuildContext context) {
    final allowedSubjects =
        subjects.where((s) => allowedSubjectIds.contains(s.id)).toList();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: "All",
            isSelected: value == "all",
            onTap: () {
              onChanged("all");
              onFilterClicked("all");
            },
          ),
          ...allowedSubjects.map((subject) => _buildFilterChip(
                label: subject.name,
                isSelected: value == subject.id,
                onTap: () {
                  onChanged(subject.id);
                  onFilterClicked(subject.name);
                },
                color: _getSubjectColor(subject.name),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? (color ?? AppColors.accent) : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
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
