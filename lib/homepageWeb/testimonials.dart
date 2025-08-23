import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class Testimonials extends StatelessWidget {
  const Testimonials({super.key});

  @override
  Widget build(BuildContext context) {
    final quotes = [
      [
        'Parent, Delhi (Class 8)',
        'By day five my son could explain the LCM step without me prompting. The 10-minute rhythm works.'
      ],
      [
        'Parent, Bengaluru (Class 7)',
        'The brief told me why she was stuck, not just the score. Our dinner chat fixed it that night.'
      ],
      [
        'Parent, Pune (Class 9)',
        'Clear, respectful, short. I forward the weekly card to her teacher—everyone stays aligned.'
      ],
    ];
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: Column(
          children: [
            const SectionHeader(
                eyebrow: 'What parents say',
                title: 'Short chats, clearer answers',
                subtitle:
                    'Real families using Tuto’s daily understanding check.',
                icon: Icons.bubble_chart_outlined),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final col = c.maxWidth > 1000 ? 3 : 1;
              const spacing = 12.0;
              final tileWidth = (c.maxWidth - (col - 1) * spacing) / col;
              final desiredHeight = col == 3 ? 180.0 : 160.0;
              final aspect = tileWidth / desiredHeight; // width / height
              return GridView.count(
                crossAxisCount: col,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 20,
                childAspectRatio: aspect,
                children: [
                  for (final q in quotes)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: panelDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.star_border_outlined,
                              size: 18, color: AppColors.teal),
                          const SizedBox(height: 8),
                          Text('“${q[1]}”',
                              style: const TextStyle(
                                  color: AppColors.text, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(q[0],
                              style: const TextStyle(
                                  color: AppColors.subtext, fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
