import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/models/app_colors.dart';
import '../home/models/home_data_models.dart';
import '../aiTutor/aiTutorScreenV2.dart';

class JourneyTasksScreen extends StatefulWidget {
  final JourneyData journey;

  const JourneyTasksScreen({
    super.key,
    required this.journey,
  });

  @override
  State<JourneyTasksScreen> createState() => _JourneyTasksScreenState();
}

class _JourneyTasksScreenState extends State<JourneyTasksScreen> {
  List<TaskData> allTasks = [];

  @override
  void initState() {
    super.initState();
    _extractTasks();
  }

  void _extractTasks() {
    allTasks.clear();

    // Extract tasks from weekly plan
    for (final week in widget.journey.weeklyPlan) {
      final days = week['days'] as List<dynamic>? ?? [];
      for (final day in days) {
        final tasks = day['tasks'] as List<dynamic>? ?? [];
        for (final taskData in tasks) {
          allTasks.add(TaskData(
            id: taskData['id'] ?? '',
            title: taskData['title'] ?? '',
            description: taskData['description'] ?? '',
            type: taskData['type'] ?? '',
            chapterId: taskData['chapterId'] ?? '',
            conceptId: taskData['conceptId'] ?? '',
            journeyId: taskData['journeyId'] ?? '',
            estimatedMinutes: taskData['estimatedMinutes'] ?? 0,
            difficulty: taskData['difficulty'] ?? '',
            instructions: taskData['instructions'] ?? '',
            status: taskData['status'] ?? 'TODO',
            order: taskData['order'] ?? 0,
            metadata: taskData['metadata'] ?? {},
          ));
        }
      }
    }

    // Sort tasks by order
    allTasks.sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.journey.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Journey Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.journey.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.journey.status,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(widget.journey.status),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${widget.journey.progress['completed']}/${widget.journey.progress['total']} completed",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.sub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.journey.subjectId.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (widget.journey.progress['percentage'] as num?)
                            ?.toDouble() ??
                        0.0 / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tasks Section
            Text(
              "Tasks (${allTasks.length})",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),

            // Tasks List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = allTasks[index];
                return _buildTaskCard(task);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskData task) {
    return GestureDetector(
      onTap: () => _onTaskTap(task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Task Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTaskTypeColor(task.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.type,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getTaskTypeColor(task.type),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Task Title
            Text(
              task.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),

            // Task Description
            Text(
              task.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.sub,
              ),
            ),
            const SizedBox(height: 8),

            // Task Footer
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.sub,
                ),
                const SizedBox(width: 4),
                Text(
                  "${task.estimatedMinutes} min",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.sub,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.star,
                  size: 14,
                  color: AppColors.sub,
                ),
                const SizedBox(width: 4),
                Text(
                  task.difficulty,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.sub,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.sub,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTaskTap(TaskData task) {
    // Navigate to AI Tutor screen with the concept ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AITutorScreenV2(
          conceptId: task.conceptId,
          conceptName: task.title,
          chapterName: task.chapterId,
          maxXP: 45,
          name: 'Student', // You might want to get this from user profile
          subject: widget.journey.subjectId,
          standard: 8, // You might want to get this from user profile
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'STARTED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'PAUSED':
        return Colors.orange;
      case 'TODO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTaskTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'ASSESSMENT':
        return Colors.red;
      case 'READING':
        return Colors.blue;
      case 'CONCEPT_REVIEW':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
