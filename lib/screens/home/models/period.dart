import 'package:flutter/material.dart';

class Period {
  final String id;
  final TimeOfDay start;
  final TimeOfDay end;
  final String subject; // e.g., "Physics"
  final String topic; // e.g., "Motion"
  final IconData icon; // subject glyph
  final Color accent; // topic color (green/blue etc.)
  final int weekdayIndex; // 1=Mon ... 7=Sun

  const Period({
    required this.id,
    required this.start,
    required this.end,
    required this.subject,
    required this.topic,
    required this.icon,
    required this.accent,
    required this.weekdayIndex,
  });
}
