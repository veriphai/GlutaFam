// OrbitDialogueController — owns the Orbit dialogue queue and its pacing
// (PRD §22), VOICE-PACED per the playbook:
//
//   • Lines with a clip advance on the clip's COMPLETION (+ a 350ms breath) —
//     never on a fixed timer (a fixed timer cuts long lines mid-word).
//   • Muted / web-blocked / clip-less lines fall back to a reading-time
//     timer; the fallback DEFERS to live audio (voiceStarted cancels it).
//   • Every live clip arms a 12s SAFETY timer in case onPlayerComplete never
//     arrives (missing file, audio-focus loss, platform drop) — both paths
//     funnel through the idempotent [voiceFinished].
//   • [onQueueIdle] fires once when the queue drains AND its last line has
//     finished speaking — the controller uses it for voice-paced stage
//     advances and listen-before-skip CTA gates.
//
// It is presentation-agnostic: it calls [emit] per line; the
// MissionStageController turns that into state (text/face/voice tokens), and
// the shell's voice lane plays the clip + reports voiceStarted/voiceFinished.

import 'dart:async';
import 'dart:math' as math;

import '../config/scc_dialogue.dart';

class OrbitDialogueController {
  OrbitDialogueController({required this.emit});

  /// Called once per line as it becomes the visible line.
  final void Function(Line line) emit;

  /// Fires once whenever the queue drains and its final line has been heard
  /// (or read, when muted). Set by the MissionStageController.
  void Function()? onQueueIdle;

  final List<Line> _queue = [];
  Timer? _timer; // reading-time fallback / inter-line breath
  Timer? _safety; // live-clip watchdog
  bool _voiceActive = false;
  bool _idleNotified = true; // no queue yet → already idle

  /// True while queued lines are still flowing (or the last clip is playing).
  bool get busy => _queue.isNotEmpty || _voiceActive || _timer != null;

  /// Reading time for a line — kids read slowly; floor 2.2s. Used only as
  /// the muted/clip-less fallback.
  Duration readTime(String text) =>
      Duration(milliseconds: math.max(2200, 600 + text.length * 52));

  /// Queue [lines]; each shows for its clip's duration (voice-paced), the
  /// LAST line persists as the standing instruction.
  void say(List<Line> lines, {bool replace = true}) {
    if (replace) {
      _queue.clear();
      _cancelTimers();
      _voiceActive = false;
    }
    _queue.addAll(lines);
    _idleNotified = false;
    if (_timer == null && !_voiceActive) _next();
  }

  void _cancelTimers() {
    _timer?.cancel();
    _timer = null;
    _safety?.cancel();
    _safety = null;
  }

  void _next() {
    if (_queue.isEmpty) {
      _timer = null;
      _notifyIdle();
      return;
    }
    final line = _queue.removeAt(0);
    emit(line);
    // Arm the reading-time fallback — if the shell starts the clip (it does
    // so synchronously from the emit's notify), voiceStarted cancels this.
    _timer = Timer(readTime(line.text), () {
      _timer = null;
      if (!_voiceActive) _next();
    });
  }

  void _notifyIdle() {
    if (_idleNotified) return;
    _idleNotified = true;
    onQueueIdle?.call();
  }

  /// Shell: the current line's clip began playing.
  void voiceStarted() {
    _timer?.cancel(); // live audio paces — the reading fallback stands down
    _timer = null;
    _voiceActive = true;
    _safety?.cancel();
    _safety = Timer(const Duration(seconds: 12), voiceFinished);
  }

  /// Shell: the clip completed / failed / was muted away. Idempotent — the
  /// safety timer, onPlayerComplete, catchError, and the mute toggle may all
  /// call it.
  void voiceFinished() {
    if (!_voiceActive) return;
    _voiceActive = false;
    _safety?.cancel();
    _safety = null;
    // breath, then the next line (or idle notification)
    _timer = Timer(const Duration(milliseconds: 350), () {
      _timer = null;
      _next();
    });
  }

  /// Tap-to-advance from the bubble — skips the current line's remaining
  /// audio (the shell stops it on the next emit) and shows the next.
  void advance() {
    if (_queue.isEmpty) return;
    _cancelTimers();
    _voiceActive = false;
    _next();
  }

  void dispose() {
    _cancelTimers();
    _voiceActive = false;
    _queue.clear();
  }
}
