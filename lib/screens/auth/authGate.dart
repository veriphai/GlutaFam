// AuthGate — the first screen the app shows on launch.
//
// Reads the stored appJwt (from a previous howwowLogin) via AuthTokenService.
//   • token present, phone-collection pending → resume PhoneLinkScreen (the
//     user signed in via Google/Apple but killed the app before saving a
//     phone number).
//   • token present, onboarding pending → resume OnboardingFlow (the user
//     finished phone collection but killed the app before name/age/interests).
//   • token present → go straight to CareerHomeScreen.
//   • token absent  → go to WelcomeScreen (the branded intro with the
//     looped video, "Let's Explore" CTA, and a small debug-skip below it).
//     Tapping "Let's Explore" then routes to HowwowLoginScreen.
//
// Phone-pending takes priority over onboarding-pending because the signup
// flow is strictly Phone → Onboarding → Home — resuming onboarding before
// the user has a phone on file would skip a required step.
//
// Held briefly as a Scaffold with a tiny loader so the UI never flashes the
// welcome screen for a returning user.

import 'package:flutter/material.dart';

import '../../utils/authTokenService.dart';
import '../../utils/deeplink/howwowDeeplinkRouter.dart';
import '../home/career/careerHomeScreen.dart';
import 'onboarding/onboardingFlow.dart';
import 'phoneLinkScreen.dart';
import 'welcomeScreen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Schedule after first frame so Navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final token = await AuthTokenService().getAuthToken();
    if (!mounted) return;
    final goingToWelcome = token == null || token.isEmpty;

    // Signup-flow resume markers, checked in strict signup order:
    //   1. PhoneCollectionPending → user signed in but never saved a phone.
    //   2. OnboardingPending      → phone is on file but onboarding incomplete.
    // The pending flags are set on screen mount and cleared on success /
    // abandon, so they accurately reflect "this user was mid-X when the
    // process died" rather than "this user has ever seen X".
    final resumePhone =
        !goingToWelcome && await PhoneCollectionPending.isPending();
    final resumeOnboarding = !goingToWelcome &&
        !resumePhone &&
        await OnboardingPending.isPending();
    final phoneWasNewUser =
        resumePhone ? await PhoneCollectionPending.wasNewUser() : false;
    if (!mounted) return;

    // If we're about to show WelcomeScreen, eagerly decode its first-frame
    // placeholder JPEG now so it's already in the image cache by the time
    // the screen mounts. Without this, Image.asset would decode lazily on
    // first paint and the user would briefly see the Scaffold's blue bg
    // before the kid/rocket composition appears.
    if (goingToWelcome) {
      await precacheImage(
        const AssetImage('assets/videos/intro_first_frame.jpg'),
        context,
      );
    }
    if (!mounted) return;

    // Cold-launched via a deeplink while already authed and onboarding
    // is done? Consume the pending URL and bail — the router pushes its
    // own destination via the global navigator, so we don't also push
    // home on top of it. (Skip deeplink consumption when we're about to
    // route to phone collection or onboarding — the user has to finish
    // signup before any deeplink destination is meaningful.)
    if (!goingToWelcome && !resumePhone && !resumeOnboarding) {
      final consumed = await HowwowDeeplinkRouter.consumePending();
      if (!mounted) return;
      if (consumed) return;
    }

    final Widget next = goingToWelcome
        ? const WelcomeScreen()
        : resumePhone
            ? PhoneLinkScreen(newUser: phoneWasNewUser)
            : resumeOnboarding
                ? const OnboardingFlow()
                : const CareerHomeScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF07162F),
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC83D)),
          ),
        ),
      ),
    );
  }
}
