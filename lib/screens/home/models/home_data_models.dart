// Subject data model
class Subject {
  final String id;
  final String name;
  final String emoji;

  const Subject({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

// Lesson data model
class LessonData {
  final String id;
  final String name;
  final String subjectId;
  final String subject;
  final String chapter;
  final String topic;
  final int minutes;
  final bool recommended;
  final bool fromParent;
  final double progress;
  final String? recommendationReason;
  final double? priorityScore;
  final int? checkpointsCompleted;
  final String? conceptConversationKey;
  final int? checkpointNo;
  final Map<String, dynamic>? learningObjectivesStatus;
  final bool? newCheckpointStarted;
  final int? timeRemaining;
  final bool? resumeLesson;
  final bool? completed;

  const LessonData({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.minutes,
    this.recommended = false,
    this.fromParent = false,
    this.progress = 0.0,
    this.recommendationReason,
    this.priorityScore,
    this.checkpointsCompleted,
    this.conceptConversationKey,
    this.checkpointNo,
    this.learningObjectivesStatus,
    this.newCheckpointStarted,
    this.timeRemaining,
    this.resumeLesson,
    this.completed,
  });
}

// Chapter data model
class ChapterData {
  final String key;
  final String subjectId;
  final String subject;
  final String chapter;
  final int total;
  final int completed;
  final int inProgress;

  const ChapterData({
    required this.key,
    required this.subjectId,
    required this.subject,
    required this.chapter,
    required this.total,
    required this.completed,
    required this.inProgress,
  });
}
