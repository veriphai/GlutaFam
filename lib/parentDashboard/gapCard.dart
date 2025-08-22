import 'package:eureka_app/parentDashboard/models.dart';
import 'package:eureka_app/parentDashboard/theme.dart';
import 'package:flutter/material.dart';

Color sevFill(int s) =>
    s >= 3 ? Colors.red : (s == 2 ? Colors.orange : Colors.amber);
Color sevText(int s) =>
    s >= 3 ? Colors.red : (s == 2 ? Colors.orange : Colors.amber);

class GapCard extends StatefulWidget {
  final Gap gap;
  const GapCard({super.key, required this.gap});
  @override
  State<GapCard> createState() => _GapCardState();
}

class _GapCardState extends State<GapCard> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.gap;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: sevFill(g.severity),
                      borderRadius: BorderRadius.circular(999)),
                  child: const Text('GAP',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Text(g.type,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sevText(g.severity))),
                const Spacer(),
                Text('Severity ${g.severity}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: Text(g.why)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => open = !open),
                  child: Text(open ? 'Hide details' : 'Details'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.tag_rounded, size: 16),
                    label: const Text('Resolve now')),
              ],
            ),
            if (open) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).mutedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Tutor asked'),
                    Text(g.details.tutorAsk),
                    const SizedBox(height: 8),
                    _label('Student said'),
                    Text('“${g.details.studentText}”'),
                    const SizedBox(height: 8),
                    _label('Timeline'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (int i = 0; i < g.details.timeline.length; i++) ...[
                          _TimelinePill(ev: g.details.timeline[i]),
                          if (i < g.details.timeline.length - 1)
                            Text('→',
                                style: TextStyle(color: Colors.grey[600])),
                        ]
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.play_arrow, size: 14),
                        SizedBox(width: 6),
                        Text('10s audio snippet (preview)',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String s) =>
      Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey));
}

class _TimelinePill extends StatelessWidget {
  final TimelineEvent ev;
  const _TimelinePill({required this.ev});
  @override
  Widget build(BuildContext context) {
    Color c = Colors.grey;
    if (ev.verdict == '✅') c = Colors.green;
    if (ev.verdict == '❌') c = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (ev.verdict != null) Text(ev.verdict!, style: TextStyle(color: c)),
        if (ev.hint != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(999)),
            child: const Text('hint', style: TextStyle(fontSize: 12)),
          ),
        ],
        const SizedBox(width: 6),
        Text(ev.t, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ]),
    );
  }
}
