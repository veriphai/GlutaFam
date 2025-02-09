import 'package:chiclet/chiclet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakPopup extends StatelessWidget {
  final int streakCount;
  final int streakStartEpoch;
  final int streakGoal;

  const StreakPopup({
    Key? key,
    required this.streakCount,
    required this.streakStartEpoch,
    required this.streakGoal,
  }) : super(key: key);

  String getStreakMessage(int streakCount, int streakGoal) {
    if (streakCount == 1) {
      return "Great start! Keep going!";
    } else if (streakCount < streakGoal / 2) {
      return "You're making progress! Stay consistent!";
    } else if (streakCount == streakGoal) {
      return "Congratulations! You've achieved your streak goal! 🎉";
    } else if (streakCount > streakGoal) {
      return "🔥 You're surpassing your goal! Keep the streak alive!";
    } else {
      return "Almost there! Just ${streakGoal - streakCount} more days to your goal!";
    }
  }

  String getButtonText(int streakCount, int streakGoal) {
    if (streakCount == 1) {
      return "I CAN DO IT!";
    } else if (streakCount < streakGoal / 4) {
      return "I AM COMMITTED!";
    } else if (streakCount < streakGoal / 2) {
      return "I GOT THIS!";
    } else if (streakCount == streakGoal - 1) {
      return "NEXT LEVEL UNLOCKING!";
    } else if (streakCount == streakGoal) {
      return "PERFECT RUN! 🎉";
    } else if (streakCount > streakGoal && streakCount < streakGoal * 1.5) {
      return "I AM UNSTOPPABLE!";
    } else if (streakCount > streakGoal * 1.5) {
      return "NEW RECORD INCOMING!";
    } else if (streakCount > streakGoal * 2) {
      return "SUCCESS HABIT UNLOCKED!";
    } else {
      return "EVERY DAY COUNTS!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> weekDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
    final DateTime today = DateTime.now();
    final DateTime streakStartDate =
        DateTime.fromMillisecondsSinceEpoch(streakStartEpoch * 1000);

    // 🌀 Shift the weekDays list to start from the streak start date
    int startDayIndex =
        (streakStartDate.weekday - 1) % 7; // Convert to 0-based index
    List<String> rotatedWeekDays = [
      ...weekDays.sublist(startDayIndex),
      ...weekDays.sublist(0, startDayIndex)
    ];

    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),

            // 🔥 Streak Image
            Image.asset(
              "lib/assets/streakIcon.png",
              height: 150,
              width: 150,
            ),
            // 📅 Streak Count
            Text(
              "$streakCount",
              style: GoogleFonts.raleway(
                  fontSize: 180,
                  fontWeight: FontWeight.w800,
                  color: Color.fromRGBO(254, 169, 22, 1),
                  height: 0.9),
            ),

            // 🏆 "Day Streak" Label
            const SizedBox(height: 20),

            Text(
              "day streak",
              style: GoogleFonts.raleway(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color.fromRGBO(254, 169, 22, 1),
              ),
            ),
            const SizedBox(height: 40),

            // 📅 7-Day Calendar Widget
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Color.fromRGBO(55, 70, 79, 1), width: 2),
              ),
              child: Column(
                children: [
                  // Weekday Names with dynamic order
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      DateTime date =
                          streakStartDate.add(Duration(days: index));
                      bool isToday = date.day == today.day &&
                          date.month == today.month &&
                          date.year == today.year;

                      return Expanded(
                        child: Center(
                          child: Text(
                            rotatedWeekDays[index], // Adjusted order
                            style: GoogleFonts.raleway(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? Color.fromRGBO(254, 169, 22, 1)
                                  : Color.fromRGBO(77, 97, 110, 1),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  // Circles for Streak Days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      DateTime date =
                          streakStartDate.add(Duration(days: index));
                      bool isFilled =
                          date.isBefore(today) || date.isAtSameMomentAs(today);

                      return Expanded(
                        child: Center(
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? Color.fromRGBO(254, 169, 22, 1)
                                  : Color.fromRGBO(55, 70, 79, 1),
                              shape: BoxShape.circle,
                            ),
                            child: isFilled
                                ? Icon(
                                    Icons.check_rounded,
                                    color: Color.fromRGBO(19, 31, 36, 1),
                                    size: 25,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    color: Color.fromRGBO(55, 70, 79, 1),
                    thickness: 2,
                    height: 16,
                  ),
                  // 📝 Streak Message
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      getStreakMessage(streakCount, streakGoal),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Spacer(),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: ChicletAnimatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    buttonType: ChicletButtonTypes.roundedRectangle,
                    height: 50,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    buttonColor: const Color.fromRGBO(25, 151, 213, 1),
                    backgroundColor: const Color.fromRGBO(74, 193, 249, 1),
                    child: Text(
                      getButtonText(streakCount, streakGoal),
                      style: GoogleFonts.raleway(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ))),
          ],
        ),
      ),
    );
  }
}
