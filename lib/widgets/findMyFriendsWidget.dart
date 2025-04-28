import 'package:eureka_app/apis/fetchFriendSuggestions.dart';
import 'package:eureka_app/apis/addFriend.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/utils/generateProfileCardForSharing.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class FindMyFriendsScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const FindMyFriendsScreen({
    Key? key,
    required this.profileData,
  }) : super(key: key);

  @override
  _FindMyFriendsScreenState createState() => _FindMyFriendsScreenState();
}

class _FindMyFriendsScreenState extends State<FindMyFriendsScreen> {
  List<Map<String, dynamic>> friendSuggestions = [];
  List<String> followedFriends = [];
  bool isLoading = true;

  Future<void> getFriendSuggestions() async {
    try {
      final data = await fetchFriendSuggestions();
      // final userProfile = await refreshProfile();

      setState(() {
        friendSuggestions = data;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching friend suggestions: $error");
    }
  }

  void _shareFollowLink() async {
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
      final profileLink = await generateProfileLink(widget.profileData["id"]);

      // Generate Image with Achievement Details
      final imagePath = await generateProfileCard(context, widget.profileData);

      Navigator.pop(context); // Close the loading dialog

      // Share both the image and the link
      if (imagePath != null) {
        final xFile = XFile(imagePath);
        Share.shareXFiles(
          [xFile],
          text:
              "Check out ${widget.profileData["firstName"]}'s profile on YourApp!\n$profileLink",
          subject: "Follow ${widget.profileData["firstName"]} on YourApp",
        );
      } else {
        // If image generation fails, share only the link
        Share.share(
          "Check out ${widget.profileData["firstName"]}'s profile on YourApp!\n$profileLink",
          subject: "Follow ${widget.profileData["firstName"]} on YourApp",
        );
      }
    } catch (e) {
      print("Error sharing achievement: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getFriendSuggestions();
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
                    following:
                        followedFriends.contains(friendSuggestion["id"]))),
          );
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
                      // Follow button
                      ChicletAnimatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await addFriend(friendId: friendSuggestion["id"]);
                          setState(() {
                            followedFriends.add(friendSuggestion["id"]);
                          });
                          // fetchProfile();
                        },
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        width: 100,
                        height: 30,
                        padding: EdgeInsets.all(0),
                        buttonColor:
                            followedFriends.contains(friendSuggestion["id"])
                                ? Color.fromRGBO(19, 116, 40, 1)
                                : Color.fromRGBO(187, 160, 2, 1),
                        backgroundColor:
                            followedFriends.contains(friendSuggestion["id"])
                                ? Color.fromRGBO(29, 195, 65, 1)
                                : Color.fromRGBO(255, 217, 0, 1),
                        borderRadius: 12,
                        child: Text(
                          followedFriends.contains(friendSuggestion["id"])
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(19, 31, 36, 1),
          iconTheme: IconThemeData(
            color: Colors.grey,
          ),
          centerTitle: false, // good to keep for Android
          title: Align(
            alignment: Alignment.centerLeft, // This forces left alignment
            child: Text(
              "Find My Friends",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Card
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[800],
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Avatar
                              Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.green[900],
                                  ),
                                  padding: EdgeInsets.only(top: 0),
                                  width: double.infinity,
                                  child: Image.asset(
                                    getAvatar(widget.profileData["avatar"])[
                                        "imagePath"]!,
                                    height: 250,
                                  )),
                              const SizedBox(height: 16),

                              // User Name
                              Text(
                                widget.profileData["firstName"],
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // User Username
                              Text(
                                "@${widget.profileData["userName"]}",
                                style: GoogleFonts.raleway(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                "GLUTACLASS",
                                style: GoogleFonts.raleway(
                                  color: Colors.yellow,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Share Follow Link Button
                      ChicletAnimatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _shareFollowLink();
                        },
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        height: 50,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                        backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.ios_share_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "SHARE FOLLOW LINK",
                              style: GoogleFonts.raleway(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (friendSuggestions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 16),
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
                                height:
                                    180, // Adjust the height as per the design
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
                    ],
                  ),
                ),
              ));
  }
}
