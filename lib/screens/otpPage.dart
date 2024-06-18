import "dart:async";
import "dart:math";

import "package:eureka_app/screens/homeScreen.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:google_fonts/google_fonts.dart";
import "package:shared_preferences/shared_preferences.dart";
import '../apis/authApi.dart';



class OtpPage extends StatefulWidget {
  String verificationId;
  String phoneNumber;
  OtpPage({super.key,   required this.verificationId, required this.phoneNumber});  // FOR PRODUCTION 
  // OtpPage({super.key, this.verificationId = "", this.phoneNumber = ""}); // FOR DEVELOPMENT  because here we giving a default verificationId and phoneNumber 
  

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpControllers = List<TextEditingController>.generate(6,(index) => TextEditingController());
  final _focusNodes = List<FocusNode>.generate(6,(index) => FocusNode());
  String _errorMessage = "";
  int _resendTimer = 60;
  late Timer _timer;

  @override 
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpControllers.forEach((controller) => controller.dispose());
    _focusNodes.forEach((FocusNode) => FocusNode.dispose());
    _timer.cancel(); 
    super.dispose();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (timer) {
        setState(() {
          if (_resendTimer < 1) {
            timer.cancel();
          } else {
            _resendTimer--;
          }
        });
      }
    );
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      _setErrorMessage("Please enter all 6 digits of the OTP");
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, 
        smsCode: _otpCode,
        );
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        await getIdTokenAndSendToBackend();
        Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
    } catch(ex) {
      if (ex is FirebaseAuthException) {
        switch (ex.code) {
          case 'invalid-verification-code':
            _setErrorMessage("The OTP you entered is incorrect. Please try again.");
            break;
          case 'session-expired':
            _setErrorMessage("The OTP session has expired. Please request a new OTP");
            break;
          default:
            _setErrorMessage("An error occured. Please try again.");
        }
        } else {
          _setErrorMessage("An unexpected error occured. Please try again.");
      }
    }
  }

  Future<void> getIdTokenAndSendToBackend() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      String? idToken = await user.getIdToken();
      if (idToken != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('idToken', idToken);
        await sendIdTokenToBackend();
        await printStoredValues();
      } else {
        print("Failed to get ID token: idToken is null");
      }
      // Send token to your backend via HTTPS
    } catch (e) {
      // Handle error - could not get ID token
      print("Failed to get ID token: $e");
    }
  }
  }

  Future<void> printStoredValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? newUser = prefs.getBool('newUser');
    String? token = prefs.getString('token');
    bool? isSuccess = prefs.getBool('isSuccess');

    print("newUser: $newUser");
    print("token: $token");
    print("isSuccess: $isSuccess");
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
      print("Error: $ex");
      setState(() {
        _errorMessage = ex.toString();
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          
          margin: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 24,),
              Text(
                "You've got OTP 💌",
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  color: Color.fromRGBO(33, 33, 33, 1),
                  fontWeight: FontWeight.w700,
                  )
              ),
              Text(
                "We have sent the OTP verification code to your Mobile. Check your messages and enter the code below.",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  color: Color.fromRGBO(33, 33, 33, 1),
                  fontWeight: FontWeight.w400,
                ),
              ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      )
                    ),
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: Color.fromRGBO(33, 33, 33, 1),
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          FocusScope.of(context).nextFocus();
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      } else if (index> 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    },
                  )
                );
              }),
            ),
            if (_errorMessage.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: _resendTimer == 0 ? _resendOtp : null,
              child: Text(
                "Didn't Receive OTP?",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  color: _resendTimer == 0 ? Color.fromRGBO(105, 73, 255, 1) : Color.fromRGBO(33, 33, 33, 1)
                )
              )
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "You can resend code in ",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: Color.fromRGBO(33, 33, 33, 1),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: "$_resendTimer s",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: Color.fromRGBO(105, 73, 255, 1),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              )
            )
            ],
          ),
        ),
      ),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 58,
          width: MediaQuery.of(context).size.width-48,
          child: FloatingActionButton.extended(
            onPressed: _verifyOtp, 
            label: Text(
              "Confirm",
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700
              ),
            ),
            foregroundColor: Colors.white,
            backgroundColor: Color.fromRGBO(105, 73, 255, 1),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}