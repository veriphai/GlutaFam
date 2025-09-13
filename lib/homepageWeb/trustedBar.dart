import 'package:eureka_app/homepageWeb/statCard.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class TrustedBar extends StatelessWidget {
  const TrustedBar({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context).copyWith(top: 8, bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: panelDecoration().copyWith(
            borderRadius: radius24,
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: const [
              StatCard(
                  label: 'Daily clarity cards sent', value: 12438, suffix: '+'),
              StatCard(label: 'Avg. setup time', value: 60, suffix: 's'),
              StatCard(
                  label: 'Parents who heard improvement by day 5',
                  value: 89,
                  suffix: '%'),
              StatCard(
                  label: 'Conversation prompts delivered',
                  value: 53210,
                  suffix: '+'),
            ],
          ),
        ),
      ),
    );
  }
}
