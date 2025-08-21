import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DayStepper extends StatelessWidget {
  const DayStepper({
    super.key,
    required this.dayIndex, // 1=Mon ... 7=Sun
    required this.includeWeekends,
    this.onPrev,
    this.onNext,
    this.onToggleWeekends,
  });

  final int dayIndex;
  final bool includeWeekends;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToggleWeekends;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _pillBg = Color(0xFFE9F6C9);
  static const _pillLine = Color(0xFF86B76B);

  String _dayName(int i) => const [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ][(i - 1).clamp(0, 6)];

  @override
  Widget build(BuildContext context) {
    final day = _dayName(dayIndex);

    return Row(
      children: [
        _RoundIconButton(icon: Icons.chevron_left, onTap: onPrev),
        const SizedBox(width: 8),

        Expanded(
          child: Center(
            child: Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kalam(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _inkBlue,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
        _RoundIconButton(icon: Icons.chevron_right, onTap: onNext),

        const SizedBox(width: 10),

        // “Weekdays only” pill (toggle)
        InkWell(
          onTap: onToggleWeekends,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: ShapeDecoration(
              color: _pillBg,
              shape: StadiumBorder(
                side: BorderSide(color: _pillLine, width: 1.2),
              ),
              shadows: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              includeWeekends ? "Weekdays + Weekend" : "Weekdays only",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: _inkBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE3EEF7),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.chevron_left, size: 22, color: Color(0xFF1E4B7A)),
        ),
      ),
    );
  }
}
