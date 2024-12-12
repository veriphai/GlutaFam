import 'package:eureka_app/events/chapterListingEvents.dart';
import 'package:eureka_app/events/genericEvents.dart';
import 'package:eureka_app/screens/ncertPodcasts/miniPlayer.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastListingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/referralScreen.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sectionsListingScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';

class Chapterscreen extends StatefulWidget {
  final int standard = 8;

  const Chapterscreen({Key? key}) : super(key: key);

  @override
  _ChapterscreenState createState() => _ChapterscreenState();
}

class _ChapterscreenState extends State<Chapterscreen> {
  Set<String> bookmarkedChapters = {};
  int standard = 8; // Default standard
  List<dynamic> carouselData = [];
  final String screenName = "HomePage-ChapterListingScreen";
  final int cacheExpiryDurationInHours = 24;
  late SharedPreferences prefs;

  String getChaptersCacheKey() => 'cached_chapters_standard_$standard';
  String getCacheTimestampKey() =>
      'cached_chapters_timestamp_standard_$standard';

  String getCarouselCacheKey() => 'cached_carousel_standard_$standard';
  String getCarouselTimestampKey() =>
      'cached_carousel_timestamp_standard_$standard';

  String getPodcastsCacheKey() => 'cached_podcasts_standard_$standard';
  String getPodcastsTimestampKey() =>
      'cached_podcasts_timestamp_standard_$standard';

  Map<String, List<Map<String, dynamic>>> subjectChapters = {
    'Science': [],
    'English-2': [],
    'English-1': []
  };

  List<dynamic> podcasts = [];

  bool isLoading = true;
  bool hasError = false;

  Set<String> bookmarkedSections = {};

  final http.Client client = http.Client();

  @override
  void initState() {
    super.initState();

    _loadSelectedClass(); // Fetch the selected class before fetching chapters

    Future<void> _setCurrentScreen() async {
      await FirebaseAnalytics.instance
          .logEvent(name: 'screen_view', parameters: {
        'firebase_screen': "HomeScreen - Chapter Listing",
        'firebase_screen_class': "Chapterscreen",
      });
    }
  }

  // Fetch the selected class from SharedPreferences
  Future<void> _loadSelectedClass() async {
    prefs = await SharedPreferences.getInstance();

    setState(() {
      standard = prefs.getInt('selected_class') ??
          8; // Default to class 8 if not found
      print(standard);
    });
    logChapterListingScreenView(standard);
    fetchAllChapters();
    fetchCarouselData();
    fetchRecommendedPodcasts();
  }

  Future<void> fetchAllChapters() async {
    // Check if cached data is available and not expired
    String? cachedChapters = prefs.getString(getChaptersCacheKey());
    int? cachedTimestamp = prefs.getInt(getCacheTimestampKey());
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    if (cachedChapters != null &&
        cachedTimestamp != null &&
        currentTime - cachedTimestamp < cacheExpiryDurationInHours * 3600000) {
      // Use cached data if within expiry
      setState(() {
        final data = json.decode(cachedChapters);
        subjectChapters['Science'] =
            List<Map<String, dynamic>>.from(data['Science']);
        subjectChapters['English-2'] =
            List<Map<String, dynamic>>.from(data['English-2']);
        subjectChapters['English-1'] =
            List<Map<String, dynamic>>.from(data['English-1']);
        isLoading = false;
      });
    } else {
      // Fetch and cache new data if no valid cache is found
      await _fetchAndCacheChapters();
    }
  }

  Future<void> _fetchAndCacheChapters() async {
    try {
      // Fetch chapters for each subject
      await Future.wait([
        fetchChapterList('Science'),
        fetchChapterList('English-2'),
        fetchChapterList('English-1')
      ]);

      // Cache the data along with the current timestamp if successful
      Map<String, dynamic> cacheData = {
        'Science': subjectChapters['Science'],
        'English-2': subjectChapters['English-2'],
        'English-1': subjectChapters['English-1'],
      };
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(getChaptersCacheKey(), json.encode(cacheData));
      await prefs.setInt(getCacheTimestampKey(), currentTimestamp);

      setState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  // Update fetchChapterList to avoid setting state if called during caching
  Future<void> fetchChapterList(String subject) async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/chapters?subject=$subject&standard=$standard';

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept-Encoding': 'gzip', // Enable gzip compression
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> sortedChapters = data
            .map((e) => e as Map<String, dynamic>)
            .toList()
          ..sort((a, b) => a['chapterNo'].compareTo(b['chapterNo']));

        setState(() {
          subjectChapters[subject] = sortedChapters;
        });
      } else {
        hasError = true;
      }
    } catch (e) {
      hasError = true;
    }
  }

  Future<void> fetchRecommendedPodcasts() async {
    String? cachedPodcasts = prefs.getString(getPodcastsCacheKey());
    int? cachedTimestamp = prefs.getInt(getPodcastsTimestampKey());
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    if (cachedPodcasts != null &&
        cachedTimestamp != null &&
        currentTime - cachedTimestamp < cacheExpiryDurationInHours * 3600000) {
      // Use cached podcast data if within expiry
      setState(() {
        podcasts = json.decode(cachedPodcasts);
        isLoading = false;
      });
    } else {
      // Fetch and cache new podcast data if no valid cache is found
      await _fetchAndCachePodcasts();
    }
  }

  Future<void> _fetchAndCachePodcasts() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/recommended-podcasts?standard=$standard';

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept-Encoding': 'gzip',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          podcasts = json.decode(response.body);
        });
        await prefs.setString(getPodcastsCacheKey(), response.body);
        await prefs.setInt(
            getPodcastsTimestampKey(), DateTime.now().millisecondsSinceEpoch);
      } else {
        hasError = true;
      }
    } catch (e) {
      hasError = true;
    }
  }

  void shareReferralLink(String referralCode) async {
    referralCode = 'Sahu';
    String referralLink = await generateReferralLink(referralCode);

    Share.share(
      'Join me on GlutaClass! Use my referral link: $referralLink',
      subject: 'Your GlutaClass Referral Link',
    );
  }

  // Function to open the bottom sheet for class selection
  void _showClassSelectionBottomSheet() {
    logClassChangeEvent(standard);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              int classNumber = index + 6;

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      'Class $classNumber',
                      style: GoogleFonts.arOneSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: classNumber == standard
                            ? Color.fromRGBO(255, 217, 0, 1)
                            : Colors.white,
                      ),
                    ),
                    onTap: () async {
                      // Update selected class and refresh chapter list
                      // SharedPreferences prefs =
                      //     await SharedPreferences.getInstance();
                      // await prefs.setInt('selected_class', classNumber);

                      setState(() {
                        standard = classNumber;
                        isLoading = true;
                      });

                      await prefs.setInt('selected_class', classNumber);

                      logSelectedClassChangedEvent(classNumber);
                      fetchAllChapters();
                      fetchRecommendedPodcasts();
                      fetchCarouselData();

                      // Close the bottom sheet
                      Navigator.pop(context);
                    },
                  ),
                  if (index < 4)
                    Divider(
                        color: Colors.grey[800]), // Divider between ListTiles
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // Fetch carousel data from API
  Future<void> fetchCarouselData() async {
    String? cachedCarousel = prefs.getString(getCarouselCacheKey());
    int? cachedTimestamp = prefs.getInt(getCarouselTimestampKey());
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    if (cachedCarousel != null &&
        cachedTimestamp != null &&
        currentTime - cachedTimestamp < cacheExpiryDurationInHours * 3600000) {
      // Use cached carousel data if within expiry
      setState(() {
        carouselData = json.decode(cachedCarousel);
        isLoading = false;
      });
    } else {
      // Fetch and cache new carousel data if no valid cache is found
      await _fetchAndCacheCarouselData();
    }
  }

  Future<void> _fetchAndCacheCarouselData() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/carousal-data?standard=$standard';

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Accept-Encoding': 'gzip',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          carouselData = json.decode(response.body);
        });
        await prefs.setString(getCarouselCacheKey(), response.body);
        await prefs.setInt(
            getCarouselTimestampKey(), DateTime.now().millisecondsSinceEpoch);
      } else {
        hasError = true;
      }
    } catch (e) {
      hasError = true;
    }
  }

  void share() {
    final String deepLink = "https://glutaclass.com";

    Share.share('Download GlutaClass App: $deepLink');
  }

  String formatTimeToComplete(int timeInMillis) {
    if (timeInMillis < 100) {
      final random = Random();
      // Generate a random number of minutes between 35 and 50, then convert to milliseconds
      int randomMinutes =
          35 + random.nextInt(16); // 35 + random number between 0 and 15
      timeInMillis = randomMinutes * 60 * 1000;
    }
    final int hours = (timeInMillis / (1000 * 60 * 60)).floor();
    final int minutes =
        ((timeInMillis % (1000 * 60 * 60)) / (1000 * 60)).floor();

    if (hours > 0) {
      return "$hours hr ${minutes.toString().padLeft(2, '0')} min";
    } else {
      return "$minutes min";
    }
  }

  // Carousel Widget for Interest and Scientist
  Widget buildCarousel(String title, List<dynamic> items, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PodcastListingScreen(
                          filter: type == 'interest_led'
                              ? 'interest'
                              : 'personality',
                          standard: standard,
                          searchParam: item['id'],
                          item: item,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 100, // Fixed width for each item
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Circular container for the image
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: item['image'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Name of the item (Scientist or Interest)
                        Text(
                          item['name'],
                          style: GoogleFonts.raleway(
                            color: Colors.grey[200],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis, // Truncates if too long
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildEpisodeCarousel(List<dynamic> episodes, String title) {
    print(episodes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // const SizedBox(height: 10),
        SizedBox(
          height: 230, // Adjust the height of the card
          child: PageView.builder(
            controller:
                PageController(viewportFraction: 0.95), // Adjusts the page view
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Transform.translate(
                  offset: Offset(
                      -20, 0), // Slight offset to ensure center alignment
                  child: buildEpisodeCard(episode, index, title),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildEpisodeCard(
      Map<String, dynamic> episode, int index, String source) {
    // Define a list of gradients to use for the background of the cards.
    final List<LinearGradient> gradients = [
      LinearGradient(
        colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Colors.deepPurple[900]!, Colors.deepPurple[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Colors.teal[900]!, Colors.teal[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // LinearGradient(
      //   colors: [Colors.orange[900]!, Colors.orange[700]!],
      //   begin: Alignment.topLeft,
      //   end: Alignment.bottomRight,
      // ),
      LinearGradient(
        colors: [Colors.brown[900]!, Colors.brown[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Colors.indigo[900]!, Colors.indigo[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    // Choose a gradient based on the index.
    final cardBackgroundGradient = gradients[index % gradients.length];
    String episodeId = episode['id'];

    return GestureDetector(
      onTap: () {
        logEpisodeCardClick(episodeId, source);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PodcastScreen(
              title: episode['name'],
              description: episode['description'] ?? "No description available",
              imageUrl: episode['image'],
              audioUrl: episode['audioUrl'] ?? "",
              duration: episode['timeToComplete'] ?? 20,
              chapterName: episode['chapterName'],
              chapterNo: episode['chapterNo'],
              cerData: episode['cer'] ?? <String, dynamic>{},
              chapterId: episode['chapterId'],
              sectionNumber: episode['order'] - 1,
              subsections: episode['subSections'],
              sectionId: episode['id'],
              sectionEndQuestions: episode['sectionEndQuestions'],
            ),
          ),
        ).then((result) {
          final audioProvider = context.read<AudioProvider>();
          audioProvider.setShowMiniPlayer(true);
          logBackButtonClick(
              audioProvider.sectionId,
              audioProvider.audioPlayer!.playing,
              audioProvider.audioPlayer!.position.inSeconds,
              "AudioPlayerScreen");
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 300, // Set the width to 90% of the available width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: cardBackgroundGradient, // Set the gradient background
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode image and name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: episode[
                              'image'], // Replace with your image URL field
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode[
                                'name'], // Replace with your episode name field
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            episode['chapterName'] != null &&
                                    episode['chapterName'].isNotEmpty
                                ? "${episode['subject']} • ${episode['chapterName']}"
                                : "${episode['subject']}",
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ))
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    episode['description'] ?? 'No description available',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      color: Colors.grey[200],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Time and action buttons row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            bookmarkedSections.contains(episodeId)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            logBookmarkButtonClick(episodeId, source);
                            setState(() {
                              // Toggle the bookmark state.
                              if (bookmarkedSections.contains(episodeId)) {
                                bookmarkedSections.remove(episodeId);
                              } else {
                                bookmarkedSections.add(episodeId);
                              }
                            });
                          },
                        ),
                        // Share Button
                        IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            logShareButtonClick(episodeId, source);
                            share();
                            // Handle share functionality
                          },
                        ),
                        const Spacer(flex: 1),

                        // Play Button
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill,
                            color: Color.fromRGBO(255, 217, 0, 1),
                            size: 40,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PodcastScreen(
                                  title: episode['name'],
                                  description: episode['description'] ??
                                      "No description available",
                                  imageUrl: episode['image'],
                                  audioUrl: episode['audioUrl'] ?? "",
                                  duration: episode['timeToComplete'] ?? 20,
                                  chapterName: episode['chapterName'],
                                  chapterNo: episode['chapterNo'],
                                  cerData:
                                      episode['cer'] ?? <String, dynamic>{},
                                  chapterId: episode['chapterId'],
                                  sectionNumber: episode['order'] - 1,
                                  subsections: episode['subSections'],
                                  sectionId: episode['id'],
                                  sectionEndQuestions:
                                      episode['sectionEndQuestions'],
                                ),
                              ),
                            ).then((result) {
                              context
                                  .read<AudioProvider>()
                                  .setShowMiniPlayer(true);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: Color.fromRGBO(255, 217, 0, 1)))
            : hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Failed to load chapters',
                          style: GoogleFonts.raleway(color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              hasError = false;
                            });
                            fetchAllChapters();
                            fetchRecommendedPodcasts();
                            fetchCarouselData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                          ),
                          child: Text(
                            'Reload',
                            style: GoogleFonts.raleway(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(children: [
                    (subjectChapters.values
                            .every((chapters) => chapters.isEmpty)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'We are working on the data for this class.\nYou may check other classes.',
                                style: GoogleFonts.raleway(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (podcasts.isNotEmpty)
                                  buildEpisodeCarousel(
                                      podcasts, "Just For You"),
                                const SizedBox(height: 20),
                                _buildChapterContent(),
                                const SizedBox(height: 10),
                                ...carouselData.map((carousel) {
                                  return Column(
                                    children: [
                                      if ((carousel['type'] == 'interest_led' ||
                                              carousel['type'] ==
                                                  'famous_personality') &&
                                          carousel['items'] != null &&
                                          carousel['items'].isNotEmpty)
                                        buildCarousel(
                                            carousel['title'],
                                            carousel['items'],
                                            carousel['type']),
                                      if (carousel['type'] == 'episode' &&
                                          carousel['episodes'] != null &&
                                          carousel['episodes'].isNotEmpty)
                                        buildEpisodeCarousel(
                                            carousel['episodes'],
                                            carousel['title']),
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                }).toList(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          )),
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
                    )
                  ]),
      ),
    );
  }

  Widget _buildChapterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subjectChapters.keys.map((subject) {
        final chapters = subjectChapters[subject] ?? [];
        if (chapters.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                chapters[0]['bookName'],
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // const SizedBox(height: 10),
            SizedBox(
              height: 340, // Giving a constrained height to the PageView
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: (chapters.length / 4).ceil(),
                itemBuilder: (context, pageIndex) {
                  final pageChapters =
                      chapters.skip(pageIndex * 4).take(4).toList();
                  return Transform.translate(
                    offset: Offset(-16, 0),
                    child: ListView.builder(
                      shrinkWrap: true, // Ensures height does not overflow
                      physics:
                          NeverScrollableScrollPhysics(), // Disable scrolling in this ListView
                      itemCount: pageChapters.length,
                      itemBuilder: (context, index) {
                        final chapter = pageChapters[index];
                        return GestureDetector(
                          onTap: () {
                            logChapterClick(chapter['id']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Sectionscreen(
                                  chapterId: chapter['id'],
                                ),
                              ),
                            ).then((result) {
                              final audioProvider =
                                  context.read<AudioProvider>();
                              audioProvider.setShowMiniPlayer(true);
                              logBackButtonClick(
                                  audioProvider.sectionId,
                                  audioProvider.audioPlayer!.playing,
                                  audioProvider.audioPlayer!.position.inSeconds,
                                  "SectionListingScreen");
                            });
                          },
                          child: _buildChapterItem(chapter),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      title: Text("GlutaClass",
          style: GoogleFonts.raleway(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          )),
      actions: [
        // Display selected class on the right side of the app bar
        TextButton(
          onPressed: _showClassSelectionBottomSheet, // Open bottom sheet
          child: Row(
            children: [
              Text(
                'Class $standard',
                style: GoogleFonts.arOneSans(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
              SizedBox(
                width: 10,
              ),
              Center(
                  child: Container(
                width: 35, // Adjust inner circle size
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(255, 217, 0, 1),
                ),
                child: Center(
                  child: IconButton(
                      onPressed: () {
                        logReferralButtonClick(standard);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReferralScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.person_add_alt_1_sharp,
                        color: Colors.black,
                        size: 20,
                        // Icon color
                      )),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChapterItem(Map<String, dynamic> chapter) {
    return Card(
      color: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: chapter['image'],
                fit: BoxFit.cover,
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter['name'],
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${chapter['sections'].length} Sections • ${formatTimeToComplete(chapter['timeToComplete'])}",
                    style: GoogleFonts.arOneSans(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                _showBottomSheet(context, chapter);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Map<String, dynamic> chapter) {
    bool isBookmarked = bookmarkedChapters.contains(chapter['id']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: chapter['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  chapter['name'],
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Chapter ${chapter['chapterNo']} • ${chapter['sections'].length} Sections • ${formatTimeToComplete(chapter['timeToComplete'])} mins",
                  style: GoogleFonts.arOneSans(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: Icon(Icons.play_circle_outline_rounded,
                    color: Colors.white),
                title: Text(
                  "Go To Chapter",
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Sectionscreen(
                        chapterId: chapter['id'],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isBookmarked
                      ? Icons.bookmark
                      : Icons
                          .bookmark_outline, // Toggle between outline and filled
                  color: Colors.white,
                ),
                title: Text(
                  isBookmarked ? "Bookmarked" : "Bookmark",
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    if (isBookmarked) {
                      bookmarkedChapters.remove(chapter['id']);
                    } else {
                      bookmarkedChapters.add(chapter['id']);
                    }
                  });
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.share_outlined, color: Colors.white),
              //   title: Text(
              //     "Share",
              //     style: GoogleFonts.raleway(color: Colors.white),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     // Handle Share Action
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
