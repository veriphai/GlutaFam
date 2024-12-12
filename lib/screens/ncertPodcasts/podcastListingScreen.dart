import 'package:eureka_app/apis/logEventsApi.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class PodcastListingScreen extends StatefulWidget {
  final String filter;
  final int standard;
  final String searchParam;
  final Map<String, dynamic> item;

  const PodcastListingScreen(
      {required this.filter,
      required this.standard,
      required this.searchParam,
      required this.item});

  @override
  _PodcastListingScreenState createState() => _PodcastListingScreenState();
}

class _PodcastListingScreenState extends State<PodcastListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoading = true;
  bool hasError = false;
  Set<String> bookmarkedSimulations = {};
  Set<String> bookmarkedSections = {};
  Set<String> bookmarkedInterestLedLesson = {};
  List<dynamic> podcasts = [];
  final String screenName = "PodcastListingScreen";

  bool isBookmarked = false;

  Future<void> fetchPodcasts() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/podcasts?standard=${widget.standard}&filter=${widget.filter}&searchParam=${widget.searchParam}';

    try {
      print("Fetching podcast details from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response: ${json.decode(response.body)}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print("Decoded data: $data");

        // Use null-aware operators to assign default values if a key is missing or null.
        setState(() {
          podcasts = data;
          isLoading = false;
        });
      } else {
        setState(() {
          print("Error: Status code ${response.statusCode}");
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        print("catch error $e");
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    logPageOpenEvent(
      screenName: screenName,
      eventDetails: {
        "description": "User opened the podcast listing screen",
        "standard": widget.standard,
        "filter": widget.filter,
        "searchParam": widget.searchParam
      },
    );
    fetchPodcasts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void toggleBookmark() {
    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  // Function to handle sharing the chapter link
  void share() {
    final String deepLink = "https://glutaclass.com";

    Share.share('Download GlutaClass App: $deepLink');
  }

  void shareSimulation(simulationId) {
    final String deepLink = "https://glutaclass.com/simulation/${simulationId}";

    Share.share('Check out this simulation: $deepLink');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // On back button press, navigate to the Chapterscreen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    Chapterscreen()), // Replace with your Chapterscreen widget
            (route) =>
                false, // Remove all routes and replace with Chapterscreen
          );
          return false; // Prevent the default back button behavior
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
          ),
          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : hasError
                  ? Center(child: Text('Error fetching data'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        widget.item['image'],
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.item['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.item['description'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // const SizedBox(height: 8),
                                          // ElevatedButton(
                                          //   onPressed: () {
                                          //     // Handle follow or action
                                          //   },
                                          //   style: ElevatedButton.styleFrom(
                                          //     backgroundColor: Colors.green,
                                          //     shape: RoundedRectangleBorder(
                                          //       borderRadius: BorderRadius.circular(20),
                                          //     ),
                                          //   ),
                                          //   child: const Text(
                                          //     'Follow',
                                          //     style: TextStyle(color: Colors.white),
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // SizedBox(height: 10),
                                //   Row(
                                //     mainAxisAlignment: MainAxisAlignment.start,
                                //     children: [
                                //       IconButton(
                                //         icon: Icon(
                                //           isBookmarked
                                //               ? Icons.bookmark
                                //               : Icons
                                //                   .bookmark_border, // Toggle between filled and outline
                                //           color: Colors.grey,
                                //         ),
                                //         onPressed:
                                //             toggleBookmark, // Call bookmark toggle function
                                //       ),
                                //       IconButton(
                                //         icon: const Icon(
                                //           Icons.share_outlined,
                                //           color: Colors.grey,
                                //         ),
                                //         onPressed:
                                //             shareChapter, // Call share function
                                //       ),
                                //     ],
                                //   ),
                              ],
                            )),
                        Align(
                          alignment: Alignment
                              .centerLeft, // Keep alignment to the left
                          child: Transform.translate(
                            offset: Offset(-40,
                                0), // Adjust the first value (X-axis) to move the TabBar left
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: Color.fromRGBO(255, 217, 0, 1),
                              indicatorWeight: 2.0,
                              isScrollable:
                                  true, // Ensures the TabBar takes only necessary width
                              labelColor:
                                  Colors.white, // Text color for selected tabs.
                              unselectedLabelColor: Colors
                                  .grey, // Text color for unselected tabs.
                              labelStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              unselectedLabelStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.normal),
                              tabs: const [
                                Tab(text: 'Episodes'),
                              ],
                              dividerColor: Colors.transparent,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Episodes Tab
                              ListView.builder(
                                itemCount: podcasts.length,
                                itemBuilder: (context, index) {
                                  String section = podcasts[index]['id'];

                                  return GestureDetector(
                                      // Wrap the whole card in GestureDetector
                                      onTap: () {
                                        // Navigate to PodcastScreen on card tap
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PodcastScreen(
                                              title: podcasts[index]['name'],
                                              description: podcasts[index]
                                                      ['description'] ??
                                                  "No description available",
                                              imageUrl: podcasts[index]
                                                  ['image'],
                                              audioUrl: podcasts[index]
                                                      ['audioUrl'] ??
                                                  "",
                                              duration: podcasts[index]
                                                      ['timeToComplete'] ??
                                                  20,
                                              chapterName: podcasts[index]
                                                  ['chapterName'],
                                              chapterNo: podcasts[index]
                                                  ['chapterNo'],
                                              cerData: podcasts[index]['cer'] ??
                                                  <String, dynamic>{},
                                              chapterId: podcasts[index]
                                                  ['chapterId'],
                                              sectionNumber: index,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 0,
                                            ),
                                            child: Card(
                                              color: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child: Image.network(
                                                            podcasts[index]
                                                                ['image'],
                                                            width: 60,
                                                            height: 60,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        Expanded(
                                                            child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                              Text(
                                                                podcasts[index]
                                                                    ['name'],
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              SizedBox(
                                                                height: 5,
                                                              ),
                                                              Text(
                                                                podcasts[index]['chapterName'] !=
                                                                            null &&
                                                                        podcasts[index]['chapterName']
                                                                            .isNotEmpty
                                                                    ? "${podcasts[index]['chapterName']} • ${podcasts[index]['subject']}"
                                                                    : "${podcasts[index]['subject']}",
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ])),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0),
                                                    child: Text(
                                                      podcasts[index]
                                                              ['description'] ??
                                                          "No description available",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8.0,
                                                    ),
                                                    child: Text(
                                                      "${podcasts[index]['timeToComplete']} mins",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            bookmarkedSections
                                                                    .contains(
                                                                        section)
                                                                ? Icons.bookmark
                                                                : Icons
                                                                    .bookmark_border,
                                                            color: Colors.grey,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              // Toggle the bookmark state.
                                                              if (bookmarkedSections
                                                                  .contains(
                                                                      section)) {
                                                                bookmarkedSections
                                                                    .remove(
                                                                        section);
                                                              } else {
                                                                bookmarkedSections
                                                                    .add(
                                                                        section);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                        // IconButton(
                                                        //   icon: const Icon(
                                                        //     Icons.download_rounded,
                                                        //     color: Colors.grey,
                                                        //   ),
                                                        //   onPressed: () {
                                                        //     // Handle download action
                                                        //   },
                                                        // ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .share_outlined,
                                                            color: Colors.grey,
                                                          ),
                                                          onPressed: () {
                                                            share();
                                                            // Handle share action
                                                          },
                                                        ),
                                                        const Spacer(),

                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .play_circle_fill,
                                                            color:
                                                                Color.fromRGBO(
                                                                    255,
                                                                    217,
                                                                    0,
                                                                    1),
                                                            size: 40,
                                                          ),
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        PodcastScreen(
                                                                  title: podcasts[
                                                                          index]
                                                                      ['name'],
                                                                  description: podcasts[
                                                                              index]
                                                                          [
                                                                          'description'] ??
                                                                      "No description available",
                                                                  imageUrl: podcasts[
                                                                          index]
                                                                      ['image'],
                                                                  audioUrl:
                                                                      podcasts[index]
                                                                              [
                                                                              'audioUrl'] ??
                                                                          "",
                                                                  duration: podcasts[
                                                                              index]
                                                                          [
                                                                          'timeToComplete'] ??
                                                                      "Unknown",
                                                                  chapterName: podcasts[
                                                                          index]
                                                                      [
                                                                      'chapterName'],
                                                                  chapterNo: podcasts[
                                                                          index]
                                                                      [
                                                                      'chapterNo'],
                                                                  cerData: podcasts[
                                                                              index]
                                                                          [
                                                                          'cer'] ??
                                                                      <String,
                                                                          dynamic>{},
                                                                  chapterId: podcasts[
                                                                          index]
                                                                      [
                                                                      'chapterId'],
                                                                  sectionNumber:
                                                                      index,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (index < podcasts.length - 1)
                                            const Divider(
                                              color: Colors.grey,
                                              thickness: 0.5,
                                              indent: 16,
                                              endIndent: 16,
                                            ),
                                        ],
                                      ));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ));
  }
}
