import 'package:eureka_app/widgets/PersonalStreakContent.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakScreen extends StatefulWidget {
  final int streakCount;
  final DateTime streakStartDate;
  final int streakGoal;
  final bool expiryToday;
  final bool streakActive;

  const StreakScreen(
      {Key? key,
      required this.streakCount,
      required this.streakStartDate,
      required this.streakGoal,
      required this.expiryToday,
      required this.streakActive})
      : super(key: key);

  @override
  _StreakScreenState createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _headerColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _headerColor = widget.expiryToday
        ? Color.fromARGB(255, 68, 56, 36)
        : const Color.fromARGB(255, 221, 133, 0);
    // Listen for tab changes
    _tabController.addListener(() {
      setState(() {
        // Change header color based on the active tab
        _headerColor = _tabController.index == 0
            ? widget.expiryToday
                ? Color.fromARGB(255, 68, 56, 36)
                : const Color.fromARGB(255, 221, 133, 0) // Personal tab color
            : Colors.blue; // Friends tab color
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 1.2,
        decoration: BoxDecoration(
          color: Color.fromRGBO(19, 31, 36, 1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: _headerColor, // Dynamic header color
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
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
                  ),
                  // TabBar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                        child: Text(
                          "PERSONAL",
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          "FRIENDS",
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Use PersonalStreakContent here
                  PersonalStreakContent(
                    streakCount: widget.streakCount,
                    streakStartDate: widget.streakStartDate,
                    streakGoal: widget.streakGoal,
                    expiryToday: widget.expiryToday,
                    streakActive: widget.streakActive,
                  ),
                  // Friends Tab Content
                  Center(
                    child: Text(
                      'Friends Tab Content Coming Soon!',
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
