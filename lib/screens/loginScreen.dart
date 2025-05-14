import 'package:eureka_app/events/onboardingAndLoginEvents.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/screens/onboardingScreenV4.dart';
import 'package:eureka_app/screens/signupscreen.dart'; // Import the signup screen
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final secureStorage = FlutterSecureStorage();
  final AuthTokenService authTokenService = AuthTokenService();
  bool _isLoading = false; // Loading state
  String deviceId = "";
  String platform = "";
  String userIP = "";
  bool newUser = true;

  @override
  void initState() {
    super.initState();
    logLoginScreenOpen();
  }

  void logLoginScreenOpen() async {
    Map<String, String> deviceDetails = await getDeviceDetails();
    deviceId = deviceDetails['deviceId'] ?? "Unknown";
    platform = deviceDetails['platform'] ?? "Unknown";
    userIP = await getUserIP();

    logLoginScreenView(deviceId, platform, userIP);
  }

  Future<UserCredential> signInWithGoogle() async {
    logGoogleAuthButtonClick(deviceId, platform, userIP);
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

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
    const url = 'https://glutaclass.com:8080/gluta/fam/add-profile';

    try {
      // Make the POST request with the Authorization header
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": uid,
          "nameFromEmail": name,
          "emailId": emailId,
          "profilePic": photoUrl
        }),
      );

      if (response.statusCode == 200) {
        // If the API call is successful, navigate to the next screen
        Map<String, dynamic> data = json.decode(response.body);
        print("Auth api:$data");
        String authToken = data['token'];
        String userTrackingId = data['userTrackingId'];
        newUser = data['newUser'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userTrackingId', userTrackingId);
        await FirebaseAnalytics.instance.setUserId(id: userTrackingId);
        if (newUser) {
          FirebaseAnalytics.instance.logSignUp(signUpMethod: "gmail");
        } else {
          await prefs.setBool('appFirstLaunch', false);
          FirebaseAnalytics.instance.logLogin(loginMethod: "gmail");
        }
        await authTokenService.setAuthToken(authToken);

        // await secureStorage.write(key: "authKey", value: data['token']);
      } else {
        // Handle API errors
        print("Failed to save profile data: ${response.statusCode}");
      }
    } catch (e) {
      // Handle any errors during the HTTP request
      print("Error occurred while saving profile data: $e");
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
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
                  'lib/assets/tuto-logo.png',

                  // 'lib/assets/glutaclassLogo.png',
                  height: 120, // Adjust height as needed
                  width: 120, // Adjust width as needed
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                // Description Text
                Text(
                  "A Personalised AI Tutor",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "That Actually Understands You",
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
              color: Color.fromRGBO(
                  255, 217, 0, 1), // Optional: color of the spinner
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            child: !kIsWeb
                ? Column(
                    children: [
                      if (!kIsWeb)
                        OutlinedButton(
                          onPressed: () async {
                            logPhoneAuthButtonClick(deviceId, platform, userIP);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Signupscreen(
                                      deviceId: deviceId,
                                      platform: platform,
                                      userIP: userIP)),
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
                                width:
                                    24, // Placeholder space to match the icon size
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
                              print(user);
                              String? displayName = user.displayName;
                              String? email = user.email;
                              String? photoURL = user.photoURL;
                              String? uid = user.uid;
                              logGoogleAuthSuccess(
                                  uid, deviceId, platform, userIP);
                              await saveProfile(
                                  displayName, email, uid, photoURL);
                            }

                            if (newUser) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => OnboardingScreenV4(
                                          deviceId: deviceId,
                                          platform: platform,
                                          userIP: userIP)));
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MainPage()),
                                (Route<dynamic> route) => false,
                              );
                            }
                          } catch (error) {
                            print("Google Sign-In Failed: $error");
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Color.fromRGBO(
                                  128, 128, 128, 1)), // Border color
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
                              width:
                                  24, // Placeholder space to match the icon size
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MouseRegion(
                          cursor: SystemMouseCursors
                              .click, // Changes cursor to pointer (thumb)
                          child: GestureDetector(
                            onTap: () {
                              _launchURL(
                                  'https://play.google.com/store/apps/details?id=com.gluta.glutafam'); // Replace with your Play Store link
                            },
                            child: Image.asset(
                              'lib/assets/playStoreButton.png', // Path to your Play Store image
                              width: 150,
                              fit: BoxFit.contain,
                            ),
                          )),
                      const SizedBox(width: 20),
                      MouseRegion(
                          cursor: SystemMouseCursors
                              .click, // Changes cursor to pointer (thumb)
                          child: GestureDetector(
                            onTap: () {
                              _launchURL(
                                  'https://apps.apple.com/us/app/glutaclass-ai-tutor-for-ncert/id6736943726'); // Replace with your App Store link
                            },
                            child: Image.asset(
                              'lib/assets/appStoreButton.png', // Path to your App Store image
                              width: 150,
                              fit: BoxFit.contain,
                            ),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
