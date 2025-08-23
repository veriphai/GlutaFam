import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class Pill extends StatelessWidget {
  final String text;
  const Pill(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: panelDecoration().copyWith(
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.subtext)),
    );
  }
}
