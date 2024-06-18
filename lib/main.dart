import 'package:eureka_app/screens/communityScreen.dart';
import 'package:eureka_app/screens/exploreScreen.dart';
import 'package:eureka_app/screens/onboardingScreen.dart';
import 'package:eureka_app/screens/otpPage.dart';
import 'package:eureka_app/screens/profileCreationScreen.dart';
import 'package:eureka_app/screens/profileScreen.dart';
import 'package:eureka_app/screens/signupScreen.dart';
import 'package:eureka_app/screens/speechScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/homeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ensure this path matches your file structure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? firstLaunchBool = prefs.getBool('firstLaunch');
  bool firstLaunch = firstLaunchBool ?? true; // Default to true if null
  print(
      "First Launch: $firstLaunch"); // This should print true or false, not null

  runApp(MyApp(firstLaunch: firstLaunch));
}

class MyApp extends StatelessWidget {
  final bool firstLaunch;

  const MyApp({super.key, required this.firstLaunch});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyAppState>(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'GlutaFam',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        ),
        debugShowCheckedModeBanner: false,
        home: firstLaunch ? OnboardingScreen() : MyHomePage(),
        routes: {
          '/home': (context) => MyHomePage(),
          '/explore': (context) => ExploreScreen(),
          '/community': (context) => Signupscreen(),
          '/profile': (context) => ProfileScreen(),
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
