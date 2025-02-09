import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class PersonalStreakContent extends StatelessWidget {
  final int streakCount; // Current streak count
  final DateTime streakStartDate; // Streak start date
  final int streakGoal; // Goal for the streak
  final bool expiryToday;
  final bool streakActive;

  const PersonalStreakContent(
      {Key? key,
      required this.streakCount,
      required this.streakStartDate,
      required this.streakGoal,
      required this.expiryToday,
      required this.streakActive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
      height: MediaQuery.of(context).size.height * 1.2,
      decoration: BoxDecoration(
        color: Color.fromRGBO(19, 31, 36, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: expiryToday
                    ? Color.fromARGB(255, 68, 56, 36)
                    : Color.fromARGB(255, 221, 133, 0),
              ),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Streak Info
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 20,
                              ),
                              Stack(
                                children: [
                                  // Outline Text
                                  Text(
                                    '$streakCount',
                                    style: GoogleFonts.raleway(
                                      fontSize: 80,
                                      fontWeight: FontWeight.w700,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 12
                                        ..color = Color.fromARGB(
                                            255, 159, 129, 81), // Outline color
                                    ),
                                  ),
                                  // Filled Text
                                  Text(
                                    '$streakCount',
                                    style: GoogleFonts.raleway(
                                      fontSize: 80,
                                      fontWeight: FontWeight.w700,
                                      color: expiryToday
                                          ? Color.fromARGB(255, 68, 56, 36)
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'day streak!',
                                style: GoogleFonts.raleway(
                                  color: expiryToday
                                      ? Color.fromARGB(255, 159, 129, 81)
                                      : Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outline Text
                              Image.asset(
                                'lib/assets/streakIcon.png', // Replace with your image URL
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                color: Color.fromARGB(255, 159, 129, 81),
                              ),
                              // Filled Text
                              if (expiryToday)
                                Image.asset(
                                    'lib/assets/inactiveStreakIcon.png', // Replace with your image URL
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover)
                              else
                                Image.asset(
                                    'lib/assets/streakIcon.png', // Replace with your image URL
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (expiryToday)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Image.asset(
                                'lib/assets/watchIcon.png', // Replace with your image URL
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover),
                            SizedBox(
                              width: 20,
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Do a lesson today to extend your streak',
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'START LESSON',
                                      style: GoogleFonts.raleway(
                                        color: Color.fromRGBO(255, 217, 0, 1),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                ]),
                          ]),
                        ),

                      SizedBox(
                        height: 20,
                      ),
                    ],
                  )),
            ),
            Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Calendar',
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Color.fromARGB(255, 91, 91, 91))),
                      child: TableCalendar(
                        focusedDay: DateTime.now(),
                        firstDay: DateTime.utc(2000, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        availableGestures: AvailableGestures.none,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          outsideDaysVisible: false,
                          defaultTextStyle: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w700),
                          weekendTextStyle: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w700),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: GoogleFonts.arOneSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        rangeStartDay: streakStartDate,
                        rangeEndDay: DateTime.now(),
                        calendarBuilders: CalendarBuilders(
                          rangeStartBuilder: (context, day, focusedDay) {
                            if (streakActive) {
                              return Container(
                                // margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Color.fromRGBO(255, 217, 0,
                                        1), // Green circle for the start
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16))
                                    // shape: BoxShape.circle,
                                    ),
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700),
                                ),
                              );
                            }
                          },
                          rangeEndBuilder: (context, day, focusedDay) {
                            return Container(
                              // margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Color.fromRGBO(255, 217, 0,
                                      1), // Green circle for the end
                                  // shape: BoxShape.circle,
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16))),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700),
                              ),
                            );
                          },
                          withinRangeBuilder: (context, day, focusedDay) {
                            return Container(
                              // margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              height: 40,

                              decoration: BoxDecoration(
                                color: Color.fromRGBO(255, 217, 0, 1),
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700),
                              ),
                            );
                          },
                          todayBuilder: (context, day, focusedDay) {
                            // Styling for today's date
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(
                                    255, 217, 0, 1), // Orange circle for today
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                          rangeHighlightBuilder: (context, day, isWithinRange) {
                            // Background highlight for the entire range
                            if (isWithinRange) {
                              return Center(
                                  child: Container(
                                height: 40,
                                // decoration: BoxDecoration(
                                //   color: Colors.green.withOpacity(
                                //       0.2), // Light green background
                                // ),
                              ));
                            }
                            return null; // Default styling for dates outside the range
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Streak Goals
                    Text(
                      'Streak Goals',
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                          // color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Color.fromARGB(255, 91, 91, 91))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Start Icon

                              Image.asset(
                                "lib/assets/calendar-icon.png",
                                height: 40,
                              ),

                              Expanded(
                                child: LinearProgressIndicator(
                                  value: streakCount / streakGoal,
                                  backgroundColor:
                                      const Color.fromARGB(255, 91, 91, 91),
                                  minHeight: 20,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color.fromRGBO(255, 217, 0, 1)),
                                ),
                              ),

                              Image.asset(
                                "lib/assets/calendar-icon.png",
                                height: 40,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${streakCount} / ${streakGoal} Days',
                            style: GoogleFonts.raleway(
                              color: const Color.fromARGB(255, 91, 91, 91),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ))
            // Streak Calendar
          ],
        ),
      ),
    ));
  }
}
