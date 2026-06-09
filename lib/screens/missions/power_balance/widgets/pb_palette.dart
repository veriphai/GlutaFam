// Episode-6 colour language, taken straight from the provided styleboard so the
// portrait build matches the mock's palette (PRD §20 colour coding).

import 'package:flutter/material.dart';
import '../../../../utils/s3_assets.dart';

class PBPalette {
  PBPalette._();

  static const spaceNavy = Color(0xFF0B1E3A);
  static const deepSpace = Color(0xFF0A1024);
  static const electricBlue = Color(0xFF2270FF);
  static const skyBlue = Color(0xFF70E0FF);
  static const solarGold = Color(0xFFFFCE20);
  static const warningRed = Color(0xFFFF4D4D);
  static const successGreen = Color(0xFF38E07B);
  static const cloudWhite = Color(0xFFF7FBFF);

  /// HUD/panel glass fill + border used across the chrome.
  static const panelFill = Color(0xCC0A1730);
  static const panelBorder = Color(0x3370E0FF);
}

/// Bounded [Image.asset] with an errorBuilder so a not-yet-served asset (web dev
/// server, first run after declaring the folder) degrades to nothing instead of
/// breaking the screen (playbook gotcha). [path] is a full assets/ path.
Widget pbImage(String path,
    {Key? key, double? width, double? height, BoxFit fit = BoxFit.contain}) {
  return SizedBox(
    key: key,
    width: width,
    height: height,
    child: netImageWidget(
      path,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  );
}
