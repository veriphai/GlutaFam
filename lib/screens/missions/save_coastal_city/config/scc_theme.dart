// Episode-11 (FINAL BOSS) colour language + shared text styles, taken straight
// from the locked styleboard: cinematic dark space-blue mission-control,
// glowing cyan holographic accents; green = success/lock/stable, amber =
// caution/active, red/orange = danger/thermal (PRD §6, §23).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/s3_assets.dart';

class SccColors {
  SccColors._();

  // backgrounds
  static const deepSpace = Color(0xFF050B18);
  static const spaceNavy = Color(0xFF081B3F);
  static const panelNavy = Color(0xFF0A1730);

  // accents (styleboard §01)
  static const cyan = Color(0xFF2FD9FF);
  static const cyanDim = Color(0xFF1A7FA8);
  static const blue = Color(0xFF2270FF);
  static const success = Color(0xFF35E07B);
  static const warningAmber = Color(0xFFFFB020);
  static const alertRed = Color(0xFFFF4D4D);
  static const thermalOrange = Color(0xFFFF7A30);
  static const purple = Color(0xFFB05CFF);
  static const white = Color(0xFFF7FBFF);
  static const textSecondary = Color(0xFFA9B4E6);
  static const textMuted = Color(0xFF7E8AC0);

  // glass panel chrome reused across the mission UI
  static const panelFill = Color(0xCC0A1730);
  static const panelBorder = Color(0x3370E0FF);
}

class SccText {
  SccText._();

  /// Big stage titles — the styleboard asks for a squared sci-fi display face
  /// (Orbitron) for stage titles, rounded friendly body (Poppins, the house
  /// font) for instructions.
  static final missionTitle = GoogleFonts.orbitron(
      fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2,
      color: SccColors.white);
  static final stageTitle = GoogleFonts.orbitron(
      fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.1,
      color: SccColors.cyan);
  static final chip = GoogleFonts.poppins(
      fontSize: 10.5, fontWeight: FontWeight.w700, color: SccColors.white);
  static final body = GoogleFonts.poppins(
      fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.35,
      color: SccColors.white);
  static final dialogue = GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w600, height: 1.3,
      color: SccColors.white);
  static final label = GoogleFonts.poppins(
      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4,
      color: SccColors.textSecondary);
  static final cta = GoogleFonts.poppins(
      fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.6,
      color: SccColors.white);
  static final nodeLabel = GoogleFonts.poppins(
      fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.1,
      color: SccColors.white);
  static final meterValue = GoogleFonts.orbitron(
      fontSize: 14, fontWeight: FontWeight.w800, color: SccColors.white);
}

/// Standard glass-panel decoration (rounded + cyan hairline + soft glow).
BoxDecoration sccPanel({Color? borderColor, double radius = 18}) {
  return BoxDecoration(
    color: SccColors.panelFill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? SccColors.panelBorder, width: 1.2),
    boxShadow: [
      BoxShadow(
        color: (borderColor ?? SccColors.cyan).withValues(alpha: 0.10),
        blurRadius: 18,
        spreadRadius: 1,
      ),
    ],
  );
}

/// Edge vignette that seats floating chrome over a full-bleed scene — drop as
/// a Positioned.fill IgnorePointer layer between the scene and its panels.
Widget sceneVignette({double strength = 0.55, Color? color}) {
  return IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.25,
          colors: [
            Colors.transparent,
            (color ?? SccColors.deepSpace).withValues(alpha: strength),
          ],
          stops: const [0.62, 1.0],
        ),
      ),
    ),
  );
}

/// Bounded S3-backed image with an errorBuilder so a not-yet-served asset
/// degrades to nothing instead of breaking the screen (playbook gotcha).
/// [path] is a full `assets/images/...` path (use SCC.flutter).
Widget sccImage(String path,
    {Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode}) {
  return SizedBox(
    key: key,
    width: width,
    height: height,
    child: netImageWidget(
      path,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  );
}
