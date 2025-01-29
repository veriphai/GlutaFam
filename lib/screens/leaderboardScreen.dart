// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class LeaderboardScreen extends StatelessWidget {
//   final Map<String, dynamic> leaderboardData = {
//     "league": 1,
//     "resetTime": 5,
//     "promotePoints": 200,
//     "demotePoints": 100,
//     "standings": [
//       {
//         "id": "alex_1",
//         "name": "Alex",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 1,
//         "points": 567
//       },
//       {
//         "id": "yey_1",
//         "name": "Yey",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 2,
//         "points": 510
//       },
//       {
//         "id": "zara_1",
//         "name": "Zara",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 3,
//         "points": 480
//       },
//       {
//         "id": "mike_1",
//         "name": "Mike",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 4,
//         "points": 430
//       },
//       {
//         "id": "john_1",
//         "name": "John",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 5,
//         "points": 400,
//         "currentUser": true
//       },
//       {
//         "id": "alex_1",
//         "name": "Alex",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 6,
//         "points": 567
//       },
//       {
//         "id": "yey_1",
//         "name": "Yey",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 7,
//         "points": 510
//       },
//       {
//         "id": "zara_1",
//         "name": "Zara",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 8,
//         "points": 480
//       },
//       {
//         "id": "mike_1",
//         "name": "Mike",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 9,
//         "points": 430
//       },
//       {
//         "id": "alex_1",
//         "name": "Alex",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 10,
//         "points": 567
//       },
//       {
//         "id": "yey_1",
//         "name": "Yey",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 11,
//         "points": 510
//       },
//       {
//         "id": "zara_1",
//         "name": "Zara",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 12,
//         "points": 480
//       },
//       {
//         "id": "mike_1",
//         "name": "Mike",
//         "avatar": "https://gluta.s3.ap-south-1.amazonaws.com/boy_animation.gif",
//         "rank": 13,
//         "points": 430
//       }
//     ]
//   };

//   @override
//   Widget build(BuildContext context) {
//     final leagueNames = [
//       "Bronze",
//       "Silver",
//       "Gold",
//       "Platinum",
//       "Diamond",
//       "Titanium"
//     ];
//     final leagueIcons = [
//       Icons.emoji_events,
//       Icons.star,
//       Icons.shield,
//       Icons.verified,
//       Icons.emoji_events,
//       Icons.star,
//     ];

//     final league = leaderboardData["league"];
//     final standings = leaderboardData["standings"];

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               "${leagueNames[league - 1]} League",
//               style: GoogleFonts.raleway(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w700),
//             ),
//             Spacer(),
//             Icon(
//               Icons.timer_sharp,
//               color: Color.fromRGBO(255, 217, 0, 1),
//             ),
//             SizedBox(
//               width: 8,
//             ),
//             Text(
//               "${leaderboardData["resetTime"]} DAYS",
//               style: GoogleFonts.arOneSans(
//                   color: Color.fromRGBO(255, 217, 0, 1),
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700),
//             ),
//           ],
//         ),
//       ),
//       backgroundColor: Colors.black,
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Description
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Reach the top 3 for a reward",
//                   style: GoogleFonts.arOneSans(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w400),
//                 ),
//                 const SizedBox(height: 30),

//                 // League Icons
//                 Container(
//                   height: 100,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: leagueIcons.length,
//                     itemBuilder: (context, index) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Column(
//                           children: [
//                             Icon(
//                               leagueIcons[index],
//                               size: 60,
//                               color: league - 1 >= index
//                                   ? Colors.amber
//                                   : Colors.grey[400],
//                             ),
//                             Text(
//                               leagueNames[index],
//                               style: TextStyle(
//                                 color: league - 1 == index
//                                     ? Colors.amber
//                                     : Colors.grey[400],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(
//             color: Color.fromRGBO(66, 66, 66, 1),
//             thickness: 1,
//           ),

//           // Leaderboard
//           Expanded(
//             child: ListView.builder(
//               itemCount: standings.length + 1, // Add one for the promotion row
//               itemBuilder: (context, index) {
//                 if (index == 10) {
//                   // Render the promotion zone row after the 10th rank
//                   return Container(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.arrow_upward, color: Colors.green),
//                         SizedBox(
//                           width: 16,
//                         ),
//                         Text(
//                           "PROMOTION ZONE",
//                           style: GoogleFonts.raleway(
//                             color: Colors.green,
//                             fontSize: 18,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         SizedBox(
//                           width: 16,
//                         ),
//                         Icon(Icons.arrow_upward, color: Colors.green),
//                       ],
//                     ),
//                   );
//                 }

//                 // Adjust index for actual standings
//                 final actualIndex = index > 10 ? index - 1 : index;
//                 final entry = standings[actualIndex];
//                 final rank = entry["rank"];
//                 final isCurrentUser = entry["currentUser"] ?? false;

//                 Color rankColor;
//                 switch (rank) {
//                   case 1:
//                     rankColor = Colors.amber;
//                     break;
//                   case 2:
//                     rankColor = Colors.grey;
//                     break;
//                   case 3:
//                     rankColor = Colors.red;
//                     break;
//                   default:
//                     rankColor = Colors.transparent;
//                 }

//                 return Container(
//                   decoration: BoxDecoration(
//                     color:
//                         isCurrentUser ? Colors.grey[800] : Colors.transparent,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: rankColor,
//                       child: Text(
//                         "$rank",
//                         style: TextStyle(
//                           color: rankColor != Colors.transparent
//                               ? Colors.black
//                               : Colors.white,
//                         ),
//                       ),
//                     ),
//                     title: Row(children: [
//                       CircleAvatar(
//                         backgroundColor: Colors.blue[300],
//                         child: entry["avatar"] != ""
//                             ? Image.network(
//                                 entry["avatar"],
//                                 width: 30,
//                                 fit: BoxFit.scaleDown,
//                               )
//                             : Icon(Icons.person, color: Colors.white),
//                       ),
//                       SizedBox(
//                         width: 20,
//                       ),
//                       Text(
//                         entry["name"],
//                         style: TextStyle(
//                           color: isCurrentUser
//                               ? Color.fromRGBO(255, 217, 0, 1)
//                               : Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ]),
//                     trailing: Text(
//                       "${entry["points"]} XP",
//                       style: TextStyle(
//                         color: isCurrentUser
//                             ? Color.fromRGBO(255, 217, 0, 1)
//                             : Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/widgets/weeklyLeaderboardContent.dart';
import 'package:eureka_app/widgets/dailyLeaderboardContent.dart';
import 'package:eureka_app/widgets/weeklyLeaderboardContentForExamPrep.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _headerColor;
  bool isLoading = true;

  Map<String, dynamic> userProfile = {};

  Future<void> fetchProfile() async {
    try {
      final profileData = await getProfile();

      setState(() {
        userProfile = profileData;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
    _tabController = TabController(length: 2, vsync: this);
    _headerColor = Colors.blue; // Default header color

    // Change header color when switching tabs
    _tabController.addListener(() {
      setState(() {
        _headerColor = _tabController.index == 0
            ? Colors.orangeAccent // Daily leaderboard color
            : Colors.blue; // Weekly leaderboard color
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Leaderboard",
          style: GoogleFonts.raleway(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: _headerColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Text(
                "DAILY",
                style: GoogleFonts.raleway(fontWeight: FontWeight.w700),
              ),
            ),
            Tab(
              child: Text(
                "WEEKLY",
                style: GoogleFonts.raleway(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
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
          : TabBarView(
              controller: _tabController,
              children: [
                // Daily Leaderboard Content
                DailyLeaderboardContent(),
                // Weekly Leaderboard Content (moved from main code)
                userProfile["standard"] < 6
                    ? WeeklyLeaderboardContentForExamPrep()
                    : WeeklyLeaderboardContent()
              ],
            ),
    );
  }
}
