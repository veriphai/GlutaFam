import 'package:eureka_app/screens/ncertPodcasts/cerScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/simulationScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class Sectionscreen extends StatefulWidget {
  final String chapterId;

  const Sectionscreen({
    required this.chapterId,
  });

  @override
  _SectionscreenState createState() => _SectionscreenState();
}

class _SectionscreenState extends State<Sectionscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String chapterName = '';
  String chapterImage = '';
  int chapterNo = 0;
  String subject = '';
  int standard = 0;
  List<dynamic> sections = [];
  late List<Map<String, dynamic>> simulationList = [];
  late List<Map<String, dynamic>> interestLedLessons = [];

  bool isLoading = true;
  bool hasError = false;
  Set<String> bookmarkedSimulations = {};
  Set<String> bookmarkedSections = {};
  Set<String> bookmarkedInterestLedLesson = {};

  bool isBookmarked = false;

  Future<void> fetchChapterDetails() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/chapter?chapterId=${widget.chapterId}';

    try {
      print("Fetching chapter details from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response: ${json.decode(response.body)}");

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        print("Decoded data: $data");

        // Use null-aware operators to assign default values if a key is missing or null.
        setState(() {
          chapterName = data['name'] ?? 'Unknown Chapter';
          chapterImage = data['image'];
          chapterNo = data['chapterNo'] ?? 0;
          subject = data['subject'] ?? 'Unknown Subject';
          sections = data['sections'] ?? [];
          standard = data['standard'] ?? 0;
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

  Future<void> fetchInterestLedDetails() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/interest-led-lessons?chapterId=${widget.chapterId}';

    try {
      print("Fetching chapter details from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response: ${json.decode(response.body)}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Ensure the response is a list of maps (as expected)
        if (data is List &&
            data.isNotEmpty &&
            data[0] is Map<String, dynamic>) {
          setState(() {
            // Safely parse the list of interest-led lessons
            interestLedLessons =
                data.map((e) => e as Map<String, dynamic>).toList();
            // isLoading = false; // Optionally use a loading indicator
          });
        } else {
          setState(() {
            // hasError = true;
            // print("Error: Response is not as expected.");
          });
        }
      } else {
        setState(() {
          // print("Error: Status code ${response.statusCode}");
          // isLoading = false;
          // hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        print("catch error $e");
        // isLoading = false;
        // hasError = true;
      });
    }
  }

  Future<void> fetchSimulations() async {
    final String url =
        'https://glutaclass.com:8080/gluta/sims/fetchV2?subject=${subject}&standard=${standard}&chapterId=${widget.chapterId}&page=0&size=100';

    try {
      print("Fetching data from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response: ${json.decode(response.body)}");

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        print("Decoded data: $data");

        setState(() {
          // Safely parse the 'simulations' list.
          simulationList = (data['simulations'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          // isLoading = false;
        });
      } else {
        setState(() {
          // isLoading = false;
          // hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        // isLoading = false;
        // hasError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchInterestLedDetails();

    fetchChapterDetails().then((_) => fetchSimulations());
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
  void shareChapter() {
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
            // title: Text(
            //   widget.chapterName,
            //   style: const TextStyle(
            //     fontSize: 24,
            //     color: Colors.white,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
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
                                        chapterImage,
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
                                            chapterName,
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
                                            "Chapter ${chapterNo} • ${subject}",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
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
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isBookmarked
                                            ? Icons.bookmark
                                            : Icons
                                                .bookmark_border, // Toggle between filled and outline
                                        color: Colors.grey,
                                      ),
                                      onPressed:
                                          toggleBookmark, // Call bookmark toggle function
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
                                        Icons.share_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed:
                                          shareChapter, // Call share function
                                    ),
                                  ],
                                ),
                              ],
                            )),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: Color.fromRGBO(255, 217, 0, 1),
                            indicatorWeight: 2.0,
                            // isScrollable:
                            //     true,
                            labelColor:
                                Colors.white, // Text color for selected tabs.
                            unselectedLabelColor:
                                Colors.grey, // Text color for unselected tabs.
                            labelStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            unselectedLabelStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.normal),
                            tabs: const [
                              Tab(text: 'Episodes'),
                              Tab(text: 'Interest-Led'),
                              Tab(text: 'Simulations'),
                            ],
                            dividerColor: Colors.transparent,
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Episodes Tab
                              ListView.builder(
                                itemCount: sections.length,
                                itemBuilder: (context, index) {
                                  String section = sections[index]['name'];

                                  return GestureDetector(
                                      // Wrap the whole card in GestureDetector
                                      onTap: () {
                                        // Navigate to PodcastScreen on card tap
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PodcastScreen(
                                              title: sections[index]['name'],
                                              description: sections[index]
                                                      ['description'] ??
                                                  "No description available",
                                              imageUrl: sections[index]
                                                  ['imageUrl'],
                                              audioUrl: sections[index]
                                                      ['audioUrl'] ??
                                                  "",
                                              duration: sections[index]
                                                      ['timeToComplete'] ??
                                                  "Unknown",
                                              chapterName: chapterName,
                                              chapterNo: chapterNo,
                                              cerData: sections[index]
                                                              ['cerList'] !=
                                                          null &&
                                                      sections[index]['cerList']
                                                          .isNotEmpty
                                                  ? sections[index]['cerList']
                                                      [0]
                                                  : <String, dynamic>{},
                                              chapterId: widget.chapterId,
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
                                                            sections[index]
                                                                ['imageUrl'],
                                                            width: 60,
                                                            height: 60,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        Expanded(
                                                          child: Text(
                                                            sections[index]
                                                                ['name'],
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0),
                                                    child: Text(
                                                      sections[index]
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
                                                      "${sections[index]['timeToComplete']} mins",
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
                                                            shareChapter();
                                                            // Handle share action
                                                          },
                                                        ),
                                                        const Spacer(),
                                                        if (sections[index][
                                                                    'cerList'] !=
                                                                null &&
                                                            sections[index]
                                                                    ['cerList']
                                                                .isNotEmpty)
                                                          TextButton(
                                                            style: TextButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Color
                                                                      .fromRGBO(
                                                                          255,
                                                                          217,
                                                                          0,
                                                                          1),
                                                              padding: const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical:
                                                                      8), // Reduced padding
                                                              minimumSize: Size(
                                                                  20,
                                                                  20), // Minimum size for a smaller button
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          CERPage(
                                                                    data: sections[
                                                                            index]
                                                                        [
                                                                        'cerList'][0],
                                                                    chapterId:
                                                                        widget
                                                                            .chapterId,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Go to Case',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 12,
                                                                // decoration: TextDecoration.underline,
                                                                // decorationColor: Colors.white,
                                                              ),
                                                            ),
                                                          ),
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
                                                                  title: sections[
                                                                          index]
                                                                      ['name'],
                                                                  description: sections[
                                                                              index]
                                                                          [
                                                                          'description'] ??
                                                                      "No description available",
                                                                  imageUrl: sections[
                                                                          index]
                                                                      [
                                                                      'imageUrl'],
                                                                  audioUrl:
                                                                      sections[index]
                                                                              [
                                                                              'audioUrl'] ??
                                                                          "",
                                                                  duration: sections[
                                                                              index]
                                                                          [
                                                                          'timeToComplete'] ??
                                                                      "Unknown",
                                                                  chapterName:
                                                                      chapterName,
                                                                  chapterNo:
                                                                      chapterNo,
                                                                  cerData: sections[index]['cerList'] !=
                                                                              null &&
                                                                          sections[index]['cerList']
                                                                              .isNotEmpty
                                                                      ? sections[index]
                                                                              [
                                                                              'cerList']
                                                                          [0]
                                                                      : <String,
                                                                          dynamic>{},
                                                                  chapterId: widget
                                                                      .chapterId,
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
                                          if (index < sections.length - 1)
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
                              // Interest-Led Tab
                              ListView.builder(
                                itemCount: interestLedLessons.length,
                                itemBuilder: (context, index) {
                                  String interestLedId =
                                      interestLedLessons[index]['id'];

                                  return GestureDetector(
                                      // Wrap the whole card in GestureDetector
                                      onTap: () {
                                        // Navigate to PodcastScreen on card tap
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PodcastScreen(
                                              title: interestLedLessons[index]
                                                  ['name'],
                                              description: sections[index]
                                                      ['description'] ??
                                                  "No description available",
                                              imageUrl:
                                                  interestLedLessons[index]
                                                      ['image'],
                                              audioUrl:
                                                  interestLedLessons[index]
                                                          ['audioUrl'] ??
                                                      "",
                                              duration:
                                                  interestLedLessons[index]
                                                          ['timeToComplete'] ??
                                                      "Unknown",
                                              chapterName: chapterName,
                                              chapterNo: chapterNo,
                                              cerData: interestLedLessons[index]
                                                          ['cer'] !=
                                                      null
                                                  ? interestLedLessons[index]
                                                      ['cer']
                                                  : <String, dynamic>{},
                                              chapterId: widget.chapterId,
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
                                                            interestLedLessons[
                                                                index]['image'],
                                                            width: 60,
                                                            height: 60,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        Expanded(
                                                          child: Text(
                                                            interestLedLessons[
                                                                index]['name'],
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0),
                                                    child: Text(
                                                      interestLedLessons[index]
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
                                                      "${interestLedLessons[index]['interest']} • ${interestLedLessons[index]['timeToComplete']} mins",
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
                                                            bookmarkedInterestLedLesson
                                                                    .contains(
                                                                        interestLedId)
                                                                ? Icons.bookmark
                                                                : Icons
                                                                    .bookmark_border,
                                                            color: Colors.grey,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              // Toggle the bookmark state.
                                                              if (bookmarkedInterestLedLesson
                                                                  .contains(
                                                                      interestLedId)) {
                                                                bookmarkedInterestLedLesson
                                                                    .remove(
                                                                        interestLedId);
                                                              } else {
                                                                bookmarkedInterestLedLesson
                                                                    .add(
                                                                        interestLedId);
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
                                                            shareChapter();
                                                            // Handle share action
                                                          },
                                                        ),
                                                        const Spacer(),
                                                        if (interestLedLessons[
                                                                index]['cer'] !=
                                                            null)
                                                          TextButton(
                                                            style: TextButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Color
                                                                      .fromRGBO(
                                                                          255,
                                                                          217,
                                                                          0,
                                                                          1),
                                                              padding: const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical:
                                                                      8), // Reduced padding
                                                              minimumSize: Size(
                                                                  20,
                                                                  20), // Minimum size for a smaller button
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          CERPage(
                                                                    data: interestLedLessons[
                                                                            index]
                                                                        ['cer'],
                                                                    chapterId:
                                                                        widget
                                                                            .chapterId,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Go to Case',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 12,
                                                                // decoration: TextDecoration.underline,
                                                                // decorationColor: Colors.white,
                                                              ),
                                                            ),
                                                          ),
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
                                                                  title: interestLedLessons[
                                                                          index]
                                                                      ['name'],
                                                                  description: interestLedLessons[
                                                                              index]
                                                                          [
                                                                          'description'] ??
                                                                      "No description available",
                                                                  imageUrl: interestLedLessons[
                                                                          index]
                                                                      [
                                                                      'imageUrl'],
                                                                  audioUrl:
                                                                      interestLedLessons[index]
                                                                              [
                                                                              'audioUrl'] ??
                                                                          "",
                                                                  duration: interestLedLessons[
                                                                              index]
                                                                          [
                                                                          'timeToComplete'] ??
                                                                      "Unknown",
                                                                  chapterName:
                                                                      chapterName,
                                                                  chapterNo:
                                                                      chapterNo,
                                                                  cerData: interestLedLessons[index]
                                                                              [
                                                                              'cer'] !=
                                                                          null
                                                                      ? interestLedLessons[
                                                                              index]
                                                                          [
                                                                          'cer']
                                                                      : <String,
                                                                          dynamic>{},
                                                                  chapterId: widget
                                                                      .chapterId,
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
                                          if (index < sections.length - 1)
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
                              // Simulations Tab
                              ListView.builder(
                                itemCount: simulationList.length,
                                itemBuilder: (context, index) {
                                  String simulationId =
                                      simulationList[index]['id'];

                                  return GestureDetector(
                                      // Wrap the whole card in GestureDetector
                                      onTap: () {
                                        // Navigate to PodcastScreen on card tap
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SimulationScreen(
                                                simulationUrl:
                                                    "https://glutaclass.com/app-simulation/${simulationList[index]['id']}"),
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
                                                            simulationList[
                                                                    index][
                                                                'simulationImageUrl'],
                                                            width: 60,
                                                            height: 60,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        Expanded(
                                                          child: Text(
                                                            simulationList[
                                                                index]['name'],
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0),
                                                    child: Text(
                                                      simulationList[index]
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
                                                  // Padding(
                                                  //   padding: const EdgeInsets.symmetric(
                                                  //     horizontal: 8.0,
                                                  //   ),
                                                  //   child: Text(
                                                  //     "20 mins",
                                                  //     style: const TextStyle(
                                                  //       fontSize: 14,
                                                  //       color: Colors.grey,
                                                  //     ),
                                                  //     maxLines: 2,
                                                  //     overflow: TextOverflow.ellipsis,
                                                  //   ),
                                                  // ),
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
                                                            bookmarkedSimulations
                                                                    .contains(
                                                                        simulationId)
                                                                ? Icons.bookmark
                                                                : Icons
                                                                    .bookmark_border,
                                                            color: Colors.grey,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              // Toggle the bookmark state.
                                                              if (bookmarkedSimulations
                                                                  .contains(
                                                                      simulationId)) {
                                                                bookmarkedSimulations
                                                                    .remove(
                                                                        simulationId);
                                                              } else {
                                                                bookmarkedSimulations
                                                                    .add(
                                                                        simulationId);
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
                                                            shareSimulation(
                                                                simulationId);
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
                                                                builder: (context) =>
                                                                    SimulationScreen(
                                                                        simulationUrl:
                                                                            "https://glutaclass.com/app-simulation/${simulationList[index]['id']}"),
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
                                          if (index < simulationList.length - 1)
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
