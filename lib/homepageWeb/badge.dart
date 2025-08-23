import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const BadgeChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: panelDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.subtext),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}
