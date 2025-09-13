import 'dart:ui';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';
import 'package:flutter/material.dart';

class AnimatedBg extends StatelessWidget {
  const AnimatedBg({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // soft radial glow – moved up using Transform instead of negative margin
          Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: const Offset(0, -160), // <-- safe offset
              child: Container(
                width: 700,
                height: 700,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal.withOpacity(.18),
                      AppColors.cyan.withOpacity(.10),
                      AppColors.indigo.withOpacity(.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, .3, .55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Floating color blobs (these already use Transform, so they’re fine)
          const _Blob(offset: Offset(-220, -140), color: AppColors.teal),
          const _Blob(offset: Offset(240, 260), color: AppColors.cyan),
          const _Blob(offset: Offset(420, -40), color: AppColors.indigo),

          // filler to keep layout consistent (optional)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatefulWidget {
  final Offset offset;
  final Color color;
  const _Blob({required this.offset, required this.color});

  @override
  State<_Blob> createState() => _BlobState();
}

class _BlobState extends State<_Blob> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat(reverse: true);
  late final Animation<double> _a = Tween(begin: -8.0, end: 8.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Transform.translate(
        offset: widget.offset + Offset(0, _a.value),
        child: Container(
          width: 560,
          height: 560,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [widget.color.withOpacity(.35), Colors.transparent],
              stops: const [.0, .7],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(.18),
                blurRadius: 120,
                spreadRadius: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
