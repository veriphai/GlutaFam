// The flow packets that ride INSIDE the hero wire — the brightest, most alive
// thing on screen — plus a few quiet ambient motes behind it. The choke/surge IS
// the lesson: thin = a sparse, slow, single-file trickle; fat = a wide, fast,
// multi-lane braided stream. Density (count), speed, lane count and lane spread
// all key off the (relative) current, so the flow reads as the answer with all
// captions off (acceptance §4).
//
// This is the 2.1 current-river craft ported into the wire: each ACTIVE packet is
// a head the painter walks down the cable; the painter draws a short fading TRAIL
// of samples behind each head (riverTrailSamples) for the alive, streaming read.
//
// Pooled + deterministic: a fixed pool of slots, only [activeCount] of them
// drawn, so there is no per-frame allocation in the paint path.

import 'dart:math' as math;

import '../config/resistance_tuning.dart';

/// One packet of charge gliding down the wire. [u] is its head position along the
/// wire (0 = top terminal → 1 = wire end); [lane] is its signed cross-wire offset
/// (−1..1) scaled to the wire's current width at render time.
class FlowPacket {
  double u = 0;
  double lane = 0;
  double size = 1;
  double seed = 0;
}

class FlowField {
  FlowField({int seed = 7}) {
    final rng = math.Random(seed);
    _packets = List.generate(RTune.packetCountMax, (i) {
      final p = FlowPacket()
        ..u = rng.nextDouble()
        ..lane = rng.nextDouble() * 2 - 1
        ..size = 0.8 + rng.nextDouble() * 0.5
        ..seed = rng.nextDouble();
      return p;
    });
    _motes = List.generate(_moteCount, (i) {
      return FlowMote()
        ..x = rng.nextDouble()
        ..y = rng.nextDouble()
        ..r = 0.6 + rng.nextDouble() * 1.6
        ..speed = 0.006 + rng.nextDouble() * 0.014
        ..seed = rng.nextDouble();
    });
  }

  late final List<FlowPacket> _packets;
  late final List<FlowMote> _motes;

  static const int _moteCount = 18; // ≤20 ambient motes (clutter cap §7)

  int _activeCount = RTune.packetCountMin;
  int get activeCount => _activeCount;

  /// How many lanes the river currently braids into (1 = single file when thin).
  int _laneCount = 1;
  int get laneCount => _laneCount;

  /// The packets currently in flight (only the first [activeCount] of the pool).
  List<FlowPacket> get packets => _packets;

  List<FlowMote> get motes => _motes;

  /// Advance the field. [currentNorm] is relative current / 100 (1 = mid wire);
  /// [reducedMotion] thins the field and slows it for calm. The packets march
  /// down the wire at a speed compressed from the current so a 9× swing stays
  /// legible. On reaching the end they wrap to the top (a continuous stream).
  void tick(double dt, double currentNorm,
      {bool reducedMotion = false, int lanesAfforded = 3}) {
    final i = currentNorm.clamp(0.05, 6.0);
    final f = (i / 4.0).clamp(0.0, 1.0); // 0 (thin) → 1 (≈fat)

    // Count ∝ current, compressed into [min, max] — thin trickle ↔ fat torrent.
    final span = (RTune.packetCountMax - RTune.packetCountMin).toDouble();
    var count = RTune.packetCountMin + span * f;
    if (reducedMotion) count *= 0.6;
    _activeCount = count.round().clamp(RTune.packetCountMin, RTune.packetCountMax);

    // Lane count braids open as the cable widens AND the current rises — single
    // file when thin (geometry won't afford lanes anyway), multi-lane when fat.
    _laneCount = (1 + (f * 3).round()).clamp(1, lanesAfforded).clamp(1, 4);

    // Speed ∝ I^0.6 (legibility compression). Base tuned so the mid wire reads
    // as a steady march, fat as a rush, thin as a crawl.
    final speed = math.pow(i, RTune.flowSpeedExponent).toDouble() *
        (reducedMotion ? 0.34 : 0.58);

    for (var k = 0; k < _activeCount; k++) {
      final p = _packets[k];
      p.u += speed * dt;
      if (p.u >= 1.0) {
        p.u -= 1.0;
        // re-lane on re-entry into a discrete braided lane so the stream reads as
        // 1..laneCount columns, not a rigid grid (jittered within the lane).
        final lane = k % _laneCount;
        final center = _laneCount == 1 ? 0.0 : (lane / (_laneCount - 1)) * 2 - 1;
        p.lane = (center + (p.seed - 0.5) * 0.5).clamp(-1.0, 1.0);
      }
    }

    for (final m in _motes) {
      m.y -= m.speed * dt * (reducedMotion ? 0.4 : 1.0);
      if (m.y < -0.04) {
        m.y = 1.04;
        m.x = (m.x + 0.37 + m.seed) % 1.0;
      }
    }
  }
}

/// A quiet ambient dust mote drifting behind the hero (normalized x/y in 0..1).
class FlowMote {
  double x = 0;
  double y = 0;
  double r = 1;
  double speed = 0.01;
  double seed = 0;
}
