import 'package:eureka_app/apis/logEventsApi.dart';
import 'package:eureka_app/screens/ncertPodcasts/cerScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/endQuestionsScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/miniPlayer.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/simulationScreen.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

class Sectionscreen extends StatefulWidget {
  final String chapterId;

  const Sectionscreen({
    required this.chapterId,
  });

  @override
  _SectionscreenState createState() => _SectionscreenState();
}

class _SectionscreenState extends State<Sectionscreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final String screenName = "SectionListingScreen";

  String chapterName = '';
  String chapterImage = '';
  String pdfUrl = '';
  String bookName = '';

  int chapterNo = 0;
  String subject = '';
  int standard = 0;
  List<dynamic> sections = [];
  late List<Map<String, dynamic>> simulationList = [];
  late List<Map<String, dynamic>> interestLedLessons = [];
  bool showSimulationsTab = false;

  bool isLoading = true;
  bool hasError = false;
  Set<String> bookmarkedSimulations = {};
  Set<String> bookmarkedSections = {};
  Set<String> bookmarkedInterestLedLesson = {};
  final http.Client client = http.Client();

  bool isBookmarked = false;

  Future<void> fetchChapterDetails() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/chapter?chapterId=${widget.chapterId}';

    try {
      print("Fetching chapter details from API: $url");

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept-Encoding': 'gzip',
        },
      );
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
          bookName = data['bookName'] ?? 'Unknown Book Name';
          sections = data['sections'] ?? [];
          standard = data['standard'] ?? 0;
          pdfUrl = data['pdfUrl'] ?? '';
          isLoading = false;

          showSimulationsTab = data['subject'].toLowerCase() == 'science';
          _setupTabController();
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

  void _setupTabController() {
    // Set tab controller length based on whether the Simulations tab should be shown
    _tabController = TabController(
      length: showSimulationsTab ? 2 : 1,
      vsync: this,
    );
  }

  Future<void> fetchInterestLedDetails() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/interest-led-lessons?chapterId=${widget.chapterId}';

    try {
      print("Fetching chapter details from API: $url");

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept-Encoding': 'gzip',
        },
      );
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

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept-Encoding': 'gzip',
        },
      );
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
    _setupTabController();
    logPageOpenEvent(
      screenName: screenName,
      eventDetails: {
        "description": "User opened the section listing page",
        "chapterId": widget.chapterId
      },
    );
    // fetchInterestLedDetails();

    fetchChapterDetails().then((_) => fetchSimulations());
    Future<void> _setCurrentScreen() async {
      await FirebaseAnalytics.instance
          .logEvent(name: 'screen_view', parameters: {
        'firebase_screen': "Section Listing Screen",
        'firebase_screen_class': "Sectionscreen",
      });
    }
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
              // automaticallyImplyLeading: true,
              // leading: IconButton(
              //   icon: Icon(Icons.arrow_back),
              //   onPressed: _exitAndShowMiniPlayer,
              // ),
            ),
            body: isLoading
                ? Center(child: CircularProgressIndicator())
                : hasError
                    ? Center(child: Text('Error fetching data'))
                    : Stack(children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                                "Chapter ${chapterNo} • ${bookName}",
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                        // SizedBox(
                                        //   width: 20,
                                        // ),
                                        Spacer(),
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10),
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color.fromRGBO(
                                                    255, 217, 0, 1),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.question_answer_outlined,
                                                color: Colors.black,
                                              ),
                                              label: Text(
                                                'Go To Book Q&A',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              onPressed: () async {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EndQuestionScreen(
                                                            chapterId: widget
                                                                .chapterId),
                                                  ),
                                                );

                                                // Add functionality for the microphone button here
                                              },
                                            ))
                                      ],
                                    ),
                                  ],
                                )),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: showSimulationsTab
                                  ? TabBar(
                                      controller: _tabController,
                                      indicatorColor:
                                          Color.fromRGBO(255, 217, 0, 1),
                                      indicatorWeight: 2.0,
                                      labelColor: Colors
                                          .white, // Text color for selected tabs
                                      unselectedLabelColor: Colors
                                          .grey, // Text color for unselected tabs
                                      labelStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      unselectedLabelStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal),
                                      tabs: const [
                                        Tab(text: 'Episodes'),
                                        Tab(text: 'Simulations'),
                                      ],
                                      dividerColor: Colors.transparent,
                                    )
                                  : TabBar(
                                      controller: _tabController,
                                      indicatorColor:
                                          Color.fromRGBO(255, 217, 0, 1),
                                      indicatorWeight: 2.0,
                                      labelColor: Colors
                                          .white, // Text color for selected tabs
                                      unselectedLabelColor: Colors
                                          .grey, // Text color for unselected tabs
                                      labelStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      unselectedLabelStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal),
                                      tabs: const [
                                        Tab(text: 'Episodes'),
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
                                                    sectionId: sections[index]
                                                        ['id'],
                                                    title: sections[index]
                                                        ['name'],
                                                    description: sections[index]
                                                            ['description'] ??
                                                        "No description available",
                                                    imageUrl: sections[index]
                                                        ['imageUrl'],
                                                    audioUrl: sections[index]
                                                            ['audioUrl'] ??
                                                        "",
                                                    duration:
                                                        sections[index]['timeToCompleteV2'] ??
                                                            "Unknown",
                                                    chapterName: chapterName,
                                                    chapterNo: chapterNo,
                                                    cerData: sections[index]['cerList'] != null && sections[index]['cerList'].isNotEmpty
                                                        ? sections[index]
                                                            ['cerList'][0]
                                                        : <String, dynamic>{},
                                                    chapterId: widget.chapterId,
                                                    pdfUrl: pdfUrl,
                                                    sectionNumber: index,
                                                    subsections: sections[index]
                                                        ['subSections'],
                                                    sectionEndQuestions:
                                                        sections[index]['sectionEndQuestions'] ?? []),
                                              ),
                                            ).then((result) {
                                              context
                                                  .read<AudioProvider>()
                                                  .setShowMiniPlayer(true);
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 0,
                                                ),
                                                child: Card(
                                                  color: Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Row(
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              child:
                                                                  Image.network(
                                                                sections[index][
                                                                    'imageUrl'],
                                                                width: 60,
                                                                height: 60,
                                                                fit: BoxFit
                                                                    .cover,
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
                                                                  color: Colors
                                                                      .white,
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
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: Text(
                                                          sections[index][
                                                                  'description'] ??
                                                              "No description available",
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8.0,
                                                        ),
                                                        child: Text(
                                                          "${(sections[index]['timeToCompleteV2'] / 60000).floor()} mins",
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
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
                                                                    ? Icons
                                                                        .bookmark
                                                                    : Icons
                                                                        .bookmark_border,
                                                                color:
                                                                    Colors.grey,
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
                                                                color:
                                                                    Colors.grey,
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
                                                                sections[index][
                                                                        'cerList']
                                                                    .isNotEmpty)
                                                              TextButton(
                                                                style: TextButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      Color.fromRGBO(
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
                                                                            .circular(4),
                                                                  ),
                                                                ),
                                                                onPressed: () {
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              CERPage(
                                                                        data: sections[index]
                                                                            [
                                                                            'cerList'][0],
                                                                        chapterId:
                                                                            widget.chapterId,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                child:
                                                                    const Text(
                                                                  'Go to Case',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        12,
                                                                    // decoration: TextDecoration.underline,
                                                                    // decorationColor: Colors.white,
                                                                  ),
                                                                ),
                                                              ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons
                                                                    .play_circle_fill,
                                                                color: Color
                                                                    .fromRGBO(
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
                                                                      sectionId:
                                                                          sections[index]
                                                                              [
                                                                              'id'],
                                                                      title: sections[
                                                                              index]
                                                                          [
                                                                          'name'],
                                                                      description:
                                                                          sections[index]['description'] ??
                                                                              "No description available",
                                                                      imageUrl:
                                                                          sections[index]
                                                                              [
                                                                              'imageUrl'],
                                                                      audioUrl:
                                                                          sections[index]['audioUrl'] ??
                                                                              "",
                                                                      duration: sections[index]
                                                                              [
                                                                              'timeToCompleteV2'] ??
                                                                          "Unknown",
                                                                      chapterName:
                                                                          chapterName,
                                                                      chapterNo:
                                                                          chapterNo,
                                                                      cerData: sections[index]['cerList'] != null &&
                                                                              sections[index]['cerList']
                                                                                  .isNotEmpty
                                                                          ? sections[index]['cerList']
                                                                              [
                                                                              0]
                                                                          : <String,
                                                                              dynamic>{},
                                                                      chapterId:
                                                                          widget
                                                                              .chapterId,
                                                                      pdfUrl:
                                                                          pdfUrl,
                                                                      sectionNumber:
                                                                          index,
                                                                      subsections:
                                                                          sections[index]
                                                                              [
                                                                              'subSections'],
                                                                      sectionEndQuestions:
                                                                          sections[index]['sectionEndQuestions'] ??
                                                                              [],
                                                                    ),
                                                                  ),
                                                                ).then(
                                                                    (result) {
                                                                  context
                                                                      .read<
                                                                          AudioProvider>()
                                                                      .setShowMiniPlayer(
                                                                          true);
                                                                });
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
                                  if (showSimulationsTab)
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
                                                  builder: (context) =>
                                                      SimulationScreen(
                                                          simulationUrl:
                                                              "https://glutaclass.com/app-simulation/${simulationList[index]['id']}"),
                                                ),
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 16,
                                                    vertical: 0,
                                                  ),
                                                  child: Card(
                                                    color: Colors.transparent,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Row(
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                child: Image
                                                                    .network(
                                                                  simulationList[
                                                                          index]
                                                                      [
                                                                      'simulationImageUrl'],
                                                                  width: 60,
                                                                  height: 60,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 16),
                                                              Expanded(
                                                                child: Text(
                                                                  simulationList[
                                                                          index]
                                                                      ['name'],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .white,
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
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8.0),
                                                          child: Text(
                                                            simulationList[
                                                                        index][
                                                                    'description'] ??
                                                                "No description available",
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
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
                                                          padding:
                                                              const EdgeInsets
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
                                                                      ? Icons
                                                                          .bookmark
                                                                      : Icons
                                                                          .bookmark_border,
                                                                  color: Colors
                                                                      .grey,
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
                                                                icon:
                                                                    const Icon(
                                                                  Icons
                                                                      .share_outlined,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                                onPressed: () {
                                                                  shareSimulation(
                                                                      simulationId);
                                                                },
                                                              ),
                                                              const Spacer(),
                                                              IconButton(
                                                                icon:
                                                                    const Icon(
                                                                  Icons
                                                                      .play_circle_fill,
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          255,
                                                                          217,
                                                                          0,
                                                                          1),
                                                                  size: 40,
                                                                ),
                                                                onPressed: () {
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          SimulationScreen(
                                                                              simulationUrl: "https://glutaclass.com/app-simulation/${simulationList[index]['id']}"),
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
                                                if (index <
                                                    simulationList.length - 1)
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
                        Consumer<AudioProvider>(
                          builder: (context, audioProvider, child) {
                            return Visibility(
                                visible: audioProvider.showMiniPlayer,
                                child: Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: MiniPlayer(),
                                ));
                          },
                        ),
                      ])));
  }
}
