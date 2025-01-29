import 'package:eureka_app/utils/achievements.dart';
import 'package:eureka_app/widgets/achievementDetailsWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsPage extends StatefulWidget {
  final List<Map<String, dynamic>> achievements;

  const AchievementsPage({Key? key, required this.achievements})
      : super(key: key);

  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AchievementDetailsWidget(achievement: achievement),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        title: Text(
          "Achievements",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Awards Section
            Text(
              "Awards",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Achievements Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: widget.achievements.length,
                itemBuilder: (context, index) {
                  final achievement = widget.achievements[index];
                  final currentLevelIndex = achievement["currentLevel"] ?? 0;
                  final levels = achievement["levels"] ?? [];
                  final level = currentLevelIndex < levels.length
                      ? levels[currentLevelIndex]
                      : null;
                  return GestureDetector(
                    onTap: () => _showAchievementDetails(achievement),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              child: Center(
                                child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Opacity(
                                    opacity: achievement["unlocked"] ? 1 : 0.1,
                                    child: Image.asset(
                                      getAchievement(achievement["id"])?[
                                              "imagePath"] ??
                                          'lib/assets/placeholder.png',
                                      color: achievement["unlocked"]
                                          ? null
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    "${level["criteria"]}",
                                    style: GoogleFonts.raleway(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 5
                                        ..color = achievement["unlocked"]
                                            ? const Color.fromARGB(
                                                255, 159, 129, 81)
                                            : Colors.grey, // Outline color
                                    ),
                                  ),
                                  // Filled Text
                                  Text(
                                    "${level["criteria"]}",
                                    style: GoogleFonts.raleway(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: achievement["unlocked"]
                                          ? Colors.white
                                          : const Color.fromRGBO(19, 31, 36, 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Achievement Name
                        Text(
                          achievement["name"] ?? "Achievement",
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
