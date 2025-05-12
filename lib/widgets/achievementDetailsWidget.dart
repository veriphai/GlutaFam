import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/newEvents/achievementScreenEvents.dart';
import 'package:eureka_app/utils/achievements.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';
import 'package:eureka_app/widgets/rewardScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eureka_app/utils/generateAchievementImageForSharing.dart';

class AchievementDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final bool? friendsAchievement;

  const AchievementDetailsWidget(
      {Key? key, required this.achievement, this.friendsAchievement = false})
      : super(key: key);

  void _shareAchievement(BuildContext context, int levelCriteria) async {
    try {
      final achievementLink =
          await generateAchievementLink(achievement["id"], levelCriteria);

      // Generate Image with Achievement Details
      final imagePath =
          await generateAchievementImage(context, achievement, levelCriteria);

      // Share both the image and the link
      if (imagePath != null) {
        final xFile = XFile(imagePath);
        Share.shareXFiles(
          [xFile],
          text: "Check out my achievement on Tuto!\n$achievementLink",
          subject: "View Achievement on Tuto",
        );
      } else {
        // If image generation fails, share only the link
        Share.share(
          "Check out my achievement on Tuto!\n$achievementLink",
          subject: "View Achievement on Tuto",
        );
      }
    } catch (e) {
      print("Error sharing achievement: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    logAchievementScreenView(achievement['id']);
    final currentLevelIndex = achievement["currentLevel"] ?? 0;
    final levels = achievement["levels"] ?? [];
    final int adjustedLevelIndex =
        currentLevelIndex > 0 ? currentLevelIndex - 1 : currentLevelIndex;

    final level =
        adjustedLevelIndex < levels.length ? levels[adjustedLevelIndex] : null;

    final bool showShareButton =
        achievement['unlocked'] && !friendsAchievement! ? true : false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
              ),
              IconButton(
                onPressed: showShareButton
                    ? () {
                        logAchievementSharedViaLink(achievement['id']);
                        _shareAchievement(context, level["criteria"]);
                      }
                    : null,
                icon: Icon(Icons.ios_share,
                    color: showShareButton ? Colors.white : Colors.transparent),
              ),
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
                      opacity: achievement["unlocked"] ? 1 : 0.1,
                      child: Image.asset(
                        getAchievement(achievement["id"])?["imagePath"] ??
                            'lib/assets/placeholder.png',
                        color: achievement["unlocked"] ? null : Colors.grey,
                      ),
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
                      "${level["criteria"]}",
                      style: GoogleFonts.raleway(
                        fontSize: 70,
                        fontWeight: FontWeight.w700,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 10
                          ..color = achievement["unlocked"]
                              ? const Color.fromARGB(255, 159, 129, 81)
                              : Colors.grey, // Outline color
                      ),
                    ),
                    // Filled Text
                    Text(
                      "${level["criteria"]}",
                      style: GoogleFonts.raleway(
                        fontSize: 70,
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

          // Achievement Image
          // if (achievement["image"] != null)
          //   Center(
          //     child: Opacity(
          //         opacity: achievement["unlocked"] ? 1 : 0.1,
          //         child: Image.asset(
          //           getAchievement(achievement["id"])!["imagePath"] ?? "",
          //           height: 300,
          //           width: 300,
          //           fit: BoxFit.cover,
          //         )),
          //   )
          // else
          //   const Center(
          //     child: Icon(
          //       Icons.emoji_events,
          //       size: 120,
          //       color: Colors.grey,
          //     ),
          //   ),
          const SizedBox(height: 16),
          Text(
            achievement["description"] ?? "No description available",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Progress Bar
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     LinearProgressIndicator(
          //       value: achievement["progress"] != null
          //           ? (achievement["progress"] / 100).clamp(0.0, 1.0)
          //           : 0.0,
          //       backgroundColor: Colors.grey[800],
          //       borderRadius: BorderRadius.circular(12),
          //       color: Colors.orange,
          //       minHeight: 20,
          //     ),
          //     const SizedBox(height: 8),
          //     Text(
          //       "${achievement["progress"] ?? 0}% completed",
          //       style: GoogleFonts.raleway(
          //         color: Colors.grey[400],
          //         fontSize: 14,
          //       ),
          //     ),
          //   ],
          // ),
          Spacer(),
          if (achievement["rewardAvailable"] && !friendsAchievement!)
            ChicletAnimatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);

                // Navigate to Reward Screen
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return RewardScreen(
                        rewardFor: "achievement",
                        taskId: achievement["id"],
                      );
                    },
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              buttonType: ChicletButtonTypes.roundedRectangle,
              width: double.infinity,
              height: 50,
              buttonHeight: 4,
              padding: const EdgeInsets.all(8),
              buttonColor: const Color.fromARGB(255, 187, 160, 2),
              backgroundColor: const Color.fromARGB(255, 255, 217, 0),
              child: Text(
                "CLAIM REWARD",
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
        ],
      ),
    );
  }
}
