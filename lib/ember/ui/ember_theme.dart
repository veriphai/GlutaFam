// Ember — ui/ember_theme.dart
//
// The module-local Flutter theme. SELF-CONTAINED: it reads colours/metrics from
// the same [EmberPalette]/[EmberMetrics] the Flame layer uses, so the HUD, build
// menu, dialogue, and codex share one tonal language with the canvas — WITHOUT
// importing the host app's theme (zero coupling). Exposed as a plain ThemeData
// factory plus a small set of text/decoration helpers the widgets read.

import 'package:flutter/material.dart';

import '../art/ember_palette.dart';

/// Builds the Ember [ThemeData] from a [palette] (defaults to the warm dusk).
ThemeData buildEmberTheme([EmberPalette palette = EmberPalette.dusk]) {
  final ColorScheme scheme = ColorScheme(
    brightness: Brightness.light,
    primary: palette.ember,
    onPrimary: Colors.white,
    secondary: palette.emberBright,
    onSecondary: palette.ink,
    error: palette.danger,
    onError: Colors.white,
    surface: palette.surface,
    onSurface: palette.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    fontFamily: null, // module ships no font; use the platform default.
    textTheme: _textTheme(palette),
    splashColor: palette.ember.withValues(alpha: 0.15),
    highlightColor: palette.ember.withValues(alpha: 0.08),
  );
}

TextTheme _textTheme(EmberPalette p) {
  TextStyle base(double size, FontWeight w, {Color? color}) => TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color ?? p.ink,
        height: 1.25,
      );
  return TextTheme(
    displaySmall: base(30, FontWeight.w800),
    headlineMedium: base(24, FontWeight.w800),
    headlineSmall: base(20, FontWeight.w700),
    titleLarge: base(18, FontWeight.w700),
    titleMedium: base(16, FontWeight.w700),
    bodyLarge: base(16, FontWeight.w500),
    bodyMedium: base(14, FontWeight.w500),
    bodySmall: base(12, FontWeight.w500, color: p.inkSoft),
    labelLarge: base(15, FontWeight.w700),
  );
}

/// Reusable UI metrics + decoration helpers (self-contained, no app import).
class EmberUi {
  const EmberUi._();

  static const double gap = 12.0;
  static const double gapS = 8.0;
  static const double gapL = 20.0;
  static const double radius = EmberMetrics.panelRadius;
  static const double radiusS = EmberMetrics.chipRadius;

  /// A soft rounded panel decoration (matches the Flame placeholder panels).
  /// A subtle top->bottom sheen + a layered drop shadow give the chrome a tactile,
  /// game-like "carved bone tablet" feel instead of a flat outlined rectangle.
  static BoxDecoration panel(
    EmberPalette p, {
    Color? fill,
    Color? border,
    double radius = EmberUi.radius,
    bool raised = false,
  }) {
    final Color base = fill ?? (raised ? p.surfaceRaised : p.surface);
    // A warm sheen at the top easing to a faintly darker base.
    final Color top = Color.lerp(base, Colors.white, 0.10) ?? base;
    final Color bottom = Color.lerp(base, p.outline, 0.07) ?? base;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[top, base, bottom],
        stops: const <double>[0.0, 0.45, 1.0],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: border ?? p.outline.withValues(alpha: 0.85),
        width: 1.5,
      ),
      boxShadow: raised
          ? <BoxShadow>[
              // A soft contact shadow...
              BoxShadow(
                color: p.shadow,
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              // ...plus a tight darker base for a grounded, layered lift.
              BoxShadow(
                color: p.shadow.withValues(alpha: 0.5),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ]
          : const <BoxShadow>[],
    );
  }

  /// A chip/pill decoration.
  static BoxDecoration chip(EmberPalette p, {Color? fill, Color? border}) {
    return BoxDecoration(
      color: fill ?? p.surfaceRaised,
      borderRadius: BorderRadius.circular(radiusS),
      border: Border.all(color: border ?? p.outline, width: 1.2),
    );
  }
}
