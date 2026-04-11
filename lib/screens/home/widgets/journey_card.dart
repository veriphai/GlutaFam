import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';
import '../models/home_data_models.dart';

class JourneyCard extends StatelessWidget {
  final JourneyData journey;
  final VoidCallback onTap;

  const JourneyCard({
    super.key,
    required this.journey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
        (journey.progress['percentage'] as num?)?.toDouble() ?? 0.0;
    final completed = journey.progress['completed'] as int? ?? 0;
    final total = journey.progress['total'] as int? ?? 0;
    final currentWeek = journey.progress['currentWeek'] as int? ?? 1;
    final currentDay = journey.progress['currentDay'] as int? ?? 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Journey Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(journey.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    journey.status,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(journey.status),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Journey Title
            Text(
              journey.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),

            // Subject and Mode
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    journey.subjectId.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  journey.mode.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.sub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Section
            if (total > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.sub,
                    ),
                  ),
                  Text(
                    "$completed/$total tasks",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressPercentage > 0 ? Colors.green : Colors.grey,
                ),
                minHeight: 4,
              ),
              const SizedBox(height: 8),
            ],

            // Current Position
            Row(
              children: [
                Icon(
                  Icons.today,
                  size: 14,
                  color: AppColors.sub,
                ),
                const SizedBox(width: 4),
                Text(
                  "Week $currentWeek, Day $currentDay",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.sub,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'PAUSED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
