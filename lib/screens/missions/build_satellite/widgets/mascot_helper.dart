// Free-standing "Orbit" mascot + a smooth speech bubble with an INTEGRATED
// tail (single unioned path — no visible triangle seam) pointing at the
// mascot. Same path-union pattern as code_satellite/chat_bubble.dart, themed
// for build_satellite (dark navy fill, cyan accent border, gold-amber on hint).
// Text changes do a sequential fade-out → swap → fade-in (no overlap with the
// previous line).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/build_satellite_controller.dart';
import '../state/build_satellite_state.dart';
import '../../../../utils/s3_assets.dart';

String _moodAsset(MascotMood m) => switch (m) {
      MascotMood.welcoming => 'assets/images/build_satellite/mascot/orbit_welcoming.png',
      MascotMood.guiding => 'assets/images/build_satellite/mascot/orbit_guiding.png',
      MascotMood.happy => 'assets/images/build_satellite/mascot/orbit_happy.png',
      MascotMood.concerned => 'assets/images/build_satellite/mascot/orbit_concerned.png',
      MascotMood.thinking => 'assets/images/build_satellite/mascot/orbit_thinking.png',
      MascotMood.celebrating => 'assets/images/build_satellite/mascot/orbit_celebrating.png',
    };

class MascotHelper extends StatelessWidget {
  const MascotHelper({super.key, required this.controller});

  final BuildSatelliteController controller;

  static const _accentDefault = CareerColors.cyan;
  static const _accentHint = Color(0xFFFFC83D);

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final accent = s.hintActive ? _accentHint : _accentDefault;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: s.hintActive ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 320),
          child: Floaty(
            amplitude: 4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: netImageWidget(
                _moodAsset(s.mood),
                key: ValueKey(s.mood),
                height: 86,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: CustomPaint(
            painter: _BubblePainter(accent: accent),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 12),
              child: _FadeSwapText(
                text: s.helperMessage,
                style: CareerText.body.copyWith(
                    color: Colors.white, fontSize: 13, height: 1.32),
                maxLines: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sequential fade-out → swap → fade-in (no cross-fade overlap when the text
/// changes). One line is on screen at a time.
class _FadeSwapText extends StatefulWidget {
  const _FadeSwapText({required this.text, required this.style, this.maxLines});
  final String text;
  final TextStyle style;
  final int? maxLines;

  @override
  State<_FadeSwapText> createState() => _FadeSwapTextState();
}

class _FadeSwapTextState extends State<_FadeSwapText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: 1);
  late String _shown = widget.text;

  @override
  void didUpdateWidget(_FadeSwapText old) {
    super.didUpdateWidget(old);
    if (widget.text != old.text) {
      _c.reverse().then((_) {
        if (!mounted) return;
        setState(() => _shown = widget.text);
        _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Text(
        _shown,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Single unioned path (rounded body + left-pointing tail) so the stroke traces
/// the whole bubble seamlessly — no visible seam where the tail meets the body.
class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.accent});
  final Color accent;

  static const double _tail = 13;
  static const double _radius = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(RRect.fromLTRBR(
          _tail, 0, size.width, size.height, const Radius.circular(_radius)));

    final cy = size.height * 0.5;
    final tri = Path()
      ..moveTo(_tail + 0.5, cy - 12)
      ..lineTo(0, cy)
      ..lineTo(_tail + 0.5, cy + 12)
      ..close();

    final shape = Path.combine(PathOperation.union, body, tri);

    // Soft glow underneath.
    canvas.drawPath(
      shape,
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Dark navy gradient fill.
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE60B2147), Color(0xE6081226)],
        ).createShader(Offset.zero & size),
    );
    // Single continuous border (unioned shape → no seam).
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.accent != accent;
}
