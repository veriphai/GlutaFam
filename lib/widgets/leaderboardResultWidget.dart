import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/utils/leagues.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardResultWidget extends StatefulWidget {
  final Map<String, dynamic> leaderboardResult;

  const LeaderboardResultWidget({Key? key, required this.leaderboardResult})
      : super(key: key);

  @override
  _LeaderboardResultWidgetState createState() =>
      _LeaderboardResultWidgetState();
}

class _LeaderboardResultWidgetState extends State<LeaderboardResultWidget> {
  int currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToNextPage() {
    if (currentPage == 0) {
      setState(() {
        currentPage = 1;
      });
      _pageController.nextPage(
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previousLeague = widget.leaderboardResult["league"];
    final newLeague = widget.leaderboardResult["newLeague"];
    final rank = widget.leaderboardResult["rank"];
    final leaderboard = widget.leaderboardResult["leaderboard"];
    final promoted = newLeague > previousLeague;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(19, 31, 36, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                // Page 1: Previous League & Leaderboard Snapshot
                Column(
                  children: [
                    Spacer(),
                    Image.asset(
                      leagues["league-$previousLeague"]!["imagePath"]!,
                      height: 150,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "You finished $rank${_getOrdinalSuffix(rank)} last week",
                      style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 20),
                    _buildLeaderboardSnapshot(leaderboard, rank),
                    SizedBox(height: 20),
                    Spacer(),
                    ChicletAnimatedButton(
                      onPressed: goToNextPage,
                      height: 50,
                      width: double.infinity,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "CONTINUE",
                        style: GoogleFonts.raleway(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),

                // Page 2: New League & Message
                Column(
                  children: [
                    Spacer(),
                    Image.asset(
                      leagues["league-$newLeague"]!["imagePath"]!,
                      height: 300,
                    ),
                    SizedBox(height: 20),
                    Text(
                      promoted
                          ? "Congratulations! You've been promoted to this week's ${leagues["league-$newLeague"]!["name"]} League"
                          : "Keep going! Stay strong in your league!",
                      style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                    ChicletAnimatedButton(
                      onPressed: goToNextPage,
                      height: 50,
                      width: double.infinity,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "CONTINUE",
                        style: GoogleFonts.raleway(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getRankImage(int rank) {
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
    return rankImage;
  }

  Widget _buildLeaderboardSnapshot(
      Map<String, dynamic> leaderboard, int userRank) {
    List<Map<String, dynamic>> snapshot = [];

    for (var entry in leaderboard["standings"]) {
      if (userRank == 1) {
        if ((entry["rank"] - userRank).abs() <= 4) {
          snapshot.add(entry);
        }
      } else if ((entry["rank"] - userRank).abs() <= 2) {
        snapshot.add(entry);
      }
    }

    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color.fromARGB(255, 91, 91, 91), width: 2),
        ),
        child: Column(
          children: snapshot.map((entry) {
            return Container(
              decoration: BoxDecoration(
                color: entry["rank"] == userRank
                    ? Colors.grey[800]
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: entry["rank"] < 4
                      ? Image.asset(getRankImage(entry["rank"]))
                      : Text(
                          "${entry["rank"]}",
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
                          getAvatar(entry["avatar"])["imagePath"]!,
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
                  Text(
                    entry.containsKey("name") ? entry["name"] : "Dummy",
                    style: TextStyle(
                      color: entry["rank"] == userRank
                          ? Color.fromRGBO(255, 217, 0, 1)
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                trailing: Text(
                  "${entry["points"]} XP",
                  style: TextStyle(
                    color: entry["rank"] == userRank
                        ? Color.fromRGBO(255, 217, 0, 1)
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            );
            // return Container(
            //   margin: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
            //   padding: EdgeInsets.all(12),
            //   decoration: BoxDecoration(
            //     color: entry["rank"] == userRank
            //         ? Colors.grey[800]
            //         : Colors.transparent,
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text(
            //         "${entry["rank"]}. ${entry["name"]}",
            //         style:
            //             GoogleFonts.raleway(color: Colors.white, fontSize: 16),
            //       ),
            //       Text(
            //         "${entry["points"]} XP",
            //         style:
            //             GoogleFonts.raleway(color: Colors.white, fontSize: 16),
            //       ),
            //     ],
            //   ),
            // );
          }).toList(),
        ));
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return "th";
    }
    switch (number % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }
}
