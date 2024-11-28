import 'package:eureka_app/screens/communityScreen.dart';
import 'package:eureka_app/screens/landingScreen.dart';
import 'package:eureka_app/screens/landingScreenWeb.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/classSelection.dart';
import 'package:eureka_app/screens/ncertPodcasts/feedbackScreen.dart';
import 'package:eureka_app/screens/profileScreen.dart';
import 'package:eureka_app/screens/signupScreen.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'package:eureka_app/services/myAudioHandler.dart';
import 'package:eureka_app/services/notificationService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eureka_app/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
// import 'package:miniplayer/miniplayer.dart'; // Add miniplayer import
import 'dart:io' show Platform;
import 'package:audio_service/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
      androidNotificationChannelId: 'com.gluta.glutafam.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/notification_icon'

      // Keeps the notification active
      );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? firstLaunchBool = prefs.getBool('firstLaunch');
  bool firstLaunch = firstLaunchBool ?? true; // Default to true if null

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  bool isRealDevice = await checkIfRealDevice();
  if (isRealDevice) {
    String? token = await notificationService.getDeviceToken();
    print("FCM Device Token: $token");
    await notificationService.subscribeToTopic("all_users");
  }
  print("First Launch: $firstLaunch");

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
          return MaterialApp(
            title: 'GlutaClass',
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
                    : LandingScreen())
                : Chapterscreen(),
            routes: {
              '/home': (context) => Chapterscreen(),
              '/explore': (context) => CommunityPage(),
              '/community': (context) => Signupscreen(),
              '/profile': (context) => ProfileScreen(),
            },
          );
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
