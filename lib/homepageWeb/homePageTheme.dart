import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color.fromRGBO(2, 6, 24, 1.0); // deep slate
  static const panel = Color.fromRGBO(255, 255, 255, 0.05); // white/5-ish
  static const border = Color(0x1AFFFFFF); // white/10
  static const text = Color(0xFFE6EDF5);
  static const subtext = Color(0xFFCAD5E2);
  static const teal = Color(0xE55EEAD4);
  static const cyan = Color(0xFF0891B2);
  static const indigo = Color(0xFF6366F1);
  static const tealV2 = Color(0xFF86EFE1);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.teal,
        secondary: AppColors.cyan,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      dividerColor: AppColors.border,
    );
  }
}

/// Common paddings and a max content width similar to 7xl
class AppLayout {
  static const double maxWidth = 1200;
  static EdgeInsets sectionPadding(BuildContext context) =>
      const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
}

BoxDecoration panelDecoration() => BoxDecoration(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    );

BorderRadius radius16 = BorderRadius.circular(16);
BorderRadius radius24 = BorderRadius.circular(24);

Widget constrained(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxWidth),
        child: child,
      ),
    );

ButtonStyle primaryBtn = FilledButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  foregroundColor: const Color(0xFF0F172A), // slate-950
  textStyle: const TextStyle(fontWeight: FontWeight.w700),
  backgroundColor: AppColors.teal,
).copyWith(
  backgroundColor: MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.hovered)) {
      return const Color(0xFF10A192);
    }
    return const Color(0xFF14B8A6);
  }),
);

ButtonStyle ghostBtn = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  side: const BorderSide(color: AppColors.border),
  foregroundColor: AppColors.text,
).copyWith(
  overlayColor: MaterialStateProperty.all(const Color(0x14FFFFFF)), // white/8
);

Widget maybeExpanded({required bool useExpanded, required Widget child}) =>
    useExpanded ? Expanded(child: child) : child;
