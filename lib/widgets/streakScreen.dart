import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakScreen extends StatelessWidget {
  final int streakCount; // Current streak count
  final DateTime streakStartDate; // Streak start date
  final int streakGoal; // Goal for the streak

  const StreakScreen({
    Key? key,
    required this.streakCount,
    required this.streakStartDate,
    required this.streakGoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final streakDates = List.generate(
      DateTime.now().difference(streakStartDate).inDays + 1,
      (i) => streakStartDate.add(Duration(days: i)),
    ).toSet();

    return SingleChildScrollView(
        child: Container(
      height: MediaQuery.of(context).size.height * 1.2,
      decoration: BoxDecoration(
        color: Colors.black,
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
                color: Color.fromARGB(255, 221, 133, 0),
              ),
              child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          Text(
                            'Streak',
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 24), // Spacer for alignment
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Streak Info
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      color: Colors.white, // Fill color
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'day Streak',
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Image.asset(
                            'lib/assets/glutaclassLogo.png', // Replace with your image URL
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ],
                  )),
            ),
            const SizedBox(height: 20),
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
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.orange,
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
                        calendarBuilders: CalendarBuilders(
                          rangeHighlightBuilder: (context, day, focusedDay) {
                            if (streakDates.contains(day)) {
                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.green, // Highlight streak range
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            return null; // Default style for other dates
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

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

                              Icon(
                                Icons.calendar_today,
                                size: 30,
                                color: Colors.white,
                              ),

                              Expanded(
                                child: LinearProgressIndicator(
                                  value: streakCount / streakGoal,
                                  backgroundColor:
                                      const Color.fromARGB(255, 91, 91, 91),
                                  minHeight: 20,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.green),
                                ),
                              ),

                              Icon(
                                Icons.calendar_today,
                                size: 30,
                                color: Colors.white,
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
