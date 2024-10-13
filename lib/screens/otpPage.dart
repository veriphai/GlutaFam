import "dart:async";
import "dart:math";
import "package:eureka_app/screens/ncertPodcasts/classSelection.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:google_fonts/google_fonts.dart";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 100),
              // Heading
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Verification Code",
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "We have sent the verification code to ${widget.phoneNumber}",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 100),
              // Image in the center
              Center(
                child: Image.asset(
                  'lib/assets/signup.png', // Replace with your image asset
                  width: 300,
                  height: 300,
                ),
              ),
              const SizedBox(height: 100),
              // OTP Input Field
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
                  contentPadding:
                      const EdgeInsets.only(left: 20, top: 16, bottom: 16),
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
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 32),
              // Display loading spinner if OTP is being verified
              _isLoading
                  ? CircularProgressIndicator(
                      color: Colors.orange, // Spinner color
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
                                : _verifyOtp, // Disable button during loading
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(
                                  255, 217, 0, 1), // Button color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: Text(
                              "Confirm",
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
            ],
          ),
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
