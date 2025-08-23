import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class ValueGrid extends StatelessWidget {
  const ValueGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: Column(
          children: [
            const SectionHeader(
              eyebrow: 'What parents actually get',
              title: 'Immediate clarity. Action tonight. Progress this week.',
              subtitle:
                  'A guided chat reveals the reasoning, you get the playbook to reinforce at home.',
              icon: Icons.bubble_chart_outlined,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final col = c.maxWidth > 1000 ? 4 : (c.maxWidth > 700 ? 2 : 1);
              const spacing = 12.0;
              final tileWidth = (c.maxWidth - (col - 1) * spacing) / col;
              final desiredHeight = col == 4 ? 160.0 : 130.0;
              final aspect = tileWidth / desiredHeight; // width / height
              return GridView.count(
                crossAxisCount: col,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 20,
                childAspectRatio: aspect,
                children: const [
                  _ValueCard(
                      icon: Icons.visibility_outlined,
                      title: 'Same-day visibility',
                      desc:
                          'See the exact idea that’s shaky and why it slipped—right after class.'),
                  _ValueCard(
                      icon: Icons.chat_bubble_outline_outlined,
                      title: 'Ready-to-use prompts',
                      desc:
                          '2–3 questions to ask tonight, plus a quick read/video link to share.'),
                  _ValueCard(
                      icon: Icons.multitrack_audio_outlined,
                      title: 'Hear the improvement',
                      desc:
                          'Compare Monday vs Friday answers to the same idea—confidence becomes audible.'),
                  _ValueCard(
                      icon: Icons.watch_later_outlined,
                      title: 'Tiny daily rhythm',
                      desc:
                          '~10 minutes for your child; 5 minutes for you. No worksheets, no cram marathons.'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;

  const _ValueCard(
      {required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }
}
