import 'package:eureka_app/screens/home/models/subjectChipData.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectChip extends StatelessWidget {
  const SubjectChip({
    super.key,
    required this.data,
    this.onTap,
  });

  final SubjectChipData data;
  final VoidCallback? onTap;

  // palette (kept local for now)
  static const _inkBlue = Color.fromRGBO(19, 78, 147, 1);
  static const _chipFill = Color.fromRGBO(253, 241, 214, 1); // beige
  static const _chipLine = Color.fromRGBO(195, 186, 154, 1); // beige border

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 60,
          // padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: _chipFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _chipLine,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon block
              Container(
                height: 40,
                width: 40,
                // decoration: BoxDecoration(
                //   color: Colors.white.withOpacity(0.55),
                //   borderRadius: BorderRadius.circular(10),
                //   border: Border.all(color: _chipLine, width: 1),
                // ),
                child: Icon(
                  data.icon,
                  size: 40,
                  color: _inkBlue,
                ),
              ),
              const SizedBox(height: 2),
              // Label pill (like in PNG)
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.kalam(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _inkBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
