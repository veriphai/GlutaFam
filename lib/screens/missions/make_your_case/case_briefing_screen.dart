// The CASE BRIEFING — the episode's intro screen (shown when the episode opens,
// before the first activity). Renders the pre-designed dossier image directly
// (BoxFit.fitWidth on black), with a functional back tap-target over the drawn
// back button and a real gold "Start Investigating" button pinned at the bottom.
// "Start Investigating" → the first activity.
//
// Registered as a normal activity resource (episode1_case_briefing) so the lesson
// runner plays it first and pops to the next resource on Start.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/career/careerCommon.dart';
import '../lessonRunner.dart';
import 'config/cer_config.dart';

const String _briefingImage = 'assets/images/episode_board/case_briefing.png';

/// The briefing chrome accent — gold for the EP1 dossier, electric-blue for EP2.
enum BriefingAccent { gold, blue }

/// The chamfered-button + back-button colour set for an accent.
class _Palette {
  const _Palette({
    required this.glow,
    required this.face,
    required this.rim,
    required this.groove,
    required this.ink,
  });
  final Color glow; // outer glow + back-button border/glow
  final List<Color> face; // 3-stop button face gradient (top → bottom)
  final Color rim; // bright outer rim + back-button icon
  final Color groove; // inset groove line (the double-frame)
  final Color ink; // text + search icon on the button face
}

const _Palette _goldPalette = _Palette(
  glow: Color(0xFFE6A93C),
  face: [Color(0xFFFBD66A), Color(0xFFF0B83E), Color(0xFFDD9322)],
  rim: Color(0xFFFFD27A),
  groove: Color(0xFF7A521A),
  ink: Color(0xFF1A1206),
);

const _Palette _bluePalette = _Palette(
  glow: Color(0xFF3DA0E6),
  face: [Color(0xFFAEDCF4), Color(0xFF5FA4E3), Color(0xFF3877C0)],
  rim: Color(0xFF8FE3FF),
  groove: Color(0xFF15406B),
  ink: Color(0xFF0A1628),
);

_Palette _paletteFor(BriefingAccent a) =>
    a == BriefingAccent.blue ? _bluePalette : _goldPalette;

class CaseBriefingScreen extends StatefulWidget {
  const CaseBriefingScreen({
    super.key,
    this.config = kEp1CerConfig,
    this.image = _briefingImage,
    this.accent = BriefingAccent.gold,
  });

  final CerConfig config;

  /// The pre-designed dossier briefing image for this episode (EP1 by default;
  /// EP2 passes its own — registered as `episode2_case_briefing`).
  final String image;

  /// The chrome accent — matches the dossier art (EP1 gold, EP2 electric-blue).
  final BriefingAccent accent;

  @override
  State<CaseBriefingScreen> createState() => _CaseBriefingScreenState();
}

class _CaseBriefingScreenState extends State<CaseBriefingScreen> {
  // Back / system-back → the runner's leave-confirm guard (leave the lesson).
  void _back() => Navigator.of(context).maybePop();

  // START INVESTIGATION → ADVANCE to the first activity. Concept activities are
  // guarded, so a plain maybePop would raise the leave modal — completeActivity
  // pops `true` past the guard (exactly like an activity's "Continue").
  void _start() => completeActivity(context);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reserve = 92 + media.padding.bottom; // space kept for the pinned button
    final p = _paletteFor(widget.accent);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // The dossier image — fit to width, centred in the space above the
            // button (scrolls if it's taller than the screen so nothing is lost).
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: reserve),
                      child: Center(
                        child: Image.asset(
                          widget.image,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 400,
                            child: Center(child: Text('Case briefing', style: TextStyle(color: Colors.white54))),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Real back button (this image has none drawn in).
            Positioned(
              top: media.padding.top + 8,
              left: 16,
              child: PressableScale(
                onTap: _back,
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(color: p.glow.withValues(alpha: 0.6), width: 1.4),
                    boxShadow: [BoxShadow(color: p.glow.withValues(alpha: 0.22), blurRadius: 12)],
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 22, color: p.rim),
                ),
              ),
            ),

            // The real gold button, pinned at the bottom.
            Positioned(
              left: 20,
              right: 20,
              bottom: 14 + media.padding.bottom,
              child: _StartButton(onTap: _start, palette: p),
            ),
          ],
        ),
      ),
    );
  }
}

// ── START INVESTIGATING — gold chamfered button (matches the dossier) ────────
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap, required this.palette});
  final VoidCallback onTap;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: CustomPaint(
        painter: _ChamferPainter(palette),
        child: Container(
          height: 66,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, size: 26, color: palette.ink),
              const SizedBox(width: 14),
              Text(
                'START INVESTIGATION',
                style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: palette.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chamfered (octagonal) button matching the dossier: a brushed metallic face,
/// a strong outer glow, a bright outer rim, and an inset groove line (the double
/// beveled frame). Colours come from the episode's [_Palette] (gold / blue).
class _ChamferPainter extends CustomPainter {
  const _ChamferPainter(this.palette);
  final _Palette palette;
  static const double _cut = 16;

  static Path _chamfer(Rect r, double cut) => Path()
    ..moveTo(r.left + cut, r.top)
    ..lineTo(r.right - cut, r.top)
    ..lineTo(r.right, r.top + cut)
    ..lineTo(r.right, r.bottom - cut)
    ..lineTo(r.right - cut, r.bottom)
    ..lineTo(r.left + cut, r.bottom)
    ..lineTo(r.left, r.bottom - cut)
    ..lineTo(r.left, r.top + cut)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = _chamfer(rect, _cut);
    final inner = _chamfer(rect.deflate(5), _cut - 4);

    // Outer glow.
    canvas.drawPath(
      outer,
      Paint()
        ..color = palette.glow.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Brushed metallic face (bright top → deep bottom, with a mid highlight).
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.face,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    // A soft sheen band across the top third.
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.42),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.42)),
    );
    canvas.restore();
    // Bright outer rim.
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = palette.rim,
    );
    // Inset groove (the double-frame look).
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = palette.groove.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_ChamferPainter old) => old.palette != palette;
}
