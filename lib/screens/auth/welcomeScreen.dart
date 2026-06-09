// WelcomeScreen — the very first thing a user sees after AuthGate decides
// they're not signed in. Mirrors the design mock: the 9:16 intro video
// fills the full screen as a background (status bar overlays it), the
// branding + headline + tagline sit in the blue area on the upper-left,
// and a single primary yellow "Let's Explore" CTA opens the brand
// transition screen (WowFirstHowNextScreen), which then leads into the
// auth options (HowwowLoginScreen).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'videoBackground.dart';
import 'wowFirstHowNextScreen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _gold = Color(0xFFFFC83D);
  static const _onLight = Color(0xFF1A1340);

  @override
  Widget build(BuildContext context) {
    // Make the status bar overlay the video instead of reserving a black
    // strip for it. The video's blue area shows through; the system clock
    // / signal icons sit on top in white.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        // Sampled from the source video's solid-blue area (#006BDE). With
        // fitWidth + bottomCenter the video leaves a ~6% strip uncovered at
        // the top of the screen on tall (20:9) phones; matching the
        // Scaffold colour to the video's blue makes that strip blend
        // seamlessly into the rest of the composition.
        backgroundColor: const Color(0xFF006BDE),
        body: Stack(
          children: [
            // 1) Full-bleed muted intro video (loops 0 → 3.9s). BoxFit.cover
            //    fills the screen edge-to-edge; on tall 20:9 phones a small
            //    slice (~6%) of empty sky on each side gets clipped, but the
            //    focal elements (kid, rocket, drone, truck) stay intact.
            //    The first-frame JPEG is shown as a still placeholder while
            //    the controller initialises so there's no black flash on
            //    cold launch — the still and the first decoded frame are
            //    visually identical, so the swap is invisible.
            const Positioned.fill(
              child: VideoBackground(
                placeholderAsset: 'assets/videos/intro_first_frame.jpg',
              ),
            ),

            // 2) Text overlay — pinned to the upper-left, constrained in
            //    width so it never spills onto the imagery on the right
            //    side of the video. Top padding holds the text ~100px
            //    below the safe area so the brand mark doesn't crowd the
            //    status bar.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 112, 28, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _brandMark(),
                        const SizedBox(height: 22),
                        _headline(),
                        const SizedBox(height: 18),
                        _tagline(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3) Bottom CTA — yellow "Let's Explore" pill + a small debug
            //    text-button below it for development.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _letsExploreButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────

  /// "TheHow**Wow** -" — single visual run with the "Wow" syllable in
  /// the brand gold.
  Widget _brandMark() => RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.0,
          ),
          children: const [
            TextSpan(text: 'TheHow'),
            TextSpan(text: 'Wow', style: TextStyle(color: _gold)),
            TextSpan(text: ' -'),
          ],
        ),
      );

  Widget _headline() => Text(
        'The How behind the Wow',
        style: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.12,
        ),
      );

  Widget _tagline() => Text(
        'We turn real-world systems into epic stories, hands-on '
        'experiments and simulations that spark curiosity and '
        'power big dreams.',
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.white,
          height: 1.45,
        ),
      );

  Widget _letsExploreButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WowFirstHowNextScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _onLight,
          padding: const EdgeInsets.symmetric(vertical: 18),
          // Rectangular silhouette with softly-rounded corners — 16 px
          // reads as "primary CTA tile" instead of the previous pill.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: _gold.withValues(alpha: 0.55),
        ),
        child: Text(
          "Let's Explore",
          style: GoogleFonts.poppins(
            // 17 → 20.5 (~20% larger) so the label reads with more weight
            // against the cinematic background.
            fontSize: 20.5,
            fontWeight: FontWeight.w700,
            color: _onLight,
          ),
        ),
      ),
    );
  }
}
