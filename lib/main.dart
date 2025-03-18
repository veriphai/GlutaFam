import 'dart:ffi';

import 'package:eureka_app/apis/updateFCMToken.dart';
import 'package:eureka_app/events/genericEvents.dart';
import 'package:eureka_app/popups/streakPopup.dart';
import 'package:eureka_app/screens/conceptLearningScreen.dart';
import 'package:eureka_app/screens/conceptLearningScreenV2.dart';
import 'package:eureka_app/screens/feedsScreen.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:eureka_app/screens/homeScreen.dart';
import 'package:eureka_app/screens/landingScreen.dart';
import 'package:eureka_app/screens/landingScreenWeb.dart';
import 'package:eureka_app/screens/leaderboardScreen.dart';
import 'package:eureka_app/screens/loginScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/classSelection.dart';
import 'package:eureka_app/screens/ncertPodcasts/sectionsListingScreen.dart';
import 'package:eureka_app/screens/onboardingScreenV3.dart';
import 'package:eureka_app/screens/onboardingScreenV4.dart';
import 'package:eureka_app/screens/profileScreen.dart';
import 'package:eureka_app/screens/progressReportScreen.dart';
import 'package:eureka_app/screens/quizzesScreen.dart';
import 'package:eureka_app/screens/socraticTutorScreen.dart';
import 'package:eureka_app/screens/socraticTutorScreenV2.dart';
import 'package:eureka_app/screens/socraticTutorScreenV3.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'package:eureka_app/services/notificationService.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/lifecycle_event_handler.dart';
import 'package:eureka_app/widgets/achievementDetailsWidget.dart';
import 'package:eureka_app/widgets/achievementDetailsWidgetV2.dart';
import 'package:eureka_app/widgets/conversationScreen.dart';
import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:eureka_app/widgets/mcqQuestionsWidget.dart';
import 'package:eureka_app/widgets/questsScreen.dart';
import 'package:eureka_app/widgets/weeklyLeaderboardContent.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eureka_app/firebase_options.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import './utils/navigation_utils.dart'; // Import the navigatorKey

// import 'package:miniplayer/miniplayer.dart'; // Add miniplayer import
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? firstLaunchBool = prefs.getBool('appFirstLaunch');
  bool firstLaunch = firstLaunchBool ?? true; // Default to true if null

  await setFirebaseTrackingId(prefs);

  // Initialize notifications
  final notificationService = NotificationService();
  Future.microtask(() async {
    await JustAudioBackground.init(
        androidNotificationChannelId: 'com.gluta.glutafam.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/notification_icon'

        // Keeps the notification active
        );

    if (!kIsWeb) {
      await notificationService.initNotifications();

      bool isRealDevice = await checkIfRealDevice();
      if (isRealDevice) {
        String? token = await notificationService.getDeviceToken();
        prefs.setString("fcmToken", token ?? "");
        print("FCM Device Token: $token");
        await notificationService.subscribeToTopic("all_users");
        if (!firstLaunch) {
          updateFCMToken(fcmToken: token ?? "");
        }
      }
    }
    print("First Launch: $firstLaunch");
    Map<String, String> deviceDetails = await getDeviceDetails();
    String deviceId = deviceDetails['deviceId'] ?? "Unknown";
    String platform = deviceDetails['platform'] ?? "Unknown";
    String userIP = await getUserIP();
    logAppLaunchEvent(deviceId, platform, userIP, firstLaunch);
    if (!kIsWeb) {
      initDynamicLinkListener(prefs);
      await handleInitialDynamicLink(prefs);
    }
  });

  runApp(MyApp(
    firstLaunch: firstLaunch,
    notificationService: notificationService,
  ));
}

class MyApp extends StatelessWidget {
  final bool firstLaunch;
  final NotificationService notificationService;

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  const MyApp({
    super.key,
    required this.firstLaunch,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAppState()),
        ChangeNotifierProvider(
            create: (_) => AudioProvider()), // Add AudioProvider
      ],
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addObserver(LifecycleEventHandler(
              context: context, firstLaunch: firstLaunch));

          return MaterialApp(
            title: 'GlutaClass: AI Tutor for NCERT',
            navigatorKey: navigatorKey,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
              textTheme: Theme.of(context).textTheme.apply(
                    fontSizeFactor: 1.0,
                  ),
            ),
            navigatorObservers: [
              observer,
            ],
            debugShowCheckedModeBanner: false,
            home: firstLaunch
                ? (checkIsWebOnDesktop(context)
                    ? LandingScreenWeb()
                    : LoginScreen())
                : MainPage(),
            routes: {
              '/home': (context) => Chapterscreen(),
              '/chapterDetails': (context) => Sectionscreen(
                    chapterId: "",
                  ),
            },
          );
        },
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  final int? initialIndex; // Optional index parameter

  const MainPage({Key? key, this.initialIndex}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    int currentIndex = initialIndex ?? context.watch<MyAppState>().currentIndex;

    // Define your screens
    final screens = [
      HomeScreen(),
      WeeklyLeaderboardContent(),
      // ClassSelectionPage(),
      // QuizzesScreen(),
      ProgressReportScreen(),
      // ConversationScreen(),
      // Chapterscreen(),
      ProfileScreen(),
      QuestsScreen(),
      // SocraticTutorScreen()
      // SocraticTutorScreenV3()
      // ConceptLearningScreenV2()
      // OnboardingScreenV4()
      // StreakPopup(streakCount: 3, streakStartEpoch: 1741359449, streakGoal: 50)
      FeedScreen()
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          context.read<MyAppState>().setIndex(index);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

bool checkIsWebOnDesktop(BuildContext context) {
  if (!kIsWeb) {
    return false; // Not running on web
  }

  // Check if the screen width exceeds a typical mobile width threshold
  final double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth >= 600; // Adjust this breakpoint for your needs
}

Future<bool> checkIfRealDevice() async {
  if (kIsWeb) {
    print("Running on the Web");
    return false;
  }

  if (Platform.isIOS) {
    final iosDeviceInfo = await DeviceInfoPlugin().iosInfo;
    return iosDeviceInfo.isPhysicalDevice;
  }
  return true;
}

void initDynamicLinkListener(SharedPreferences prefs) {
  // Listen for incoming dynamic links
  FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData? data) {
    final Uri? deepLink = data?.link;

    if (deepLink != null) {
      handleDeeplinks(prefs, deepLink);
    }
  }).onError((error) {
    print('Dynamic Link Error: $error');
  });
}

// Retrieve initial link (for when the app is opened via a dynamic link)
Future<void> handleInitialDynamicLink(SharedPreferences prefs) async {
  final PendingDynamicLinkData? initialLink =
      await FirebaseDynamicLinks.instance.getInitialLink();

  if (initialLink?.link != null) {
    final Uri deepLink = initialLink!.link;
    handleDeeplinks(prefs, deepLink);
  }
}

void handleDeeplinks(SharedPreferences prefs, Uri deepLink) {
  if (deepLink.queryParameters.containsKey('referralCode')) {
    String referralCode = deepLink.queryParameters['referralCode']!;
    print('Referral Code from Initial Link: $referralCode');
    prefs.setString("referralCode", referralCode);
    // Handle referral code logic
  }

  // Check if the link is for a profile
  if (deepLink.path == '/profile' &&
      deepLink.queryParameters.containsKey('userId')) {
    String userId = deepLink.queryParameters['userId']!;
    print('Profile User ID from Initial Link: $userId');

    // Navigate to the ProfileScreen
    navigateToProfileScreen(userId);
  }
  if (deepLink.path == '/achievement' &&
      deepLink.queryParameters.containsKey('achievementId')) {
    String achievementId = deepLink.queryParameters['achievementId']!;
    String levelCriteria = deepLink.queryParameters['levelCriteria']!;

    // Navigate to the ProfileScreen
    navigateToAchievementDetails(achievementId, levelCriteria);
  }
}

// Function to navigate to ProfileScreen
void navigateToProfileScreen(String userId) {
  // Use Navigator to push the ProfileScreen with the userId
  Navigator.push(
    navigatorKey.currentContext!,
    MaterialPageRoute(
      builder: (context) => FriendsProfileScreen(
        friendId: userId,
        following: false,
      ),
    ),
  );
}

void navigateToAchievementDetails(String achievementId, String levelCriteria) {
  int levelCriteriaInt = int.tryParse(levelCriteria) ?? 0;

  Navigator.push(
    navigatorKey.currentContext!,
    MaterialPageRoute(
      builder: (context) => AchievementDetailsWidgetV2(
        achievementId: achievementId,
        levelCriteria: levelCriteriaInt,
      ),
    ),
  );
}

Future<void> setFirebaseTrackingId(SharedPreferences prefs) async {
  try {
    String? userTrackingId = prefs.getString('userTrackingId');
    if (userTrackingId != null && userTrackingId.isNotEmpty) {
      await FirebaseAnalytics.instance.setUserId(id: userTrackingId);
    }
  } catch (e) {
    print("Error setting Firebase user ID: $e");
  }
}
