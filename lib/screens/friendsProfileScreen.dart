import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchAchievements.dart';
import 'package:eureka_app/apis/fetchFriendsProfile.dart';
import 'package:eureka_app/apis/addFriend.dart';
import 'package:eureka_app/screens/achievementsScreen.dart';
import 'package:eureka_app/screens/friendsScreen.dart';
import 'package:eureka_app/utils/achievements.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/widgets/achievementDetailsWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class FriendsProfileScreen extends StatefulWidget {
  final String friendId;
  final bool following;

  const FriendsProfileScreen(
      {Key? key, required this.friendId, required this.following})
      : super(key: key);
  @override
  _FriendsProfileScreenState createState() => _FriendsProfileScreenState();
}

class _FriendsProfileScreenState extends State<FriendsProfileScreen> {
  late Map<String, dynamic> profileData;
  List<Map<String, dynamic>> achievements = [];
  late Map<String, String>? avatar;
  late bool isFriend;
  late bool friendAdded = false;
  late int friends;

  bool isLoading = true;

  Future<void> fetchProfile() async {
    try {
      String encodedFriendId = widget.friendId.startsWith('+')
          ? widget.friendId.replaceFirst('+', '%2B')
          : widget.friendId;

      final userProfile = await fetchFriendsProfile(friendsId: encodedFriendId);
      // final userProfile = await refreshProfile();

      setState(() {
        profileData = userProfile;
        avatar = getAvatar(userProfile.containsKey("avatar")
            ? userProfile["avatar"]
            : "random");

        isLoading = false;
        friends = userProfile["friends"].length;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  Future<void> getAchievements() async {
    try {
      String encodedFriendId = widget.friendId.startsWith('+')
          ? widget.friendId.replaceFirst('+', '%2B')
          : widget.friendId;
      final data = await fetchAchievements(friendsId: encodedFriendId);
      // final userProfile = await refreshProfile();

      setState(() {
        achievements = data;
        // isLoading = false;
      });
    } catch (error) {
      print("Error fetching achievements: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
    getAchievements();
    isFriend = widget.following;
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      builder: (context) {
        return AchievementDetailsWidget(
          achievement: achievement,
          friendsAchievement: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
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
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Container
                  Container(
                    height: 230,
                    color: Colors.orange,
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(top: 40),
                    child: Stack(
                      children: [
                        // Avatar Image or Placeholder
                        Center(
                          child: avatar != null
                              ? Image.asset(
                                  avatar!['imagePath'] ?? '',
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 150,
                                ),
                        ),

                        // Edit Icon Positioned at the Top Right of the Container
                        Positioned(
                          top: 0,
                          left: 10,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context, friendAdded);
                            },
                            child: Icon(
                              Icons.arrow_back,
                              color: Color.fromRGBO(19, 31, 36, 1),
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Personal Details Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Standard
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              profileData.containsKey("firstName")
                                  ? profileData["firstName"]
                                  : "Dummy",
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "Class ${profileData["standard"]}",
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "@${profileData["userName"]}",
                          style: GoogleFonts.raleway(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Joined ${DateFormat('MMMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(profileData["joiningTime"] * 1000).toLocal())}",
                          style: GoogleFonts.raleway(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendsScreen(
                                      userId: widget.friendId,
                                    ), // 0 for "Following"
                                  ),
                                );
                              },
                              child: Text(
                                "$friends Friends",
                                style: GoogleFonts.arOneSans(
                                  color: Color.fromRGBO(255, 217, 0, 1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          ],
                        ),

                        SizedBox(
                          height: 20,
                        ),
                        ChicletAnimatedButton(
                            onPressed: isFriend
                                ? null
                                : () async {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      isFriend = true;
                                      friendAdded = true;
                                      friends += 1;
                                    });
                                    await addFriend(friendId: widget.friendId);
                                    // print('${concepts[index]['name']} clicked');
                                  },
                            buttonType: ChicletButtonTypes.roundedRectangle,
                            height: 50,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            buttonColor: isFriend
                                ? Color.fromRGBO(29, 195, 65, 1)
                                : Color.fromRGBO(187, 160, 2, 1),
                            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    isFriend
                                        ? Icons.person
                                        : Icons.person_add_alt,
                                    color: Colors.black),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  isFriend ? "ADDED" : "ADD FRIEND",
                                  style: GoogleFonts.raleway(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),

                  Divider(
                    color: Colors.grey,
                  ),

                  SizedBox(
                    height: 16,
                  ),
                  // Overview Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Overview",
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2.5,
                      ),
                      children: [
                        _buildOverviewTile(
                            "Day Streak",
                            profileData["streakActive"]
                                ? "${profileData["streakDetails"]["activeDays"]}"
                                : "0",
                            'lib/assets/streakIcon.png'),
                        _buildOverviewTile(
                            "Total XP",
                            "${profileData["totalXP"]}",
                            'lib/assets/xpIcon.png'),
                        _buildOverviewTile(
                            "Current League",
                            fetchLeague(profileData["league"]),
                            'lib/assets/gemIcon.png'),
                        _buildOverviewTile(
                            "Top 3 Finishes",
                            "${profileData["topThreeFinishes"]}",
                            'lib/assets/topFinishesIcon.png'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Achievements Section
                  if (achievements.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Achievements",
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to the AchievementsPage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AchievementsPage(
                                            achievements: achievements),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "VIEW ALL",
                                    style: GoogleFonts.raleway(
                                      color: Colors.yellow,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              ]),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Color.fromARGB(255, 91, 91, 91)),
                            ),
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                final achievement = achievements[index];
                                final achievementImage =
                                    getAchievement(achievement["id"]);
                                final currentLevelIndex =
                                    achievement["currentLevel"] ?? 0;
                                final levels = achievement["levels"] ?? [];
                                final int adjustedLevelIndex =
                                    currentLevelIndex > 0
                                        ? currentLevelIndex - 1
                                        : currentLevelIndex;

                                final level = adjustedLevelIndex < levels.length
                                    ? levels[adjustedLevelIndex]
                                    : null;
                                return GestureDetector(
                                    onTap: () =>
                                        _showAchievementDetails(achievement),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Image with padding
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3.0),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                height: 120,
                                                width: 120,
                                                child: Center(
                                                  child: SizedBox(
                                                    height: 110,
                                                    width: 110,
                                                    child: Opacity(
                                                      opacity: achievement[
                                                              "unlocked"]
                                                          ? 1
                                                          : 0.1,
                                                      child: Image.asset(
                                                        getAchievement(
                                                                    achievement[
                                                                        "id"])?[
                                                                "imagePath"] ??
                                                            'lib/assets/placeholder.png',
                                                        color: achievement[
                                                                "unlocked"]
                                                            ? null
                                                            : Colors.grey,
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
                                                      style:
                                                          GoogleFonts.raleway(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        foreground: Paint()
                                                          ..style =
                                                              PaintingStyle
                                                                  .stroke
                                                          ..strokeWidth = 5
                                                          ..color = achievement[
                                                                  "unlocked"]
                                                              ? const Color
                                                                  .fromARGB(255,
                                                                  159, 129, 81)
                                                              : Colors
                                                                  .grey, // Outline color
                                                      ),
                                                    ),
                                                    // Filled Text
                                                    Text(
                                                      "${level["criteria"]}",
                                                      style:
                                                          GoogleFonts.raleway(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: achievement[
                                                                "unlocked"]
                                                            ? Colors.white
                                                            : const Color
                                                                .fromRGBO(
                                                                19, 31, 36, 1),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Vertical divider
                                        if (index <
                                            2) // No divider after the last image
                                          VerticalDivider(
                                            color:
                                                Color.fromARGB(255, 91, 91, 91),
                                            thickness: 0.5,
                                            width:
                                                0, // Adjust spacing between image and divider
                                          ),
                                      ],
                                    ));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewTile(String title, String value, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromARGB(255, 91, 91, 91)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                height: 30,
                width: 30,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.raleway(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
