import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetableEmptyBody extends StatelessWidget {
  const TimetableEmptyBody({
    super.key,
    required this.onAddTimetable,
    required this.onImportFromPhoto,
  });

  final VoidCallback onAddTimetable;
  final VoidCallback onImportFromPhoto;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _greenText = Color(0xFF2E7D57);
  static const _goldFill = Color.fromRGBO(253, 233, 137, 1);
  static const _goldLine = Color.fromRGBO(228, 204, 109, 1);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // Tagline
            Text(
              "Add your school timetable\nto get smart reminders",
              textAlign: TextAlign.center,
              style: GoogleFonts.kalam(
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: _greenText,
              ),
            ),

            const SizedBox(height: 16),

            // Illustration row (placeholder icons for now; we’ll refine next)
            Image.asset('lib/assets/emptyTimetable.png',
                width: double.infinity, fit: BoxFit.contain),

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: const [
            //     _SketchCard.icon(Icons.calendar_month_outlined),
            //     SizedBox(width: 18),
            //     _SketchCard.icon(Icons.access_time),
            //   ],
            // ),

            const SizedBox(height: 18),

            // Primary CTA
            SizedBox(
                width: double.infinity,
                child: _PrimaryCtaButton(
                  text: "Add timetable",
                  onTap: onAddTimetable,
                )),

            const SizedBox(height: 12),

            // Secondary link
            InkWell(
              onTap: onImportFromPhoto,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_camera_outlined,
                        size: 35, color: _inkBlue),
                    const SizedBox(width: 8),
                    Text(
                      "Import from photo",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _inkBlue,
                        fontFamily: GoogleFonts.kalam().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),
          ],
        ));
  }
}

class _SketchCard extends StatelessWidget {
  const _SketchCard.icon(this.icon, {this.size = 136});
  final IconData icon;
  final double size;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        border: Border.all(color: _trayLine, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.44, color: _inkBlue),
    );
  }
}

class _PrimaryCtaButton extends StatelessWidget {
  const _PrimaryCtaButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  static const _inkText = Color(0xFF3B2F2A);
  static const _goldFill = Color.fromRGBO(253, 233, 137, 1);
  static const _goldLine = Color.fromRGBO(228, 204, 109, 1);

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: _goldLine, width: 3),
    );
    return Material(
      color: _goldFill,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Text(
            text,
            style: GoogleFonts.kalam(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _inkText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
