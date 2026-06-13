import 'package:eureka_app/apis/fetchRewardDetails.dart';
import 'package:eureka_app/apis/refreshAccessToken.dart';
import 'package:eureka_app/apis/updateFCMToken.dart';
import 'package:eureka_app/apis/howwow/howwowAuth.dart';
import 'package:eureka_app/utils/routeObserver.dart';
import 'package:eureka_app/events/genericEvents.dart';
import 'package:eureka_app/homepageWeb/tutoHomePage.dart';
import 'package:eureka_app/newEvents/notificationEvents.dart';
import 'package:eureka_app/parentDashboard/parentDashboardPage.dart';
import 'package:eureka_app/screens/aiTutor/newLesson.dart';
import 'package:eureka_app/screens/aiTutor/statistics_lesson.dart';
import 'package:eureka_app/screens/conceptLearningScreenV2.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:eureka_app/screens/home/homeScreenV2.dart';
import 'package:eureka_app/screens/home/career/careerHomeScreen.dart';
import 'package:eureka_app/screens/auth/authGate.dart';
import 'package:eureka_app/screens/htmlExampleScreen.dart';
import 'package:eureka_app/screens/loginScreen.dart';
import 'package:eureka_app/screens/micTest.dart';
import 'package:eureka_app/screens/ncertPodcasts/sectionsListingScreen.dart';
import 'package:eureka_app/screens/profileScreen.dart';
import 'package:eureka_app/screens/vaultScreen.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'package:eureka_app/services/notificationService.dart';
// Network detection (connectivity-based "No Internet" / "Back online!" popups)
// disabled for now per product — kept in lib/services/simpleNetworkService.dart,
// lib/providers/simpleNetworkProvider.dart and lib/widgets/networkListener.dart
// for possible later use.
// import 'package:eureka_app/services/simpleNetworkService.dart';
// import 'package:eureka_app/providers/simpleNetworkProvider.dart';
import 'package:app_links/app_links.dart';
import 'package:eureka_app/utils/deeplink/howwowDeeplinkRouter.dart';
import 'package:eureka_app/utils/howwowEventLogger.dart';
import 'package:eureka_app/utils/howwowEventNames.dart';
// import 'package:eureka_app/widgets/networkListener.dart'; // disabled (network popups)
import 'package:singular_flutter_sdk/singular.dart';
import 'package:singular_flutter_sdk/singular_config.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:eureka_app/utils/lifecycle_event_handler.dart';
import 'package:eureka_app/widgets/achievementDetailsWidgetV2.dart';
import 'package:eureka_app/widgets/collectionDetailsWidget.dart';
import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:eureka_app/widgets/questsScreen.dart';
import 'package:eureka_app/widgets/weeklyLeaderboardContent.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eureka_app/firebase_options.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart'; // REMOVED: Package discontinued
import 'package:eureka_app/services/deep_link_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import './utils/navigation_utils.dart'; // Import the navigatorKey
import 'package:url_launcher/url_launcher.dart';

// import 'package:miniplayer/miniplayer.dart'; // Add miniplayer import
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force google_fonts to use only the TTF files bundled under /google_fonts/
  // in pubspec — no runtime network fetch, so the first paint already has
  // Poppins available. Eliminates the cold-start font-flash where text
  // initially rendered in the system default font and then re-flowed.
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Network detection disabled for now (connectivity popups commented out) — was:
  // await SimpleNetworkService().initialize();
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
        // Howwow: push the current FCM token on every cold start. The helper
        // no-ops when there's no stored appJwt (anonymous session) so this
        // is safe regardless of auth state.
        howwowSetFcmToken(token);
        // Howwow: also watch for FCM-initiated token rotation (~270d idle,
        // reinstall, etc.) so the backend never holds a stale token.
        FirebaseMessaging.instance.onTokenRefresh.listen((rotated) {
          prefs.setString("fcmToken", rotated);
          howwowSetFcmToken(rotated);
        });
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          logNotificationReceived();
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          logNotificationTapped();
          final deeplink = message.data['deeplink'];
          if (deeplink != null) {
            _handleDeeplinkFromFCM(Uri.parse(deeplink));
          }
        });

        FirebaseMessaging.instance
            .getInitialMessage()
            .then((RemoteMessage? message) {
          if (message != null) {
            logNotificationTapped();
            final deeplink = message.data['deeplink'];
            if (deeplink != null) {
              _handleDeeplinkFromFCM(Uri.parse(deeplink));
            }
          }
        });
      }
    }
    print("First Launch: $firstLaunch");
    Map<String, String> deviceDetails = await getDeviceDetails();
    String deviceId = deviceDetails['deviceId'] ?? "Unknown";
    String platform = deviceDetails['platform'] ?? "Unknown";
    String userIP = await getUserIP();

    AuthTokenService authTokenService = AuthTokenService();
    Map<String, dynamic> refreshTokenResponse = await refreshAccessToken();
    await authTokenService.setAuthToken(refreshTokenResponse['token'] ?? "");

    logAppLaunchEvent(deviceId, platform, userIP, firstLaunch);
    if (!kIsWeb) {
      final deepLinkService = DeepLinkService();
      await deepLinkService.initialize();

      // Initialize Singular SDK
      await initializeSingular();
    }
  });

  // Initialise howwow analytics logger BEFORE any screen fires events.
  // Loads the persistent offline queue, mints/restores the anonymousId
  // (device-stable UUID kept in SharedPreferences), and kicks off the
  // 30 s periodic flush timer. The very first event fired is app_opened.
  await HowwowEventLogger.instance.init();
  HowwowEventLogger.instance.logImmediate(HowwowEvents.appOpened, props: {
    'first_launch': firstLaunch,
  });

  // Subscribe app_links for howwow:// URLs (cold-start + foreground
  // stream). The legacy DeepLinkService also subscribes for tuto://
  // routes; each handler filters by scheme so they coexist without
  // conflict.
  await _initHowwowDeeplinks();

  runApp(MyApp(
    firstLaunch: firstLaunch,
    notificationService: notificationService,
  ));
}

/// Logs `screen_viewed` on every named route push and `app_backgrounded`
/// on app lifecycle paused state. Wired into MaterialApp via
/// `navigatorObservers:` and the global WidgetsBindingObserver.
class _HowwowScreenObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _emit(newRoute);
  }

  void _emit(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    HowwowEventLogger.instance.log(
      HowwowEvents.screenViewed,
      props: {'screen': name},
    );
  }
}

/// Adds the howwow `app_backgrounded` flush hook on top of the existing
/// LifecycleEventHandler so the analytics queue drains before the OS
/// freezes the process.
class _HowwowLifecycleObserver with WidgetsBindingObserver {
  DateTime? _foregroundSince;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _foregroundSince = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final sec = _foregroundSince == null
          ? 0
          : DateTime.now().difference(_foregroundSince!).inSeconds;
      HowwowEventLogger.instance.log(
        HowwowEvents.appBackgrounded,
        props: {'session_duration_sec': sec},
      );
      // Best-effort flush — fire-and-forget; OS may freeze us before it
      // completes, but the queue is persisted to SharedPreferences.
      HowwowEventLogger.instance.flush();
    } else if (state == AppLifecycleState.resumed) {
      _foregroundSince = DateTime.now();
    }
  }
}

class MyApp extends StatelessWidget {
  final bool firstLaunch;
  final NotificationService notificationService;

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  static final _HowwowScreenObserver howwowScreenObserver =
      _HowwowScreenObserver();
  static final _HowwowLifecycleObserver _howwowLifecycle =
      _HowwowLifecycleObserver()..start();
  const MyApp({
    super.key,
    required this.firstLaunch,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    // Touch the lifecycle observer so the static initialiser runs even
    // when the build path elides the singleton field. No-op at runtime.
    // ignore: unnecessary_statements
    _howwowLifecycle;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAppState()),
        ChangeNotifierProvider(
            create: (_) => AudioProvider()), // Add AudioProvider
        // Network detection provider disabled for now (popups off) — was:
        // ChangeNotifierProvider(
        //     create: (_) => SimpleNetworkProvider()), // Add Network Provider
      ],
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addObserver(LifecycleEventHandler(
              context: context, firstLaunch: firstLaunch));

          // NetworkListener drives the connectivity "No Internet" /
          // "Back online!" popups — disabled for now (kept in
          // lib/widgets/networkListener.dart for later). The MaterialApp is
          // returned directly instead of being wrapped.
          // return NetworkListener(
          //   child: MaterialApp(
          return MaterialApp(
              title: "Tuto: AI Tutor for Class 6-12",
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
                howwowScreenObserver,
                appRouteObserver,
              ],
              debugShowCheckedModeBanner: false,
              onGenerateInitialRoutes: (initialRoute) {
                Widget start;
                if (initialRoute == '/parent-dashboard') {
                  start = const ParentDashboardPage();
                } else if (initialRoute == '/home') {
                  // start = const TutoHomePage();
                  start = HomeScreenV2();
                } else {
                  start = firstLaunch
                      ? (kIsWeb
                          ? (checkIsWebOnDesktop(context)
                              // ? TutoHomePage()
                              ? MainPage()
                              : MainPage())
                          // ? LandingScreenWeb()
                          // : LandingScreenMobile())
                          : LoginScreen())
                      : MainPage();
                }
                // Howwow launch flow: AuthGate checks for a stored appJwt
                // (from a previous howwowLogin) and routes to either the
                // CareerHomeScreen or the HowwowLoginScreen.
                start = const AuthGate();
                return [
                  MaterialPageRoute(
                      builder: (_) => start,
                      settings: RouteSettings(name: initialRoute)),
                ];
              },
              // home: firstLaunch
              //     ? (kIsWeb
              //         ? (checkIsWebOnDesktop(context)
              //             ? LandingScreenWeb()
              //             // ? ParentDashboardPage()
              //             : LandingScreenMobile())
              //         : LoginScreen())
              //     : MainPage(),
              routes: {
                // howwow: '/home' now points at the new career home. The
                // legacy TutoHomePage still ships in the bundle but is no
                // longer reachable via a named route.
                '/home': (_) => const CareerHomeScreen(),
                '/chapterDetails': (context) => Sectionscreen(
                      chapterId: "",
                    ),
                '/parent-dashboard': (_) => ParentDashboardPage(),
                '/vault': (_) => VaultScreen(),
              },
            );
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final int? initialIndex;

  const MainPage({Key? key, this.initialIndex}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreenV2(),
      // HomeScreen(),

      // QuestsScreen(),
      // TimetableEditorScreen(),
      // WeeklyLeaderboardContent(),
      // ProgressReportScreen(),
      ProfileScreen(),
      // HtmlExampleScreen(),
      // StatisticsLessonScreen()
      // UrbanPlannerLesson()
      // VaultScreen()
      // MicSmokeTest()
      // OnboardingScreenV4()
      // ResumeLessonsPage()
      // FeedScreen()
      // LoginScreen()
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
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
  // if (!kIsWeb) {
  //   return false; // Not running on web
  // }

  // Check if the screen width exceeds a typical mobile width threshold
  final double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth >= 600; // Adjust this breakpoint for your needs
  // return true;
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
  // REMOVED: Firebase Dynamic Links functionality
  // The Firebase Dynamic Links service has been discontinued
  print('Dynamic Links functionality removed - service discontinued');
}

// Retrieve initial link (for when the app is opened via a dynamic link)
Future<void> handleInitialDynamicLink(SharedPreferences prefs) async {
  // REMOVED: Firebase Dynamic Links functionality
  // The Firebase Dynamic Links service has been discontinued
  print('Initial Dynamic Link functionality removed - service discontinued');
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
  if (deepLink.path == '/collection' &&
      deepLink.queryParameters.containsKey('collectionItemId')) {
    String collectionItemId = deepLink.queryParameters['collectionItemId']!;
  }
}

void _handleDeeplinkFromFCM(Uri deeplink) async {
  if (deeplink.path == '/lesson' &&
      deeplink.queryParameters.containsKey('conceptId')) {
    String conceptId = deeplink.queryParameters['conceptId']!;
    String conceptName = deeplink.queryParameters['conceptName']!;
    String name = deeplink.queryParameters['name']!;
    String? standardStr = deeplink.queryParameters['standard'];
    int standard = int.tryParse(standardStr ?? '') ?? 0;
    String subject = deeplink.queryParameters['subject']!;
    String bookId = deeplink.queryParameters['bookId']!;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("bookId", bookId);
    await prefs.setString("subject", subject);

    // Navigator.push(
    //   navigatorKey.currentContext!,
    //   MaterialPageRoute(
    //     builder: (context) => ConceptLearningScreenV2(
    //         conceptId: conceptId,
    //         conceptName: conceptName,
    //         maxXP: 90,
    //         name: name,
    //         subject: subject,
    //         standard: standard),
    //   ),
    // );
  } else if (deeplink.path == '/quests') {
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => MainPage(initialIndex: 1),
      ),
    );
  } else if (deeplink.path == '/leaderboard') {
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => MainPage(initialIndex: 2),
      ),
    );
  } else if (deeplink.path == "/update") {
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

  // You can add more FCM deeplink routes here if needed
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

void navigateToCollectionItem(String collectionItemId) async {
  // Use Navigator to push the ProfileScreen with the userId
  Map<String, dynamic> rewardData =
      await fetchRewardDetails(rewardId: collectionItemId);
  Navigator.push(
    navigatorKey.currentContext!,
    MaterialPageRoute(
      builder: (context) => CollectionDetailsWidget(
        collectionItem: rewardData,
        feedOwner: false,
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

/// Subscribe to app_links for `howwow://` URLs and route them through
/// {@link HowwowDeeplinkRouter}. Two paths:
///   • cold-start — the URL that launched the process (if any).
///   • foreground — every URL delivered while the app is running.
/// URLs from other schemes (e.g. `tuto://`) are ignored here; the legacy
/// {@code DeepLinkService} subscribes separately for those.
Future<void> _initHowwowDeeplinks() async {
  try {
    final appLinks = AppLinks();

    // Cold-start.
    final initial = await appLinks.getInitialLink();
    if (initial != null && initial.scheme == 'howwow') {
      // ignore: discarded_futures
      HowwowDeeplinkRouter.handle(initial, defaultSource: 'external');
    }

    // Foreground stream. The subscription leaks intentionally — it's
    // valid for the lifetime of the process.
    appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme != 'howwow') return;
      // ignore: discarded_futures
      HowwowDeeplinkRouter.handle(uri, defaultSource: 'external');
    }, onError: (e) {
      // ignore: avoid_print
      print('howwow deeplink stream error: $e');
    });
  } catch (e) {
    // ignore: avoid_print
    print('howwow deeplink init failed (non-fatal): $e');
  }
}

/// Initialize Singular SDK for deferred deep linking
Future<void> initializeSingular() async {
  try {
    // Your actual Singular API Key and Secret
    const String SINGULAR_API_KEY = 'trytuto_590c9adb';
    const String SINGULAR_SECRET = 'c7b0ed3598ac60cd649b1495f11e828d';

    // Configure Singular
    SingularConfig config = SingularConfig(SINGULAR_API_KEY, SINGULAR_SECRET);

    // Initialize Singular
    Singular.start(config);

    print('✅ Singular SDK initialized successfully');
    print('📱 Singular will handle deferred deep linking automatically');
  } catch (e) {
    print('❌ Error initializing Singular SDK: $e');
  }
}
