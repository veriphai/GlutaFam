import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';
import 'pill.dart';

class PhoneMock extends StatelessWidget {
  const PhoneMock({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 380,
        decoration: panelDecoration().copyWith(
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MetaRow(),
              const SizedBox(height: 12),
              const _Bubble(
                  who: 'Tuto',
                  text: 'Let’s talk about what you studied today. Ready?'),
              const _Bubble(who: 'Child', text: 'Yes', childTone: true),
              const _Bubble(
                  who: 'Tuto', text: 'Explain how you’d add 1/3 and 1/4.'),
              const _Bubble(who: 'Child', text: '2/7', childTone: true),
              const _Bubble(
                  who: 'Tuto',
                  text:
                      'Try walking me through your steps. What comes before adding?'),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Pill('Talk'),
                  SizedBox(width: 8),
                  Pill('Type'),
                  SizedBox(width: 8),
                  Pill('Replay')
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('Today • Maths',
            style: TextStyle(color: AppColors.subtext, fontSize: 12)),
        Text('00:09', style: TextStyle(color: AppColors.subtext, fontSize: 12)),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String who;
  final String text;
  final bool childTone;
  const _Bubble(
      {required this.who, required this.text, this.childTone = false});

  @override
  Widget build(BuildContext context) {
    final isChild = childTone;
    return Row(
      mainAxisAlignment:
          isChild ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isChild ? AppColors.teal.withOpacity(.12) : AppColors.panel,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(who.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.subtext,
                      letterSpacing: .6)),
              const SizedBox(height: 2),
              Text(text, style: TextStyle(color: AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }
}
