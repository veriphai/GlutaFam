import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchFeeds.dart';
import 'package:eureka_app/widgets/feedActionButtons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> feedData = [];
  bool isLoading = true;

  Future<void> getFeeds() async {
    try {
      final feeds = await fetchFeeds();

      setState(() {
        feedData = feeds;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching feeds: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    getFeeds();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        title: Text(
          "Feed",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: feedData.length,
                itemBuilder: (context, index) {
                  final feed = feedData[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color.fromARGB(255, 91, 91, 91)),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.yellow,
                                        child: Text(
                                          feed['name'][0],
                                          style: GoogleFonts.raleway(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              8), // Spacing between avatar and name
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            getTimeDifferenceFromEpoch(
                                                feed["time"]),
                                            style: GoogleFonts.arOneSans(
                                              color: const Color.fromARGB(
                                                  255, 91, 91, 91),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                      height:
                                          16), // Spacing between name and description
                                  SizedBox(
                                      height: 44,
                                      child: Text(
                                        feed['description'],
                                        style: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                        maxLines:
                                            2, // Ensure text doesn't overflow
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(
                                width:
                                    16), // Spacing between description and image
                            // Feed Image
                            Image.network(
                              feed['feedImage'],
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                        const SizedBox(
                            height:
                                36), // Spacing between feed details and the action button
                        ActionButton(
                          buttonText: feed["feedButton"],
                          feed: feed,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
