// Singleton client-side analytics logger for the howwow event stream.
//
// Two delivery modes:
//   • log(eventType, props)         — batched. Queued in memory + persisted
//     to SharedPreferences. Flushed every 30 s, on app pause, and when
//     the queue size hits 50.
//   • logImmediate(eventType, props) — single POST, fire-and-forget. Use
//     for events you want to see in real time even if the user kills the
//     app in the next 100 ms (auth outcomes, lesson lifecycle markers).
//
// Both modes attach a stable {@link _anonymousId} (device UUID kept in
// SharedPreferences), a {@link _sessionId} that rotates per app launch,
// and the current {@link _userId} once set via {@link #setUserId}.
//
// All network calls are wrapped in try/catch — analytics failures must
// NEVER bubble up to the UI. The persistent queue handles retry on the
// next flush attempt.
//
// Initialise once from main.dart (before runApp) via:
//   await HowwowEventLogger.instance.init();

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../apis/howwow/howwowEvents.dart';

class HowwowEventLogger {
  HowwowEventLogger._();
  static final HowwowEventLogger instance = HowwowEventLogger._();

  /// SharedPreferences key for the persisted offline queue.
  static const String _kQueueKey = 'howwow_event_queue';

  /// SharedPreferences key for the device-stable anonymousId.
  static const String _kAnonymousIdKey = 'howwow_anonymous_id';

  /// Time between automatic flush attempts.
  static const Duration _flushInterval = Duration(seconds: 30);

  /// Queue size at which we proactively flush rather than wait for the timer.
  static const int _flushAtSize = 50;

  /// Hard cap on in-memory queue size — oldest dropped beyond this so a
  /// week-long offline run doesn't OOM the app.
  static const int _maxQueueSize = 500;

  /// Backend cap on batch size — slice if our queue exceeds this.
  static const int _maxBatchPerCall = 200;

  bool _initialized = false;
  bool _flushInProgress = false;
  String _anonymousId = '';
  String _sessionId = '';
  String? _appVersion;
  String _platform = 'unknown';
  String? _userId;

  final List<Map<String, dynamic>> _queue = [];
  Timer? _flushTimer;

  // ── lifecycle ──────────────────────────────────────────────────────

  /// Must be called once from main() BEFORE the first log() / logImmediate().
  /// Loads the persistent queue, mints / restores the anonymousId, mints
  /// a fresh sessionId, and kicks off the periodic flush timer.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // Device-stable anonymousId — survives logout, app updates, but NOT
    // app uninstall (Android limits cross-install storage). Good enough
    // for product analytics.
    _anonymousId = prefs.getString(_kAnonymousIdKey) ?? '';
    if (_anonymousId.isEmpty) {
      _anonymousId = const Uuid().v4();
      await prefs.setString(_kAnonymousIdKey, _anonymousId);
    }

    // Fresh sessionId every cold-start. Doesn't survive backgrounding —
    // that's a different "session" semantically and is correct.
    _sessionId = const Uuid().v4();

    _platform = _detectPlatform();
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // PackageInfo failure → fallback to null, harmless.
    }

    // Restore offline queue.
    final raw = prefs.getString(_kQueueKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          if (e is Map) _queue.add(Map<String, dynamic>.from(e));
        }
      } catch (_) {
        // Corrupt cache — start fresh.
        await prefs.remove(_kQueueKey);
      }
    }

    _initialized = true;
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => unawaited(flush()));

    // Drain anything that was sitting from a previous launch.
    if (_queue.isNotEmpty) unawaited(flush());
  }

  /// Call after login succeeds so subsequent events carry the userId. Set
  /// to null on logout.
  void setUserId(String? userId) {
    _userId = (userId != null && userId.isNotEmpty) ? userId : null;
  }

  /// Stop the timer. Pair with [init] in test/teardown.
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  // ── public log API ─────────────────────────────────────────────────

  /// Queue an event for batched delivery.
  void log(String eventType, {Map<String, dynamic>? props}) {
    if (!_initialized) {
      // ignore: avoid_print
      print('HowwowEventLogger.log("$eventType") called before init()');
      return;
    }
    _queue.add(_buildEvent(eventType, props));
    // Bound memory if the queue grows unchecked offline.
    while (_queue.length > _maxQueueSize) {
      _queue.removeAt(0);
    }
    // Non-blocking persist so a synchronous log() returns fast.
    unawaited(_persistQueue());
    if (_queue.length >= _flushAtSize) {
      unawaited(flush());
    }
  }

  /// Send one event immediately via the single-event endpoint.
  /// Fire-and-forget — the call does not wait for the network round trip.
  void logImmediate(String eventType, {Map<String, dynamic>? props}) {
    if (!_initialized) {
      // ignore: avoid_print
      print('HowwowEventLogger.logImmediate("$eventType") called before init()');
      return;
    }
    unawaited(howwowPostEvent(_buildEvent(eventType, props)));
  }

  /// Force-flush the queue. Call from app-pause lifecycle, on logout,
  /// or any time you want a clean drain. Safe to await; safe to fire-
  /// and-forget. Failures keep the events in the queue for retry.
  Future<void> flush() async {
    if (!_initialized) return;
    if (_flushInProgress) return;
    if (_queue.isEmpty) return;

    _flushInProgress = true;
    try {
      // Slice — backend caps at _maxBatchPerCall events per call. Do
      // one slice per flush invocation; the next timer tick (or the
      // next size-threshold trigger) picks up the rest.
      final batchSize = _queue.length > _maxBatchPerCall
          ? _maxBatchPerCall
          : _queue.length;
      final snapshot = List<Map<String, dynamic>>.from(_queue.take(batchSize));
      final ok = await howwowPostEventBatch(snapshot);
      if (ok) {
        _queue.removeRange(0, batchSize);
        await _persistQueue();
      }
      // On failure: keep the queue — next flush retries.
    } finally {
      _flushInProgress = false;
    }
  }

  // ── internals ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildEvent(String eventType, Map<String, dynamic>? props) {
    return {
      'eventType': eventType,
      'props': props ?? <String, dynamic>{},
      'clientTs': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'sessionId': _sessionId,
      'anonymousId': _anonymousId,
      if (_userId != null) 'userId': _userId,
      if (_appVersion != null) 'appVersion': _appVersion,
      'platform': _platform,
    };
  }

  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_queue.isEmpty) {
        await prefs.remove(_kQueueKey);
      } else {
        await prefs.setString(_kQueueKey, jsonEncode(_queue));
      }
    } catch (_) {
      // Storage write failure is non-fatal — events remain in memory.
    }
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      // Platform check failures are exceedingly rare; fall through to default.
    }
    return 'unknown';
  }
}
