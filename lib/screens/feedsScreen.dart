import 'package:bubble_box/bubble_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchFeeds.dart';
import 'package:eureka_app/apis/reactOnFeed.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/newEvents/profileScreenEvents.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/widgets/feedActionButtons.dart';
import 'package:eureka_app/widgets/findMyFriendsWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> feedData = [];
  bool isLoading = true;
  late Map<String, dynamic> userProfile;

  Future<void> getFeeds() async {
    try {
      final feeds = await fetchFeeds();
      feeds.sort((a, b) => b["time"].compareTo(a["time"]));

      setState(() {
        feedData = feeds;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching feeds: $error");
    }
  }

  Future<void> fetchProfile() async {
    try {
      final profileData = await getProfile();

      setState(() {
        userProfile = profileData;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    getFeeds();
    fetchProfile();
  }

  String getTimeDifferenceFromEpoch(int epochTimeInSeconds) {
    DateTime currentTime = DateTime.now();
    DateTime feedTime =
        DateTime.fromMillisecondsSinceEpoch(epochTimeInSeconds * 1000);
    Duration difference = currentTime.difference(feedTime);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds} seconds ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }

  Widget buildFeedContainerForNudge(Map<String, dynamic> feed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 91, 91, 91)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Profile Image, Name, and Feed Image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Description Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        feed.containsKey("userAvatar")
                            ? Image.asset(
                                getAvatar(feed["userAvatar"])["imagePath"]!,
                                height: 50,
                                fit: BoxFit.scaleDown,
                              )
                            : Image.asset(
                                getAvatar("random")["imagePath"]!,
                                height: 50,
                                fit: BoxFit.scaleDown,
                              ),
                        const SizedBox(
                            width: 8), // Spacing between avatar and name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(
                                feed['name'],
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Text(
                                "nudged you",
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              )
                            ]),
                            Text(
                              getTimeDifferenceFromEpoch(feed["time"]),
                              style: GoogleFonts.arOneSans(
                                color: const Color.fromARGB(255, 91, 91, 91),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    BubbleBox(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                      shape: BubbleShapeBorder(
                        border: BubbleBoxBorder(
                          color: Colors.grey.shade700,
                          width: 3,
                        ),
                        radius: BorderRadius.circular(12),
                        position: const BubblePosition.start(20),
                        direction: BubbleDirection.top,
                        arrowHeight: 12,
                      ),
                      backgroundColor: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feed["feedData"]["heading"],
                                  style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  feed["feedData"]["message"],
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                              ],
                            )),
                            const SizedBox(width: 10),
                            Image.asset(feed["feedData"]["image"], height: 50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ActionButton(
                buttonText: "View Friend Quest",
                feed: feed,
                isReacted: feed.containsKey("feedReactions") &&
                    (feed["feedReactions"] as Map<String, dynamic>)
                        .containsKey(userProfile["id"]),
                onPress: () {
                  HapticFeedback.lightImpact();
                  reactOnFeed(feedId: feed["id"]);
                },
              ),
              if (feed.containsKey("feedReactions"))
                Row(children: [
                  Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color.fromARGB(255, 91, 91, 91))),
                      child: Icon(
                        Icons.celebration_rounded,
                        color: Colors.white,
                      )),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    "${feed["feedReactions"].length}",
                    style: GoogleFonts.raleway(
                      color: Color.fromARGB(255, 91, 91, 91),
                      fontSize: 18,
                    ),
                  )
                ])
            ],
          )
        ],
      ),
    );
  }

  Widget buildFeedContainer(Map<String, dynamic> feed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 91, 91, 91)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Profile Image, Name, and Feed Image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Description Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        feed.containsKey("userAvatar")
                            ? Image.asset(
                                getAvatar(feed["userAvatar"])["imagePath"]!,
                                height: 50,
                                fit: BoxFit.scaleDown,
                              )
                            : Image.asset(
                                getAvatar("random")["imagePath"]!,
                                height: 50,
                                fit: BoxFit.scaleDown,
                              ),
                        const SizedBox(
                            width: 8), // Spacing between avatar and name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feed['name'],
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              getTimeDifferenceFromEpoch(feed["time"]),
                              style: GoogleFonts.arOneSans(
                                color: const Color.fromARGB(255, 91, 91, 91),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 16), // Spacing between name and description
                    SizedBox(
                        height: 50,
                        child: Text(
                          feed['description'],
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          maxLines: 2, // Ensure text doesn't overflow
                          overflow: TextOverflow.ellipsis,
                        )),
                  ],
                ),
              ),
              const SizedBox(
                  width: 16), // Spacing between description and image
              // Feed Image
              CachedNetworkImage(
                imageUrl: feed['feedImage'],
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ],
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ActionButton(
                buttonText: feed["feedButton"],
                feed: feed,
                isReacted: feed.containsKey("feedReactions") &&
                    (feed["feedReactions"] as Map<String, dynamic>)
                        .containsKey(userProfile["id"]),
                onPress: () {
                  reactOnFeed(feedId: feed["id"]);
                },
              ),
              if (feed.containsKey("feedReactions"))
                Row(children: [
                  Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color.fromARGB(255, 91, 91, 91))),
                      child: Icon(
                        Icons.celebration_rounded,
                        color: Colors.white,
                      )),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    "${feed["feedReactions"].length}",
                    style: GoogleFonts.raleway(
                      color: Color.fromARGB(255, 91, 91, 91),
                      fontSize: 18,
                    ),
                  )
                ])
            ],
          )
        ],
      ),
    );
  }

  Widget buildEmptyFeedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset("lib/assets/animations/coolCat.json",
              fit: BoxFit.cover, height: 250, width: 250),
          const SizedBox(height: 24),
          Text(
            "Nothing here yet!",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let’s get the ball rolling.",
            style: GoogleFonts.raleway(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ChicletAnimatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => MainPage(initialIndex: 0)),
                (route) => false,
              );
            },
            width: 220,
            height: 48,
            buttonType: ChicletButtonTypes.roundedRectangle,
            buttonColor: Color.fromRGBO(187, 160, 2, 1),
            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
            child: Text(
              "EXPLORE LESSONS",
              style: GoogleFonts.raleway(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              logAddFriendsClicked();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FindMyFriendsScreen(
                          profileData: userProfile,
                        )),
              );
              // Add logic to invite friends
            },
            child: Text(
              "🎯 Invite friends to GlutaClass",
              style: GoogleFonts.raleway(
                color: Color.fromRGBO(255, 217, 0, 1),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Feed",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        scrolledUnderElevation: 0,
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        elevation: 0,
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
          : feedData.isEmpty
              ? buildEmptyFeedView(context)
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: feedData.length,
                    itemBuilder: (context, index) {
                      final feed = feedData[index];
                      if (feed["hidden"]) {
                        return Container();
                      }
                      if (feed["type"] != "NUDGE") {
                        return buildFeedContainer(feed);
                      } else {
                        return buildFeedContainerForNudge(feed);
                      }
                    },
                  ),
                ),
    );
  }
}
