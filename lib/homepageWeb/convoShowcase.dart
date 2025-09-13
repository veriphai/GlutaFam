import 'package:eureka_app/homepageWeb/sectionBar.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class ConvoShowcase extends StatefulWidget {
  const ConvoShowcase({super.key});

  @override
  State<ConvoShowcase> createState() => _ConvoShowcaseState();
}

class _ConvoShowcaseState extends State<ConvoShowcase> {
  final PageController _pc = PageController();
  int index = 0;

  final slides = const [
    _Slide(
      title: 'Fractions — adding unlike denominators',
      convo: [
        ['Tuto', 'How would you add 1/3 and 1/4?'],
        ['Child', '2/7'],
        ['Tuto', 'What comes before adding?'],
        ['Child', 'Find LCM if denominators differ…'],
      ],
      finding: 'Skipped LCM step; confusion around ‘equivalent’.',
      prompts: [
        'Walk me through your steps when denominators don’t match.',
        'Define ‘equivalent fraction’ in your own words.'
      ],
      note: 'At dinner, he could explain the LCM step without help by day 3.',
    ),
    _Slide(
      title: 'Photosynthesis — role of stomata',
      convo: [
        ['Tuto', 'Where do plants exchange gases?'],
        ['Child', 'Leaves'],
        ['Tuto', 'Be specific.'],
        ['Child', 'Through tiny pores called stomata.'],
      ],
      finding: 'Vague vocabulary; missed the term ‘stomata’.',
      prompts: [
        'Name and describe the pores involved in gas exchange.',
        'Why do they open/close?'
      ],
      note: 'By day 5 the term usage was natural and accurate.',
    ),
    _Slide(
      title: 'Linear equations — balancing both sides',
      convo: [
        ['Tuto', 'Solve 2x + 3 = 11. What’s your first move?'],
        ['Child', '2x = 11 - 3'],
        ['Tuto', 'Why is that valid?'],
        ['Child', 'We do the same to both sides to keep balance.'],
      ],
      finding: 'Could do steps but couldn’t justify balance principle.',
      prompts: [
        'Explain ‘doing the same to both sides’.',
        'Give a non-example where balance breaks.'
      ],
      note: 'Reasoning improved; fewer rote mistakes in homework.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: AppLayout.sectionPadding(context),
        child: Column(
          children: [
            const SectionHeader(
                eyebrow: 'In the wild',
                title: 'Real conversations, real fixes',
                subtitle:
                    'A short chat, a clear brief, and a tiny nudge that evening.',
                icon: Icons.bubble_chart_outlined),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final two = c.maxWidth > 900;
              final s = slides[index];
              final content = Flex(
                direction: two ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment:
                    two ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                children: [
                  maybeExpanded(
                    useExpanded: two,
                    child: Container(
                      decoration: panelDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: const TextStyle(color: AppColors.teal)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: panelDecoration(),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: s.convo
                                  .map((l) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              decoration: BoxDecoration(
                                                color: l[0] == 'Tuto'
                                                    ? AppColors.teal
                                                    : Colors.grey,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                      color: AppColors.subtext),
                                                  children: [
                                                    TextSpan(
                                                        text: '${l[0]}: ',
                                                        style: const TextStyle(
                                                            color:
                                                                AppColors.text,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    TextSpan(text: l[1]),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(
                                style: ghostBtn,
                                onPressed: () {
                                  setState(() {
                                    index = (index - 1 + slides.length) %
                                        slides.length;
                                  });
                                },
                                child: const Row(children: [
                                  Icon(Icons.chevron_left),
                                  Text('Prev')
                                ]),
                              ),
                              OutlinedButton(
                                style: ghostBtn,
                                onPressed: () {
                                  setState(() {
                                    index = (index + 1) % slides.length;
                                  });
                                },
                                child: const Row(children: [
                                  Text('Next'),
                                  Icon(Icons.chevron_right)
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12, height: 12),
                  maybeExpanded(
                    useExpanded: two,
                    child: Container(
                      decoration: panelDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Parent brief snapshot',
                              style: TextStyle(color: AppColors.teal)),
                          const SizedBox(height: 8),
                          const Text('Finding',
                              style: TextStyle(color: AppColors.subtext)),
                          const SizedBox(height: 4),
                          Text(s.finding,
                              style: TextStyle(color: AppColors.text)),
                          const SizedBox(height: 12),
                          const Text('Tonight’s prompts',
                              style: TextStyle(color: AppColors.subtext)),
                          const SizedBox(height: 4),
                          ...s.prompts.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: const TextStyle(
                                            color: AppColors.subtext)),
                                    Expanded(
                                        child: Text(p,
                                            style: const TextStyle(
                                                color: AppColors.subtext))),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 12),
                          Container(
                            decoration: panelDecoration(),
                            padding: const EdgeInsets.all(12),
                            child: Text('Parent note: ${s.note}',
                                style:
                                    const TextStyle(color: AppColors.subtext)),
                          ),
                        ],
                      ),
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

class _Slide {
  final String title;
  final List<List<String>> convo;
  final String finding;
  final List<String> prompts;
  final String note;
  const _Slide({
    required this.title,
    required this.convo,
    required this.finding,
    required this.prompts,
    required this.note,
  });
}
