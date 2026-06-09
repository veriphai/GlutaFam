// Mission panel (PRD §26): free-standing Orbit mascot (pose-per-mood) + a
// smooth speech bubble carrying the mission/hint/success text — same
// integrated-tail pattern as build_satellite/widgets/mascot_helper.dart.
// Text changes use sequential fade-out → swap → fade-in so the previous
// line never overlaps the new one.

import 'package:flutter/material.dart';

import '../../../../utils/s3_assets.dart';
import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/restore_earth_controller.dart';
import '../state/restore_earth_state.dart';

// The Orbit sprite pack lives under build_satellite/mascot/ (uploaded to S3).
// It's the same character across activities; we reference the canonical path.
String _orbitAsset(MascotMood m) => 'assets/images/build_satellite/mascot/'
    '${switch (m) {
      MascotMood.idle => 'orbit_guiding.png',
      MascotMood.hint => 'orbit_thinking.png',
      MascotMood.excited => 'orbit_happy.png',
      MascotMood.celebrate => 'orbit_celebrating.png',
      MascotMood.oops => 'orbit_concerned.png',
    }}';

class MissionPanel extends StatelessWidget {
  const MissionPanel({super.key, required this.controller});

  final RestoreEarthController controller;

  static const _accentDefault = CareerColors.cyan;
  static const _accentHint = Color(0xFFFFC83D);

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final accent = s.mascot == MascotMood.hint ? _accentHint : _accentDefault;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: Floaty(
            amplitude: 4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: netImageWidget(
                _orbitAsset(s.mascot),
                key: ValueKey(s.mascot),
                height: 86,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                text: s.missionText,
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
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180), value: 1);
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

/// Single unioned path (rounded body + left-pointing tail) so the stroke
/// traces the whole bubble seamlessly — no visible seam where the tail
/// meets the body.
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

    canvas.drawPath(
      shape,
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE60B2147), Color(0xE6081226)],
        ).createShader(Offset.zero & size),
    );
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
