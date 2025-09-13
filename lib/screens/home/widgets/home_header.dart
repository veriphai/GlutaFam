import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String? firstName;

  const HomeHeader({
    super.key,
    this.firstName,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = firstName ?? 'Student';
    if (hour < 12) return "Good morning, $name";
    if (hour < 17) return "Good afternoon, $name";
    return "Good evening, $name";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateTime.now().toString().split(' ')[0],
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.sub,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getGreeting(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //   decoration: BoxDecoration(
        //     color: AppColors.card,
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: AppColors.border),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Text(
        //         "Streak",
        //         style: GoogleFonts.inter(
        //           fontSize: 12,
        //           color: AppColors.sub,
        //         ),
        //       ),
        //       const SizedBox(width: 4),
        //       Text(
        //         "3🔥",
        //         style: GoogleFonts.inter(
        //           fontSize: 12,
        //           fontWeight: FontWeight.w600,
        //           color: AppColors.ink,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
