import 'package:eureka_app/parentDashboard/models.dart';
import 'package:flutter/material.dart';

int pct(double x) => (x * 100).round();

class MasteryStrip extends StatelessWidget {
  final Mastery mastery;
  const MasteryStrip({super.key, required this.mastery});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mastery improvement',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
            'Started ${pct(mastery.start)}% → Finished ${pct(mastery.end)}% (+${pct(mastery.end - mastery.start)})'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (int i = 0; i < mastery.checkpoints.length; i++)
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('C${i + 1}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                          value: mastery.checkpoints[i],
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
