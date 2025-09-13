import 'package:eureka_app/homepageWeb/badge.dart';
import 'package:eureka_app/homepageWeb/phoneMock.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding:
            AppLayout.sectionPadding(context).copyWith(top: 40, bottom: 30),
        child: LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth > 900;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              maybeExpanded(
                useExpanded: isWide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: panelDecoration(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.safety_check_rounded,
                            color: AppColors.teal,
                            size: 16,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          const Text('Daily understanding check • CBSE 6–10',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.teal)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('No more exam-day shocks.',
                        style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text)),
                    const SizedBox(height: 12),
                    const Text(
                      'In ~10 minutes a day, Tuto shows you what your child really grasped today—and gives you exactly what to ask tonight to close the gap.',
                      style: TextStyle(fontSize: 20, color: AppColors.subtext),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      FilledButton(
                          onPressed: () {},
                          style: primaryBtn,
                          child: const Text('Run today’s free check')),
                      const SizedBox(width: 10),
                      OutlinedButton(
                          onPressed: () {},
                          style: ghostBtn,
                          child: const Text('See how it works')),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        BadgeChip(
                          icon: Icons.access_time,
                          label: '~10 mins/day',
                        ),
                        BadgeChip(icon: Icons.mic, label: 'Talk or type'),
                        BadgeChip(
                            icon: Icons.verified_user,
                            label: 'Parent brief every time'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24, height: 24),
              // maybeExpanded(
              //   useExpanded: isWide,
              //   child: const PhoneMock(),
              // ),
              maybeExpanded(
                useExpanded: isWide,
                child: const PhoneMock(),
              ),
            ],
          );
        }),
      ),
    );
  }
}
