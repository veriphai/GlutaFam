// WowFirstHowNextScreen — the brand-statement bridge that sits between
// WelcomeScreen and the auth options.
//
// The layout encodes the brand thesis "Wow First. How Next." literally:
//   • Curved serif "Wow First." arches across the top (∩ dome).
//   • A glowing "magic box" sits at the centre of the screen surrounded by
//     curiosity-themed glyphs orbiting in a soft halo.
//   • Curved serif "How Next." arches across the bottom (∪ bowl).
//   • A "Back / Next" row at the very bottom — Back returns to Welcome,
//     Next pushes HowwowLoginScreen so the user enters the auth flow.
//
// Pure-black background to match the reference: the wonder reads strongest
// against a void, and the gold magic box pops without competing colour.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/career/careerCommon.dart';
import '../home/career/careerTheme.dart';
import '../home/career/cosmicBackground.dart';
import 'howwowLoginScreen.dart';
import 'widgets/magical_field.dart';

class WowFirstHowNextScreen extends StatelessWidget {
  const WowFirstHowNextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareerColors.bgMid,
      body: Stack(
        children: [
          // Same cosmic starfield used on the welcome / login / career
          // surfaces so this screen feels like one continuous canvas
          // rather than a black hole in the middle of the brand.
          const Positioned.fill(child: CosmicBackground()),
          SafeArea(
            child: Stack(
              children: [
                // Centred cluster + primary CTA. Two Spacers around the
                // title/orbit cluster pad the remaining vertical space
                // symmetrically so the cluster sits in the visual centre
                // regardless of phone height; the "Begin" button stays
                // pinned to the bottom edge.
                Column(
                  children: [
                    const Spacer(),
                    const _TitleText('Wow First.'),
                    const SizedBox(height: 12),
                    const MagicalField(),
                    const SizedBox(height: 12),
                    const _TitleText('How Next.', reversed: true),
                    const Spacer(),
                    _beginButton(context),
                    const SizedBox(height: 18),
                  ],
                ),
                // Glass back arrow tucked into the top-left corner,
                // floated above the cluster on the Stack so the
                // Spacer-driven centring math isn't disturbed.
                Positioned(
                  left: 18,
                  top: 12,
                  child: _topBackButton(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Floating glass back arrow at the top-left. Reuses the same 44×44
  /// glass-tile pattern as PhoneLinkScreen + PhoneLoginScreen so back
  /// nav reads identically across the whole auth surface.
  Widget _topBackButton(BuildContext context) {
    return PressableScale(
      onTap: () => Navigator.of(context).maybePop(),
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
    );
  }

  /// Primary CTA — full-width gradient tile, label "Begin". The gold of
  /// the welcome CTA reads too "warm" against the cosmic indigo of this
  /// screen, so the button picks up the brand accents already present
  /// here: purple → blue gradient (echoes the title's cyan/blue/purple
  /// half) with a soft purple glow underneath. White label, no shadow
  /// fight with the starfield.
  Widget _beginButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: PressableScale(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HowwowLoginScreen()),
          );
        },
        pressedScale: 0.97,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B5CFF), // brighter purple — top-left
                Color(0xFF3F7FC6), // brand blue — bottom-right
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: CareerColors.purple.withValues(alpha: 0.42),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Begin',
            style: GoogleFonts.poppins(
              fontSize: 20.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Title text — straight, Poppins w800, painted with the brand sweep
// (cyan → blue → purple → magenta → pink → orange). Same gradient as
// the "howwow" wordmark on the login screen so the brand reads as one
// continuous voice across the auth flow.
// ─────────────────────────────────────────────────────────────────────

class _TitleText extends StatelessWidget {
  const _TitleText(this.text, {this.reversed = false});

  final String text;

  /// Flip the gradient horizontally. False → cyan(left) → orange(right).
  /// True → orange(left) → cyan(right). Used to mirror the two title
  /// lines around the centre so the cluster feels symmetrical: "Wow
  /// First." sweeps cool→warm, "How Next." sweeps warm→cool.
  final bool reversed;

  static const _gradientColors = [
    Color(0xFF4FB3D5), // cyan-teal
    Color(0xFF3F7FC6), // blue
    Color(0xFF7C4DFF), // purple
    Color(0xFFC942C8), // magenta
    Color(0xFFE54A5E), // pink-red
    Color(0xFFF8893A), // orange
  ];
  static const _gradientStops = [0.00, 0.18, 0.40, 0.62, 0.82, 1.00];

  @override
  Widget build(BuildContext context) {
    final begin =
        reversed ? Alignment.centerRight : Alignment.centerLeft;
    final end = reversed ? Alignment.centerLeft : Alignment.centerRight;
    return ShaderMask(
      // Horizontal sweep so each character lands on its own colour band.
      // The Text below is painted white; ShaderMask uses that as the
      // alpha mask and replaces it with the gradient.
      shaderCallback: (rect) => LinearGradient(
        begin: begin,
        end: end,
        colors: _gradientColors,
        stops: _gradientStops,
      ).createShader(rect),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          // Must stay opaque-white — ShaderMask treats this as the mask
          // alpha; any other colour would tint the gradient.
          color: Colors.white,
          height: 1.12,
        ),
      ),
    );
  }
}

