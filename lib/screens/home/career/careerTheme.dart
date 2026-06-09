// Design tokens for the career-discovery homepage.
// Colours, gradients, radii, spacing and text styles live here so the rest of
// the feature stays free of magic numbers and is trivial to re-theme.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CareerColors {
  CareerColors._();

  // Cosmic background
  static const bgTop = Color(0xFF081B3F);
  static const bgMid = Color(0xFF07162F);
  static const bgBottom = Color(0xFF0B1028);

  // Accents
  static const purple = Color(0xFF7C4DFF);
  static const blue = Color(0xFF00B8FF);
  static const gold = Color(0xFFFFC83D);
  static const cyan = Color(0xFF18D6FF);
  static const green = Color(0xFF65D65E);
  static const pink = Color(0xFFB45CFF);
  static const orange = Color(0xFFFF8A3D);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA9B4E6);
  static const textMuted = Color(0xFF7E8AC0);
  static const onLight = Color(0xFF1A1340); // dark navy text on bright cards

  // Glass surfaces
  static const glassFill = Color(0x14FFFFFF); // white @ 8%
  static const glassFillStrong = Color(0x1FFFFFFF); // white @ 12%
  static const glassBorder = Color(0x26FFFFFF); // white @ 15%
}

class CareerGradients {
  CareerGradients._();

  static const page = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [CareerColors.bgTop, CareerColors.bgMid, CareerColors.bgBottom],
  );

  static const heroBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [CareerColors.purple, CareerColors.blue],
  );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD25E), Color(0xFFFFB020)],
  );

  static const challenge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC444), Color(0xFFFF9A3D)],
  );

  static const challengeCta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF7A3D), Color(0xFFFF4D6D)],
  );

  static const passport = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA98CF2), Color(0xFF7C5BD6)],
  );
}

class CareerRadii {
  CareerRadii._();
  static const card = 24.0;
  static const smallCard = 20.0;
  static const pill = 30.0;
  static const chip = 12.0;
}

class CareerSpace {
  CareerSpace._();
  static const page = 16.0;
  static const section = 26.0;
  static const gap = 12.0;
}

class CareerText {
  CareerText._();

  static final greeting = GoogleFonts.poppins(
      fontSize: 16.5, fontWeight: FontWeight.w800, color: CareerColors.textPrimary, height: 1.05);
  static final subtitle = GoogleFonts.poppins(
      fontSize: 10.5, fontWeight: FontWeight.w500, color: CareerColors.textSecondary);
  static final sectionTitle = GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w800, color: CareerColors.textPrimary);
  static final heroTitle = GoogleFonts.poppins(
      fontSize: 22, fontWeight: FontWeight.w800, color: CareerColors.textPrimary, height: 1.02);
  static final cardTitle = GoogleFonts.poppins(
      fontSize: 12.5, fontWeight: FontWeight.w700, color: CareerColors.textPrimary);
  static final cardTitleLg = GoogleFonts.poppins(
      fontSize: 13.5, fontWeight: FontWeight.w800, color: CareerColors.textPrimary);
  static final worldLabel = GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600);
  static final body = GoogleFonts.poppins(
      fontSize: 10, fontWeight: FontWeight.w500, color: CareerColors.textSecondary, height: 1.3);
  static final label = GoogleFonts.poppins(
      fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: CareerColors.textPrimary);
  static final cta = GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700);
  static final statValue = GoogleFonts.poppins(
      fontSize: 12.5, fontWeight: FontWeight.w800, color: CareerColors.textPrimary);
  static final statLabel = GoogleFonts.poppins(
      fontSize: 8.5, fontWeight: FontWeight.w600, color: CareerColors.textSecondary);
  static final chip = GoogleFonts.poppins(
      fontSize: 9, fontWeight: FontWeight.w600, color: CareerColors.textPrimary);
  static final navLabel = GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600);
}
