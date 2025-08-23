import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding:
            AppLayout.sectionPadding(context).copyWith(top: 28, bottom: 28),
        child: Column(
          children: [
            const SectionHeader(
                eyebrow: 'Your first school week with Tuto',
                title:
                    'Diagnose today. Reinforce tonight. Hear progress by day 5.',
                subtitle:
                    'Parent prompts + quick resources now. In-app targeted practice is coming soon.',
                icon: Icons.bubble_chart_outlined),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final col = c.maxWidth > 1000 ? 3 : 1;
              const spacing = 12.0;
              final tileWidth = (c.maxWidth - (col - 1) * spacing) / col;
              final desiredHeight = col == 3 ? 230.0 : 230.0;
              final aspect = tileWidth / desiredHeight; // width / height
              return GridView.count(
                crossAxisCount: col,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 12,
                childAspectRatio: aspect,
                children: const [
                  _StepCard(
                      day: 'Day 1',
                      title: 'Quick chat → clear brief',
                      points: [
                        'Child talks ~10 min about today’s topic.',
                        'You get the specific idea at risk and why it slipped.',
                        'Use 2–3 prompts + a short link tonight.',
                      ]),
                  _StepCard(
                      day: 'Days 2–4',
                      title: 'Re-scan & reinforce',
                      points: [
                        'Fresh 10-min chat revisits the weak spot and nearby ideas.',
                        'You get new prompts/resources to guide the fix.',
                        'Targeted in-app practice → coming soon.',
                      ]),
                  _StepCard(
                      day: 'Day 5/6',
                      title: 'Hear the difference',
                      points: [
                        'Same core idea asked again.',
                        'Play day-1 vs day-5 answer; confidence is obvious.',
                        'Share the weekly wrap with a teacher/tutor.',
                      ]),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String day;
  final String title;
  final List<String> points;
  const _StepCard(
      {required this.day, required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: panelDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  color: AppColors.teal,
                  size: 16,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(day,
                    style: const TextStyle(fontSize: 12, color: AppColors.teal))
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  // fontSize: 20,
                  fontSize: 18,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(p,
                            style: const TextStyle(color: AppColors.subtext))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
