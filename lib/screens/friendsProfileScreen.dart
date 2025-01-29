import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchAchievements.dart';
import 'package:eureka_app/apis/fetchFriendsProfile.dart';
import 'package:eureka_app/apis/addFriend.dart';
import 'package:eureka_app/screens/friendsScreen.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

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
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  Future<void> getAchievements() async {
    try {
      final data = await fetchAchievements();
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
                    padding: EdgeInsets.only(top: 80),
                    child: profileData.containsKey("avatar")
                        ? Image.network(
                            profileData["avatar"],
                          )
                        : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 150,
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
                          "Joined ${DateTime.fromMillisecondsSinceEpoch(profileData["joiningTime"]).toLocal().toString().split(' ')[0]}",
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
                                    builder: (context) =>
                                        FriendsScreen(), // 0 for "Following"
                                  ),
                                );
                              },
                              child: Text(
                                "${profileData["followingCount"]} Following",
                                style: GoogleFonts.arOneSans(
                                  color: Color.fromRGBO(255, 217, 0, 1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendsScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "${profileData["followersCount"]} Followers",
                                style: GoogleFonts.arOneSans(
                                  color: Color.fromRGBO(255, 217, 0, 1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: 20,
                        ),
                        ChicletAnimatedButton(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              await addFriend(friendId: widget.friendId);
                              // print('${concepts[index]['name']} clicked');
                            },
                            buttonType: ChicletButtonTypes.roundedRectangle,
                            height: 50,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            buttonColor: Color.fromRGBO(187, 160, 2, 1),
                            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    widget.following
                                        ? Icons.person
                                        : Icons.person_add_alt,
                                    color: Colors.black),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  widget.following ? "FOLLOWING" : "FOLLOW",
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
                          Text(
                            "Achievements",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                              itemCount: achievements.length,
                              itemBuilder: (context, index) {
                                final achievement = achievements[index];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Image with padding
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Opacity(
                                        opacity: 0.1,
                                        // achievement["unlocked"] ? 1 : 0.1,
                                        child: Image.network(
                                          achievement["image"],
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // Vertical divider
                                    if (index <
                                        achievements.length -
                                            1) // No divider after the last image
                                      VerticalDivider(
                                        color: Color.fromARGB(255, 91, 91, 91),
                                        thickness: 0.5,
                                        width:
                                            35, // Adjust spacing between image and divider
                                      ),
                                  ],
                                );
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
