// HowwowLoginScreen — the entry point users see after AuthGate decides there
// is no stored appJwt. Offers three providers (Apple on iOS only, Google,
// Phone).
//
// Flow per provider:
//   1. Drive Firebase auth (signInWithCredential).
//   2. Pull the Firebase ID token.
//   3. POST it to /howwow/auth/login via howwowLogin(...).
//   4. Route by the embedded profile.phoneVerified + newUser:
//        phoneVerified false → PhoneLinkScreen (collect phone), which then
//                              continues into OnboardingFlow for new users
//        phoneVerified true  → OnboardingFlow if newUser, else CareerHomeScreen

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../apis/apiClient.dart';
import '../../utils/deeplink/howwowDeeplinkRouter.dart';
import '../../utils/howwowEventLogger.dart';
import '../../utils/howwowEventNames.dart';
import '../../apis/howwow/howwowAuth.dart';
import '../../models/howwow/authResponses.dart';
import '../home/career/careerCommon.dart';
import '../home/career/careerHomeScreen.dart';
import '../home/career/careerTheme.dart';
import '../home/career/cosmicBackground.dart';
import 'onboarding/onboardingFlow.dart';
import 'phoneLinkScreen.dart';
import 'widgets/magical_field.dart';
import 'phoneLoginScreen.dart';

class HowwowLoginScreen extends StatefulWidget {
  const HowwowLoginScreen({super.key});

  @override
  State<HowwowLoginScreen> createState() => _HowwowLoginScreenState();
}

class _HowwowLoginScreenState extends State<HowwowLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _errorMessage = '';

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

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
                    offset: Offset(0, (1 - t) * 18),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 4),
                    // Same shared `MagicalField` as the wow-first
                    // bridge — logo + halo + two clockwise orbits of
                    // curiosity glyphs — sized smaller (240 / 78) so
                    // the wordmark, tagline, and 3 auth buttons below
                    // it still breathe on a phone.
                    const Center(
                      child: MagicalField(size: 240, logoSize: 78),
                    ),
                    const SizedBox(height: 28),
                    _wordmark(),
                    const SizedBox(height: 10),
                    _tagline(),
                    const Spacer(flex: 5),
                    if (_errorMessage.isNotEmpty) ...[
                      _errorBanner(),
                      const SizedBox(height: 14),
                    ],
                    _authButtons(),
                    const SizedBox(height: 18),
                    _legalLine(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) _loadingOverlay(),
        ],
      ),
    );
  }

  // ── hero ───────────────────────────────────────────────────────────

  Widget _wordmark() {
    return ShaderMask(
      // Multi-stop horizontal sweep matching the "HowWow" brand
      // illustration: cyan → blue → purple → magenta → pink → orange.
      // Left-to-right sweep mirrors the reading direction so "how" lands
      // in the cool half (curiosity / question) and "wow" finishes in
      // the warm half (delight / discovery).
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4FB3D5), // cyan-teal
          Color(0xFF3F7FC6), // blue
          Color(0xFF7C4DFF), // purple
          Color(0xFFC942C8), // magenta
          Color(0xFFE54A5E), // pink-red
          Color(0xFFF8893A), // orange
        ],
        stops: [0.00, 0.18, 0.40, 0.62, 0.82, 1.00],
      ).createShader(rect),
      child: Text(
        'TheHowWow',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          // 'TheHowWow' is 9 chars vs 'howwow's 6, so the same 56 px
          // overflowed on a phone. Trimmed to 42 px + slightly less
          // negative tracking so the wordmark still feels weighty but
          // fits comfortably edge-to-edge.
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
          letterSpacing: -1.2,
        ),
      ),
    );
  }

  Widget _tagline() {
    // Mirrors the welcome screen's headline — same brand thesis, smaller
    // weight + size so it reads as a sub-line under the wordmark rather
    // than a competing hero. Stays one line on a phone at 18 px.
    return Text(
      'The How behind the Wow',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.78),
        height: 1.3,
      ),
    );
  }

  // ── error ──────────────────────────────────────────────────────────

  Widget _errorBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x33FF4D6D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x66FF4D6D)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFFFB8C0), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_errorMessage,
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFFFB8C0),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35)),
            ),
          ],
        ),
      );

  // ── auth buttons ───────────────────────────────────────────────────

  Widget _authButtons() {
    return Column(
      children: [
        if (_isIos) ...[
          _AppleButton(onTap: _isLoading ? null : _signInWithApple),
          const SizedBox(height: 12),
        ],
        _GoogleButton(onTap: _isLoading ? null : _signInWithGoogle),
        const SizedBox(height: 12),
        _PhoneButton(onTap: _isLoading ? null : _signInWithPhone),
      ],
    );
  }

  Widget _legalLine() {
    return Text(
      'By continuing you agree to our Terms & Privacy.',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _loadingOverlay() => Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(CareerColors.gold),
              ),
            ),
          ),
        ),
      );

  // ── auth handlers ──────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    HowwowEventLogger.instance.log(
      HowwowEvents.loginAttempted,
      props: {'provider': 'google'},
    );
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      String? idToken;

      if (kIsWeb) {
        // Web: google_sign_in does a token-only flow (no id_token), so
        // GoogleAuthProvider.credential(idToken: null) would fail. Use
        // Firebase's own popup instead — it handles the OIDC handshake
        // and returns a FirebaseUser whose getIdToken() is the Firebase
        // ID token (which is what the backend wants anyway).
        final userCredential = await FirebaseAuth.instance
            .signInWithPopup(GoogleAuthProvider());
        idToken = await userCredential.user?.getIdToken();
      } else {
        // Native iOS/Android: google_sign_in returns a proper id_token we
        // can hand to Firebase as a Google credential.
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        idToken = await userCredential.user?.getIdToken();
      }

      if (idToken == null || idToken.isEmpty) {
        throw StateError('No Firebase ID token returned after Google sign-in.');
      }
      final response = await howwowLogin(idToken: idToken, provider: 'google');
      _routeAfterLogin(response);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError('Google sign-in', e);
      });
    }
  }

  Future<void> _signInWithApple() async {
    HowwowEventLogger.instance.log(
      HowwowEvents.loginAttempted,
      props: {'provider': 'apple'},
    );
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('No Firebase ID token returned after Apple sign-in.');
      }
      // Apple delivers the name only on first sign-in — capture it and pass
      // through so the backend can store it on the new HowwowUser record.
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      final response = await howwowLogin(
        idToken: idToken,
        provider: 'apple',
        appleName: fullName.isEmpty ? null : fullName,
      );
      _routeAfterLogin(response);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError('Apple sign-in', e);
      });
    }
  }

  void _signInWithPhone() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
  }

  // ── routing ────────────────────────────────────────────────────────

  void _routeAfterLogin(LoginResponse response) {
    if (!mounted) return;
    final isNewUser = response.newUser;
    if (response.profile?.phoneVerified == false) {
      // Google / Apple first sign-in — need a verified phone before home.
      // PhoneLinkScreen routes onward by `newUser`: first-timers continue
      // into the onboarding flow, returning users go straight home.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PhoneLinkScreen(newUser: isNewUser)),
        (route) => false,
      );
    } else if (isNewUser) {
      // Phone already on file but first sign-in — personalize before home.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingFlow()),
        (route) => false,
      );
    } else {
      _goHome();
    }
  }

  /// After auth completes, consume any deeplink that was stashed by a
  /// prior auth-gated redirect before falling through to the default
  /// home route. Async — but routing is fire-and-forget; the consumer
  /// pushes its own navigation on the global navigator.
  Future<void> _goHome() async {
    final consumed = await HowwowDeeplinkRouter.consumePending();
    if (!mounted || consumed) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CareerHomeScreen()),
      (route) => false,
    );
  }

  String _friendlyError(String prefix, Object e) {
    // Log to the Chrome DevTools console so we can diagnose failures (the
    // banner is space-limited). Pass only a STRING — passing the raw `e`
    // as `error:` triggers a Flutter-web debug-inspector bug when the
    // exception is JS-backed (FirebaseAuthException), looping a
    // "LegacyJavaScriptObject is not DiagnosticsNode" error every frame.
    developer.log('$prefix error: $e', name: 'howwow.auth');

    if (e is ApiException) {
      return '$prefix failed [HTTP ${e.statusCode}'
          '${e.code != null ? ' / ${e.code}' : ''}]: ${e.message ?? 'no message'}';
    }
    if (e is FirebaseAuthException) {
      return '$prefix failed [${e.code}]: ${e.message ?? 'no message'}';
    }
    if (e is SignInWithAppleAuthorizationException) {
      return '$prefix failed [${e.code}]: ${e.message}';
    }
    return '$prefix failed: $e';
  }
}


// ─────────────────────────────────────────────────────────────────────
// Provider buttons — each with its own brand treatment so each reads as
// the canonical auth pill for that provider, instead of three identical
// glass pills that all blur together.
// ─────────────────────────────────────────────────────────────────────

class _AppleButton extends StatelessWidget {
  const _AppleButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _AuthPill(
      onTap: onTap,
      background: Colors.black,
      borderColor: Colors.white.withValues(alpha: 0.10),
      glowColor: Colors.black.withValues(alpha: 0.50),
      label: 'Continue with Apple',
      labelColor: Colors.white,
      iconBuilder: (size) => Icon(Icons.apple, size: size, color: Colors.white),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _AuthPill(
      onTap: onTap,
      background: Colors.white,
      borderColor: Colors.white.withValues(alpha: 0.0),
      glowColor: Colors.white.withValues(alpha: 0.18),
      label: 'Continue with Google',
      labelColor: const Color(0xFF1A1340),
      iconBuilder: (size) => _GoogleGlyph(size: size),
    );
  }
}

class _PhoneButton extends StatelessWidget {
  const _PhoneButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _AuthPill(
      onTap: onTap,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD976), Color(0xFFFFB42E)],
      ),
      glowColor: CareerColors.gold.withValues(alpha: 0.40),
      label: 'Continue with Phone',
      labelColor: CareerColors.onLight,
      iconBuilder: (size) =>
          const Icon(Icons.phone_iphone_rounded, size: 22,
              color: CareerColors.onLight),
    );
  }
}

/// Shared pill body — single source of truth for height / corner radius
/// / press feedback so all three provider buttons render at identical
/// proportions and snap together vertically without padding hacks.
class _AuthPill extends StatelessWidget {
  const _AuthPill({
    required this.label,
    required this.labelColor,
    required this.iconBuilder,
    required this.glowColor,
    this.background,
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  final String label;
  final Color labelColor;
  final Widget Function(double size) iconBuilder;
  final Color glowColor;
  final Color? background;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.97,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.85 : 1.0,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: background,
            gradient: gradient,
            // Rounded-rectangle silhouette (was a full pill at 999) so
            // the CTA matches the welcome screen's "Let's Explore" tile.
            borderRadius: BorderRadius.circular(16),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconBuilder(22),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  // 15.5 → 18.5 (~20% larger) for parity with the
                  // welcome CTA.
                  fontSize: 18.5,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini Google-brand "G" — four-quadrant ring approximating the
/// official Google logo enough to read as the brand at button scale
/// without bundling an asset / SVG.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  // Canonical Google brand colours.
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final stroke = size.width * 0.18;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r - stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four quadrant arcs in Google brand colours.
    paint.color = _blue;
    canvas.drawArc(rect, -math.pi / 2, math.pi / 2, false, paint);
    paint.color = _green;
    canvas.drawArc(rect, 0, math.pi / 2, false, paint);
    paint.color = _yellow;
    canvas.drawArc(rect, math.pi / 2, math.pi / 2, false, paint);
    paint.color = _red;
    canvas.drawArc(rect, math.pi, math.pi / 2, false, paint);

    // Inner "G" tongue — short blue horizontal bar.
    final tongue = Paint()
      ..color = _blue
      ..strokeWidth = stroke * 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.55, cy),
      tongue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
