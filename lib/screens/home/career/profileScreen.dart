// Profile tab — premium glass profile card over the cosmic backdrop, fed
// from the session-cached HowwowProfile (set at login; no extra network
// round trip). Reached from the bottom nav's Profile tab.
//
// Layout: avatar hero (gradient ring + glow) → identity (name, contact,
// sign-in provider chip) → stats tiles (XP / badges / streak) → "About me"
// (age group + interest chips) → Log Out at the end.
//
// Logout flow: howwowLogout() (server FCM-token clear + analytics flush)
// → best-effort Firebase/Google sign-out (so the next login can pick a
// different account) → wipe the stored appJwt + session profile → hard
// reset navigation to AuthGate, which lands on the welcome screen.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../apis/howwow/howwowAuth.dart';
import '../../../apis/howwow/howwowSession.dart';
import '../../../models/howwow/howwowProfile.dart';
import '../../../utils/authTokenService.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import '../../auth/authGate.dart';
import 'careerCommon.dart';
import 'careerTheme.dart';
import 'cosmicBackground.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _maxContentWidth = 480;

  bool _loggingOut = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    HowwowEventLogger.instance.log(
      HowwowEvents.screenViewed,
      props: {'screen': 'profile'},
    );
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'v${info.version} (${info.buildNumber})');
      }
    }).catchError((_) {});
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    // Server-side logout + analytics flush. Never let a network failure
    // strand the user logged-in locally — everything below still runs.
    try {
      await howwowLogout();
    } catch (_) {}
    // Release the identity providers so the next login shows the account
    // picker instead of silently reusing the old account.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await AuthTokenService().setAuthToken('');
    HowwowSession.instance.setProfile(null);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = HowwowSession.instance.profile;
    return Scaffold(
      backgroundColor: CareerColors.bgMid,
      body: Stack(
        children: [
          const Positioned.fill(child: CosmicBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                // Top-anchored content + bottom-pinned logout: the profile
                // always starts right under the app bar and Log Out hugs
                // the bottom of the screen, with the middle scrolling when
                // the about-card grows past the available height.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          CareerSpace.page, 8, CareerSpace.page, 0),
                      child: _topBar(context),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            CareerSpace.page, 0, CareerSpace.page, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _heroCard(profile),
                            const SizedBox(height: CareerSpace.gap),
                            _statsRow(profile?.stats),
                            if ((profile?.ageGroup ?? '').isNotEmpty ||
                                (profile?.interests.isNotEmpty ?? false)) ...[
                              const SizedBox(height: CareerSpace.gap),
                              _aboutCard(profile!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          CareerSpace.page, 6, CareerSpace.page, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _logoutButton(),
                          if (_version.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Tuto $_version',
                                style: GoogleFonts.poppins(
                                  color: CareerColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: () => Navigator.of(context).maybePop(),
          child: GlassSurface(
            radius: 16,
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: CareerColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ── hero: avatar + identity ───────────────────────────────────────────

  Widget _heroCard(HowwowProfile? p) {
    final name = (p?.displayName?.trim().isNotEmpty ?? false)
        ? p!.displayName!.trim()
        : (p?.firstName?.trim().isNotEmpty ?? false)
            ? p!.firstName!.trim()
            : 'Explorer';
    final contact = (p?.emailId?.isNotEmpty ?? false)
        ? p!.emailId!
        : (p?.phoneNumber?.isNotEmpty ?? false)
            ? p!.phoneNumber!
            : null;

    return Container(
      padding: const EdgeInsets.all(1.6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CareerRadii.card),
        gradient: CareerGradients.heroBorder,
        boxShadow: [
          BoxShadow(
            color: CareerColors.purple.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CareerRadii.card - 1.6),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF18244F), Color(0xFF0C1430)],
          ),
        ),
        child: Column(
          children: [
            _avatar(p?.avatar),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: CareerColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            if (contact != null) ...[
              const SizedBox(height: 4),
              Text(
                contact,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: CareerColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _providerChip(p?.signInProvider),
          ],
        ),
      ),
    );
  }

  Widget _avatar(HowwowAvatar? avatar) {
    final url = avatar?.imageUrl;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FD0FF), Color(0xFF4A90D9)],
        ),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5),
        boxShadow: [
          BoxShadow(
              color: CareerColors.blue.withValues(alpha: 0.45), blurRadius: 22),
        ],
        image: url != null && url.startsWith('http')
            ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : const DecorationImage(
                image: AssetImage('assets/images/avatar.png'),
                fit: BoxFit.cover,
                onError: _ignore,
              ),
      ),
      alignment: Alignment.center,
      child: const Text('🧒', style: TextStyle(fontSize: 48)),
    );
  }

  static void _ignore(Object e, StackTrace? s) {}

  Widget _providerChip(String? provider) {
    final (icon, label) = switch (provider) {
      'google.com' => (Icons.g_mobiledata_rounded, 'Google account'),
      'apple.com' => (Icons.apple_rounded, 'Apple account'),
      'phone' => (Icons.phone_iphone_rounded, 'Phone login'),
      _ => (Icons.verified_user_rounded, 'Signed in'),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
      decoration: BoxDecoration(
        color: CareerColors.glassFillStrong,
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(color: CareerColors.glassBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: CareerColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: CareerColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  // ── stats tiles ───────────────────────────────────────────────────────

  Widget _statsRow(HowwowStats? stats) {
    Widget tile(String emoji, String value, String label, Color glow) {
      return Expanded(
        child: GlassSurface(
          radius: CareerRadii.smallCard,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: CareerColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: glow.withValues(alpha: 0.6), blurRadius: 12)],
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: CareerColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ),
      );
    }

    return Row(children: [
      tile('⚡', '${stats?.xp ?? 0}', 'XP', CareerColors.gold),
      const SizedBox(width: CareerSpace.gap),
      tile('🏅', '${stats?.badges ?? 0}', 'BADGES', CareerColors.purple),
      const SizedBox(width: CareerSpace.gap),
      tile('🔥', '${stats?.streakDays ?? 0}', 'DAY STREAK', CareerColors.orange),
    ]);
  }

  // ── about me ──────────────────────────────────────────────────────────

  Widget _aboutCard(HowwowProfile p) {
    String prettify(String id) => id
        .split(RegExp(r'[-_]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    final age = switch (p.ageGroup) {
      'under-11' => 'Under 11',
      '11-13' => '11–13',
      '14-16' => '14–16',
      '17-plus' => '17+',
      _ => p.ageGroup,
    };

    return GlassSurface(
      radius: CareerRadii.card,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT ME',
            style: GoogleFonts.poppins(
              color: CareerColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          if (age != null && age.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.cake_rounded,
                  size: 18, color: CareerColors.cyan),
              const SizedBox(width: 8),
              Text(
                'Age group:  $age',
                style: GoogleFonts.poppins(
                  color: CareerColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ],
          if (p.interests.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: CareerColors.gold),
              const SizedBox(width: 8),
              Text(
                'I love…',
                style: GoogleFonts.poppins(
                  color: CareerColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in p.interests)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CareerColors.purple.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                      border: Border.all(
                          color: CareerColors.purple.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      prettify(id),
                      style: GoogleFonts.poppins(
                        color: CareerColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── logout ────────────────────────────────────────────────────────────

  Widget _logoutButton() {
    return PressableScale(
      onTap: _logout,
      pressedScale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D5E).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          border: Border.all(
              color: const Color(0xFFFF4D5E).withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loggingOut)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFFFF8A94)),
                ),
              )
            else
              const Icon(Icons.logout_rounded,
                  size: 19, color: Color(0xFFFF8A94)),
            const SizedBox(width: 8),
            Text(
              _loggingOut ? 'Logging out…' : 'Log Out',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF8A94),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
