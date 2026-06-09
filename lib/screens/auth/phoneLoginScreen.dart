// PhoneLoginScreen — direct phone sign-in (not the post-Google "link a phone"
// flow; that's PhoneLinkScreen). Two phases:
//   1. Phone entry → FirebaseAuth.verifyPhoneNumber → SMS code.
//   2. OTP entry  → FirebaseAuth.signInWithCredential → howwowLogin().
//
// Phone-auth always lands the user with profile.phoneVerified == true (the
// backend reads the phone_number claim from the Firebase token and sets the
// flag), so on success we route by `newUser`: first sign-in → OnboardingFlow
// (name → age group → interests), returning user → CareerHomeScreen.

import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../apis/apiClient.dart';
import '../../apis/howwow/howwowAuth.dart';
import '../../utils/howwowEventLogger.dart';
import '../../utils/howwowEventNames.dart';
import '../home/career/careerCommon.dart';
import '../home/career/careerHomeScreen.dart';
import '../home/career/careerTheme.dart';
import '../home/career/cosmicBackground.dart';
import 'onboarding/onboardingFlow.dart';

enum _Phase { enterPhone, verifyOtp }

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.enterPhone;
  final TextEditingController _phoneTextController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final ValueNotifier<String> _otpValue = ValueNotifier<String>('');

  String _phoneNumber = '';
  String? _verificationId;
  bool _isLoading = false;
  bool _phoneFocused = false;
  String _errorMessage = '';

  // Resend-code countdown — visual + functional gate on hammering Firebase.
  static const int _resendSeconds = 30;
  int _resendIn = 0;
  Timer? _resendTimer;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      if (mounted) setState(() => _phoneFocused = _phoneFocusNode.hasFocus);
    });
    _intro.forward();
  }

  @override
  void dispose() {
    _phoneTextController.dispose();
    _phoneFocusNode.dispose();
    _otpValue.dispose();
    _intro.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareerColors.bgMid,
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
                  child: IntrinsicHeight(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) {
                        // Cross-fade + slight horizontal slide so phase
                        // changes feel mechanical, not jumpy.
                        final slide = Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(anim);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _phase == _Phase.enterPhone
                          ? _phoneEntry(key: const ValueKey('phone'))
                          : _otpEntry(key: const ValueKey('otp')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── top bar ──────────────────────────────────────────────────────────

  Widget _topBar({required VoidCallback onBack}) {
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
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

  // ── PHASE 1 — phone entry ────────────────────────────────────────────

  Widget _phoneEntry({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(onBack: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 28),
        const Center(child: _AuthHero(icon: Icons.phone_iphone_rounded)),
        const SizedBox(height: 28),
        _heading('Sign in with phone'),
        const SizedBox(height: 12),
        _subheading("We'll text you a 6-digit code to verify your number."),
        const SizedBox(height: 28),
        _phoneInputCard(),
        const SizedBox(height: 14),
        if (_errorMessage.isNotEmpty) ...[
          _errorRow(),
          const SizedBox(height: 14),
        ],
        _privacyChip(text: 'Encrypted. Never shared.'),
        const Spacer(),
        const SizedBox(height: 18),
        _ctaButton(
          label: 'Send OTP',
          onTap: _isLoading ? null : _sendOtp,
          icon: Icons.send_rounded,
        ),
        const SizedBox(height: 12),
        _legalLine(),
      ],
    );
  }

  Widget _phoneInputCard() {
    final accent = CareerColors.gold;
    final border = _phoneFocused
        ? accent.withValues(alpha: 0.65)
        : CareerColors.glassBorder;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: CareerColors.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: _phoneFocused ? 1.4 : 1),
        boxShadow: _phoneFocused
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
        focusNode: _phoneFocusNode,
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

  // ── PHASE 2 — OTP entry ──────────────────────────────────────────────

  Widget _otpEntry({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(onBack: () {
          // Back from OTP → go back to phone entry. Less destructive than
          // popping the whole screen — user has the number entered.
          _resendTimer?.cancel();
          setState(() {
            _phase = _Phase.enterPhone;
            _errorMessage = '';
            _otpValue.value = '';
          });
        }),
        const SizedBox(height: 28),
        const Center(child: _AuthHero(icon: Icons.message_rounded)),
        const SizedBox(height: 28),
        _heading('Enter code'),
        const SizedBox(height: 12),
        _subheadingRich(
          prefix: 'We sent a 6-digit code to ',
          highlight: _phoneNumber,
        ),
        const SizedBox(height: 28),
        _OtpBoxes(
          value: _otpValue,
          onChanged: (v) {
            // Hide any stale error as the user starts typing again.
            if (_errorMessage.isNotEmpty) {
              setState(() => _errorMessage = '');
            }
            // Auto-submit on 6-digit completion.
            if (v.length == 6 && !_isLoading) _verifyOtp();
          },
        ),
        const SizedBox(height: 14),
        if (_errorMessage.isNotEmpty) ...[
          _errorRow(),
          const SizedBox(height: 14),
        ],
        _resendRow(),
        const Spacer(),
        const SizedBox(height: 18),
        _ctaButton(
          label: 'Verify & sign in',
          onTap: _isLoading ? null : _verifyOtp,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _phase = _Phase.enterPhone;
                      _otpValue.value = '';
                      _errorMessage = '';
                    }),
            child: Text(
              'Change phone number',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resendRow() {
    final disabled = _resendIn > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Didn't get the code?",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
        TextButton(
          onPressed: disabled ? null : _sendOtp,
          style: TextButton.styleFrom(
            minimumSize: const Size(60, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            disabled ? 'Resend in ${_resendIn}s' : 'Resend code',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: disabled
                  ? Colors.white.withValues(alpha: 0.42)
                  : CareerColors.gold,
            ),
          ),
        ),
      ],
    );
  }

  // ── shared bits ──────────────────────────────────────────────────────

  Widget _heading(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.05,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _subheading(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.72),
        height: 1.45,
      ),
    );
  }

  Widget _subheadingRich({required String prefix, required String highlight}) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.72),
          height: 1.45,
        ),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: highlight,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyChip({required String text}) {
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
          const Icon(Icons.lock_rounded, size: 14, color: CareerColors.cyan),
          const SizedBox(width: 8),
          Text(
            text,
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

  Widget _errorRow() {
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

  Widget _ctaButton({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    final disabled = onTap == null;
    return PressableScale(
      onTap: onTap,
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
            // Rounded rectangle (was a pill) so CTA shape stays
            // consistent across the whole auth flow.
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(CareerColors.onLight),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        // 16 → 19 (~+19%).
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: CareerColors.onLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 20, color: CareerColors.onLight),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _legalLine() {
    return Center(
      child: Text(
        'By continuing you agree to our Terms & Privacy.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  // ── resend countdown ────────────────────────────────────────────────

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendIn -= 1;
        if (_resendIn <= 0) {
          _resendIn = 0;
          t.cancel();
        }
      });
    });
  }

  // ── flow ───────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (_phoneNumber.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }
    HowwowEventLogger.instance.log(
      HowwowEvents.loginAttempted,
      props: {'provider': 'phone'},
    );
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval path on some Androids.
          await _signInAndCallBackend(credential);
        },
        verificationFailed: (FirebaseAuthException ex) {
          setState(() {
            _errorMessage = ex.message ?? 'Verification failed';
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _phase = _Phase.verifyOtp;
            _isLoading = false;
          });
          _startResendCountdown();
        },
        codeAutoRetrievalTimeout: (String _) {},
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not send the code: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.value.length < 6 || _verificationId == null) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpValue.value,
      );
      await _signInAndCallBackend(credential);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  /// Sign in to Firebase with the phone credential (no linking — this is a
  /// fresh sign-in), pull the new ID token, hand it to /howwow/auth/login.
  ///
  /// First-ever sign-in (`newUser`) detours through the onboarding flow
  /// (name → age group → interests) before landing on home.
  Future<void> _signInAndCallBackend(PhoneAuthCredential credential) async {
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Failed to retrieve Firebase ID token after phone sign-in.');
    }
    final response = await howwowLogin(idToken: idToken, provider: 'phone');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => response.newUser
            ? const OnboardingFlow()
            : const CareerHomeScreen(),
      ),
      (route) => false,
    );
  }

  String _friendlyError(Object e) {
    if (e is ApiException) return e.message ?? 'Login failed';
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-verification-code':
          return 'That code was incorrect. Please try again.';
        case 'session-expired':
          return 'The code expired. Please request a new one.';
        default:
          return e.message ?? 'Verification failed';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Hero badge — gold-gradient hex with the supplied glyph at the centre.
// Identical structure to PhoneLinkScreen's hero so the auth surface
// reads as a family of related steps.
// ─────────────────────────────────────────────────────────────────────

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.icon});
  final IconData icon;

  static const _size = 108.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size + 40,
      height: _size + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft glow halo.
          Container(
            width: _size + 36,
            height: _size + 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  CareerColors.gold.withValues(alpha: 0.22),
                  CareerColors.gold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Hex badge with glyph.
          SizedBox(
            width: _size,
            height: _size,
            child: CustomPaint(
              painter: _HexBadgePainter(),
              child: Center(
                child: Icon(icon, size: 46, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final r = w / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final x = cx + r * 0.96 * math.cos(angle);
      final y = cy + r * 0.96 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          CareerColors.gold,
          Color.lerp(CareerColors.gold, Colors.black, 0.55)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────
// OTP entry — six independent boxes with focus chaining, paste support,
// and a "filled" glow per cell. Joined value is exposed via a
// ValueNotifier so the parent can react without rebuilding the boxes.
// ─────────────────────────────────────────────────────────────────────

class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({required this.value, required this.onChanged});

  /// Two-way: the parent reads the joined OTP from here, and seeds /
  /// resets it (e.g. after the user changes their phone number).
  final ValueNotifier<String> value;

  /// Fired whenever the joined value changes — typed digit, backspace,
  /// paste, or programmatic reset.
  final ValueChanged<String> onChanged;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  static const _len = 6;
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_len, (_) => TextEditingController());
    _focusNodes = List.generate(_len, (_) => FocusNode());
    widget.value.addListener(_handleExternalReset);
    // Autofocus the first box once the screen is settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.value.removeListener(_handleExternalReset);
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// React to programmatic resets (e.g. parent cleared the value after
  /// the user tapped "Change phone number").
  void _handleExternalReset() {
    if (_joined() == widget.value.value) return;
    final v = widget.value.value;
    for (int i = 0; i < _len; i++) {
      _ctrls[i].text = i < v.length ? v[i] : '';
    }
    if (v.isEmpty && mounted) _focusNodes.first.requestFocus();
  }

  String _joined() => _ctrls.map((c) => c.text).join();

  void _onBoxChanged(int index, String raw) {
    // Handle paste: if the raw value has more than one char, distribute
    // across boxes starting from `index`.
    if (raw.length > 1) {
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < _len; i++) {
        final boxIdx = index + i;
        if (boxIdx >= _len) break;
        _ctrls[boxIdx].text = i < digits.length ? digits[i] : '';
      }
      final filledTo = (index + digits.length).clamp(0, _len);
      if (filledTo < _len) {
        _focusNodes[filledTo].requestFocus();
      } else {
        _focusNodes.last.unfocus();
      }
      _emitChange();
      return;
    }
    // Single char (typed): keep at most the last digit, advance focus.
    if (raw.isNotEmpty) {
      // Reject non-digits — the input formatter already strips them but
      // be defensive.
      final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
      _ctrls[index].text = clean.isEmpty ? '' : clean.substring(clean.length - 1);
      if (clean.isNotEmpty && index < _len - 1) {
        _focusNodes[index + 1].requestFocus();
      } else if (clean.isNotEmpty) {
        _focusNodes[index].unfocus();
      }
    }
    _emitChange();
  }

  void _onBoxKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      // Backspace on an already-empty box jumps back to the previous one
      // and clears it. Native iOS behaviour.
      if (_ctrls[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _ctrls[index - 1].text = '';
        _emitChange();
      }
    }
  }

  void _emitChange() {
    final v = _joined();
    if (widget.value.value != v) widget.value.value = v;
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < _len; i++) _box(i),
      ],
    );
  }

  Widget _box(int i) {
    final isFocused = _focusNodes[i].hasFocus;
    final isFilled = _ctrls[i].text.isNotEmpty;
    // Outer accent: focused > filled > idle. Glow only when focused.
    final accent = isFocused
        ? CareerColors.gold
        : (isFilled
            ? CareerColors.gold.withValues(alpha: 0.55)
            : CareerColors.glassBorder);
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 60,
          decoration: BoxDecoration(
            color: CareerColors.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent, width: isFocused ? 1.6 : 1.0),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: CareerColors.gold.withValues(alpha: 0.20),
                      blurRadius: 14,
                      spreadRadius: 0.4,
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (e) => _onBoxKey(i, e),
            child: TextField(
              controller: _ctrls[i],
              focusNode: _focusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              showCursor: true,
              cursorColor: CareerColors.gold,
              cursorHeight: 26,
              enableSuggestions: false,
              autocorrect: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
              onChanged: (v) {
                _onBoxChanged(i, v);
                // Touch state so the filled/focus accent re-evaluates.
                if (mounted) setState(() {});
              },
              onTap: () {
                if (mounted) setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
