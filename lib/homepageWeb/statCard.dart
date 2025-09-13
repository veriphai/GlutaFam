import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class StatCard extends StatefulWidget {
  final String label;
  final int value;
  final String suffix;
  const StatCard(
      {super.key, required this.label, required this.value, this.suffix = ''});

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: .98, end: 1.0).animate(_a),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _a,
              builder: (_, __) {
                final n = (widget.value * _a.value).toInt();
                return Text(
                  '${_format(n)}${widget.suffix}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(widget.label,
                style: const TextStyle(color: AppColors.subtext)),
          ],
        ),
      ),
    );
  }

  String _format(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      b.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) b.write(',');
    }
    return b.toString();
  }
}
