// Data-transmission visuals, drawn in Flutter (replaces the poor Flame bursts).
// While sending: a GREEN "connected" beam from the satellite to the ground
// receiver, with packets traveling along it. When the send finishes: a small
// "DATA SENT" pill above the satellite + "DATA RECEIVED" pill near the receiver.
//
// Coordinates are full-screen stage pixels (same space the controller computes),
// so this overlay must be a Positioned.fill sibling of the GameWidget.

import 'package:flutter/material.dart';

import '../config/power_balance_tuning.dart';
import 'pb_palette.dart';

class TransmissionFx extends StatefulWidget {
  const TransmissionFx({
    super.key,
    required this.startToken, // bumps when a send STARTS (sendToken)
    required this.doneToken, // bumps when a send FINISHES (transmitDoneToken)
    required this.satellite,
    required this.dish,
  });

  final int startToken;
  final int doneToken;
  final Offset satellite;
  final Offset dish;

  @override
  State<TransmissionFx> createState() => _TransmissionFxState();
}

class _TransmissionFxState extends State<TransmissionFx> with TickerProviderStateMixin {
  late final AnimationController _tx = AnimationController(
      vsync: this, duration: Duration(milliseconds: (PBTune.sendBeat * 1000).round()));
  late final AnimationController _pill =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  Offset _pillSat = Offset.zero;
  Offset _pillDish = Offset.zero;

  @override
  void didUpdateWidget(covariant TransmissionFx old) {
    super.didUpdateWidget(old);
    if (widget.startToken != old.startToken && widget.startToken > 0) {
      _tx.forward(from: 0);
    }
    if (widget.doneToken != old.doneToken && widget.doneToken > 0) {
      _pillSat = widget.satellite;
      _pillDish = widget.dish;
      _pill.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tx.dispose();
    _pill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // green beam + traveling packets (during the send)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _tx,
              builder: (_, __) {
                if (_tx.value == 0 || _tx.value >= 1) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _BeamPainter(widget.satellite, widget.dish, _tx.value),
                );
              },
            ),
          ),
          // "DATA SENT" / "DATA RECEIVED" pills (after the send finishes).
          // Positioned.fill so the inner Stack fills the screen and the pills
          // anchor to real coordinates (not a zero-size box).
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pill,
              builder: (_, __) {
                final t = _pill.value;
                if (t == 0 || t >= 1) return const SizedBox.shrink();
                final op = (t < 0.15 ? t / 0.15 : (t > 0.8 ? 1 - (t - 0.8) / 0.2 : 1.0))
                    .clamp(0.0, 1.0);
                return Stack(
                  children: [
                    _pillAt(_pillSat + const Offset(0, -48), 'DATA SENT', op),
                    _pillAt(_pillDish + const Offset(0, -36), 'DATA RECEIVED', op),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillAt(Offset centre, String label, double opacity) => Positioned(
        left: centre.dx,
        top: centre.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: Opacity(opacity: opacity, child: _pillChip(label)),
        ),
      );

  Widget _pillChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xF00B2417),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PBPalette.successGreen, width: 1.3),
          boxShadow: [BoxShadow(color: PBPalette.successGreen.withValues(alpha: 0.5), blurRadius: 12)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 13, color: PBPalette.successGreen),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: PBPalette.successGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6)),
          ],
        ),
      );
}

class _BeamPainter extends CustomPainter {
  _BeamPainter(this.sat, this.dish, this.t);

  final Offset sat;
  final Offset dish;
  final double t;
  static const _green = PBPalette.successGreen;

  @override
  void paint(Canvas canvas, Size size) {
    // fade the beam in at the start and out at the end
    final env = (t < 0.12 ? t / 0.12 : (t > 0.88 ? 1 - (t - 0.88) / 0.12 : 1.0)).clamp(0.0, 1.0);

    final glow = Paint()
      ..color = _green.withValues(alpha: 0.28 * env)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()
      ..color = _green.withValues(alpha: 0.9 * env)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(sat, dish, glow);
    canvas.drawLine(sat, dish, core);

    // connection nodes at each end
    canvas.drawCircle(sat, 4.5, Paint()..color = _green.withValues(alpha: 0.95 * env));
    canvas.drawCircle(dish, 5.5, Paint()..color = _green.withValues(alpha: 0.95 * env));

    // packets traveling satellite → receiver
    const n = 4;
    for (var i = 0; i < n; i++) {
      final frac = ((t * 2.4) + i / n) % 1.0;
      final p = Offset.lerp(sat, dish, frac)!;
      canvas.drawCircle(
          p, 6, Paint()
            ..color = _green.withValues(alpha: 0.7 * env)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 8, height: 8), const Radius.circular(2));
      canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.95 * env));
    }
  }

  @override
  bool shouldRepaint(_BeamPainter o) => o.t != t || o.sat != sat || o.dish != dish;
}
