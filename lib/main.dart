import 'package:eureka_app/screens/communityScreen.dart';
import 'package:eureka_app/screens/landingScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/screens/profileScreen.dart';
import 'package:eureka_app/screens/signupScreen.dart';
import 'package:eureka_app/services/notificationService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eureka_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

// Ensure this path matches your file structure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    // For targeted notifications, retrieve and print device token
    String? token = await notificationService.getDeviceToken();
    print("FCM Device Token: $token");

    // Subscribe to a topic for broadcast notifications
    await notificationService.subscribeToTopic("all_users");
  }
  print(
      "First Launch: $firstLaunch"); // This should print true or false, not null

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
    return ChangeNotifierProvider<MyAppState>(
      create: (context) => MyAppState(),
      child: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              boldText: false,
              textScaler: MediaQuery.of(context)
                  .textScaler
                  .clamp(minScaleFactor: 0.95, maxScaleFactor: 0.95),
            ),
            child: MaterialApp(
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
              home: firstLaunch ? LandingScreen() : Chapterscreen(),
              // home: firstLaunch ? LandingScreen() : Chapterscreen(),

              routes: {
                '/home': (context) => Chapterscreen(),
                '/explore': (context) => CommunityPage(),
                '/community': (context) => Signupscreen(),
                '/profile': (context) => ProfileScreen(),
              },
            ),
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
    notifyListeners(); // This will trigger the widgets that depend on this state to rebuild
  }
}

Future<bool> checkIfRealDevice() async {
  if (Platform.isIOS) {
    final iosDeviceInfo = await DeviceInfoPlugin().iosInfo;
    return iosDeviceInfo.isPhysicalDevice; // Returns true for real devices
  }
  return true; // Non-iOS platforms are considered real devices
}
