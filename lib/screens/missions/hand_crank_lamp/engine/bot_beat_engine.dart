// bot_beat_engine — Voltix's dialogue engine for beat P.1 (and the template for
// all 28 beats). See voltix_voice_and_prologue_dialogue.md.
//
// Voltix is a COMPANION, not a narrator: he reacts and points, he never
// explains. The cardinal rule is encoded structurally — the discovery beat
// carries a short REACTION (mood: surprised) fired AT the cutoff, and the only
// light "naming" is the synthesis line, fired LAST, after the kid has felt the
// pattern across a couple of devices.
//
// Each line carries an AVATAR MOOD (the face is load-bearing: a surprised face
// at the kid's discovery experiences it WITH them; a lightbulb/idea face there
// would silently steal the discovery). Timing is load-bearing too — reactions
// fire AS the thing happens, driven by physics milestones the host emits.
//
// Firing order: intro/before → (idle) → firstLit → discovery → afterLine →
// swapInvitation → device-swap reactions → synthesis → outro.

import 'package:flutter/foundation.dart';

/// Voltix avatar moods (→ a sprite in widgets/voltix_helper.dart).
enum VoltixMood {
  wave,
  thinking,
  idea,
  celebrating,
  confused,
  confident,
  thumbsUp,
  surprised,
}

/// A single line + the face Voltix wears while saying it.
@immutable
class VoltixLine {
  const VoltixLine(this.text, this.mood);
  final String text;
  final VoltixMood mood;
}

/// onIdle escalation: fire 1 encourages, fire 2 hints. Each with its own mood.
@immutable
class IdleConfig {
  const IdleConfig(this.fires, {this.cooldownMs = 8000});
  final List<VoltixLine> fires;
  final int cooldownMs;
  int get maxFires => fires.length;
}

/// A brief visual emphasis (the ring/flash on the lamp + wire at the cutoff).
@immutable
class VisualEmphasis {
  const VisualEmphasis({this.id = 'default'});
  final String id;
}

/// The full per-beat config. Device-swap reaction lines live separately (keyed
/// by output) so this stays decoupled from the P.1 output enum — the host looks
/// them up and feeds them via [reportDeviceSwap].
@immutable
class BeatConfig {
  const BeatConfig({
    required this.introLine,
    required this.beforeLine,
    required this.discovery,
    required this.afterLine,
    required this.swapInvitation,
    required this.generalisation,
    required this.outro,
    required this.onIdle,
    this.onFirstLit,
    this.discoveryVisual = const VisualEmphasis(id: 'cutoff_ring'),
    this.idleThresholdMs = 7000,
    this.discoveryToAfterMs = 400,
    this.swapInviteDelayMs = 3000,
    this.generalisationDelayMs = 2600,
    this.generalisationFallbackMs = 9000,
    this.outroDelayMs = 3600,
  });

  final VoltixLine introLine; // first session only
  final VoltixLine beforeLine; // every later run
  final VoltixLine? onFirstLit; // optional warm reaction at first light
  final VoltixLine discovery; // AT the cutoff (with the visual)
  final VoltixLine afterLine; // light naming, a beat later
  final VoltixLine swapInvitation; // open invitation, after the naming lands
  final VoltixLine generalisation; // the one synthesis, after ~2 swaps
  final VoltixLine outro; // closing hook into Episode 1

  final IdleConfig onIdle;
  final VisualEmphasis discoveryVisual;

  final int idleThresholdMs;
  final int discoveryToAfterMs; // discovery → afterLine gap
  final int swapInviteDelayMs; // afterLine → swapInvitation gap
  final int generalisationDelayMs; // 2nd swap reaction → synthesis
  final int generalisationFallbackMs; // 1 swap only → synthesis (fallback)
  final int outroDelayMs; // synthesis → outro
}

/// The current utterance + a monotonic token (so the host detects a NEW line
/// even when text repeats) + the mood the avatar should wear.
@immutable
class BotUtterance {
  const BotUtterance(this.text, this.token, this.mood);
  final String text;
  final int token;
  final VoltixMood mood;
}

/// Drives Voltix for ONE beat. The host emits physics milestones; the engine
/// owns gating, timing, and the firing order.
class BotBeatEngine {
  BotBeatEngine({
    required this.config,
    required this.onLine,
    required this.onDiscoveryVisual,
    this.onOutro,
  });

  final BeatConfig config;
  final void Function(BotUtterance line) onLine;
  final void Function(VisualEmphasis visual) onDiscoveryVisual;

  /// Fired when the outro line lands — the host can reveal a "Continue" CTA.
  final void Function()? onOutro;

  // --- State -----------------------------------------------------------------
  bool _entered = false;
  bool _firstLitFired = false;
  bool _discoveryFired = false;
  bool _afterFired = false;
  bool _swapInviteFired = false;
  bool _generalisationFired = false;
  bool _outroFired = false;

  int _idleFires = 0;
  int _swapReactions = 0;
  int _token = 0;
  double _idleCooldown = 0;

  // Scheduled lines (ms remaining; -1 = inactive).
  double _afterPending = -1;
  double _swapInvitePending = -1;
  double _generalisationPending = -1;
  double _outroPending = -1;

  bool get discoveryFired => _discoveryFired;

  void _log(String msg) {
    if (kDebugMode) debugPrint('[voltix] $msg');
  }

  void _emit(VoltixLine line) {
    _token++;
    onLine(BotUtterance(line.text, _token, line.mood));
  }

  // --- Beats -----------------------------------------------------------------
  /// Entry. First-ever session → the one-time intro (voltix_wave); every later
  /// run → the plain beforeLine (voltix_confident).
  void enter({required bool firstSession}) {
    if (_entered) return;
    _entered = true;
    final line = firstSession ? config.introLine : config.beforeLine;
    _log('enter → ${firstSession ? 'introLine' : 'beforeLine'} (${line.mood.name})');
    _emit(line);
  }

  /// No meaningful progress for idleThresholdMs — gated, only BEFORE the learner
  /// engages, escalates once (encourage → hint).
  void reportIdle() {
    if (_firstLitFired || _discoveryFired) return; // engaged → stop nudging
    if (_idleFires >= config.onIdle.maxFires) return;
    if (_idleCooldown > 0) return;
    final line = config.onIdle.fires[_idleFires];
    _idleFires++;
    _idleCooldown = config.onIdle.cooldownMs.toDouble();
    _log('onIdle fire=$_idleFires/${config.onIdle.maxFires} (${line.mood.name})');
    _emit(line);
  }

  /// Brightness crossed clearlyLitThreshold — optional warm "there it is"
  /// (voltix_thumbs_up). Names nothing; the discovery is the STOP, not the light.
  void reportFirstLight() {
    if (_firstLitFired || _discoveryFired) return;
    _firstLitFired = true;
    final line = config.onFirstLit;
    if (line == null) return;
    _log('firstLight → onFirstLit (${line.mood.name})');
    _emit(line);
  }

  /// First stop after the lamp was clearly lit. Fires the suppression-exempt
  /// VISUAL and the discovery REACTION simultaneously, AT the cutoff
  /// (voltix_surprised — amazed WITH the kid), then schedules afterLine.
  void triggerDiscovery() {
    if (_discoveryFired) return;
    _discoveryFired = true;
    _log('discovery → visual + reaction (surprised) @ cutoff');
    onDiscoveryVisual(config.discoveryVisual);
    _emit(config.discovery);
    _afterPending = config.discoveryToAfterMs.toDouble();
  }

  /// The learner swapped to a non-lamp device the host hasn't reacted to yet.
  /// React (point, never name) on the first two only, then go quiet; the
  /// synthesis is scheduled after ~2 reactions (or a fallback if they try one).
  void reportDeviceSwap(VoltixLine line) {
    _swapInvitePending = -1; // they swapped — cancel the invite
    if (_generalisationFired) return;
    if (_swapReactions < 2) {
      _swapReactions++;
      _log('deviceSwap reaction #$_swapReactions (${line.mood.name})');
      _emit(line);
    }
    // Schedule the synthesis: soon after the 2nd reaction, or a longer fallback
    // if the kid only tries one device.
    _generalisationPending = (_swapReactions >= 2
            ? config.generalisationDelayMs
            : config.generalisationFallbackMs)
        .toDouble();
  }

  // --- Tick ------------------------------------------------------------------
  void update(double dtMs) {
    if (_idleCooldown > 0) _idleCooldown -= dtMs;

    if (_afterPending > 0) {
      _afterPending -= dtMs;
      if (_afterPending <= 0) {
        _afterPending = -1;
        _afterFired = true;
        _log('afterLine (thinking)');
        _emit(config.afterLine);
        _swapInvitePending = config.swapInviteDelayMs.toDouble();
      }
    }

    if (_swapInvitePending > 0) {
      _swapInvitePending -= dtMs;
      if (_swapInvitePending <= 0) {
        _swapInvitePending = -1;
        // Only invite if they haven't already started swapping.
        if (_swapReactions == 0 && !_swapInviteFired) {
          _swapInviteFired = true;
          _log('swapInvitation (idea)');
          _emit(config.swapInvitation);
        }
      }
    }

    if (_generalisationPending > 0) {
      _generalisationPending -= dtMs;
      if (_generalisationPending <= 0) {
        _generalisationPending = -1;
        if (!_generalisationFired) {
          _generalisationFired = true;
          _log('synthesis (confident)');
          _emit(config.generalisation);
          _outroPending = config.outroDelayMs.toDouble();
        }
      }
    }

    if (_outroPending > 0) {
      _outroPending -= dtMs;
      if (_outroPending <= 0) {
        _outroPending = -1;
        if (!_outroFired) {
          _outroFired = true;
          _log('outro (thinking) → finish available');
          _emit(config.outro);
          onOutro?.call();
        }
      }
    }
  }

  // referenced by guards above; kept for the contract's completeness.
  bool get afterFired => _afterFired;
}
