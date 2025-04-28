import 'dart:math';

import 'package:eureka_app/apis/fetchLeaderboard.dart';
import 'package:eureka_app/apis/fetchLeaderboardResult.dart';
import 'package:eureka_app/apis/markLeaderboardResultSeen.dart';
import 'package:eureka_app/newEvents/leaderboardScreenEvents.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:eureka_app/screens/profileScreen.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/widgets/leaderboardResultWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eureka_app/utils/leagues.dart';

class WeeklyLeaderboardContent extends StatefulWidget {
  @override
  _WeeklyLeaderboardContentState createState() =>
      _WeeklyLeaderboardContentState();
}

class _WeeklyLeaderboardContentState extends State<WeeklyLeaderboardContent> {
  Map<String, dynamic> leaderboardData = {};
  Map<String, dynamic> leaderboardResult = {};
  bool isLoading = true;
  late Map<String, dynamic> userProfile;
  late int promotionIndex;
  late int demotionIndex;
  late int promotionZoneXP;
  late int demotionZoneXP;

  Future<void> fetchProfile() async {
    try {
      final profileData = await getProfile();
      // final profileData = await refreshProfile();
      setState(() {
        userProfile = profileData;
      });
      if (!profileData["leaderboardResultSeen"]) {
        final leaderboardResultData = await fetchLeaderboardResult();
        logLeaderboardResultScreenView();
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          isDismissible: false,
          builder: (context) {
            return LeaderboardResultWidget(
                leaderboardResult: leaderboardResultData);
          },
        );
        await markLeaderboardResultSeen();
      }
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  Future<void> getLeaderboardResult() async {
    try {
      final leaderboardResultData = await fetchLeaderboardResult();
      // final profileData = await refreshProfile();

      setState(() {
        leaderboardResult = leaderboardResultData;
      });
    } catch (error) {
      print("Error fetching leaderboardResult: $error");
    }
  }

  Future<void> getLeaderboardData() async {
    try {
      final leaderboard = await fetchLeaderboard(leaderboardType: "weekly");
      final int standingsLength = leaderboard["standings"].length;

      // Ensure that we have at least some valid indexes
      promotionIndex = max(3, min(standingsLength - 1, standingsLength ~/ 3));

      // promotionIndex = standingsLength > 3 ? standingsLength ~/ 3 : 1;
      demotionIndex = standingsLength > 3
          ? standingsLength - (standingsLength ~/ 3)
          : standingsLength - 1;

      setState(() {
        leaderboardData = leaderboard;
        isLoading = false;
        promotionZoneXP = leaderboard["standings"][promotionIndex]["points"];
        demotionZoneXP = leaderboard["standings"][demotionIndex]["points"];
      });
    } catch (error) {
      print("Error fetching leaderboard: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    logLeaderboardScreenView();
    fetchProfile();
    getLeaderboardData();
  }

  String getExpiryText(int expiryEpoch) {
    DateTime expiryDateTime =
        DateTime.fromMillisecondsSinceEpoch(expiryEpoch * 1000);
    Duration difference = expiryDateTime.difference(DateTime.now());

    if (difference.inSeconds <= 0) {
      return "Expired";
    } else if (difference.inMinutes < 1) {
      return "${difference.inSeconds} SECONDS";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes} MINUTES";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} HOURS";
    } else {
      return "${difference.inDays} DAYS";
    }
  }

  String getHeadingTextBasedOnXP() {
    int xp = leaderboardData["standings"].firstWhere(
        (standing) => standing["userId"] == userProfile["id"],
        orElse: () => {"points": 0})["points"];
    if (xp < promotionZoneXP && xp > demotionZoneXP) {
      return "Earn ${promotionZoneXP - xp} to get promoted";
    } else if (xp < demotionZoneXP) {
      return "Earn ${demotionZoneXP - xp} to be in the same league";
    }
    int rank = leaderboardData["standings"].firstWhere(
        (standing) => standing["userId"] == userProfile["id"],
        orElse: () => {"rank": 100})["rank"];

    if (rank < 4) {
      return "Maintain your rank for a reward";
    }
    return "Reach the top 3 for a reward";
  }

  @override
  Widget build(BuildContext context) {
    final leagueNames = [
      "Bronze",
      "Silver",
      "Gold",
      "Platinum",
      "Diamond",
      "Titanium"
    ];
    final leagueIcons = [
      Icons.emoji_events,
      Icons.star,
      Icons.shield,
      Icons.verified,
      Icons.emoji_events,
      Icons.star,
    ];

    final league = leaderboardData["league"];
    final standings = leaderboardData["standings"];
    bool showDemotionZone = league != null && league > 1 ? true : false;

    return isLoading
        ? Scaffold(
            backgroundColor: Color.fromRGBO(19, 31, 36, 1),
            body: Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[300]!,
                child: Text(
                  'Loading...',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ))
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${leagueNames[league - 1]} League",
                    style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                  Spacer(),
                  Icon(
                    Icons.timer_sharp,
                    color: Color.fromRGBO(255, 217, 0, 1),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    getExpiryText(leaderboardData["expiry"]),
                    style: GoogleFonts.arOneSans(
                        color: Color.fromRGBO(255, 217, 0, 1),
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            backgroundColor: Color.fromRGBO(19, 31, 36, 1),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getHeadingTextBasedOnXP(),
                        style: GoogleFonts.arOneSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 10),

                      // League Icons
                      Container(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: leagues.length,
                          itemBuilder: (context, index) {
                            final leagueKey = "league-${index + 1}";
                            final leagueData = leagues[leagueKey];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: [
                                  Image.asset(
                                    leagueData?["imagePath"] ??
                                        "lib/assets/placeholder.png", // Use image path from the map
                                    height: 80,
                                    width: 80,
                                    color: league - 1 >= index
                                        ? null
                                        : Colors.grey,
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Color.fromRGBO(66, 66, 66, 1),
                  thickness: 1,
                ),

                // Leaderboard
                Expanded(
                  child: ListView.builder(
                    itemCount: showDemotionZone
                        ? standings.length + 2
                        : standings.length + 1,
                    itemBuilder: (context, index) {
                      if (index == promotionIndex) {
                        // Render the promotion zone row after the 10th rank
                        return Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_double_arrow_up,
                                color: Colors.green,
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Text(
                                "PROMOTION ZONE",
                                style: GoogleFonts.raleway(
                                  color: Colors.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Icon(
                                Icons.keyboard_double_arrow_up,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        );
                      }
                      if (index == demotionIndex && showDemotionZone) {
                        // Render the demotion zone row after the 20th rank
                        return Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard_double_arrow_down,
                                  color: Colors.red),
                              SizedBox(width: 16),
                              Text(
                                "DEMOTION ZONE",
                                style: GoogleFonts.raleway(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.keyboard_double_arrow_down,
                                  color: Colors.red),
                            ],
                          ),
                        );
                      }

                      final actualIndex = showDemotionZone
                          ? (index > promotionIndex && index < demotionIndex
                              ? index - 1
                              : (index > demotionIndex ? index - 2 : index))
                          : (index > promotionIndex ? index - 1 : index);

                      final entry = standings[actualIndex];
                      final rank = entry["rank"];
                      final isCurrentUser =
                          entry["userId"] == userProfile["id"];

                      String rankImage;
                      switch (rank) {
                        case 1:
                          rankImage = "lib/assets/first-place-medal.png";
                        case 2:
                          rankImage = "lib/assets/second-place-medal.png";
                        case 3:
                          rankImage = "lib/assets/third-place-medal.png";
                        default:
                          rankImage = "";
                      }

                      return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            logProfileOpened(entry["userId"]);
                            if (isCurrentUser) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendsProfileScreen(
                                    friendId: entry["userId"],
                                    following: false,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.grey[800]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: rank < 4
                                    ? Image.asset(rankImage)
                                    : Text(
                                        "$rank",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),
                              title: Row(children: [
                                entry.containsKey("avatar") &&
                                        entry["avatar"] != null &&
                                        entry["avatar"]!.isNotEmpty
                                    ? Image.asset(
                                        getAvatar(
                                            entry["avatar"])["imagePath"]!,
                                        height: 50,
                                        fit: BoxFit.scaleDown,
                                      )
                                    : Image.asset(
                                        getAvatar("random")["imagePath"]!,
                                        height: 50,
                                        fit: BoxFit.scaleDown,
                                      ),
                                SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                    child: Text(
                                  entry.containsKey("name")
                                      ? entry["name"]
                                      : "Dummy",
                                  style: TextStyle(
                                    color: isCurrentUser
                                        ? Color.fromRGBO(255, 217, 0, 1)
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ]),
                              trailing: Text(
                                "${entry["points"]} XP",
                                style: TextStyle(
                                  color: isCurrentUser
                                      ? Color.fromRGBO(255, 217, 0, 1)
                                      : Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ));
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
