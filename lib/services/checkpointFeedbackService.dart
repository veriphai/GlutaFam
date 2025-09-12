import 'package:eureka_app/apis/fetchCheckpointFeedback.dart';
import 'package:eureka_app/apis/updateLearningGapStatus.dart';

class CheckpointFeedbackService {
  static Future<CheckpointReport> getCheckpointFeedback({
    required String conceptConversations,
    required int checkpointNumber,
  }) async {
    try {
      final response = await fetchCheckpointFeedback(
        conceptConversationsKey: conceptConversations,
        checkpointNumber: checkpointNumber,
      );

      return CheckpointReport.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load checkpoint feedback: $e');
    }
  }

  static Future<bool> updateGapStatus({
    required String gapId,
    required bool resolved,
    String? chapterId,
    String? episodeId,
    String? checkpointId,
  }) async {
    try {
      final response = await updateLearningGapStatus(
        gapId: gapId,
        resolved: resolved,
        chapterId: chapterId,
        episodeId: episodeId,
        checkpointId: checkpointId,
      );

      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to update gap status: $e');
    }
  }
}

// Data Models with JSON serialization
class CheckpointReport {
  final String subject;
  final String title;
  final String checkpointTitle;
  final int timeSpentSec;
  final TurnsData turns;
  final String summary;
  final List<Objective> objectives;
  final List<LearningGap> gaps;
  final List<ShiningMoment> shining;
  final double clarity;
  final String clarityText;
  final double depth;
  final String depthText;
  final BoardDelta? boardDelta;
  final bool showAllGaps;

  CheckpointReport({
    required this.subject,
    required this.title,
    required this.checkpointTitle,
    required this.timeSpentSec,
    required this.turns,
    required this.summary,
    required this.objectives,
    required this.gaps,
    required this.shining,
    required this.clarity,
    required this.depth,
    required this.clarityText,
    required this.depthText,
    this.boardDelta,
    this.showAllGaps = false,
  });

  factory CheckpointReport.fromJson(Map<String, dynamic> json) {
    return CheckpointReport(
      subject: json['subject'] ?? '',
      title: json['title'] ?? '',
      checkpointTitle: json['checkpointTitle'] ?? '',
      timeSpentSec: json['timeSpentSec'] ?? 0,
      turns: TurnsData.fromJson(json['turns'] ?? {}),
      summary: json['summary'] ?? '',
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((obj) => Objective.fromJson(obj))
              .toList() ??
          [],
      gaps: (json['gaps'] as List<dynamic>?)
              ?.map((gap) => LearningGap.fromJson(gap))
              .toList() ??
          [],
      shining: (json['shining'] as List<dynamic>?)
              ?.map((moment) => ShiningMoment.fromJson(moment))
              .toList() ??
          [],
      clarity: (json['clarity'] ?? 0).toDouble(),
      clarityText: json['clarityText'] ?? '',
      depthText: json['depthText'] ?? '',
      depth: (json['depth'] ?? 0).toDouble(),
      boardDelta: json['boardDelta'] != null
          ? BoardDelta.fromJson(json['boardDelta'])
          : null,
      showAllGaps: json['showAllGaps'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'title': title,
      'checkpointTitle': checkpointTitle,
      'timeSpentSec': timeSpentSec,
      'turns': turns.toJson(),
      'summary': summary,
      'objectives': objectives.map((obj) => obj.toJson()).toList(),
      'gaps': gaps.map((gap) => gap.toJson()).toList(),
      'shining': shining.map((moment) => moment.toJson()).toList(),
      'clarity': clarity,
      'depth': depth,
      'boardDelta': boardDelta?.toJson(),
      'showAllGaps': showAllGaps,
    };
  }

  CheckpointReport copyWith({
    String? subject,
    String? title,
    String? checkpointTitle,
    int? timeSpentSec,
    TurnsData? turns,
    String? summary,
    List<Objective>? objectives,
    List<LearningGap>? gaps,
    List<ShiningMoment>? shining,
    double? clarity,
    double? depth,
    BoardDelta? boardDelta,
    bool? showAllGaps,
  }) {
    return CheckpointReport(
      subject: subject ?? this.subject,
      title: title ?? this.title,
      checkpointTitle: checkpointTitle ?? this.checkpointTitle,
      timeSpentSec: timeSpentSec ?? this.timeSpentSec,
      turns: turns ?? this.turns,
      summary: summary ?? this.summary,
      objectives: objectives ?? this.objectives,
      gaps: gaps ?? this.gaps,
      shining: shining ?? this.shining,
      clarity: clarity ?? this.clarity,
      depth: depth ?? this.depth,
      clarityText: clarityText ?? this.clarityText,
      depthText: depthText ?? this.depthText,
      boardDelta: boardDelta ?? this.boardDelta,
      showAllGaps: showAllGaps ?? this.showAllGaps,
    );
  }
}

class TurnsData {
  final int student;
  final int assistant;
  final int hints;

  TurnsData({
    required this.student,
    required this.assistant,
    required this.hints,
  });

  factory TurnsData.fromJson(Map<String, dynamic> json) {
    return TurnsData(
      student: json['student'] ?? 0,
      assistant: json['assistant'] ?? 0,
      hints: json['hints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student': student,
      'assistant': assistant,
      'hints': hints,
    };
  }
}

class Objective {
  final String id;
  final String text;
  final double score;
  final String evidence;
  final bool open;

  Objective({
    required this.id,
    required this.text,
    required this.score,
    required this.evidence,
    this.open = false,
  });

  factory Objective.fromJson(Map<String, dynamic> json) {
    return Objective(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      evidence: json['evidence'] ?? '',
      open: json['open'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'score': score,
      'evidence': evidence,
      'open': open,
    };
  }

  Objective copyWith({bool? open}) {
    return Objective(
      id: id,
      text: text,
      score: score,
      evidence: evidence,
      open: open ?? this.open,
    );
  }
}

class LearningGap {
  final String id;
  final String type;
  final String title;
  final int severity;
  final String evidence;
  final String fix;
  final String action;
  final bool resolved;

  LearningGap({
    required this.id,
    required this.type,
    required this.title,
    required this.severity,
    required this.evidence,
    required this.fix,
    required this.action,
    this.resolved = false,
  });

  factory LearningGap.fromJson(Map<String, dynamic> json) {
    return LearningGap(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      severity: json['severity'] ?? 0,
      evidence: json['evidence'] ?? '',
      fix: json['fix'] ?? '',
      action: json['action'] ?? '',
      resolved: json['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'severity': severity,
      'evidence': evidence,
      'fix': fix,
      'action': action,
      'resolved': resolved,
    };
  }

  LearningGap copyWith({bool? resolved}) {
    return LearningGap(
      id: id,
      type: type,
      title: title,
      severity: severity,
      evidence: evidence,
      fix: fix,
      action: action,
      resolved: resolved ?? this.resolved,
    );
  }
}

class ShiningMoment {
  final String type;
  final String quote;

  ShiningMoment({
    required this.type,
    required this.quote,
  });

  factory ShiningMoment.fromJson(Map<String, dynamic> json) {
    return ShiningMoment(
      type: json['type'] ?? '',
      quote: json['quote'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'quote': quote,
    };
  }
}

class BoardDelta {
  final List<String> added;
  final List<String> removed;

  BoardDelta({
    required this.added,
    required this.removed,
  });

  factory BoardDelta.fromJson(Map<String, dynamic> json) {
    return BoardDelta(
      added: List<String>.from(json['added'] ?? []),
      removed: List<String>.from(json['removed'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'added': added,
      'removed': removed,
    };
  }
}
