import 'package:bubble_box/bubble_box.dart';
import 'package:eureka_app/apis/fetchBooks.dart';
import 'package:eureka_app/apis/fetchChaptersV2.dart';
import 'package:eureka_app/apis/fetchCompletedConcepts.dart';
import 'package:eureka_app/apis/getAppVersionDetails.dart';
import 'package:eureka_app/apis/saveAppVersion.dart';
import 'package:eureka_app/newEvents/homeScreenEvents.dart';
import 'package:eureka_app/popups/genericPopupWidget.dart';
import 'package:eureka_app/popups/popUpManager.dart';
import 'package:eureka_app/screens/conceptLearningScreen.dart';
import 'package:eureka_app/screens/conceptLearningScreenV2.dart';
import 'package:eureka_app/screens/conceptLearningV3.dart';
import 'package:eureka_app/screens/conceptStartScreen.dart';
import 'package:eureka_app/screens/loginScreen.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/cachingUtils.dart';
import 'package:eureka_app/widgets/chapterSelection.dart';
import 'package:eureka_app/widgets/lifelinesWidget.dart';
import 'package:eureka_app/widgets/shopScreen.dart';
import 'package:eureka_app/widgets/streakScreen.dart';
import 'package:eureka_app/widgets/subjectSelection.dart';
import 'package:flutter/material.dart';
import 'package:chiclet/chiclet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _activeTopic = '';
  String activeChapter = '';
  int activeTopicIndex = 0;
  List<GlobalKey> _topicKeys = [];
  String _selectedSubject = "";
  String selectedBookId = "";
  bool isLoading = true;
  String conceptToStartFrom = "";

  List<String> completedConcepts = [];

  late List<Map<String, dynamic>> chapters;
  late List<Map<String, dynamic>> books;
  late Map<String, dynamic> userProfile;
  late int creditsAvailable;
  late int lifelinesAvailable;
  late SharedPreferences prefs;
  int xpMultiplier = 1;
  bool unlimitedLifelines = false;
  int totalXPForConcept = 90;
  bool firstLesson = true;

  String? selectedConceptId;

  Map<String, dynamic> activePowerup = {};
  double _listOpacity = 0.0;

  void toggleOverlay(String conceptId) {
    setState(() {
      selectedConceptId = selectedConceptId == conceptId ? null : conceptId;
    });
  }

  final List<Map<String, dynamic>> buttonColours = [
    {
      "background": Color.fromRGBO(255, 217, 0, 1),
      "button": Color.fromRGBO(187, 160, 2, 1)
    },
    {
      "background": Color.fromRGBO(249, 168, 93, 1),
      "button": Color.fromRGBO(189, 113, 41, 1)
    },
    {
      "background": Color.fromRGBO(151, 241, 105, 1),
      "button": Color.fromRGBO(105, 185, 65, 1)
    },
    {
      "background": Color.fromRGBO(105, 207, 241, 1),
      "button": Color.fromRGBO(66, 158, 188, 1)
    },
    {
      "background": Color.fromRGBO(235, 122, 245, 1),
      "button": Color.fromRGBO(187, 86, 196, 1)
    }
  ];

  Map<String, dynamic> _activeButtonColour = {};

  void addSequentialNumbers(List<Map<String, dynamic>> chapters) {
    int seqNumber = 1; // Start the sequence from 1

    for (var chapter in chapters) {
      for (var topic in chapter['topics']) {
        topic['seqNumber'] = seqNumber; // Add seqNumber to the topic
        seqNumber++; // Increment for the next topic
      }
    }
  }

  Future<String> getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool isVersionLower(String current, String latest) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> l = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < c.length; i++) {
      if (c[i] < l[i]) return true;
      if (c[i] > l[i]) return false;
    }
    return false;
  }

  void launchAppStore() async {
    final url = Platform.isAndroid
        ? Uri.parse(
            'https://play.google.com/store/apps/details?id=com.gluta.glutafam')
        : Uri.parse(
            'https://apps.apple.com/us/app/tuto-ai-tutor-for-class-6-12/id6736943726');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch app store URL");
    }
  }

  void checkForAppUpdate(BuildContext context) async {
    try {
      final currentVersion = await getCurrentAppVersion();
      final versionInfo = await getLatestAppVersinDetails();

      // Platform detection
      final bool isAndroid = Platform.isAndroid;
      final bool isIOS = Platform.isIOS;

      final String latestVersion = isAndroid
          ? versionInfo['latestVersionAndroid']
          : versionInfo['latestVersionIOS'];
      final String minimumVersion = versionInfo['minimumVersion'];
      final bool forceUpdate = versionInfo['forceUpdate'];
      final String message = versionInfo['message'];
      final List<String> notes =
          List<String>.from(versionInfo['updateNotes'] ?? []);

      if (isVersionLower(currentVersion, minimumVersion)) {
        // Force update
        showUpdateSheet(
          context,
          message: message,
          updateNotes: notes,
          forceUpdate: true,
          onUpdate: () {
            launchAppStore();
          },
        );
      } else if (isVersionLower(currentVersion, latestVersion)) {
        showUpdateSheet(
          context,
          message: message,
          updateNotes: notes,
          forceUpdate: forceUpdate,
          onUpdate: () {
            launchAppStore();
          },
        );
      }
    } catch (e) {
      // Handle error or skip update check
    }
  }

  void showUpdateSheet(
    BuildContext context, {
    required String message,
    required List<String> updateNotes,
    required bool forceUpdate,
    required VoidCallback onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: !forceUpdate,
      enableDrag: !forceUpdate,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      barrierColor: forceUpdate ? Colors.black.withOpacity(0.7) : null,
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update, size: 40, color: Colors.blueAccent),
              SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),
              // Text(
              //   "What's new?",
              //   style: GoogleFonts.raleway(
              //     color: Colors.white,
              //     fontWeight: FontWeight.w700,
              //     fontSize: 16,
              //   ),
              // ),
              ...updateNotes.map(
                (note) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2), // Adjust for less space
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          size: 12, color: Color.fromRGBO(255, 217, 0, 1)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
              ChicletAnimatedButton(
                onPressed: onUpdate,
                buttonType: ChicletButtonTypes.roundedRectangle,
                width: double.infinity,
                height: 50,
                buttonColor: Color.fromRGBO(187, 160, 2, 1),
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                child: Text(
                  "UPDATE NOW",
                  style: GoogleFonts.raleway(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!forceUpdate)
                ChicletOutlinedAnimatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  buttonType: ChicletButtonTypes.roundedRectangle,
                  width: double.infinity,
                  height: 50,
                  borderColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    "MAYBE LATER",
                    style: GoogleFonts.raleway(
                      color: Color.fromRGBO(255, 217, 0, 1),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveCurrentAppVersion() async {
    final currentAppVersion = await getCurrentAppVersion();
    saveAppVersion(appVersion: currentAppVersion);
  }

  Future<void> fetchProfile() async {
    try {
      // final profileData = await getProfile();
      final profileData = await refreshProfile();
      prefs = await SharedPreferences.getInstance();
      fetchData(profileData["standard"], profileData["stream"], true);
      // String referralCode = "PHLQ7Y";

      setState(() {
        userProfile = profileData;
      });
      // String referralLink = await generateReferralLink(referralCode);
      // print(referralLink);
    } catch (error) {
      print("Error fetching userProfile: $error");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> fetchCreditsAndLifelines() async {
    try {
      // final profileData = await getProfile();
      final prefs = await SharedPreferences.getInstance();
      final creditsFromCache = prefs.getInt("credits");
      final lifelinesFromCache = prefs.getInt("lifelines");
      bool unlimitedHeartsEnabled =
          prefs.getBool("unlimitedLifelines") ?? false;
      int xpMultiplierFromCache = prefs.getInt("xpMultiplier") ?? 1;

      bool firstLessonFromCache = prefs.getBool("firstLesson") ?? true;

      double powerupStartTime = prefs.getDouble("powerupStartTime") ?? 0;
      int currentTimeInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      bool validityPassed = (currentTimeInSeconds - powerupStartTime) >= 3600;
      if (validityPassed) {
        unlimitedHeartsEnabled = false;
        xpMultiplierFromCache = 1;
        prefs.setBool("unlimitedLifelines", false);
      }

      setState(() {
        creditsAvailable = creditsFromCache ?? 0;
        lifelinesAvailable = lifelinesFromCache ?? 0;
        unlimitedLifelines = unlimitedHeartsEnabled;
        xpMultiplier = xpMultiplierFromCache;
        firstLesson = firstLessonFromCache;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  Future<void> fetchData(
      int standard, String stream, bool updateSelectedSubject) async {
    try {
      final booksData =
          await getBooksWithCache(standard: standard, stream: stream);

      final scienceBook = booksData.firstWhere(
        (book) => book["subject"]?.toLowerCase() == "science",
        orElse: () => <String, dynamic>{},
      );

      selectedBookId = prefs.getString("bookId") ?? "";
      _selectedSubject = prefs.getString("subject") ?? "";
      if (selectedBookId == "") {
        if (scienceBook.isNotEmpty) {
          selectedBookId = scienceBook["id"];
          prefs.setString("bookId", scienceBook["id"]);
          _selectedSubject = scienceBook["subject"];
          prefs.setString("subject", scienceBook["subject"]);
        } else {
          selectedBookId = booksData[0]["id"];
          prefs.setString("bookId", booksData[0]["id"]);
          _selectedSubject = booksData[0]["subject"];
          prefs.setString("subject", booksData[0]["subject"]);
        }
      }
      final chapterData = await getChaptersWithCache(
          standard: standard, subject: _selectedSubject);
      if (chapterData.isEmpty) {
        return;
      }

      final completedConceptsData = await fetchCompletedConcepts(
          bookId: selectedBookId, subject: _selectedSubject);

      setState(() {
        chapters = chapterData;
        chapters.sort((a, b) => a["chapterNo"].compareTo(b["chapterNo"]));
        books = booksData;
        // _selectedSubject = booksData[0]["subject"];

        completedConcepts =
            (completedConceptsData["completedConcepts"] as List<dynamic>)
                .cast<String>();
        // conceptToStartFrom =
        //     "crop_production_and_management_8_Science_Section_6_SubSection_7";
        conceptToStartFrom = completedConceptsData["conceptToStartFrom"];
        if (chapters.isNotEmpty && chapters[0]['topics'].isNotEmpty) {
          _activeTopic = chapters[0]['topics'][0]['name'];
          activeChapter = chapters[0]['name'];
          _activeButtonColour = buttonColours[0];
          // if (conceptToStartFrom == "") {
          //   conceptToStartFrom = chapters[0]['topics'][0]['lessons'][0]["id"];
          // }
          addSequentialNumbers(chapters);
          _topicKeys = List.generate(
            chapters.fold<int>(0,
                (total, chapter) => total + (chapter['topics'].length as int)),
            (index) => GlobalKey(),
          );
        }
        isLoading = false;
        _scrollController.addListener(_onScroll);
      });

      if (conceptToStartFrom != "") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToConcept(conceptToStartFrom);
          }
        });
      } else {
        setState(() {
          _listOpacity = 1.0;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching chapters: $error");
    }
  }

  Future<void> fetchDataWhenSubjectChanged(
      int standard, String stream, bool updateSelectedSubject) async {
    try {
      final booksData =
          await getBooksWithCache(standard: standard, stream: stream);
      selectedBookId = prefs.getString("bookId") ?? "";
      _selectedSubject = prefs.getString("subject") ?? "";

      final scienceBook = booksData.firstWhere(
        (book) => book["subject"]?.toLowerCase() == "science",
        orElse: () => <String, dynamic>{},
      );

      if (selectedBookId == "") {
        selectedBookId = scienceBook["id"];
        prefs.setString("bookId", scienceBook["id"]);
      }
      if (_selectedSubject == "") {
        _selectedSubject = scienceBook["subject"];
        prefs.setString("subject", scienceBook["subject"]);
      }
      final chapterData = await getChaptersWithCache(
          standard: standard, subject: _selectedSubject);
      if (chapterData.isEmpty) {
        return;
      }

      final completedConceptsData = await fetchCompletedConcepts(
          bookId: selectedBookId, subject: _selectedSubject);

      setState(() {
        chapters = chapterData;
        chapters.sort((a, b) => a["chapterNo"].compareTo(b["chapterNo"]));
        books = booksData;
        // _selectedSubject = booksData[0]["subject"];

        completedConcepts =
            (completedConceptsData["completedConcepts"] as List<dynamic>)
                .cast<String>();
        // conceptToStartFrom =
        //     "crop_production_and_management_8_Science_Section_6_SubSection_7";
        conceptToStartFrom = completedConceptsData["conceptToStartFrom"];
        if (chapters.isNotEmpty && chapters[0]['topics'].isNotEmpty) {
          _activeTopic = chapters[0]['topics'][0]['name'];
          activeChapter = chapters[0]['name'];
          _activeButtonColour = buttonColours[0];
          // if (conceptToStartFrom == "") {
          //   conceptToStartFrom = chapters[0]['topics'][0]['lessons'][0]["id"];
          // }
          addSequentialNumbers(chapters);
          _topicKeys = List.generate(
            chapters.fold<int>(0,
                (total, chapter) => total + (chapter['topics'].length as int)),
            (index) => GlobalKey(),
          );
        }
        isLoading = false;
        _scrollController.addListener(_onScroll);
      });

      if (conceptToStartFrom != "") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToConcept(conceptToStartFrom);
          }
        });
      } else {
        setState(() {
          _listOpacity = 1.0;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching chapters: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    logHomeScreenView();
    checkForAppUpdate(context);
    saveCurrentAppVersion();
    fetchProfile().then((_) {
      fetchCreditsAndLifelines();
    });
  }

  double _previousScrollPosition = 0.0;

  void _onScroll() {
    if (currentOverlayEntry != null) {
      currentOverlayEntry?.remove();
      currentOverlayEntry = null;
    }
    double currentScrollPosition = _scrollController.position.pixels;
    bool isScrollingDown = currentScrollPosition > _previousScrollPosition;

    for (int i = 0; i < _topicKeys.length; i++) {
      final keyContext = _topicKeys[i].currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        if (isScrollingDown) {
          // Scrolling Down: Update when the topic section enters the viewport
          if (position.dy <= MediaQuery.of(context).size.height * 0.25 &&
              position.dy >= 0) {
            setState(() {
              final topicList =
                  chapters.expand((chapter) => chapter['topics']).toList();
              final activeTopic = topicList[i];
              _activeTopic = activeTopic['name'];

              // Get the chapter containing the active topic
              for (var chapter in chapters) {
                if (chapter['topics'].contains(activeTopic)) {
                  activeChapter = chapter['name'];
                  break;
                }
              }
              _activeButtonColour = buttonColours[i % buttonColours.length];
              activeTopicIndex = i;
            });
            break;
          }
        } else {
          // Scrolling Up: Update when the topic section is about to leave the viewport
          if (position.dy <= MediaQuery.of(context).size.height * 0.4 &&
              position.dy > -(box.size.height - 150)) {
            setState(() {
              final topicList =
                  chapters.expand((chapter) => chapter['topics']).toList();
              final activeTopic = topicList[i];
              _activeTopic = activeTopic['name'];

              // Get the chapter containing the active topic
              for (var chapter in chapters) {
                if (chapter['topics'].contains(activeTopic)) {
                  activeChapter = chapter['name'];
                  break;
                }
              }
              _activeButtonColour = buttonColours[i % buttonColours.length];
              activeTopicIndex = i;
            });
            break;
          }
        }
      }
    }

    _previousScrollPosition = currentScrollPosition;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    currentOverlayEntry = null;
    super.dispose();
  }

  void _showSubjectSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      builder: (BuildContext context) {
        return SubjectSelection(
          selectedSubject: _selectedSubject,
          books: books,
          onSubjectSelect: (selected, bookId) async {
            logSubjectSelected(selected);
            setState(() {
              _selectedSubject = selected;
              selectedBookId = bookId;
              chapters = [];
            });
            await prefs.setString("bookId", bookId);
            await prefs.setString("subject", selected);
            fetchDataWhenSubjectChanged(
                userProfile["standard"], userProfile["stream"], false);
          },
        );
      },
    );
  }

  void _showLifelinesSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      builder: (BuildContext context) {
        return LifelinesWidget(
          lifelines: lifelinesAvailable,
          onLifelinesUpdated: (updatedLifelines, updatedCredits) {
            setState(() {
              lifelinesAvailable = updatedLifelines;
              creditsAvailable = updatedCredits;
            });
          },
        );
      },
    );
  }

  Future<void> _scrollToConcept(String conceptId) async {
    int conceptIndex = 0;
    int topicIndex = 0;
    int chapterIndex = 0;
    bool found = false;

    // 🔍 Find the index of `conceptToStartFrom`
    for (int cIndex = 0; cIndex < chapters.length; cIndex++) {
      final chapter = chapters[cIndex];
      for (int tIndex = 0; tIndex < chapter['topics'].length; tIndex++) {
        final topic = chapter['topics'][tIndex];

        for (int lIndex = 0; lIndex < topic['lessons'].length; lIndex++) {
          if (topic['lessons'][lIndex]['id'] == conceptId) {
            conceptIndex = lIndex;
            topicIndex = tIndex;
            chapterIndex = cIndex;
            found = true;
            break;
          }
        }
        if (found) break;
      }
      if (found) break;
    }

    if (!found) return; // If not found, exit early

    await scrollToTopic(topicIndex, chapterIndex);

    double additionalOffset =
        (conceptIndex * 100.0) - 50; // Approximate height per concept

    await _scrollController.animateTo(
      _scrollController.offset +
          additionalOffset, // Add to current offset instead of overriding
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    setState(() {
      _listOpacity = 1.0;
    });
  }

  Future<void> scrollToTopic(int firstTopicIndex, int chapterIndex) async {
    final topicKey = _topicKeys[firstTopicIndex];
    int conceptCount = 0;
    for (int i = 0; i < chapterIndex; i++) {
      for (var topic in chapters[i]['topics']) {
        conceptCount +=
            (topic['lessons']?.length as int); // Count concepts in each topic
      }
    }

    // First, try to use the key's context
    if (topicKey.currentContext != null) {
      // If the widget is already rendered, scroll directly to it
      await Scrollable.ensureVisible(
        topicKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Aligns it slightly below the top
      );
    } else {
      // If the widget is not yet rendered, approximate the position and scroll
      final estimatedPosition =
          (conceptCount * 100.0) + (firstTopicIndex * 100);
      await _scrollController.animateTo(
        estimatedPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Post-frame callback to ensure the widget is visible after rendering
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (topicKey.currentContext != null) {
          await Scrollable.ensureVisible(
            topicKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });
    }
  }

  void _showChapterSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
            expand: false,
            minChildSize: 0.4, // 40% of screen height
            initialChildSize: 0.5, // 60% when opened
            maxChildSize: 0.9, // Can grow up to 90%
            builder: (_, scrollController) {
              return ChapterSelection(
                chapters: chapters,
                activeChapter: activeChapter,
                subjects: books,
                selectedSubject: _selectedSubject,
                standard: userProfile["standard"],
                scrollController: scrollController,
                onChapterSelect: (index, chapterName) {
                  // Handle the selected chapter
                  print("Selected Chapter: $chapterName (Index: $index)");
                  logChapterSelected(chapters[index]['id']);
                  // Get the first topic of the selected chapter
                  final topics = (chapters[index]['topics'] as List<dynamic>)
                      .map((topic) => topic as Map<String, dynamic>)
                      .toList();
                  if (topics.isNotEmpty) {
                    // Find the key for the first topic in the selected chapter
                    final firstTopicIndex = chapters
                        .take(
                            index) // Take all chapters before the selected chapter
                        .fold<int>(
                          0,
                          (total, chapter) =>
                              total + (chapter['topics'].length as int),
                        ); // Calculate cumulative topic index

                    scrollToTopic(firstTopicIndex, index);

                    // Update the active topic
                    setState(() {
                      activeChapter = chapterName;
                      _activeTopic =
                          topics.first['name']; // Set first topic name
                    });
                  }

                  // Navigator.pop(context); // Close the bottom sheet
                },
                onSubjectSelect: (selected, bookId) async {
                  logSubjectSelectedFromChaptersList(selected);
                  setState(() {
                    _selectedSubject = selected;
                    selectedBookId = bookId;
                    chapters = [];
                  });
                  await prefs.setString("bookId", bookId);
                  await prefs.setString("subject", selected);
                  fetchDataWhenSubjectChanged(
                      userProfile["standard"], userProfile["stream"], false);
                },
              );
            });
      },
    );
  }

  bool isToday(int epochTimeInSeconds) {
    DateTime expiryDate =
        DateTime.fromMillisecondsSinceEpoch(epochTimeInSeconds * 1000);
    DateTime now = DateTime.now();

    return expiryDate.year == now.year &&
        expiryDate.month == now.month &&
        expiryDate.day == now.day;
  }

  OverlayEntry? currentOverlayEntry;

  void showOverlay(BuildContext context, Map<String, dynamic> concept,
      GlobalKey buttonKey, Color background, bool isCompleted, bool isLocked) {
    // Remove the current overlay only if it exists and not due to scrolling
    if (currentOverlayEntry != null) {
      currentOverlayEntry?.remove();
      currentOverlayEntry = null;
    }

    // Get the button's position and size
    final RenderBox renderBox =
        buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height - 50;
    const double padding = 40.0;
    final double overlayWidth =
        MediaQuery.of(context).size.width - (2 * padding);

    const double overlayHeight = 150; // Approximate height of the overlay
    final double overlayBottom =
        buttonPosition.dy + buttonSize.height + overlayHeight;

    // Check if overlay would go out of the screen
    if (overlayBottom > screenHeight) {
      // Calculate the amount to scroll
      final scrollAmount =
          overlayBottom - screenHeight + 20; // Add extra padding if needed

      _scrollController
          .animateTo(
        _scrollController.offset + scrollAmount,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        // Directly adjust the top position without recalculating from `localToGlobal`
        final adjustedPosition =
            Offset(buttonPosition.dx, buttonPosition.dy - scrollAmount);

        // Re-display the overlay at the adjusted position
        _displayOverlay(context, concept, adjustedPosition, buttonSize,
            overlayWidth, background, isCompleted, isLocked);
      });
    } else {
      // If no scrolling is needed, directly display the overlay
      _displayOverlay(context, concept, buttonPosition, buttonSize,
          overlayWidth, background, isCompleted, isLocked);
    }
  }

  void _displayOverlay(
      BuildContext context,
      Map<String, dynamic> concept,
      Offset buttonPosition,
      Size buttonSize,
      double overlayWidth,
      Color background,
      bool isCompleted,
      bool isLocked) {
    currentOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background that dismisses the overlay on tap
          GestureDetector(
            behavior:
                HitTestBehavior.translucent, // Allows taps to pass through
            onTap: () {
              currentOverlayEntry?.remove(); // Remove the overlay
              currentOverlayEntry = null;
            },
          ),
          // Overlay content
          Positioned(
            top: buttonPosition.dy + buttonSize.height, // Position below button
            left: (MediaQuery.of(context).size.width - overlayWidth) /
                2, // Center overlay horizontally
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: overlayWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept['name'],
                      style: GoogleFonts.raleway(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time, // 🕒 Clock icon
                          size: 18,
                          color: Colors.black,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Time to complete : ${concept['expectedCompletionTime']} mins",
                          style: GoogleFonts.arOneSans(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ChicletAnimatedButton(
                      onPressed: () {
                        if (isLocked) {
                          return;
                        }
                        HapticFeedback.lightImpact();
                        logConceptStart(concept['id']);
                        currentOverlayEntry?.remove();
                        currentOverlayEntry = null;
                        // if (firstLesson) {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => ConceptStartScreen(
                        //         conceptId: concept['id'],
                        //         conceptName: concept['name'],
                        //         maxXP: totalXPForConcept * xpMultiplier,
                        //         name: userProfile['firstName'],
                        //         subject: _selectedSubject,
                        //         standard: userProfile['standard'],
                        //         firstLesson: true,
                        //       ),
                        //     ),
                        //   );
                        // } else {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => ConceptLearningScreenV2(
                        //         conceptId: concept['id'],
                        //         conceptName: concept['name'],
                        //         maxXP: totalXPForConcept * xpMultiplier,
                        //         name: userProfile['firstName'],
                        //         subject: _selectedSubject,
                        //         standard: userProfile['standard'],
                        //       ),
                        //     ),
                        //   );
                        // }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConceptLearningScreenV3(
                              conceptId: concept['id'],
                              conceptName: concept['name'],
                              maxXP: totalXPForConcept * xpMultiplier,
                              name: userProfile['firstName'],
                              subject: _selectedSubject,
                              standard: userProfile['standard'],
                            ),
                          ),
                        );
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      height: 40,
                      width: double.infinity,
                      buttonHeight: 4,
                      padding: EdgeInsets.all(0),
                      buttonColor: Colors.green,
                      backgroundColor: Colors.lightGreen,
                      child: Text(
                        isCompleted
                            ? "Discuss Again"
                            : isLocked
                                ? "LOCKED"
                                : "Let's Discuss  +${totalXPForConcept * xpMultiplier} XP",
                        style: GoogleFonts.arOneSans(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Insert the new overlay
    Overlay.of(context)?.insert(currentOverlayEntry!);
  }

  void _applyPowerUp(Map<String, dynamic> powerup) {
    setState(() {
      // Example: Update XP Boost or Lifelines
      activePowerup = powerup;
      if (powerup['type'] == 'XP_BOOST') {
        xpMultiplier = powerup['benefit'];
        prefs.setInt("xpMultiplier", xpMultiplier);
      } else if (powerup['type'] == 'LIFELINE_BOOST') {
        if (powerup['id'] == 'lifeline_boost_1') {
          unlimitedLifelines = true;
          toggleUnlimitedLifelines(prefs, unlimitedLifelines);
        } else if (powerup['id'] == 'lifeline_boost_2') {
          lifelinesAvailable = 5; // Refill hearts
          updateLifelines(prefs, lifelinesAvailable);
        }
      } else if (powerup['type'] == 'GOD_MODE') {
        xpMultiplier = 3; // Example of combined benefits
        prefs.setInt("xpMultiplier", xpMultiplier);
        unlimitedLifelines = true;
        toggleUnlimitedLifelines(prefs, unlimitedLifelines);
      }
    });
  }

  Future<void> _applyTimedPowerUp(
      Map<String, dynamic> powerup, int credits) async {
    setState(() {
      creditsAvailable = credits;
    });
    prefs.setDouble(
        "powerupStartTime", DateTime.now().millisecondsSinceEpoch / 1000);
    if (powerup['validity'] == 1) {
      _applyPowerUp(powerup);
      return;
    }
    if (powerup['validity'] > 1) {
      // Apply the power-up
      _applyPowerUp(powerup);

      // Reset after validity period
      await Future.delayed(Duration(minutes: powerup['validity']), () {
        setState(() {
          activePowerup = {};
          if (powerup['type'] == 'XP_BOOST') {
            xpMultiplier = 1; // Reset XP multiplier
            prefs.setInt("xpMultiplier", xpMultiplier);

            showEventPopup(context,
                {"powerupEnded": true, "powerupName": "XP Multiplier"});
          } else if (powerup['type'] == 'LIFELINE_BOOST') {
            // setState(() {
            //   unlimitedLifelines = false;
            // });
            unlimitedLifelines = false;
            toggleUnlimitedLifelines(prefs, false);
            showEventPopup(context,
                {"powerupEnded": true, "powerupName": "Unlimited Hearts"});
          } else if (powerup['type'] == 'GOD_MODE') {
            xpMultiplier = 1;
            // setState(() {
            //   unlimitedLifelines = false;
            // });
            prefs.setInt("xpMultiplier", xpMultiplier);

            unlimitedLifelines = false;
            toggleUnlimitedLifelines(prefs, false);
            showEventPopup(
                context, {"powerupEnded": true, "powerupName": "God Mode"});
          }
        });
      });
    }
  }

  void showEventPopup(BuildContext context, Map<String, dynamic> event) {
    final popupData = PopupManager.getPopupForEvent(event);
    if (popupData != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return GenericPopup(popupData: popupData);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
            backgroundColor: Color.fromRGBO(19, 31, 36, 1),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[700]!,
                      highlightColor: Colors.grey[300]!,
                      child: Text(
                        'Loading...',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            backgroundColor: Color.fromRGBO(19, 31, 36, 1),
            appBar: _listOpacity == 0
                ? null
                : AppBar(
                    backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: AnimatedOpacity(
                        opacity: _listOpacity, // Use the opacity variable
                        duration:
                            Duration(milliseconds: 1), // Animation duration
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Image.asset(
                                  'lib/assets/bookIcon.png',
                                  height: 24,
                                  width: 24,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _showSubjectSelectionSheet(context);
                                  logSubjectSelectionButtonClick();
                                },
                              ),
                              Row(children: [
                                GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      logStreakButtonClick();
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => StreakScreen(
                                          streakCount:
                                              userProfile["streakActive"]
                                                  ? userProfile["streakDetails"]
                                                      ["activeDays"]
                                                  : 0,
                                          streakStartDate: userProfile[
                                                  "streakActive"]
                                              ? DateTime.now().subtract(Duration(
                                                  days: userProfile[
                                                              "streakDetails"]
                                                          ["activeDays"] -
                                                      1))
                                              : DateTime.now(),
                                          streakGoal: 7,
                                          expiryToday: userProfile[
                                                  "streakActive"]
                                              ? isToday(
                                                  userProfile["streakDetails"]
                                                      ["expiry"])
                                              : true,
                                          streakActive:
                                              userProfile["streakActive"],
                                        ),
                                      );
                                    },
                                    child: !userProfile["streakActive"] ||
                                            isToday(userProfile["streakDetails"]
                                                ["expiry"])
                                        ? Image.asset(
                                            'lib/assets/inactiveStreakIcon.png',
                                            height: 24,
                                            width: 24,
                                          )
                                        : Image.asset(
                                            'lib/assets/streakIcon.png',
                                            height: 24,
                                            width: 24,
                                          )),
                                SizedBox(width: 5),
                                Text(
                                    !userProfile["streakActive"]
                                        ? '0'
                                        : '${userProfile["streakDetails"]["activeDays"]}',
                                    style: TextStyle(color: Colors.white)),
                              ]),
                              GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    logShopButtonClick();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => ShopScreen(
                                        gems: creditsAvailable,
                                        onPowerUpPurchased: (powerup, credits) {
                                          _applyTimedPowerUp(powerup, credits);
                                        },
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'lib/assets/gemIcon.png',
                                        height: 24,
                                        width: 24,
                                      ),
                                      SizedBox(width: 5),
                                      Text("$creditsAvailable",
                                          style: TextStyle(color: Colors.white))
                                    ],
                                  )),
                              GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    logLifelinesButtonClick();
                                    _showLifelinesSheet(context);
                                  },
                                  child: Row(children: [
                                    // Image.asset(
                                    //   'lib/assets/gemIcon.png',
                                    //   height: 24,
                                    //   width: 24,
                                    // ),
                                    Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                        unlimitedLifelines
                                            ? "∞"
                                            : "$lifelinesAvailable",
                                        style: TextStyle(color: Colors.white))
                                  ]))
                            ]))),
            body: Stack(children: [
              if (_listOpacity == 0)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[700]!,
                      highlightColor: Colors.grey[300]!,
                      child: Text(
                        'Loading...',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              AnimatedOpacity(
                  opacity: _listOpacity, // Use the opacity variable
                  duration: Duration(milliseconds: 1), // Animation duration
                  child: Stack(children: [
                    Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: SizedBox(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: chapters.length,
                          itemBuilder: (context, chapterIndex) {
                            final chapter = chapters[chapterIndex];
                            return Column(children: [
                              // Padding(
                              //     padding: const EdgeInsets.only(top: 40),
                              //     child: Text(
                              //       chapter['name'],
                              //       style: GoogleFonts.raleway(
                              //         color: Color.fromRGBO(255, 217, 0, 1),
                              //         fontSize: 24,
                              //         fontWeight: FontWeight.w700,
                              //       ),
                              //       maxLines: 3,
                              //       overflow: TextOverflow.ellipsis,
                              //       textAlign: TextAlign.center,
                              //     )),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 40, left: 0, right: 0),
                                child: Container(
                                  width: double
                                      .infinity, // <-- this makes it expand horizontally
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(
                                        21, 40, 48, 1), // Optional background
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.keyboard_double_arrow_down,
                                            color:
                                                Color.fromRGBO(255, 217, 0, 1)),
                                        SizedBox(
                                          width: 16,
                                        ),
                                        Expanded(
                                          child: Text(
                                            chapter['name'],
                                            style: GoogleFonts.raleway(
                                              color: Color.fromRGBO(
                                                  255, 217, 0, 1),
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 16,
                                        ),
                                        Icon(Icons.keyboard_double_arrow_down,
                                            color:
                                                Color.fromRGBO(255, 217, 0, 1)),
                                      ]),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: chapter['topics']
                                    .asMap()
                                    .entries
                                    .map<Widget>((topicEntry) {
                                  final int topicIndex = topicEntry.key;
                                  final topic = topicEntry.value;
                                  final concepts = topic['lessons'];
                                  final globalKeyIndex = chapters
                                          .take(chapterIndex)
                                          .fold<int>(
                                              0,
                                              (total, chapter) =>
                                                  total +
                                                  (chapter['topics'].length
                                                      as int)) +
                                      topicIndex;
                                  final buttonColour = buttonColours[
                                      (topic['seqNumber'] - 1) %
                                          buttonColours.length];

                                  // final buttonColour;
                                  // if (chapterIndex == 0 && topicIndex == 0) {
                                  //   buttonColour = buttonColours[topicIndex];
                                  // } else {
                                  //   int randomIndex = Random().nextInt(4) +
                                  //       1; // Generates a random number from 1 to 5
                                  //   buttonColour = buttonColours[randomIndex];
                                  // }
                                  return Padding(
                                    key: _topicKeys[globalKeyIndex],
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Divider with Topic Name
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 0, horizontal: 20),
                                          child: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Divider(
                                                      color: Colors.grey,
                                                      thickness: 1,
                                                      endIndent: 10,
                                                    ),
                                                  ),
                                                  Container(
                                                    constraints: BoxConstraints(
                                                      maxWidth: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width *
                                                          0.7, // Limits text width
                                                    ),
                                                    child: Text(
                                                      topic['name'],
                                                      style:
                                                          GoogleFonts.raleway(
                                                        color: Colors.grey,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Divider(
                                                      color: Colors.grey,
                                                      thickness: 1,
                                                      indent:
                                                          10, // Space between text and divider
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Concept Islands in a Stack with Alternating Pattern
                                        SizedBox(
                                          height: concepts.length * 100.0,
                                          child: Stack(
                                            children: [
                                              ...List.generate(concepts.length,
                                                  (index) {
                                                double topOffset =
                                                    index * 100.0;
                                                double screenWidth =
                                                    MediaQuery.of(context)
                                                        .size
                                                        .width;
                                                double leftOffset;

                                                int globalConceptIndex = chapters
                                                        .take(chapterIndex)
                                                        .fold<int>(0,
                                                            (total, chapter) {
                                                      return total +
                                                          ((chapter['topics'] as List).fold<
                                                                  int>(
                                                              0,
                                                              (subTotal,
                                                                      topic) =>
                                                                  subTotal +
                                                                  (topic['lessons']
                                                                          as List)
                                                                      .length));
                                                    }) +
                                                    (chapter['topics'] as List)
                                                        .take(topicIndex)
                                                        .fold<int>(
                                                            0,
                                                            (subTotal, topic) =>
                                                                subTotal +
                                                                (topic['lessons']
                                                                        as List)
                                                                    .length) +
                                                    index;

                                                int topicConceptIndex =
                                                    index; // Resets per topic

                                                int wavePosition =
                                                    topicConceptIndex % 6;
                                                bool isLeft = wavePosition <
                                                    3; // First 3 go left, last 3 go right

                                                int shift = [
                                                  50,
                                                  80,
                                                  120,
                                                  120,
                                                  80,
                                                  50
                                                ][wavePosition];

                                                leftOffset = isLeft
                                                    ? (screenWidth / 2) - shift
                                                    : (screenWidth / 2) -
                                                        shift +
                                                        60; // Shift right
                                                final concept = concepts[index];
                                                //current_lesson
                                                final isLastCompleted =
                                                    concept['id'] ==
                                                        conceptToStartFrom;
                                                final isCompleted =
                                                    completedConcepts.contains(
                                                        concept['id']);
                                                final isStartOfTopic =
                                                    !isCompleted &&
                                                        concept['id'] !=
                                                            conceptToStartFrom &&
                                                        concept['id']
                                                            .toString()
                                                            .endsWith('_1');

                                                const isDisabled = false;
                                                final GlobalKey buttonKey =
                                                    GlobalKey();

                                                return Positioned(
                                                  top: topOffset,
                                                  left: leftOffset,
                                                  child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .only(
                                                              top: 30.0,
                                                              left: 20,
                                                              right:
                                                                  20), // Add space above the stack
                                                          child:
                                                              ChicletAnimatedButton(
                                                            key: buttonKey,
                                                            onPressed: () {
                                                              HapticFeedback
                                                                  .lightImpact();
                                                              logConceptClicked(
                                                                  concept[
                                                                      'id']);
                                                              showOverlay(
                                                                  context,
                                                                  concept,
                                                                  buttonKey,
                                                                  isDisabled
                                                                      ? Color.fromRGBO(
                                                                          56,
                                                                          70,
                                                                          79,
                                                                          1)
                                                                      : buttonColour[
                                                                          'background'],
                                                                  isCompleted,
                                                                  isDisabled);
                                                            },
                                                            buttonType:
                                                                ChicletButtonTypes
                                                                    .oval,
                                                            width: 70,
                                                            height: 60,
                                                            buttonHeight: 6,
                                                            padding:
                                                                EdgeInsets.all(
                                                                    0),
                                                            buttonColor:
                                                                isDisabled
                                                                    ? Color
                                                                        .fromRGBO(
                                                                            42,
                                                                            55,
                                                                            63,
                                                                            1)
                                                                    : isCompleted
                                                                        ? Colors
                                                                            .green
                                                                        : buttonColour[
                                                                            'button'],
                                                            backgroundColor:
                                                                isDisabled
                                                                    ? Color
                                                                        .fromRGBO(
                                                                            56,
                                                                            70,
                                                                            79,
                                                                            1)
                                                                    : isCompleted
                                                                        ? Colors.green[
                                                                            200]
                                                                        : buttonColour[
                                                                            'background'],
                                                            child: Shimmer
                                                                .fromColors(
                                                              enabled: isDisabled ||
                                                                      isCompleted
                                                                  ? false
                                                                  : true,

                                                              baseColor:
                                                                  Colors.black,
                                                              highlightColor:
                                                                  buttonColour[
                                                                      'background'],
                                                              child: index == 0
                                                                  ? Icon(
                                                                      Icons
                                                                          .fast_forward_rounded,
                                                                      color:
                                                                          Colors
                                                                              .black,
                                                                      size: 40)
                                                                  : Icon(
                                                                      Icons
                                                                          .star_rounded,
                                                                      color: Colors
                                                                          .black,
                                                                      size: 40),
                                                              // : concepts[index]['type'] == 'reward'
                                                              //     ? Icon(Icons.card_giftcard,
                                                              //         color: Colors.black, size: 40)
                                                              //     : Icon(Icons.star_rounded,
                                                              //         color: Colors.black,
                                                              //         size: 40),
                                                            ),
                                                          ),
                                                        ),
                                                        if (isLastCompleted)
                                                          _BouncingTextIndicator(
                                                            text: "START",
                                                            textColor:
                                                                buttonColour[
                                                                    "background"],
                                                            powerupType: activePowerup
                                                                    .isNotEmpty
                                                                ? activePowerup[
                                                                    "type"]
                                                                : null,
                                                          ),
                                                        if (isStartOfTopic)
                                                          _BouncingTextIndicator(
                                                              text: "JUMP HERE",
                                                              textColor:
                                                                  buttonColour[
                                                                      "background"]),
                                                      ]),
                                                );
                                              })
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            ]);
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: ChicletAnimatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showChapterSelectionSheet(context);
                          logTopicButtonClick(_activeTopic);
                        },
                        height: 85,

                        // height: 100,
                        buttonHeight: 4,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        buttonColor: _activeButtonColour['button'],
                        backgroundColor: _activeButtonColour['background'],
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Ensures left alignment
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    activeChapter,
                                    style: GoogleFonts.raleway(
                                      color: Colors.black54,
                                      fontSize:
                                          16, // Small size kept aligned to the left
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _activeTopic,
                                    style: GoogleFonts.raleway(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: ChicletAnimatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showChapterSelectionSheet(context);
                            logChapterSelectionButtonClick();
                          },
                          buttonType: ChicletButtonTypes.circle,
                          width: 80,
                          height: 50,
                          buttonHeight: 4,
                          padding: EdgeInsets.all(0),
                          buttonColor: Color.fromRGBO(187, 160, 2, 1),
                          backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                          child: Icon(Icons.menu_book,
                              color: Colors.black, size: 30)),
                    )
                  ]))
            ]),
          );
  }
}

// BouncingTextIndicator widget inside the same file:
class _BouncingTextIndicator extends StatefulWidget {
  final String text;
  final Color textColor;
  final String? powerupType;

  const _BouncingTextIndicator(
      {Key? key, required this.text, required this.textColor, this.powerupType})
      : super(key: key);

  @override
  State<_BouncingTextIndicator> createState() => _BouncingTextIndicatorState();
}

class _BouncingTextIndicatorState extends State<_BouncingTextIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true); // Repeat the animation in reverse

    _animation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget getPowerupIcon() {
    switch (widget.powerupType) {
      case "XP_BOOST":
        return Icon(Icons.trending_up, color: Colors.purple.shade400, size: 20);
      case "LIFELINE_BOOST":
        return Icon(Icons.favorite, color: Colors.red, size: 20);
      case "GOD_MODE":
        return Icon(Icons.star, color: Colors.blue, size: 20);
      default:
        return SizedBox(); // Empty widget if no power-up type is provided
    }
  }

  Color getTextColor() {
    switch (widget.powerupType) {
      case "XP_BOOST":
        return Colors.purple.shade400;
      case "LIFELINE_BOOST":
        return Colors.red;
      case "GOD_MODE":
        return Colors.blue;
      default:
        return widget.textColor;
    }
  }

  /// **Dynamically get Border Color**
  Color getBorderColor() {
    switch (widget.powerupType) {
      case "XP_BOOST":
        return Colors.purple.shade400;
      case "LIFELINE_BOOST":
        return Colors.red;
      case "GOD_MODE":
        return Colors.blue;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value,
          // left: 7,
          child: BubbleBox(
              maxWidth: double.infinity,
              shape: BubbleShapeBorder(
                  border: BubbleBoxBorder(
                    color: getBorderColor(),
                    width: 3,
                  ),
                  radius: BorderRadius.circular(12),
                  position: const BubblePosition.center(0),
                  direction: BubbleDirection.bottom,
                  arrowHeight: 8),
              backgroundColor: Color.fromRGBO(19, 31, 36, 1),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                child: Row(children: [
                  getPowerupIcon(),
                  if (widget.powerupType != null) SizedBox(width: 6),
                  Text(
                    widget.text,
                    style: GoogleFonts.raleway(
                      color: getTextColor(),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  )
                ]),
              )),
        );
      },
    );
  }
}
