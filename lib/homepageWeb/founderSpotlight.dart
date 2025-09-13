import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class FounderSpotlight extends StatelessWidget {
  const FounderSpotlight({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: Column(
          children: [
            const SectionHeader(
                eyebrow: 'Who’s building Tuto',
                title: 'Built by an educator–builder obsessed with diagnostics',
                subtitle:
                    'On a mission to make world-class 1-to-1 tutoring quality available at everyday cost—starting with better diagnosis.',
                icon: Icons.bubble_chart_outlined),
            const SizedBox(height: 40),
            LayoutBuilder(builder: (context, c) {
              final two = c.maxWidth > 900;
              return Flex(
                direction: two ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(right: 16, bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                          colors: [AppColors.teal, AppColors.cyan]),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.teal.withOpacity(.25),
                            blurRadius: 20,
                            spreadRadius: 2),
                      ],
                    ),
                  ),
                  maybeExpanded(
                    useExpanded: two,
                    child: Padding(
                        padding: EdgeInsets.only(left: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _Point(
                                'Early NLP work: built Jaano India, a natural-language to SQL chatbot to query official survey data.'),
                            _Point(
                                'Embibe (Jio): led consumer PM; created a knowledge-graph-driven adaptive practice system that still powers measurable gains.'),
                            _Point(
                                'Now: scaling Tuto—an AI system focused on knowing what a child truly understands, every day.'),
                            SizedBox(height: 12),
                            _QuoteCard(
                              'We believe the first step in teaching is knowing. Once diagnosis is reliable, the path to world-class guidance becomes simpler. Targeted student plans are in development.',
                            ),
                          ],
                        )),
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

class _Point extends StatelessWidget {
  final String text;
  const _Point(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: AppColors.subtext)),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String text;
  const _QuoteCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Text(text, style: const TextStyle(color: AppColors.subtext)),
    );
  }
}
