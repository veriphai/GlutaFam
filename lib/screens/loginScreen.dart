import 'package:eureka_app/screens/ncertPodcasts/classSelection.dart';
import 'package:eureka_app/screens/signupscreen.dart'; // Import the signup screen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "package:flutter_secure_storage/flutter_secure_storage.dart";

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final secureStorage = FlutterSecureStorage();
  bool _isLoading = false; // Loading state

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
    clientId: "550557666388-63droq2fcbdbp6b0is1seudikinugev3.apps.googleusercontent.com",
  );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return Future.error("Google sign-in cancelled");
    }

    setState(() {
      _isLoading = true; // Show loader
    });

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> saveProfile(
      String? name, String? emailId, String? uid, String? photoUrl) async {
    // Retrieve the saved class and auth token

    // Check if authToken and selectedClass are valid
    // Prepare the API URL (replace with your actual backend URL)
    final url = 'https://glutaclass.com:8080/gluta/fam/add-profile';

    try {
      // Make the POST request with the Authorization header
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": uid,
          "firstName": name,
          "emailId": emailId,
          "profilePic": photoUrl
        }),
      );

      if (response.statusCode == 200) {
        // If the API call is successful, navigate to the next screen
        Map<String, dynamic> data = json.decode(response.body);
        print("Auth api:$data");

        await secureStorage.write(key: "authKey", value: data['token']);
      } else {
        // Handle API errors
        print("Failed to save profile data: ${response.statusCode}");
      }
    } catch (e) {
      // Handle any errors during the HTTP request
      print("Error occurred while saving profile data: $e");
    }
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
                // GlutaClass Icon
                Image.asset(
                  'lib/assets/glutaclassLogo.png', // Replace with your logo's path
                  height: 120, // Adjust height as needed
                  width: 120, // Adjust width as needed
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                // Description Text
                Text(
                  "Interest-led Audio Lessons",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "for Your Curriculum",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 28,
                    color: Color.fromRGBO(182, 182, 182, 1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )),
          )),
          if (_isLoading)
            CircularProgressIndicator(
              color: Colors.orange, // Optional: color of the spinner
            ),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Signupscreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Color.fromRGBO(128, 128, 128,
                              1)), // Border color // Border color
                      minimumSize:
                          const Size(double.infinity, 50), // Full width
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.smartphone_outlined,
                          color: Colors.white,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Continue with phone number',
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 24, // Placeholder space to match the icon size
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Google Sign-In Button
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        UserCredential userCredential =
                            await signInWithGoogle();
                        User? user = userCredential.user;

                        if (user != null) {
                          String? displayName = user.displayName;
                          String? email = user.email;
                          String? photoURL = user.photoURL;
                          String? uid = user.uid;
                          print(user);
                          print(uid);
                          saveProfile(displayName, email, uid, photoURL);
                        }

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ClassSelectionPage()));
                      } catch (error) {
                        print("Google Sign-In Failed: $error");
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color:
                              Color.fromRGBO(128, 128, 128, 1)), // Border color
                      minimumSize:
                          const Size(double.infinity, 50), // Full width
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'lib/assets/google_logo.png',
                          height: 24,
                          width: 24,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Continue with Google',
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 24, // Placeholder space to match the icon size
                        )
                      ],
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
