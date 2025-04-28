import 'dart:math';

import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchAchievements.dart';
import 'package:eureka_app/apis/fetchFriendSuggestions.dart';
import 'package:eureka_app/apis/addFriend.dart';
import 'package:eureka_app/apis/updateAvatar.dart';
import 'package:eureka_app/apis/updateStandard.dart';
import 'package:eureka_app/newEvents/profileScreenEvents.dart';
import 'package:eureka_app/screens/achievementsScreen.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:eureka_app/screens/friendsScreen.dart';
import 'package:eureka_app/utils/achievements.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/utils/generateProfileCardForSharing.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';
import 'package:eureka_app/widgets/achievementDetailsWidget.dart';
import 'package:eureka_app/widgets/avatarSelectionScreen.dart';
import 'package:eureka_app/widgets/collectionDetailsWidget.dart';
import 'package:eureka_app/widgets/findMyFriendsWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> profileData;
  List<Map<String, dynamic>> achievements = [];
  List<Map<String, dynamic>> friendSuggestions = [];
  late int standard;
  String? selectedStream;
  late SharedPreferences prefs;
  List<String> friends = [];
  late int friendsCount;
  late Map<String, String>? avatar;

  bool isLoading = true;

  final List<Map<String, dynamic>> classOptions = [
    {"text": "Class 6", "standard": 6},
    {"text": "Class 7", "standard": 7},
    {"text": "Class 8", "standard": 8},
    {"text": "Class 9", "standard": 9},
    {"text": "Class 10", "standard": 10},
    {"text": "Class 11 - Science", "standard": 11, "stream": "Science"},
    {"text": "Class 11 - Commerce", "standard": 11, "stream": "Commerce"},
    {"text": "Class 11 - Humanities", "standard": 11, "stream": "Humanities"},
    {"text": "Class 12 - Science", "standard": 12, "stream": "Science"},
    {"text": "Class 12 - Commerce", "standard": 12, "stream": "Commerce"},
    {"text": "Class 12 - Humanities", "standard": 12, "stream": "Humanities"}
  ];

  Future<void> fetchProfile() async {
    try {
      // final userProfile = await getProfile();
      final userProfile = await refreshProfile();
      prefs = await SharedPreferences.getInstance();

      setState(() {
        profileData = userProfile;
        standard = userProfile["standard"];
        prefs.setInt('selected_class', profileData["standard"]);
        friendsCount = userProfile["friends"].length;
        avatar = getAvatar(userProfile["avatar"]);

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

  Future<void> getFriendSuggestions() async {
    try {
      final data = await fetchFriendSuggestions();
      // final userProfile = await refreshProfile();

      setState(() {
        friendSuggestions = data;
        // isLoading = false;
      });
    } catch (error) {
      print("Error fetching friend suggestions: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    logProfileScreenView();
    fetchProfile();
    getAchievements();
    getFriendSuggestions();
  }

  void _shareProfileLink(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing while loading
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ),
      );
      final profileLink = await generateProfileLink(profileData["id"]);

      // Generate Image with Achievement Details
      final imagePath = await generateProfileCard(context, profileData);

      Navigator.pop(context); // Close the loading dialog

      // Share both the image and the link
      if (imagePath != null) {
        final xFile = XFile(imagePath);
        Share.shareXFiles(
          [xFile],
          text:
              "Check out ${profileData["firstName"]}'s profile on YourApp!\n$profileLink",
          subject: "Follow ${profileData["firstName"]} on YourApp",
        );
      } else {
        // If image generation fails, share only the link
        Share.share(
          "Check out ${profileData["firstName"]}'s profile on YourApp!\n$profileLink",
          subject: "Follow ${profileData["firstName"]} on YourApp",
        );
      }
    } catch (e) {
      print("Error sharing achievement: $e");
    }
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      builder: (context) {
        return AchievementDetailsWidget(achievement: achievement);
      },
    ).then((_) => getAchievements());
  }

  void _showCollectionItemDetails(Map<String, dynamic> collectionItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      builder: (context) {
        return CollectionDetailsWidget(
          collectionItem: collectionItem,
          feedOwner: true,
        );
      },
    );
  }

  void editAvatar() async {
    final selectedAvatarKey = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarSelectionScreen(
          initialAvatarKey: profileData["avatar"],
        ),
      ),
    );

    if (selectedAvatarKey != null) {
      setState(() {
        profileData["avatar"] = selectedAvatarKey;
        avatar = getAvatar(selectedAvatarKey);
      });

      await updateAvatar(avatarId: selectedAvatarKey);
    }
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
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              editAvatar();
                            },
                            child: Icon(
                              Icons.edit_outlined,
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
                              profileData["firstName"],
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  logClassSelectionClicked();
                                  _showClassSelectionBottomSheet();
                                },
                                child: Row(children: [
                                  Text(
                                    "Class $standard",
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                  )
                                ])),
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
                                logViewFriendsClicked();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendsScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "$friendsCount Friends",
                                style: GoogleFonts.arOneSans(
                                  color: Color.fromRGBO(255, 217, 0, 1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            )
                          ],
                        ),

                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Add Friends Button
                            Expanded(
                              child: ChicletAnimatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  logAddFriendsClicked();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            FindMyFriendsScreen(
                                              profileData: profileData,
                                            )),
                                  );

                                  // Logic for adding friends
                                },
                                buttonType: ChicletButtonTypes.roundedRectangle,
                                height: 50,
                                padding: const EdgeInsets.all(8),
                                buttonColor:
                                    const Color.fromRGBO(187, 160, 2, 1),
                                backgroundColor:
                                    const Color.fromRGBO(255, 217, 0, 1),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_add_alt,
                                        color: Colors.black),
                                    const SizedBox(width: 10),
                                    Text(
                                      "ADD FRIENDS",
                                      style: GoogleFonts.raleway(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 16), // Spacing between buttons

                            // Share Button
                            ChicletAnimatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                logShareProfileClicked();
                                _shareProfileLink(context);
                              },
                              buttonType: ChicletButtonTypes.roundedRectangle,
                              height: 50,
                              padding: const EdgeInsets.all(8),
                              buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                              backgroundColor:
                                  const Color.fromRGBO(255, 217, 0, 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.ios_share_rounded,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                                    HapticFeedback.lightImpact();
                                    logViewAllAchievementsClicked();
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
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      logAchievementClicked(achievement['id']);
                                      _showAchievementDetails(achievement);
                                    },
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
                  if (friendSuggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Friend suggestions",
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 180, // Adjust the height as per the design
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: friendSuggestions.length,
                              itemBuilder: (context, index) {
                                return buildFriendCard(
                                    friendSuggestions[index], index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 20,
                  ),
                  if (profileData.containsKey("userCollection") &&
                      profileData["userCollection"].isNotEmpty)
                    _buildUserCollectionsSection(),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildFriendCard(Map<String, dynamic> friendSuggestion, int index) {
    return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FriendsProfileScreen(
                    friendId: friendSuggestion["id"],
                    following: friends.contains(friendSuggestion["id"]))),
          ).then((value) {
            if (value) {
              setState(() {
                friendsCount += 1;
                friends.add(friendSuggestion["id"]);
              });
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            width: 130, // Adjust card width as per your design
            decoration: BoxDecoration(
              border: Border.all(color: Color.fromARGB(255, 91, 91, 91)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Cross button
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close,
                        color: Color.fromARGB(255, 91, 91, 91), size: 16),
                    onPressed: () {
                      setState(() {
                        friendSuggestions.removeAt(index); // Remove the card
                      });
                    },
                  ),
                ),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(children: [
                      SizedBox(height: 20),

                      // Friend image

                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                            color: Colors.amber,
                            child: Image.asset(
                              getAvatar(
                                  friendSuggestion["avatar"])["imagePath"]!,
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            )),
                      ),
                      SizedBox(height: 8),
                      // Friend name
                      Text(
                        friendSuggestion.containsKey("name") &&
                                friendSuggestion["name"] != null
                            ? friendSuggestion["name"]
                            : "Dummy",
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      // Friend suggestion hint
                      Text(
                        "You may know each other",
                        style: GoogleFonts.raleway(
                          color: Color.fromARGB(255, 91, 91, 91),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ChicletAnimatedButton(
                        onPressed: friends.contains(friendSuggestion["id"])
                            ? null
                            : () async {
                                HapticFeedback.lightImpact();
                                await addFriend(
                                    friendId: friendSuggestion["id"]);
                                logFriendAddedFromSuggestions(
                                    friendSuggestion["id"]);
                                setState(() {
                                  friendsCount += 1;
                                  friends.add(friendSuggestion["id"]);
                                });
                                // fetchProfile();
                              },
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        width: 100,
                        height: 30,
                        padding: EdgeInsets.all(0),
                        buttonColor: friends.contains(friendSuggestion["id"])
                            ? Color.fromRGBO(29, 195, 65, 1)
                            : Color.fromRGBO(187, 160, 2, 1),
                        backgroundColor:
                            friends.contains(friendSuggestion["id"])
                                ? Color.fromRGBO(29, 195, 65, 1)
                                : Color.fromRGBO(255, 217, 0, 1),
                        borderRadius: 12,
                        child: Text(
                          friends.contains(friendSuggestion["id"])
                              ? "ADDED"
                              : "ADD",
                          style: GoogleFonts.raleway(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ]))
              ],
            ),
          ),
        ));
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

  Widget _buildUserCollectionsSection() {
    final userCollection =
        profileData["userCollection"] as Map<String, dynamic>;
    final List<Map<String, dynamic>> collectionItems = userCollection.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Collection",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1,
            ),
            itemCount: collectionItems.length,
            itemBuilder: (context, index) {
              final item = collectionItems[index];
              return _buildCollectionTile(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTile(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        logCollectionItemClicked(item['id']);
        _showCollectionItemDetails(item);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item["image"] ?? "",
              height: 100,
              width: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image, size: 60, color: Colors.grey);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClassSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled:
          true, // Allows the modal to expand for scrollable content
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.5, // Set max height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: classOptions.length,
                  itemBuilder: (context, index) {
                    final classOption = classOptions[index];
                    final String text = classOption['text'];
                    final int standardValue = classOption['standard'];
                    final String? stream = classOption['stream'];

                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            text,
                            style: GoogleFonts.raleway(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: (standard > 10
                                      ? (standardValue == standard &&
                                          stream == selectedStream)
                                      : (standardValue == standard))
                                  ? const Color.fromRGBO(
                                      255, 217, 0, 1) // Selected color
                                  : Colors.white, // Default color
                            ),
                          ),
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await prefs.setInt('selected_class', standardValue);
                            if (stream != null) {
                              await prefs.setString('selected_stream', stream);
                            } else {
                              await prefs.remove(
                                  'selected_stream'); // Clear stream for lower classes
                            }

                            setState(() {
                              standard = standardValue;
                              selectedStream =
                                  stream; // Update state with stream
                            });

                            await updateStandard(
                                standard: standardValue, stream: stream);
                            logClassUpdated(standard, stream ?? '');

                            // Close the bottom sheet
                            Navigator.pop(context);
                          },
                        ),
                        if (index < classOptions.length - 1)
                          Divider(
                              color: Colors
                                  .grey[800]), // Divider between ListTiles
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
