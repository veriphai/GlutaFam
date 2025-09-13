import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final TextAlign align;
  final IconData icon;
  final bool applyPaddingOnTitle;

  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.applyPaddingOnTitle = true,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final h3 = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
        );
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: panelDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppColors.teal,
                  size: 16,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  eyebrow,
                  style: const TextStyle(fontSize: 12, color: AppColors.teal),
                ),
              ],
            )),
        const SizedBox(height: 12),
        Padding(
            padding:
                EdgeInsets.symmetric(horizontal: applyPaddingOnTitle ? 130 : 0),
            child: Text(title,
                textAlign: align,
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: align, style: const TextStyle(color: AppColors.subtext)),
      ],
    );
  }
}
