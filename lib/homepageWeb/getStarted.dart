import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: LayoutBuilder(builder: (context, c) {
          final two = c.maxWidth > 900;
          return Flex(
            direction: two ? Axis.horizontal : Axis.vertical,
            children: [
              maybeExpanded(
                useExpanded: two,
                child: SectionHeader(
                  eyebrow: 'It takes a minute',
                  title: 'Get started now',
                  subtitle:
                      'Create the child profile, hand over the phone, and use tonight’s prompts.',
                  icon: Icons.bubble_chart_outlined,
                  align: TextAlign.left,
                  applyPaddingOnTitle: false,
                ),
              ),
              const SizedBox(width: 16, height: 16),
              maybeExpanded(
                useExpanded: two,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _GSItem(
                        n: 1,
                        title: 'Select class, board, and current chapter'),
                    const SizedBox(height: 12),
                    const _GSItem(
                        n: 2, title: 'Child chats with Tuto for ~10 minutes'),
                    const SizedBox(height: 12),
                    const _GSItem(
                        n: 3,
                        title:
                            'Use the prompts tonight—close one gap the same day'),
                    const SizedBox(height: 18),
                    FilledButton(
                        onPressed: () {},
                        style: primaryBtn,
                        child: const Text('Run today’s free check ->')),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _GSItem extends StatelessWidget {
  final int n;
  final String title;
  const _GSItem({required this.n, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            // gradient:
            //     const LinearGradient(colors: [AppColors.teal, AppColors.cyan]),
            color: Color(0x4D14B8A6),
          ),
          child: Text('$n',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                    fontSize: 16))),
      ]),
    );
  }
}
