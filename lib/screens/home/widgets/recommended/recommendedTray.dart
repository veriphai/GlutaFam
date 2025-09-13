import 'package:flutter/material.dart';

class RecommendedTray extends StatelessWidget {
  const RecommendedTray({
    super.key,
    required this.child,
    this.radius = 8,
    this.padding =
        const EdgeInsets.fromLTRB(12, 32, 12, 12), // top space for content
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  // palette
  static const _trayFill = Color.fromRGBO(248, 236, 201, 1); // cream
  static const _trayLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _trayFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _trayLine, width: 2.0),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
