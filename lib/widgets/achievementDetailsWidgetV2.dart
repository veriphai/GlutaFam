import 'package:eureka_app/utils/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementDetailsWidgetV2 extends StatelessWidget {
  final String achievementId;
  final int levelCriteria;

  const AchievementDetailsWidgetV2(
      {Key? key, required this.achievementId, required this.levelCriteria})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      color: Color.fromRGBO(19, 31, 36, 1),
      child: Column(
        children: [
          // Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close, color: Colors.white),
              )
            ],
          ),
          Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 320,
                width: 320,
                child: Center(
                  child: SizedBox(
                    height: 300,
                    width: 300,
                    child: Opacity(
                      opacity: 1,
                      child: Image.asset(
                          getAchievement(achievementId)?["imagePath"] ??
                              'lib/assets/placeholder.png'),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      "$levelCriteria",
                      style: GoogleFonts.raleway(
                          fontSize: 70,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 10
                            ..color = const Color.fromARGB(255, 159, 129, 81),
                          decoration: TextDecoration.none),
                    ),
                    // Filled Text
                    Text(
                      "$levelCriteria",
                      style: GoogleFonts.raleway(
                          fontSize: 70,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.none),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Text(
          //   achievement["description"] ?? "No description available",
          //   style: GoogleFonts.raleway(
          //     color: Colors.white,
          //     fontSize: 20,
          //     fontWeight: FontWeight.w700,
          //     height: 1.5,
          //   ),
          //   textAlign: TextAlign.center,
          // ),

          Spacer(),
        ],
      ),
    );
  }
}
