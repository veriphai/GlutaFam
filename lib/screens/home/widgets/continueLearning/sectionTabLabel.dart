import 'package:eureka_app/screens/home/widgets/common/scribbleborderPainter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionTabLabel extends StatelessWidget {
  const SectionTabLabel({
    super.key,
    required this.text,
    this.margin = const EdgeInsets.only(top: 8),
    this.seed, // NEW: stable wobble
  });

  final String text;
  final EdgeInsets margin;
  final int? seed; // NEW

  @override
  Widget build(BuildContext context) {
    const fill = Color.fromRGBO(253, 233, 137, 1);
    const border = Color(0xFFB7A987);
    const radius = 10.0;

    return Stack(
      children: [
        // note fill + shadow (no solid border here)
        Container(
          // margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.kalam(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: const Color.fromRGBO(48, 52, 47, 1),
            ),
          ),
        ),

        // scribbly border overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ScribbleBorderPainter(
                color: border,
                radius: radius,
                strokeWidth: 1.5,
                step: 10, // segment length (bigger = fewer kinks)
                jitter: 0.5, // wobble amount
                seed: seed ?? Object.hash(text, 'section-tab'),
                drawTop: true,
                drawRight: true,
                drawBottom: true,
                drawLeft: true,
                doubleStroke: true, // nice pencil vibe
              ),
            ),
          ),
        ),
      ],
    );
  }
}
