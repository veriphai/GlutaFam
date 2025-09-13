import 'package:eureka_app/screens/onboardingScreenV2.dart';
import 'package:eureka_app/screens/onboardingScreenV3.dart';
import 'package:eureka_app/screens/signupscreen.dart'; // Import the signup screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    _setCurrentScreen();
  }

  Future<void> _setCurrentScreen() async {
    // await FirebaseAnalytics.instance.setCurrentScreen(
    //   screenName: 'LandingScreen',
    //   screenClassOverride: 'LandingScreen',
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "GlutaClass",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 30),
                    Image.asset(
                      'lib/assets/glutaclassLogo.png',
                      height: 110,
                      width: 110,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Personalised Audio Tutor",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        fontSize: 24,
                        color: Color.fromRGBO(182, 182, 182, 1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "for Your NCERT Books",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        fontSize: 24,
                        color: Color.fromRGBO(182, 182, 182, 1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OnboardingScreenV3()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
              ),
              child: Text(
                'Get Started',
                style: GoogleFonts.nunito(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
