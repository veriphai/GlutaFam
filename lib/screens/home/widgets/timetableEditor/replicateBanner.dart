import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReplicateBanner extends StatelessWidget {
  const ReplicateBanner({
    super.key,
    required this.fromDay,
    required this.onReplicate,
    required this.onSkip,
  });

  final String fromDay; // e.g., "Monday"
  final VoidCallback onReplicate;
  final VoidCallback onSkip;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);
  static const _goldFill = Color.fromRGBO(253, 233, 137, 1);
  static const _goldLine = Color.fromRGBO(228, 204, 109, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trayLine, width: 1),
      ),
      child: Row(
        children: [
          // message
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: _inkBlue,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2),
                children: [
                  const TextSpan(text: "Copy "),
                  TextSpan(
                    text: fromDay,
                    style: GoogleFonts.kalam(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _inkBlue),
                  ),
                  const TextSpan(text: " to Tue–Fri? (Weekends excluded)"),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Skip
          TextButton(
            onPressed: onSkip,
            child: const Text("Skip",
                style: TextStyle(fontWeight: FontWeight.w900, color: _inkBlue)),
          ),
          const SizedBox(width: 6),

          // Replicate (primary)
          Material(
            color: _goldFill,
            shape: const StadiumBorder(
                side: BorderSide(color: _goldLine, width: 1.3)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onReplicate,
              customBorder: const StadiumBorder(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  "Replicate",
                  style: GoogleFonts.kalam(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B2F2A)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
