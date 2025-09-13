import 'package:flutter/material.dart';

class _DashboardExt extends ThemeExtension<_DashboardExt> {
  final Color accentTint;
  final Color muted;
  const _DashboardExt({required this.accentTint, required this.muted});
  @override
  _DashboardExt copyWith({Color? accentTint, Color? muted}) => _DashboardExt(
      accentTint: accentTint ?? this.accentTint, muted: muted ?? this.muted);
  @override
  ThemeExtension<_DashboardExt> lerp(
      ThemeExtension<_DashboardExt>? other, double t) {
    if (other is! _DashboardExt) return this;
    return _DashboardExt(
      accentTint: Color.lerp(accentTint, other.accentTint, t) ?? accentTint,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
    );
  }
}

// 👉 safe fallbacks even if extension isn't installed in your ThemeData
extension DashboardTheme on ThemeData {
  _DashboardExt get _dash =>
      extension<_DashboardExt>() ??
      const _DashboardExt(
        accentTint: Color(0xFFEDE8F8),
        muted: Color(0xFFF2F3F5),
      );
  Color get accentTint => _dash.accentTint;
  Color get mutedBg => _dash.muted;
}
