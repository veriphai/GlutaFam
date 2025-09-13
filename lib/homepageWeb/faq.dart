import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class FAQ extends StatelessWidget {
  const FAQ({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      [
        'Do I need to sit through the chat?',
        'No. Review the brief after; spend 5–10 minutes using the prompts. That’s where the fix happens.'
      ],
      [
        'What if today’s topic wasn’t covered?',
        'Pick ‘review yesterday’ or choose a recent chapter. Tuto follows school pace.'
      ],
      [
        'Is this replacing tuition?',
        'Think of it as your daily understanding scan that keeps school/tuition on track.'
      ],
      [
        'When will targeted in-app plans be available?',
        'They’re in active development. Until then, you get conversation prompts and resources to close each detected gap.'
      ],
    ];
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      // width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          const Text('FAQs',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 12),
          Container(
            decoration: panelDecoration(),
            child: Column(children: [
              for (final it in items) _FaqItem(q: it[0], a: it[1]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () => setState(() => open = !open),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                  child: Text(widget.q,
                      style: TextStyle(color: AppColors.text, fontSize: 16))),
              Icon(
                open ? Icons.expand_less : Icons.chevron_right,
                color: AppColors.text,
              ),
            ],
          ),
        ),
      ),
      if (open)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            widget.a,
            style: const TextStyle(color: AppColors.subtext),
            textAlign: TextAlign.left,
          ),
        ),
      Divider(height: 1, color: AppColors.border),
    ]);
  }
}
