import 'package:eureka_app/screens/home/models/period.dart';
import 'package:flutter/material.dart';

class TimetableFooter extends StatelessWidget {
  const TimetableFooter({
    super.key,
    required this.periodsForToday,
    this.now,
    this.remindersOn = true,
    this.onTapUpdatePack,
    this.onTapShare,
    this.onTapEdit,
    this.timeRailWidth = 56, // keep alignment with grid, if needed later
  });

  final List<Period> periodsForToday;
  final DateTime? now;
  final bool remindersOn;
  final VoidCallback? onTapUpdatePack;
  final VoidCallback? onTapShare;
  final VoidCallback? onTapEdit;
  final double timeRailWidth;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);
  static const _greenText = Color.fromRGBO(51, 97, 53, 1);
  static const _linkBlue = Color(0xFF1F63C3);

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Period? _nextPeriod(DateTime clock) {
    int mins(TimeOfDay t) => t.hour * 60 + t.minute;
    final nowM = clock.hour * 60 + clock.minute;
    final afterNow = periodsForToday.where((p) => mins(p.start) > nowM).toList()
      ..sort((a, b) => (mins(a.start) - mins(b.start)));
    return afterNow.isEmpty ? null : afterNow.first;
  }

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    final next = _nextPeriod(clock);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // top rule separating grid and footer
        Container(height: 1, color: _trayLine.withOpacity(0.9)),

        const SizedBox(height: 10),

        // Row 1: Reminders + Update pack
        // Row(
        //   children: [
        //     Row(
        //       children: [
        //         Icon(
        //           remindersOn
        //               ? Icons.notifications_active
        //               : Icons.notifications_off_outlined,
        //           size: 18,
        //           color: _greenText,
        //         ),
        //         const SizedBox(width: 6),
        //         Text(
        //           remindersOn ? "Auto reminders On" : "Auto reminders Off",
        //           style: const TextStyle(
        //             fontSize: 13.5,
        //             fontWeight: FontWeight.w900,
        //             color: _greenText,
        //           ),
        //         ),
        //       ],
        //     ),
        //     const Spacer(),
        //     InkWell(
        //       onTap: onTapUpdatePack,
        //       borderRadius: BorderRadius.circular(6),
        //       child: const Padding(
        //         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        //         child: Text(
        //           "Update pack",
        //           style: TextStyle(
        //             fontSize: 13.5,
        //             fontWeight: FontWeight.w900,
        //             color: _linkBlue,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),

        // const SizedBox(height: 8),

        // Row 2: Next line
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // const Icon(Icons.arrow_forward, size: 16, color: _greenText),
            const SizedBox(width: 10),
            if (next != null)
              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 14,
                        color: _greenText,
                        fontWeight: FontWeight.w500),
                    children: [
                      const TextSpan(text: "Next: "),
                      TextSpan(text: next.subject),
                      const TextSpan(text: " — "),
                      TextSpan(text: next.topic),
                      const TextSpan(text: "  •  "),
                      TextSpan(
                        text: "${_fmt(next.start)}–${_fmt(next.end)}",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text(
                "All done for today 🎉",
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: _greenText),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 3: Share / Edit
        Row(
          children: [
            InkWell(
              onTap: onTapShare,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: const [
                  Icon(Icons.attach_file, size: 16, color: _inkBlue),
                  SizedBox(width: 6),
                  Text(
                    "Share with Parent?",
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _inkBlue),
                  ),
                ],
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onTapEdit,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: const [
                  Icon(Icons.edit_outlined, size: 16, color: _inkBlue),
                  SizedBox(width: 6),
                  Text(
                    "Edit",
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _inkBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
