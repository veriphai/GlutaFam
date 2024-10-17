import 'package:eureka_app/screens/onboardingScreenV2.dart';
import 'package:eureka_app/screens/signupscreen.dart'; // Import the signup screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
                        'lib/assets/glutaclassLogo.png', // Replace with your logo's path
                        height: 110, // Adjust height as needed
                        width: 110, // Adjust width as needed
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 30),
                      Text(
                        "Interest-led Audio Lessons",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 24,
                          color: Color.fromRGBO(182, 182, 182, 1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "for Your Curriculum",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 24,
                          color: Color.fromRGBO(182, 182, 182, 1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OnboardingScreenV2()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize:
                    Size.fromHeight(50), // Make the button fill the width
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
