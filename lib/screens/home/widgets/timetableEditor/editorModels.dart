import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final IconData icon;
  final Color color; // accent for the subject
  const Subject(
      {required this.id,
      required this.name,
      required this.icon,
      required this.color});
}

class Chapter {
  final String id;
  final String subjectId;
  final String name;
  const Chapter(
      {required this.id, required this.subjectId, required this.name});
}

class PeriodDraft {
  final int index; // 1-based display number
  final String? subjectId; // null until chosen
  final String? chapterId; // null until chosen
  const PeriodDraft({required this.index, this.subjectId, this.chapterId});

  PeriodDraft copyWith({int? index, String? subjectId, String? chapterId}) =>
      PeriodDraft(
          index: index ?? this.index,
          subjectId: subjectId ?? this.subjectId,
          chapterId: chapterId ?? this.chapterId);
}
