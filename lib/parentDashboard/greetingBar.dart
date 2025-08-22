import 'package:flutter/material.dart';

String _greet(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  if (h >= 17 && h < 24) return 'Good evening';
  return 'Hello';
}

class GreetingBar extends StatelessWidget {
  final String name;
  const GreetingBar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_greet(DateTime.now())}, $name 👋',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Icon(Icons.calendar_month, size: 16),
        const SizedBox(width: 8),
        Text('Last 7 days view (change below)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600])),
      ],
    );
  }
}
