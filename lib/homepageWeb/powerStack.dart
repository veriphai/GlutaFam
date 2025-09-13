import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class PowerStack extends StatelessWidget {
  const PowerStack({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: Column(
          children: [
            const SectionHeader(
                eyebrow: 'Under the hood',
                title: 'Why this is possible now',
                subtitle:
                    'A fine-grained concept map, adaptive lesson control, privacy by design, and a parent-first brief after every check.',
                icon: Icons.bubble_chart_outlined),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final col = c.maxWidth > 1000 ? 4 : (c.maxWidth > 700 ? 2 : 1);
              const spacing = 12.0;
              final tileWidth = (c.maxWidth - (col - 1) * spacing) / col;
              final desiredHeight = col == 4 ? 180.0 : 150.0;
              final aspect = tileWidth / desiredHeight; // width / height
              return GridView.count(
                crossAxisCount: col,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 20,
                childAspectRatio: aspect,
                children: const [
                  _PowerItem(
                    icon: Icons.auto_graph,
                    title: 'Competency graph',
                    desc:
                        'A rich map of ideas across classes 6–10 with nuanced links, letting Tuto pinpoint exactly where reasoning slips.',
                  ),
                  _PowerItem(
                    icon: Icons.alt_route,
                    title: 'Adaptive learning trees',
                    desc:
                        'Dynamic lesson paths and depth control for faster, smarter dialogue that focuses only where it matters.',
                  ),
                  _PowerItem(
                    icon: Icons.privacy_tip,
                    title: 'Private by design',
                    desc:
                        'Voice is disguised and personal details are masked before any model call. Signals from the concept graph are pseudonymised.',
                  ),
                  _PowerItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Actionable brief',
                    desc:
                        'Parents receive clear findings, prompts to ask that evening, and a short read/video to share—so fixes start the same day.',
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Note: AI surfaces patterns quickly; caring adults remain essential for context and motivation. We explain the ‘why’ behind each finding and keep you in control.',
              style: TextStyle(color: AppColors.subtext, fontSize: 12),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}

class _PowerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _PowerItem(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Color(0x4D14B8A6),
              // gradient: const LinearGradient(
              //     colors: [AppColors.teal, AppColors.cyan]),
            ),
            child: Icon(
              icon,
              color: AppColors.text,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.text)),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: AppColors.subtext)),
      ]),
    );
  }
}
