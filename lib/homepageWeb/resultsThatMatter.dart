import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class ResultsThatMatter extends StatelessWidget {
  const ResultsThatMatter({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: Column(
          children: [
            const SectionHeader(
                eyebrow: 'Outcomes at home',
                title: 'Fewer surprises. Calmer prep. Clearer answers.',
                subtitle: 'Stay ahead of trouble with a tiny daily ritual.',
                icon: Icons.bubble_chart_outlined),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final col = c.maxWidth > 1000 ? 3 : 1;
              const spacing = 12.0;
              final tileWidth = (c.maxWidth - (col - 1) * spacing) / col;
              final desiredHeight = col == 3 ? 140.0 : 120.0;
              final aspect = tileWidth / desiredHeight; // width / height
              return GridView.count(
                crossAxisCount: col,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 20,
                childAspectRatio: aspect,
                children: const [
                  _ResultCard(
                      title: 'No more last-minute panic',
                      desc:
                          'You spot weak ideas days earlier and address them the same evening.'),
                  _ResultCard(
                      title: 'Confidence you can hear',
                      desc:
                          'By the end of week one, explanations sound steadier and more complete.'),
                  _ResultCard(
                      title: 'Better alignment with school',
                      desc:
                          'Your quick nudges keep classwork, tuition and revision on target.'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String desc;
  const _ResultCard({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: AppColors.subtext)),
        ],
      ),
    );
  }
}
