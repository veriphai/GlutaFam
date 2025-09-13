import 'package:eureka_app/parentDashboard/models.dart';
import 'package:eureka_app/parentDashboard/theme.dart';
import 'package:flutter/material.dart';

int pct(double x) => (x * 100).round();

class ConceptSummaryCard extends StatelessWidget {
  final ConceptSummary item;
  final VoidCallback onOpen;
  const ConceptSummaryCard(
      {super.key, required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Left(item: item),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: Icon(Icons.tag_rounded, size: 16),
                    label: const Text('Fix now'),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: TextButton(
                      onPressed: onOpen, child: const Text('View details')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Left extends StatelessWidget {
  final ConceptSummary item;
  const _Left({required this.item});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.grey[600]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item.subject} • ${item.chapter}', style: muted),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.menu_book, size: 16),
          const SizedBox(width: 6),
          Flexible(
              child: Text(item.concept,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 2),
        Text(item.oneLiner, style: muted),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text('${item.gapsFound} gaps')),
            _ProgressTiny(label: 'Mastery', value: item.mastery, width: 140),
            _ProgressTiny(
                label: 'Confidence', value: item.confidence, width: 110),
          ],
        ),
      ],
    );
  }
}

class _ProgressTiny extends StatelessWidget {
  final String label;
  final double value;
  final double width;
  const _ProgressTiny(
      {required this.label, required this.value, required this.width});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600])),
      const SizedBox(width: 6),
      SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Theme.of(context).mutedBg,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('${pct(value)}%', style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
