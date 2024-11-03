import "dart:async";
import "dart:math";
import "package:eureka_app/apis/authApi.dart";
import "package:eureka_app/screens/ncertPodcasts/classSelection.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:google_fonts/google_fonts.dart";
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpPage extends StatefulWidget {
  String verificationId;
  String phoneNumber;
  OtpPage({super.key, required this.verificationId, required this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();

  String _errorMessage = "";
  int _resendTimer = 60;
  late Timer _timer;
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      setState(() {
        if (_resendTimer < 1) {
          timer.cancel();
        } else {
          _resendTimer--;
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 6) {
      setState(() {
        _errorMessage = "Please enter all 6 digits of the OTP";
      });
      return;
    }

    setState(() {
      _isLoading = true; // Start loading state when OTP verification begins
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await getIdTokenAndSendToBackend();
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => ClassSelectionPage()));
    } catch (ex) {
      setState(() {
        _isLoading = false; // Stop loading if there's an error
      });

      if (ex is FirebaseAuthException) {
        switch (ex.code) {
          case 'invalid-verification-code':
            _setErrorMessage(
                "The OTP you entered is incorrect. Please try again.");
            break;
          case 'session-expired':
            _setErrorMessage(
                "The OTP session has expired. Please request a new OTP");
            break;
          default:
            _setErrorMessage("An error occurred. Please try again.");
        }
      } else {
        _setErrorMessage("An unexpected error occurred. Please try again.");
      }
    }
  }

  Future<void> getIdTokenAndSendToBackend() async {
    User? user = FirebaseAuth.instance.currentUser;
    final secureStorage = FlutterSecureStorage();
    if (user != null) {
      try {
        String? idToken = await user.getIdToken();
        if (idToken != null) {
          await secureStorage.write(key: "IdToken", value: idToken);
          // Send token to the backend...
          await sendIdTokenToBackend();
        }
      } catch (e) {
        print("Failed to get ID token: $e");
      }
    }
  }

  void _setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _resendOtp() async {
    if (_resendTimer > 0) return;
    final phone_Number = widget.phoneNumber;
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phone_Number",
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException ex) {
          setState(() {
            _errorMessage = ex.message ?? "Verification failed";
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            widget.verificationId = verificationId;
            _resendTimer = 60;
            _startTimer();
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (ex) {
      setState(() {
        _errorMessage = ex.toString();
      });
    }
  }

  Future<UserCredential> signInWithGoogle() async {
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
        final secureStorage = FlutterSecureStorage();

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back button color to white
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height, // Full screen height
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Verification Code",
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We have sent the verification code to ${widget.phoneNumber}",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(6)],
                        decoration: InputDecoration(
                          labelText: "Enter OTP",
                          labelStyle: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                          contentPadding: const EdgeInsets.only(
                              left: 20, top: 16, bottom: 16),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.orange,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.orange,
                              width: 2,
                            ),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _errorMessage = "";
                          });
                        },
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator(
                              color: Colors.orange,
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromRGBO(255, 217, 0, 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    ),
                                    child: Text(
                                      "Confirm",
                                      style: GoogleFonts.nunito(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
            // Spacer to push content up
            // Spacer(),
            // Google Sign-In option
            Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Add this for left alignment

                children: [
                  Text(
                    "Not able to get OTP?",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
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
                      side: BorderSide(color: Color.fromRGBO(128, 128, 128, 1)),
                      minimumSize: const Size(double.infinity, 50),
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
                          width: 24,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
