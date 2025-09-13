import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class BriefPeek extends StatelessWidget {
  const BriefPeek({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth > 900;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              maybeExpanded(useExpanded: isWide, child: const _LeftCopy()),
              const SizedBox(width: 16, height: 16),
              maybeExpanded(useExpanded: isWide, child: const _BriefCard()),
            ],
          );
        }),
      ),
    );
  }
}

class _LeftCopy extends StatelessWidget {
  const _LeftCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: 'What arrives after every check',
          title: 'Your one-screen parent brief',
          subtitle:
              'Today’s finding, tonight’s prompts, a quick link, and a simple progress tick.',
          align: TextAlign.left,
          icon: Icons.bubble_chart_outlined,
          applyPaddingOnTitle: false,
        ),
        SizedBox(height: 16),
        _Bullet('Specific idea + the ‘why’ behind the struggle'),
        _Bullet('2–3 ready-to-use questions to ask tonight'),
        _Bullet('A short read/video to reinforce at home'),
        _Bullet('Weekly wrap you can forward to a teacher/tutor'),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_outlined,
              size: 16, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: const TextStyle(color: AppColors.subtext))),
        ],
      ),
    );
  }
}

class _BriefCard extends StatelessWidget {
  const _BriefCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('Today’s Brief', style: TextStyle(color: AppColors.teal)),
          Text('Aligned to class pacing',
              style: TextStyle(color: AppColors.subtext, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1726),
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Concept at risk',
                    style: TextStyle(color: AppColors.subtext)),
                SizedBox(height: 4),
                Text('Fractions → Adding unlike denominators',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                        fontSize: 18)),
                SizedBox(height: 12),
                Text('Why it slipped',
                    style: TextStyle(color: AppColors.subtext)),
                SizedBox(height: 4),
                Text(
                    'Skipped LCM step when denominators differ; vocabulary confusion around “equivalent”.',
                    style: TextStyle(color: AppColors.text, fontSize: 18)),
                SizedBox(height: 12),
                _PromptPanels(),
              ]),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Row(
            children: [
              Text('Momentum: ', style: TextStyle(color: AppColors.subtext)),
              Text('+2 improved ', style: TextStyle(color: AppColors.teal)),
              Text('/ 1 unchanged', style: TextStyle(color: AppColors.subtext))
            ],
          ),
          // Text('Momentum: +2 improved / 1 unchanged',
          //     style: TextStyle(color: AppColors.subtext)),
          Text('Try it now', style: TextStyle(color: AppColors.text)),
        ]),
      ]),
    );
  }
}

class _PromptPanels extends StatelessWidget {
  const _PromptPanels();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final two = c.maxWidth > 300;

      final content = Flex(
        direction: two ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment:
            two ? CrossAxisAlignment.stretch : CrossAxisAlignment.start, // 👈
        children: [
          maybeExpanded(
            useExpanded: two,
            child: _Panel(
              title: 'Ask tonight',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ListDot(
                      'Walk me through your steps when denominators don’t match.'),
                  _ListDot(
                      'What does “equivalent fraction” mean in your own words?'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10, height: 10),
          maybeExpanded(
            useExpanded: two,
            child: _Panel(
              title: 'Quick link',
              child: Text(
                '2-min refresher: LCM before adding',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: AppColors.subtext,
                ),
              ),
            ),
          ),
        ],
      );

      // Ensures the row takes on the tallest child height, so both panels match.
      return two ? IntrinsicHeight(child: content) : content;
    });
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFF86EFE1))),
        const SizedBox(height: 6),
        child,
      ]),
    );
  }
}

class _ListDot extends StatelessWidget {
  final String text;
  const _ListDot(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('• ', style: TextStyle(color: AppColors.subtext)),
        Expanded(
            child:
                Text(text, style: const TextStyle(color: AppColors.subtext))),
      ]),
    );
  }
}
