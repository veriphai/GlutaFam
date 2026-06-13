// PhoneLinkScreen — shown after a Google/Apple login when the embedded
// LoginResponse.profile.phoneVerified is false. Collects a phone number and
// saves it on the HowwowUser server-side via /howwow/auth/phone.
//
// TEMP: real Firebase OTP verification is disabled here while we sort out
// web reCAPTCHA + the tuto-era account-merge edge case. We just trust the
// number the user types, persist it, and move on. The full OTP + link
// implementation is kept at the bottom of this file inside a /* ... */
// block so it can be re-enabled by swapping the active method body for
// the preserved one (and re-adding the firebase_auth import).
//
// On success: navigates with [onSuccess] when supplied; otherwise routes by
// [newUser] — first-timers continue into OnboardingFlow (name → age group →
// interests), returning users land on the '/home' named route.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../apis/apiClient.dart';
import '../../apis/howwow/howwowAuth.dart';
import '../../apis/howwow/howwowSession.dart';
import '../../utils/authTokenService.dart';
import '../../utils/howwowEventLogger.dart';
import '../../utils/howwowEventNames.dart';
import '../home/career/careerCommon.dart';
import '../home/career/careerTheme.dart';
import '../home/career/cosmicBackground.dart';
import 'howwowLoginScreen.dart';
import 'onboarding/onboardingFlow.dart';

// ── resume-on-relaunch flag ─────────────────────────────────────────────
//
// AuthGate reads this on cold start: if a JWT is present AND this flag
// is true, it routes back to PhoneLinkScreen instead of slipping the
// user into the career home. Mirrors {@link OnboardingPending} so the
// auth flow is fully resume-able from any point.
//
// Lifecycle:
//   • mark()  — called from PhoneLinkScreen.initState the moment the
//               screen mounts (also from HowwowLoginScreen._routeAfter
//               Login as a belt-and-braces guard so the flag is set
//               BEFORE PhoneLinkScreen ever paints, eliminating the
//               race where the user kills the app between push and
//               first frame).
//   • clear() — called on _savePhone success (we have a phone now) and
//               on _onBackPressed (user abandoned, auth token cleared).
//               Also on howwowLogout() so a re-login doesn't inherit a
//               stale pending flag.
class PhoneCollectionPending {
  PhoneCollectionPending._();
  static const _key = 'howwowPhonePending';
  static const _keyNewUser = 'howwowPhonePendingNewUser';

  static Future<void> mark({required bool newUser}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await prefs.setBool(_keyNewUser, newUser);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_keyNewUser);
  }

  static Future<bool> isPending() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  static Future<bool> wasNewUser() async =>
      (await SharedPreferences.getInstance()).getBool(_keyNewUser) ?? false;
}

class PhoneLinkScreen extends StatefulWidget {
  const PhoneLinkScreen({super.key, this.onSuccess, this.newUser = false});

  /// What to do after the phone is saved + backend acknowledged.
  /// When null, routes by [newUser] (OnboardingFlow vs '/home').
  final VoidCallback? onSuccess;

  /// Whether this sign-in created a brand-new account (LoginResponse.newUser).
  /// New users continue from here into the onboarding flow — the name screen
  /// comes right after the phone number, per the signup design.
  final bool newUser;

  @override
  State<PhoneLinkScreen> createState() => _PhoneLinkScreenState();
}

class _PhoneLinkScreenState extends State<PhoneLinkScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneTextController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _phoneNumber = ''; // E.164, set by InternationalPhoneNumberInput
  bool _isLoading = false;
  String _errorMessage = '';
  bool _focused = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
    _intro.forward();
    // Persist a "phone collection still in progress" marker so a cold
    // restart (kill + relaunch) resumes here instead of slipping into
    // the career home. Cleared on success / abandon / logout.
    // ignore: discarded_futures
    PhoneCollectionPending.mark(newUser: widget.newUser);
  }

  @override
  void dispose() {
    _phoneTextController.dispose();
    _focusNode.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareerColors.bgMid,
      // resizeToAvoidBottomInset: true is the default and is what we want:
      // when the keyboard opens we let the column scroll up so the CTA
      // stays reachable.
      body: Stack(
        children: [
          const Positioned.fill(child: CosmicBackground()),
          SafeArea(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(_intro.value);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 16),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical -
                        MediaQuery.of(context).viewInsets.bottom -
                        32,
                  ),
                  child: IntrinsicHeight(child: _content()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── content tree ─────────────────────────────────────────────────────

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(),
        const SizedBox(height: 32),
        _heading(),
        const SizedBox(height: 12),
        _subheading(),
        const SizedBox(height: 28),
        _phoneInputCard(),
        const SizedBox(height: 12),
        _errorText(),
        const SizedBox(height: 18),
        _privacyChip(),
        const Spacer(),
        const SizedBox(height: 18),
        _ctaButton(),
        const SizedBox(height: 12),
        _footerMicrocopy(),
      ],
    );
  }

  // ── top bar (custom, so we can theme cleanly) ─────────────────────────

  Widget _topBar() {
    return Row(
      children: [
        PressableScale(
          onTap: _onBackPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CareerColors.glassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CareerColors.glassBorder),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  /// PhoneLinkScreen is pushed via `pushAndRemoveUntil((route) => false)`
  /// from the login screen — there's no route below us, so a plain
  /// `Navigator.maybePop()` is a no-op and the back button looks broken.
  ///
  /// Treat "back" as "I want to start sign-up over": clear the in-flight
  /// auth token + cached profile so the next /howwow/* call doesn't go
  /// out as an authenticated half-onboarded user, then route to the
  /// login screen as the new root. Returning users can re-sign-in and
  /// land back here; users who picked the wrong account can swap.
  Future<void> _onBackPressed() async {
    try {
      await AuthTokenService().setAuthToken('');
    } catch (_) {
      // Token-clear failure isn't a blocker for navigation.
    }
    HowwowSession.instance.setProfile(null);
    HowwowEventLogger.instance.setUserId(null);
    // User abandoned phone collection — clear the resume flag so a cold
    // restart doesn't bounce them back here. They'll see the login
    // screen instead, which matches what the back gesture intends.
    await PhoneCollectionPending.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HowwowLoginScreen()),
      (route) => false,
    );
  }

  // ── hero ─────────────────────────────────────────────────────────────

  Widget _heading() {
    return Text(
      'Add your number',
      style: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.05,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _subheading() {
    return Text(
      "Just one quick step to lock in your account.\nWe'll use it to keep your progress safe.",
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.72),
        height: 1.45,
      ),
    );
  }

  // ── phone input ──────────────────────────────────────────────────────

  Widget _phoneInputCard() {
    // Accent border + soft outer glow when the field has focus — gives
    // the input a "this is the active thing" affordance without being
    // visually loud.
    final accent = CareerColors.gold;
    final border = _focused
        ? accent.withValues(alpha: 0.65)
        : CareerColors.glassBorder;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: CareerColors.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: _focused ? 1.4 : 1),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InternationalPhoneNumberInput(
        onInputChanged: (PhoneNumber number) {
          _phoneNumber = number.phoneNumber ?? '';
        },
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.DIALOG,
          showFlags: true,
          setSelectorButtonAsPrefixIcon: false,
        ),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.disabled,
        initialValue: PhoneNumber(isoCode: 'IN'),
        textFieldController: _phoneTextController,
        focusNode: _focusNode,
        formatInput: false,
        spaceBetweenSelectorAndTextField: 8,
        keyboardType:
            const TextInputType.numberWithOptions(signed: true, decimal: true),
        inputDecoration: InputDecoration(
          hintText: 'Phone number',
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.42),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        selectorTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        textStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── privacy chip ─────────────────────────────────────────────────────

  Widget _privacyChip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: CareerColors.glassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CareerColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded,
              size: 14, color: CareerColors.cyan),
          const SizedBox(width: 8),
          Text(
            'Private. Never shared.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorText() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 16, color: Color(0xFFFF6E7A)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _errorMessage,
            style: GoogleFonts.poppins(
              color: const Color(0xFFFF6E7A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── CTA ──────────────────────────────────────────────────────────────

  Widget _ctaButton() {
    final disabled = _isLoading;
    return PressableScale(
      onTap: disabled ? null : _savePhone,
      pressedScale: 0.97,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.85 : 1.0,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD976), Color(0xFFFFB42E)],
            ),
            // Rounded rectangle, not a pill — consistent CTA shape
            // across the auth flow.
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CareerColors.gold.withValues(alpha: 0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CareerColors.onLight,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        // Toned down from 19 / w800 to match the login
                        // screen's calmer auth-button label.
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: CareerColors.onLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 20, color: CareerColors.onLight),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _footerMicrocopy() {
    return Center(
      child: Text(
        'By continuing you agree to our Terms and Privacy.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  // ── flow ───────────────────────────────────────────────────────────

  /// TEMP no-verification path: POST the typed number straight to the backend
  /// which persists it on the HowwowUser and flips phoneVerified=true. No
  /// SMS, no reCAPTCHA, no Firebase account linking.
  Future<void> _savePhone() async {
    if (_phoneNumber.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }
    HowwowEventLogger.instance.log(HowwowEvents.phoneCollectionSubmitted);
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    try {
      await howwowSetPhone(phoneNumber: _phoneNumber);
      // Phone collection complete — clear the resume marker BEFORE
      // navigating so a kill mid-onboarding doesn't bounce the user
      // back here on the next launch.
      await PhoneCollectionPending.clear();
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else if (widget.newUser) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingFlow()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  String _friendlyError(Object e) {
    if (e is ApiException) {
      return e.message ?? 'Could not save your number';
    }
    return 'Something went wrong. Please try again.';
  }
}


// ───────────────────────────────────────────────────────────────────────
// PRESERVED OTP IMPLEMENTATION — kept verbatim for easy re-enable.
//
// To re-enable real Firebase phone verification:
//   1. Add `import 'package:firebase_auth/firebase_auth.dart';` at the top.
//   2. Replace `_savePhone()` above with the OTP flow below (and restore
//      the two-phase UI with `_Phase`, `_otpController`, `_verificationId`,
//      `_buildOtpEntry`, `_sendOtp`, `_verifyOtp`, `_linkAndVerify`).
//   3. Swap the backend call from `howwowSetPhone(...)` to
//      `howwowVerifyPhone(phoneNumber: ..., firebaseIdToken: ...)`.
//
// /*
// enum _Phase { enterPhone, verifyOtp }
//
// // STATE additions:
// //   _Phase _phase = _Phase.enterPhone;
// //   final TextEditingController _otpController = TextEditingController();
// //   String? _verificationId;
//
// // UI: _buildOtpEntry renders the 6-digit code field + "Verify" CTA.
//
// Future<void> _sendOtp() async {
//   if (_phoneNumber.length < 10) {
//     setState(() => _errorMessage = 'Please enter a valid phone number');
//     return;
//   }
//   setState(() { _errorMessage = ''; _isLoading = true; });
//   try {
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: _phoneNumber,
//       verificationCompleted: (credential) async {
//         await _linkAndVerify(credential);
//       },
//       verificationFailed: (ex) {
//         setState(() {
//           _errorMessage = ex.message ?? 'Verification failed';
//           _isLoading = false;
//         });
//       },
//       codeSent: (verificationId, _) {
//         setState(() {
//           _verificationId = verificationId;
//           _phase = _Phase.verifyOtp;
//           _isLoading = false;
//         });
//       },
//       codeAutoRetrievalTimeout: (_) {},
//     );
//   } catch (e) {
//     setState(() {
//       _errorMessage = 'Could not send the code: $e';
//       _isLoading = false;
//     });
//   }
// }
//
// Future<void> _verifyOtp() async {
//   if (_otpController.text.length < 6 || _verificationId == null) {
//     setState(() => _errorMessage = 'Please enter all 6 digits');
//     return;
//   }
//   setState(() { _errorMessage = ''; _isLoading = true; });
//   try {
//     final credential = PhoneAuthProvider.credential(
//       verificationId: _verificationId!,
//       smsCode: _otpController.text,
//     );
//     await _linkAndVerify(credential);
//   } catch (e) {
//     if (!mounted) return;
//     setState(() {
//       _errorMessage = _friendlyError(e);
//       _isLoading = false;
//     });
//   }
// }
//
// // Link the verified phone credential to the already-signed-in Firebase
// // user. Handles the credential-already-in-use case by deleting the just-
// // created Google Firebase user and switching the active session to the
// // existing phone-owned user via signInWithCredential.
// Future<void> _linkAndVerify(PhoneAuthCredential credential) async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) {
//     throw StateError('No Firebase user is signed in — cannot link phone.');
//   }
//   UserCredential result;
//   bool merged = false;
//   try {
//     result = await user.linkWithCredential(credential);
//   } on FirebaseAuthException catch (e) {
//     if (e.code == 'credential-already-in-use') {
//       merged = true;
//       try { await user.delete(); } catch (_) {}
//       result = await FirebaseAuth.instance.signInWithCredential(credential);
//     } else {
//       rethrow;
//     }
//   }
//   final idToken = await result.user!.getIdToken(true);
//   if (idToken == null || idToken.isEmpty) {
//     throw StateError('Failed to retrieve a refreshed Firebase ID token.');
//   }
//   if (merged) {
//     await howwowLogin(idToken: idToken);
//   } else {
//     await howwowVerifyPhone(phoneNumber: _phoneNumber, firebaseIdToken: idToken);
//   }
//   if (!mounted) return;
//   if (widget.onSuccess != null) {
//     widget.onSuccess!();
//   } else {
//     Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
//   }
// }
// */
