import 'package:eureka_app/screens/signupscreen.dart'; // Import the signup screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      Image.asset(
                        'lib/assets/glutaFamLogo.png', // Replace with your logo's path
                        height: 200, // Adjust height as needed
                        width: 200, // Adjust width as needed
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 30),
                      Text(
                        "Unlock learning with audio! Podcasts for classes 6 to 12, anytime, anywhere.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          color: Color.fromRGBO(33, 33, 33, 1),
                          fontWeight: FontWeight.w600,
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
                  MaterialPageRoute(builder: (context) => Signupscreen()),
                );
              },
              child: Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize:
                    Size.fromHeight(50), // Make the button fill the width
                backgroundColor: Color.fromRGBO(105, 73, 255, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
