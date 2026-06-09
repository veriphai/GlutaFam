// Howwow analytics ingest — single + batch.
//
// These are the low-level API methods called by lib/utils/howwowEventLogger.dart.
// They DO NOT throw on failure — analytics events are non-critical, and a
// transient 500 should never break the foreground flow. Errors are
// debugPrint'd and swallowed; the logger handles retries via the
// SharedPreferences queue.
//
// Auth: optional. The endpoint accepts anonymous posts so pre-login
// events (welcome-screen taps, login_attempted) are captured under the
// device's anonymousId. When a Bearer is present the server overrides
// userId with the authoritative JWT-derived id.

import 'package:flutter/foundation.dart';

import '../apiClient.dart';
import '../endpoints.dart';

/// POST `/howwow/events` — fire one event immediately, fire-and-forget.
Future<void> howwowPostEvent(Map<String, dynamic> event) async {
  try {
    await ApiClient.instance.postJson(
      Endpoints.howwow('/events'),
      body: event,
    );
  } catch (e) {
    debugPrint('howwowPostEvent failed (non-fatal): $e');
  }
}

/// POST `/howwow/events/batch` — flush a queue. Backend caps at 200 per
/// call, so the logger slices before invoking.
///
/// Returns true on success; false on failure so the logger keeps the
/// batch in its persistent queue for the next flush attempt.
Future<bool> howwowPostEventBatch(List<Map<String, dynamic>> events) async {
  if (events.isEmpty) return true;
  try {
    await ApiClient.instance.postJson(
      Endpoints.howwow('/events/batch'),
      body: events,
    );
    return true;
  } catch (e) {
    debugPrint('howwowPostEventBatch failed (non-fatal): $e');
    return false;
  }
}
