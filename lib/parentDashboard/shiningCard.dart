import 'package:eureka_app/parentDashboard/models.dart';
import 'package:flutter/material.dart';

class ShiningCard extends StatefulWidget {
  final ShiningMoment moment;
  const ShiningCard({super.key, required this.moment});

  @override
  State<ShiningCard> createState() => _ShiningCardState();
}

class _ShiningCardState extends State<ShiningCard> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(999)),
              child: const Text('WOW',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(m.wow,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          Text('“${m.quote}”', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextButton(
              onPressed: () => setState(() => open = !open),
              child: Text(open ? 'Hide evidence' : 'Show evidence')),
          if (open)
            Row(children: const [
              Icon(Icons.play_arrow, size: 14),
              SizedBox(width: 6),
              Text('Short audio (preview)',
                  style: TextStyle(fontSize: 12, color: Colors.grey))
            ]),
        ]),
      ),
    );
  }
}
