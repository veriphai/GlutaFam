import 'package:eureka_app/parentDashboard/gapCard.dart';
import 'package:eureka_app/parentDashboard/shiningCard.dart';
import 'package:flutter/material.dart';
import 'package:eureka_app/parentDashboard/models.dart';

int pct(double x) => (x * 100).round();

class CheckpointCard extends StatefulWidget {
  final CheckpointDetails cp;
  const CheckpointCard({super.key, required this.cp});
  @override
  State<CheckpointCard> createState() => _CheckpointCardState();
}

class _CheckpointCardState extends State<CheckpointCard> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final cp = widget.cp;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Checkpoint ${cp.id}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
                onPressed: () => setState(() => open = !open),
                child: Text(open ? 'Hide' : 'View')),
          ]),
          const SizedBox(height: 6),
          Text('Learning objectives',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cp.objectives
                  .map((o) => Row(
                        children: [
                          const Text('• '),
                          Expanded(child: Text(o)),
                        ],
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text('Mastery',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: cp.mastery,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200),
          ),
          if (open) ...[
            const SizedBox(height: 10),
            ...cp.gaps.map((g) => GapCard(gap: g)),
            ...cp.shining.map((s) => ShiningCard(moment: s)),
          ],
        ]),
      ),
    );
  }
}
