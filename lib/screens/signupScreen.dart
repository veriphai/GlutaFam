import 'package:eureka_app/events/onboardingAndLoginEvents.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import "package:flutter/material.dart";
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import 'otpPage.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart'; // Import the package

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
  String initialCountry = 'IN'; // Default to India
  PhoneNumber number = PhoneNumber(isoCode: 'IN'); // Default country code

  @override
  void initState() {
    super.initState();
    _initializeFirebase();

    logPhoneAuthScreenEvents();
  }

  void logPhoneAuthScreenEvents() async {
    Map<String, String> deviceDetails = await getDeviceDetails();
    String deviceId = deviceDetails['deviceId'] ?? "Unknown";
    String platform = deviceDetails['platform'] ?? "Unknown";
    String userIP = await getUserIP();

    logPhoneLoginScreenView(deviceId, platform, userIP);
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _verifyPhoneNumber() async {
    if (_phoneNumber.length < 10) {
      setState(() {
        _errorMessage = "Please enter a valid phone number";
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

    Map<String, String> deviceDetails = await getDeviceDetails();
    String deviceId = deviceDetails['deviceId'] ?? "Unknown";
    String platform = deviceDetails['platform'] ?? "Unknown";
    logContinueButtonClickForOtp(deviceId, platform, _phoneNumber);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneNumber, // Now includes country code
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
                  style: GoogleFonts.raleway(
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
                  style: GoogleFonts.raleway(
                    fontSize: 22,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Phone Number Input with Flag Selector
              Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Column(children: [
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      setState(() {
                        _phoneNumber = number.phoneNumber!;
                      });
                    },
                    onInputValidated: (bool value) {
                      print(value);
                    },
                    selectorConfig: SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      leadingPadding:
                          10, // Reduce padding between flag and input
                      useEmoji: true,
                      setSelectorButtonAsPrefixIcon:
                          true, // Align flag to the left
                      trailingSpace: false, // Minimize space after country code
                      showFlags: true, // Show flags only
                    ),
                    initialValue: number,
                    textFieldController: _controller,
                    inputDecoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: GoogleFonts.raleway(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding:
                          EdgeInsets.only(left: 20, top: 16, bottom: 16),
                      hintText: "Enter Phone Number",
                      hintStyle: GoogleFonts.raleway(color: Colors.grey[600]),
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
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    formatInput: false,
                    maxLength: 15,
                    keyboardType: TextInputType.numberWithOptions(
                        signed: true, decimal: true),
                    textStyle: GoogleFonts.raleway(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage,
                          style: GoogleFonts.raleway(
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
                                onPressed:
                                    _isLoading ? null : _verifyPhoneNumber,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromRGBO(255, 217, 0, 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: Text(
                                  "Continue",
                                  style: GoogleFonts.raleway(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
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
