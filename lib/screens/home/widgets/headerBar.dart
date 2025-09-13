import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DayPart { morning, afternoon, evening, night }

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.dayPart,
    this.date,
    this.dateString,
    this.subtext =
        "Let's pick what you’re studying right now.", // shown below the row
    this.onAvatarTap,
  });

  /// REQUIRED
  final String userName;

  /// OPTIONALS
  final String? avatarUrl; // network/local path; falls back to initials
  final DayPart? dayPart; // if null, computed from [date] or now()
  final DateTime? date; // used to compute greeting/date defaults
  final String? dateString; // override e.g., "Tue, 12 Aug"
  final String subtext; // second line under the row
  final VoidCallback? onAvatarTap;

  // --- Colors (local for now; can move to theme later)
  static const _inkBlue = Color.fromRGBO(19, 78, 147, 1);
  static const _inkMuted = Color.fromRGBO(48, 52, 47, 1);
  static const _chipFill = Color(0xFFEFE3CB); // beige chip fill
  static const _chipLine = Color(0xFFB7A987); // chip border
  static const _avatarStroke = Color(0xFF1E4B7A);

  @override
  Widget build(BuildContext context) {
    final dt = date ?? DateTime.now();
    final dp = dayPart ?? _inferDayPart(dt);
    final greeting = _greetingFor(dp);
    final formatted = dateString ?? _formatDate(dt); // "Tue, 12 Aug"

    return Container(
        color: Color.fromRGBO(255, 249, 221, 1),
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // ✅ center all children vertically
              children: [
                // Avatar
                InkWell(
                  onTap: onAvatarTap,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _avatarStroke, width: 1.2),
                    ),
                    child: ClipOval(
                      child: avatarUrl == null
                          ? _Initials(userName: userName)
                          : Image.network(avatarUrl!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Good evening, Aanya"
                      const SizedBox(height: 24),

                      Text(
                        "$greeting,",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kalam(
                          fontSize: 28, height: 1,
                          color: _inkBlue,
                          fontWeight: FontWeight.w600,
                          // swap to your handwritten font later
                          // fontFamily: 'Schoolbell',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kalam(
                          fontSize: 28, height: 1,
                          color: _inkBlue,
                          fontWeight: FontWeight.w600,
                          // swap to your handwritten font later
                          // fontFamily: 'Schoolbell',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right column: sticker + date chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Daypart sticker (emoji for now)
                    Text(
                      _emojiFor(dp),
                      style: const TextStyle(fontSize: 40),
                    ),
                    // const SizedBox(height: 6),
                    _DateChip(text: formatted),
                  ],
                ),
              ],
            ),

            // Subtext line below the whole row
            const SizedBox(height: 16),
            Center(
                child: Text(
              subtext,
              style: GoogleFonts.kalam(
                fontSize: 18, height: 1.3,
                color: _inkMuted,
                // fontFamily: 'Nunito',
              ),
            )),
          ],
        ));
  }

  // --- Helpers ---------------------------------------------------------------

  static DayPart _inferDayPart(DateTime dt) {
    final h = dt.hour;
    if (h >= 5 && h < 12) return DayPart.morning;
    if (h >= 12 && h < 17) return DayPart.afternoon;
    if (h >= 17 && h < 21) return DayPart.evening;
    return DayPart.night;
  }

  static String _greetingFor(DayPart dp) {
    switch (dp) {
      case DayPart.morning:
        return "Good morning";
      case DayPart.afternoon:
        return "Good afternoon";
      case DayPart.evening:
        return "Good evening";
      case DayPart.night:
        return "Good night";
    }
  }

  static String _emojiFor(DayPart dp) {
    switch (dp) {
      case DayPart.morning:
        return "🌅";
      case DayPart.afternoon:
        return "🌤️";
      case DayPart.evening:
        return "🌇";
      case DayPart.night:
        return "🌙";
    }
  }

  static String _formatDate(DateTime dt) {
    // Tue, 12 Aug
    const w = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    const m = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    final weekday = w[(dt.weekday + 6) % 7]; // make Mon index 0
    final day = dt.day.toString().padLeft(2, '0');
    final mon = m[dt.month - 1];
    return "$weekday, $day $mon";
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.text});
  final String text;

  static const _chipFill = Color.fromRGBO(253, 240, 214, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipFill,
        // borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: _chipLine, width: 1),
        // boxShadow: const [
        //   BoxShadow(
        //     color: Colors.black12,
        //     blurRadius: 6,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Text(
        text,
        style: GoogleFonts.kalam(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: HeaderBar._inkBlue,
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    final initials = userName.trim().isEmpty
        ? "?"
        : userName
            .trim()
            .split(RegExp(r"\s+"))
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase();
    return Container(
      color: const Color(0xFFE3EEF7),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF1E4B7A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
