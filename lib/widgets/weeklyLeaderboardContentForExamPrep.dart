import 'package:eureka_app/apis/fetchLeaderboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class WeeklyLeaderboardContentForExamPrep extends StatefulWidget {
  @override
  _WeeklyLeaderboardContentForExamPrepState createState() =>
      _WeeklyLeaderboardContentForExamPrepState();
}

class _WeeklyLeaderboardContentForExamPrepState
    extends State<WeeklyLeaderboardContentForExamPrep> {
  Map<String, dynamic> leaderboardData = {};
  bool isLoading = true;

  Future<void> getLeaderboardData() async {
    try {
      final leaderboard = await fetchLeaderboard(leaderboardType: "weekly");

      setState(() {
        leaderboardData = leaderboard;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching feeds: $error");
    }
  }

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final standings = leaderboardData["standings"];

    return isLoading
        ? Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[700]!,
              highlightColor: Colors.grey[300]!,
              child: Text(
                'Loading...',
                style: TextStyle(fontSize: 24),
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.black,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        standings.length, // Add one for the promotion row
                    itemBuilder: (context, index) {
                      if (index == 10) {
                        // Render the promotion zone row after the 10th rank
                        return Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.green),
                              SizedBox(
                                width: 16,
                              ),
                              Text(
                                "PROMOTION ZONE",
                                style: GoogleFonts.raleway(
                                  color: Colors.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Icon(Icons.arrow_upward, color: Colors.green),
                            ],
                          ),
                        );
                      }

                      // Adjust index for actual standings
                      final actualIndex = index > 10 ? index - 1 : index;
                      final entry = standings[actualIndex];
                      final rank = entry["rank"];
                      final isCurrentUser = entry["currentUser"] ?? false;

                      Color rankColor;
                      switch (rank) {
                        case 1:
                          rankColor = Colors.amber;
                          break;
                        case 2:
                          rankColor = Colors.grey;
                          break;
                        case 3:
                          rankColor = Colors.red;
                          break;
                        default:
                          rankColor = Colors.transparent;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.grey[800]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: rankColor,
                            child: Text(
                              "$rank",
                              style: TextStyle(
                                color: rankColor != Colors.transparent
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                          title: Row(children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue[300],
                              child: entry.containsKey("avatar") &&
                                      entry["avatar"] != null &&
                                      entry["avatar"]!.isNotEmpty
                                  ? Image.network(
                                      entry["avatar"]!,
                                      width: 30,
                                      fit: BoxFit.scaleDown,
                                    )
                                  : Icon(Icons.person, color: Colors.white),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              entry.containsKey("name")
                                  ? entry["name"]
                                  : "Dummy",
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Color.fromRGBO(255, 217, 0, 1)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ]),
                          trailing: Text(
                            "${entry["points"]} XP",
                            style: TextStyle(
                              color: isCurrentUser
                                  ? Color.fromRGBO(255, 217, 0, 1)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
