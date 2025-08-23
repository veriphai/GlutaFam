import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class ConversationVsQuiz extends StatefulWidget {
  const ConversationVsQuiz({super.key});

  @override
  State<ConversationVsQuiz> createState() => _ConversationVsQuizState();
}

class _ConversationVsQuizState extends State<ConversationVsQuiz> {
  bool focusDialogue = true;

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding:
            AppLayout.sectionPadding(context).copyWith(top: 28, bottom: 28),
        child: Column(
          children: [
            const SectionHeader(
                eyebrow: 'Why this works',
                title: 'Guided exchange beats tick-marks',
                subtitle:
                    'Answers label right/wrong. Dialogue uncovers the missing step and how to rebuild it.',
                icon: Icons.bubble_chart_outlined),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final two = c.maxWidth > 900;
              final content = Flex(
                direction: two ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment:
                    two ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                children: [
                  maybeExpanded(
                    useExpanded: two,
                    child: _FocusCard(
                      active: !focusDialogue,
                      title: 'Traditional check',
                      desc:
                          'Fast, but shallow — you see the score, not the misconception.',
                      child: Container(
                        decoration: panelDecoration(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('MCQ: 3/5',
                                style: TextStyle(color: AppColors.subtext)),
                            SizedBox(height: 6),
                            Text('Tells you what was wrong. Not why.',
                                style: TextStyle(
                                    color: AppColors.subtext, fontSize: 12)),
                          ],
                        ),
                      ),
                      onEnter: () => setState(() => focusDialogue = false),
                    ),
                  ),
                  const SizedBox(width: 24, height: 12),
                  maybeExpanded(
                    useExpanded: two,
                    child: _FocusCard(
                      active: focusDialogue,
                      title: 'Tuto’s guided chat',
                      desc:
                          'Probes reasoning, spots the broken link, and points you to repair it tonight.',
                      child: const _ChatDemo(),
                      onEnter: () => setState(() => focusDialogue = true),
                    ),
                  ),
                ],
              );
              return two ? IntrinsicHeight(child: content) : content;
            }),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final bool active;
  final String title;
  final String desc;
  final Widget child;
  final VoidCallback onEnter;

  const _FocusCard({
    required this.active,
    required this.title,
    required this.desc,
    required this.child,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onEnter(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: panelDecoration().copyWith(
          border: Border.all(
              color: active ? AppColors.teal.withOpacity(.4) : AppColors.border,
              width: 2.0),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: AppColors.cyan.withOpacity(.05),
                      blurRadius: 24,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.teal)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: AppColors.subtext)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}

class _ChatDemo extends StatefulWidget {
  const _ChatDemo();

  @override
  State<_ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends State<_ChatDemo>
    with SingleTickerProviderStateMixin {
  final lines = const [
    ['Tuto', 'Tell me how you’d add 1/3 and 1/4.'],
    ['Child', 'Add numerators: 1+1=2 and denominators 3+4=7 → 2/7'],
    ['Tuto', 'Where do we use LCM there?'],
    ['Child', 'Oh… I forgot LCM when denominators differ.'],
    ['Tuto', 'Try again: find LCM of 3 & 4, then rewrite both fractions.'],
  ];

  int show = 1;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return false;
      setState(() => show = (show + 1).clamp(1, lines.length));
      return show < lines.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = show.clamp(0, lines.length); // safety

    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(count, (i) {
          final l = lines[i];
          final isChild = l[0] == 'Child';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isChild ? Colors.grey : AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.subtext),
                      children: [
                        TextSpan(
                            text: '${l[0]}: ',
                            style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600)),
                        TextSpan(text: l[1]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
