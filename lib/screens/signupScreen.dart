import "dart:ui";

import "package:eureka_app/screens/otpPage.dart";
import "package:flutter/material.dart";
import "package:flutter/painting.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:google_fonts/google_fonts.dart";
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';


class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final TextEditingController _controller = TextEditingController();
  String _phoneNumber = "";
  String _errorMessage= "";

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
      };

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$_phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential){}, 
      verificationFailed: (FirebaseAuthException ex){
        setState(() {
          _errorMessage = ex.message ?? "verfication failed";
        });
      }, 
      codeSent: (String verificationId, int? resendToken){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpPage(verificationId: verificationId, phoneNumber: _phoneNumber,)
          ),
        );
      }, 
      codeAutoRetrievalTimeout: (String verificationId){},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start, // Align at the top
          children: [

            Text(
              "Phone Number ☎️",
              style: GoogleFonts.nunito(
                fontSize: 32,
                color: Color.fromRGBO(33, 33, 33, 1),
                fontWeight: FontWeight.w700
              ),
            ),
            SizedBox(height:12),
            Text(
              "Enter your Phone Number to get an OTP code via a text message", // Add your desired text here
              style: GoogleFonts.nunito( // Customize style if needed
                fontSize: 18,
                color: Color.fromRGBO(33,33,33,1),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 32),
            Text(
              "Phone Number",
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Color.fromRGBO(33, 33, 33, 1),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                hintText: "Enter Phone Number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color.fromRGBO(33, 33, 33, 1),
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
              style: GoogleFonts.nunito(color: Colors.red, fontSize: 14)
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
          width: MediaQuery.of(context).size.width - 48, // total screen width - 48 so that "Continue" button dynamically changes according to the different screens
          child: FloatingActionButton.extended(
            onPressed: _verifyPhoneNumber,
            label: Text(
              "Continue"
            ),
            foregroundColor: Colors.white,
            backgroundColor: Color.fromRGBO(105, 73, 255, 1),
          )
        )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}



