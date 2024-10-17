import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import 'otpPage.dart';
import 'package:flutter/services.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final TextEditingController _controller = TextEditingController();
  String _phoneNumber = "";
  String _errorMessage = "";
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _verifyPhoneNumber() async {
    if (_phoneNumber.length != 10) {
      setState(() {
        _errorMessage = "Phone Number should be of 10 digits";
      });
      return;
    } else {
      setState(() {
        _errorMessage = "";
      });
    }

    setState(() {
      _isLoading = true; // Start loading when OTP is being sent
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$_phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) {
        setState(() {
          _isLoading = false; // Stop loading on verification complete
        });
      },
      verificationFailed: (FirebaseAuthException ex) {
        setState(() {
          _errorMessage = ex.message ?? "Verification failed";
          _isLoading = false; // Stop loading if verification fails
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false; // Stop loading once code is sent
        });
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OtpPage(
                    verificationId: verificationId,
                    phoneNumber: _phoneNumber,
                  )),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isLoading = false; // Stop loading on timeout
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background to black
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: true,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.white, // Set the back button color to white
          )),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start, // Align at the top
            children: [
              const SizedBox(
                height: 10,
              ),
              // Top Text
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "OTP Verification",
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Enter phone number to send one-time password",
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Center Image
              // Center(
              //   child: Image.asset(
              //     'lib/assets/signup.png', // Add your image path here
              //     width: 300, // Adjust width accordingly
              //     height: 300, // Adjust height accordingly
              //   ),
              // ),
              // const SizedBox(height: 60),
              // Phone Number Input
              Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Column(children: [
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Ensures only digits are entered
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: "Phone Number", // Floating label text
                      labelStyle: TextStyle(
                        color: Colors.orange, // Label color
                        fontWeight: FontWeight.bold,
                      ),
                      contentPadding:
                          EdgeInsets.only(left: 20, top: 16, bottom: 16),
                      hintText: "Enter Phone Number",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.orange,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.orange,
                          width: 2,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior
                          .always, // Label floats automatically
                    ),
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _phoneNumber = value;
                      });
                    },
                  ),

                  if (_errorMessage.isNotEmpty)
                    Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage,
                          style: GoogleFonts.nunito(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        )),
                  const SizedBox(height: 20),
                  // Show loading spinner if OTP is being sent
                  _isLoading
                      ? CircularProgressIndicator(
                          color:
                              Colors.orange, // Optional: color of the spinner
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _verifyPhoneNumber, // Disable button while loading
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromRGBO(255, 217, 0, 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        100), // Circular button
                                  ),
                                ),
                                child: Text(
                                  "Continue",
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // Text color
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
