// The Leaky Bucket — a pure PHASE + TIMER machine for the build-and-watch-it-leak
// DEMONSTRATION (no mascot, no dialogue, no puzzle, no plugging). It owns the beat
// timing and the top-text: short imperatives (the actions) + de-personified
// meaning-lines (the lesson). The visuals carry the per-stage leaking; the text
// just names the payoff.
//
// Flow: Build the Plant → (all 4 machines snapped in) Power It Up → [power-up
// reveals the leaks] → "So Much Fuel, So Little Light" → "The 'Lost' Energy Became
// Heat" → "Every Step Leaks Some — You Can't Catch It All" → Card 04 → "The Wires
// Ahead Leak Too" (transmission hand-off) → finish.

import '../config/leaky_tuning.dart';

enum LBPhase { build, powering, realize, closing }

class LeakyBotEngine {
  LeakyBotEngine({
    required this.onInstruction,
    required this.onPhase,
    required this.onFireCard,
    required this.onOutro,
  });

  final void Function(String text) onInstruction;
  final void Function(LBPhase phase) onPhase;
  final void Function() onFireCard;
  final void Function() onOutro;

  // Top-text (imperatives) + meaning-lines (the lesson).
  static const String tBuild = 'Build the Plant';
  static const String tPower = 'Power It Up';
  static const String tSurprise = 'So Much Fuel, So Little Light';
  static const String tRealize = 'The ‘Lost’ Energy Became Heat';
  static const String tBounded = 'Every Step Leaks Some — You Can’t Catch It All';
  static const String tHandoff = 'The Wires Ahead Leak Too';

  bool _entered = false;
  bool _builtFired = false;
  bool _poweredFired = false;
  bool _outroFired = false;

  // Scheduled meaning-lines (ms remaining; -1 = inactive).
  double _surprisePending = -1;
  double _realizePending = -1;
  double _boundedPending = -1;
  double _cardPending = -1;

  void enter() {
    if (_entered) return;
    _entered = true;
    onPhase(LBPhase.build);
    onInstruction(tBuild);
  }

  /// All four machines are snapped in — invite the power-up.
  void reportBuilt() {
    if (_builtFired) return;
    _builtFired = true;
    onInstruction(tPower);
  }

  /// The kid tapped Power It Up — the reveal begins (the visuals carry it).
  void reportPowerStart() {
    onPhase(LBPhase.powering);
    onInstruction('');
  }

  /// The power-up sweep reached the bulb (dim) — fire the lesson sequence.
  void reportPowered() {
    if (_poweredFired) return;
    _poweredFired = true;
    _surprisePending = LBTune.poweredToSurpriseMs.toDouble();
  }

  /// The kid added Card 04 to the deck → the transmission hand-off, then finish.
  void onCardCollected() {
    if (_outroFired) return;
    _outroFired = true;
    onPhase(LBPhase.closing);
    onInstruction(tHandoff);
    onOutro();
  }

  void update(double dtMs) {
    if (_surprisePending > 0) {
      _surprisePending -= dtMs;
      if (_surprisePending <= 0) {
        _surprisePending = -1;
        onPhase(LBPhase.realize);
        onInstruction(tSurprise);
        _realizePending = LBTune.surpriseToRealizeMs.toDouble();
      }
    }
    if (_realizePending > 0) {
      _realizePending -= dtMs;
      if (_realizePending <= 0) {
        _realizePending = -1;
        onInstruction(tRealize);
        _boundedPending = LBTune.realizeToBoundedMs.toDouble();
      }
    }
    if (_boundedPending > 0) {
      _boundedPending -= dtMs;
      if (_boundedPending <= 0) {
        _boundedPending = -1;
        onInstruction(tBounded);
        _cardPending = LBTune.boundedToCardMs.toDouble();
      }
    }
    if (_cardPending > 0) {
      _cardPending -= dtMs;
      if (_cardPending <= 0) {
        _cardPending = -1;
        onFireCard();
      }
    }
  }
}
