import 'package:eureka_app/screens/ncertPodcasts/cerScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastListingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sectionsListingScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

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
  Map<String, List<Map<String, dynamic>>> subjectChapters = {
    'Science': [],
    'Maths': [],
    'History': [],
    'Geography': [],
  };

  List<dynamic> podcasts = [];

  bool isLoading = true;
  bool hasError = false;

  Set<String> bookmarkedSections = {};

  @override
  void initState() {
    super.initState();
    _loadSelectedClass(); // Fetch the selected class before fetching chapters
  }

  // Fetch the selected class from SharedPreferences
  Future<void> _loadSelectedClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      standard = prefs.getInt('selected_class') ??
          8; // Default to class 8 if not found
      print(standard);
    });
    // Now that the standard is loaded, fetch the chapters
    fetchRecommendedPodcasts();
    fetchAllChapters();
    fetchCarouselData();
  }

  Future<void> fetchAllChapters() async {
    try {
      // Fetch chapters for each subject
      await Future.wait([
        fetchChapterList('Science'),
        fetchChapterList('Maths'),
        fetchChapterList('History'),
        fetchChapterList('Geography'),
      ]);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> fetchRecommendedPodcasts() async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/recommended-podcasts?standard=${widget.standard}';

    try {
      print("Fetching recommended-podcasts details from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response: ${json.decode(response.body)}");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print("Decoded data: $data");

        // Use null-aware operators to assign default values if a key is missing or null.
        setState(() {
          podcasts = data;
          // isLoading = false;
        });
      } else {
        setState(() {
          print("Error: Status code ${response.statusCode}");
          // isLoading = false;
          // hasError = true;
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

  Future<void> fetchChapterList(String subject) async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/chapters?subject=$subject&standard=$standard';

    try {
      print("Fetching data for $subject from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response for $subject: $response");

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
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    }
  }

  // Function to open the bottom sheet for class selection
  void _showClassSelectionBottomSheet() {
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
            children: List.generate(6, (index) {
              int classNumber = index + 5;

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      'Class $classNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

                      // Fetch updated chapters for the new class
                      fetchAllChapters();
                      fetchCarouselData();

                      // Close the bottom sheet
                      Navigator.pop(context);
                    },
                  ),
                  if (index < 5)
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
    final String url =
        'https://glutaclass.com:8080/gluta/fam/carousal-data?standard=$standard'; // Replace with your actual API URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          carouselData = json.decode(response.body);
          print(carouselData);
        });
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    }
  }

  void share() {
    final String deepLink = "https://glutaclass.com";

    Share.share('Download GlutaClass App: $deepLink');
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
            style: const TextStyle(
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
                          child: Image.network(
                            item['image'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Name of the item (Scientist or Interest)
                        Text(
                          item['name'],
                          style: TextStyle(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
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
                  child: buildEpisodeCard(episode, index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildEpisodeCard(Map<String, dynamic> episode, int index) {
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
            ),
          ),
        );
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
                        child: Image.network(
                          episode['image'], // Replace with your image URL field
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
                            style: const TextStyle(
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
                            style: const TextStyle(
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
                    style: TextStyle(
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
                            share();
                            // Handle share functionality
                          },
                        ),
                        const Spacer(flex: 1),

                        // "Go to Case" Button (if CER data exists)
                        if (episode['cer'] != null && episode['cer'].isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(255, 217, 0, 1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: const Size(20, 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CERPage(
                                    data: episode['cer'],
                                    chapterId: episode['chapterId'],
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Go to Case',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),

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
            ? Center(child: CircularProgressIndicator())
            : hasError
                ? Center(
                    child: Text(
                      'Failed to load chapters',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (podcasts.isNotEmpty)
                          buildEpisodeCarousel(podcasts, "Just For You"),
                        // Chapter List rendering
                        const SizedBox(height: 20),

                        _buildChapterContent(),
                        const SizedBox(height: 10),

                        // Spacing between chapter list and carousels
                        // const SizedBox(height: 20),

                        // Render carousels dynamically from carouselData
                        ...carouselData.map((carousel) {
                          return Column(
                            children: [
                              if ((carousel['type'] == 'interest_led' ||
                                      carousel['type'] ==
                                          'famous_personality') &&
                                  carousel['items'] != null &&
                                  carousel['items'].isNotEmpty)
                                buildCarousel(carousel['title'],
                                    carousel['items'], carousel['type']),

                              if (carousel['type'] == 'episode' &&
                                  carousel['episodes'] != null &&
                                  carousel['episodes'].isNotEmpty)
                                buildEpisodeCarousel(
                                    carousel['episodes'], carousel['title']),

                              // Add spacing between carousels
                              const SizedBox(height: 20),
                            ],
                          );
                        }).toList(),

                        // Spacing below the last carousel
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
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
                subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // const SizedBox(height: 10),
            SizedBox(
              height: 330, // Giving a constrained height to the PageView
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Sectionscreen(
                                  chapterId: chapter['id'],
                                ),
                              ),
                            );
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
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
              child: Image.network(
                chapter['image'],
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${chapter['sections'].length} Sections • ${chapter['timeToComplete']} mins",
                    style: const TextStyle(
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
                  child: Image.network(
                    chapter['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  chapter['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Chapter ${chapter['chapterNo']} • ${chapter['sections'].length} Sections • ${chapter['timeToComplete']} mins",
                  style: const TextStyle(
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
                  style: TextStyle(color: Colors.white),
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
                  style: TextStyle(color: Colors.white),
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
              //     style: TextStyle(color: Colors.white),
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
