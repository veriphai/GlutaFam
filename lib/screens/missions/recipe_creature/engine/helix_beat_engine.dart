// Helix's dialogue engine — the reusable reactive contract this vertical slice
// establishes (PRD §5, §7). The cardinal rule is encoded structurally: Helix
// REACTS and POINTS, he never explains. So the engine owns timing, gating, the
// firing order, and the three reactive sockets (onIdle / onCounterproductive /
// onDiscovery); the line author only writes copy + a mood per line.
//
// Mood discipline (PRD §7): at the kid's discovery Helix is `surprised`
// (experiencing it WITH them), never an idea/lightbulb face that would steal the
// moment. `celebrating` is reserved for the card; `confused` only for the
// shared-mystery torn-recipe foreshadow; `idea` only where Helix makes his own
// suggestion (the 0.2 before-line).
//
// Every later de-extinction episode feeds this engine its own [BeatConfig]s.

import 'package:flutter/foundation.dart';

/// Helix avatar moods → an expression in widgets/helix_avatar.dart.
enum Mood { curious, surprised, idea, celebrating, confused }

/// A single line + the face Helix wears while saying it.
@immutable
class HelixLine {
  const HelixLine(this.text, this.mood);
  final String text;
  final Mood mood;
}

/// onIdle escalation: fire 1 encourages, fire 2 points. Each with its own mood.
@immutable
class IdleConfig {
  const IdleConfig(this.fires, {this.cooldownMs = 8000});
  final List<HelixLine> fires;
  final int cooldownMs;
  int get maxFires => fires.length;
}

/// The per-beat config (PRD §5). The host emits physical milestones; the engine
/// owns when each socket actually speaks.
@immutable
class BeatConfig {
  const BeatConfig({
    required this.id,
    this.before, // sets pressure / points, on beat entry
    this.after, // light naming (name-last), played at the host's cue
    this.onDiscovery, // the exempt reaction AT the kid's discovery
    this.onIdle, // ~7s, sparing, single escalation
    this.onCounterproductive, // often null — the socket still fires (criterion 9)
    this.firesCollectible = false, // emit the card when [after] commits
  });

  final String id;
  final HelixLine? before;
  final HelixLine? after;
  final HelixLine? onDiscovery;
  final IdleConfig? onIdle;
  final HelixLine? onCounterproductive;
  final bool firesCollectible;
}

/// The current utterance + a monotonic token (so the host detects a NEW line
/// even when text repeats) + the mood the avatar should wear.
@immutable
class HelixUtterance {
  const HelixUtterance(this.text, this.token, this.mood);
  final String text;
  final int token;
  final Mood mood;
}

/// Drives Helix across beats. The host (the controller) calls the report* /
/// play* methods at physical moments; the engine gates and schedules.
class HelixBeatEngine {
  HelixBeatEngine({
    required this.onLine,
    this.onAfterCommitted,
    this.onFireCollectible,
  });

  final void Function(HelixUtterance line) onLine;

  /// Fired when a beat's [after] line commits — the host advances / opens the
  /// next beat from here.
  final void Function(BeatConfig beat)? onAfterCommitted;

  /// Fired when an after-line whose beat declares [firesCollectible] commits.
  final void Function()? onFireCollectible;

  BeatConfig? _beat;
  int _token = 0;
  int _idleFires = 0;
  bool _engaged = false;
  double _idleCooldown = 0;

  final List<_Scheduled> _queue = [];

  void _log(String m) {
    if (kDebugMode) debugPrint('[helix] $m');
  }

  /// Speak immediately (the host uses this for ad-hoc per-artifact reactions).
  void emit(HelixLine line) {
    _token++;
    onLine(HelixUtterance(line.text, _token, line.mood));
  }

  void _schedule(HelixLine line, int delayMs, {VoidCallback? then}) =>
      _queue.add(_Scheduled(line, delayMs.toDouble(), then));

  /// Start a beat: reset idle bookkeeping and (optionally) speak its before-line.
  void enterBeat(BeatConfig beat, {bool emitBefore = true}) {
    _beat = beat;
    _idleFires = 0;
    _engaged = false;
    _idleCooldown = 0;
    if (emitBefore && beat.before != null) {
      _log('${beat.id} → before (${beat.before!.mood.name})');
      emit(beat.before!);
    }
  }

  void markEngaged() => _engaged = true;

  /// No meaningful progress for the host's idle window — escalates once, gated by
  /// cooldown, suppressed once engaged. (Reactive socket #1.)
  void reportIdle() {
    final beat = _beat;
    final idle = beat?.onIdle;
    if (idle == null || _engaged) return;
    if (_idleFires >= idle.maxFires || _idleCooldown > 0) return;
    final line = idle.fires[_idleFires];
    _idleFires++;
    _idleCooldown = idle.cooldownMs.toDouble();
    _log('${beat!.id} → idle $_idleFires/${idle.maxFires}');
    emit(line);
  }

  /// The kid did the thing — fire the (suppression-exempt) discovery reaction and
  /// stop nudging. (Reactive socket #2.)
  void reportDiscovery() {
    final beat = _beat;
    markEngaged();
    final line = beat?.onDiscovery;
    if (line == null) return;
    _log('${beat!.id} → discovery (${line.mood.name})');
    emit(line);
  }

  /// A counterproductive action — often no line here, but the socket still fires
  /// (criterion 9): wiring it now means later beats only add copy. (Socket #3.)
  void reportCounterproductive() {
    final beat = _beat;
    final line = beat?.onCounterproductive;
    _log('${beat?.id} → counterproductive (${line == null ? "stubbed" : line.mood.name})');
    if (line != null) emit(line);
  }

  /// Schedule the beat's after-line (light naming, name-last); fires the
  /// collectible on commit if the beat declares one. The host calls this at the
  /// right physical moment per beat.
  void playAfter({int delayMs = 0}) {
    final beat = _beat;
    final line = beat?.after;
    if (beat == null || line == null) return;
    _schedule(line, delayMs, then: () {
      _log('${beat.id} → after (${line.mood.name})${beat.firesCollectible ? " + card" : ""}');
      if (beat.firesCollectible) onFireCollectible?.call();
      onAfterCommitted?.call(beat);
    });
  }

  /// Speak an ad-hoc line after a delay (the per-artifact reactions in 0.3).
  void say(HelixLine line, {int delayMs = 0}) => _schedule(line, delayMs);

  void update(double dtMs) {
    if (_idleCooldown > 0) _idleCooldown -= dtMs;
    if (_queue.isEmpty) return;
    // Iterate a snapshot — a fired line's `then` may schedule the next one.
    for (final s in List.of(_queue)) {
      s.remainMs -= dtMs;
      if (s.remainMs <= 0) {
        _queue.remove(s);
        emit(s.line);
        s.then?.call();
      }
    }
  }
}

class _Scheduled {
  _Scheduled(this.line, this.remainMs, this.then);
  final HelixLine line;
  double remainMs;
  final VoidCallback? then;
}
