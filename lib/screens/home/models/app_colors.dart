import 'package:flutter/material.dart';

// Color scheme constants matching the React design
class AppColors {
  static const Color bg = Color(0xFFF6EDDA);
  static const Color card = Color(0xFFFFFBF2);
  static const Color ink = Color(0xFF0B1220);
  static const Color sub = Color(0xFF70695B);
  static const Color border = Color(0xFFE7DEC9);
  static const Color accent = Color(0xFF1D4ED8);
  static const Color searchBg = Color(0xFFEAF6EE);
  static const Color searchBorder = Color(0xFFCFE9DE);
}

// Subject colors mapping
class SubjectColors {
  static const Map<String, Color> colors = {
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

  static Color getColor(String subject) {
    return colors[subject.toLowerCase()] ?? AppColors.accent;
  }
}
