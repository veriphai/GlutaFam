// Ember — sim/away_digest.dart
//
// The "while you were away" summary the offline catch-up accumulates: how long
// passed, how many sim steps ran, and a human-readable line per event that fired
// (built from EventOutcomes). Pure value object — the UI renders it after a
// catch-up. No clock/random of its own; it just collects what the sim produced.

import '../contracts/event_resolver.dart';
import '../core/enums.dart';

/// One line in the digest (one event that happened while away).
class AwayDigestLine {
  const AwayDigestLine({
    required this.type,
    required this.headline,
    this.detail = '',
    this.severity = 0.0,
  });

  final WorldEventType type;
  final String headline;
  final String detail;
  final double severity;

  /// Builds a line from a resolved [EventOutcome].
  factory AwayDigestLine.fromOutcome(EventOutcome o) => AwayDigestLine(
        type: o.type,
        headline: o.headline,
        detail: o.detail,
        severity: o.severity,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'headline': headline,
        'detail': detail,
        'severity': severity,
      };

  factory AwayDigestLine.fromJson(Map<String, dynamic> j) => AwayDigestLine(
        type: worldEventTypeFromName(j['type']),
        headline: j['headline'] as String? ?? '',
        detail: j['detail'] as String? ?? '',
        severity: (j['severity'] as num?)?.toDouble() ?? 0.0,
      );
}

/// The accumulated summary of an offline catch-up window.
class AwayDigest {
  AwayDigest({
    this.elapsedMs = 0,
    this.cappedElapsedMs = 0,
    this.stepsRun = 0,
    List<AwayDigestLine>? lines,
  }) : lines = lines ?? <AwayDigestLine>[];

  /// Real time elapsed since lastSeen (before the 12h cap).
  final int elapsedMs;

  /// The elapsed time actually simulated (after clamping to the cap).
  final int cappedElapsedMs;

  /// How many fixed sim steps were run during catch-up.
  final int stepsRun;

  /// One line per event that fired while away (time order).
  final List<AwayDigestLine> lines;

  bool get wasCapped => elapsedMs > cappedElapsedMs;
  bool get isEmpty => lines.isEmpty && cappedElapsedMs == 0;
  bool get hasEvents => lines.isNotEmpty;
  int get eventCount => lines.length;

  /// Appends an outcome as a digest line (mutates in place; used during the run).
  void addOutcome(EventOutcome o) => lines.add(AwayDigestLine.fromOutcome(o));

  AwayDigest copyWith({
    int? elapsedMs,
    int? cappedElapsedMs,
    int? stepsRun,
    List<AwayDigestLine>? lines,
  }) {
    return AwayDigest(
      elapsedMs: elapsedMs ?? this.elapsedMs,
      cappedElapsedMs: cappedElapsedMs ?? this.cappedElapsedMs,
      stepsRun: stepsRun ?? this.stepsRun,
      lines: lines ?? List<AwayDigestLine>.of(this.lines),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'elapsedMs': elapsedMs,
        'cappedElapsedMs': cappedElapsedMs,
        'stepsRun': stepsRun,
        'lines': <Map<String, dynamic>>[
          for (final AwayDigestLine l in lines) l.toJson(),
        ],
      };

  factory AwayDigest.fromJson(Map<String, dynamic> j) => AwayDigest(
        elapsedMs: (j['elapsedMs'] as num?)?.toInt() ?? 0,
        cappedElapsedMs: (j['cappedElapsedMs'] as num?)?.toInt() ?? 0,
        stepsRun: (j['stepsRun'] as num?)?.toInt() ?? 0,
        lines: <AwayDigestLine>[
          for (final dynamic e in (j['lines'] as List?) ?? const <dynamic>[])
            AwayDigestLine.fromJson((e as Map).cast<String, dynamic>()),
        ],
      );
}
