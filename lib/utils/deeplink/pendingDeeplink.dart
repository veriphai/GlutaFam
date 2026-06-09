// SharedPreferences-backed single-slot store for a deeplink URL that
// arrived while the user was unauthenticated.
//
// The router stashes the URL here, routes to the login screen, and the
// post-login flow consumes it before falling through to the default home
// route. Survives cold-launch because notifications can arrive while the
// app is killed and the user is signed-out.

import 'package:shared_preferences/shared_preferences.dart';

class PendingDeeplink {
  PendingDeeplink._();

  static const String _kKey = 'howwow_pending_deeplink';

  /// Persist a URL to be consumed after the next successful login. Overwrites
  /// any older pending URL — only the most recent intent matters.
  static Future<void> set(Uri uri) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, uri.toString());
    } catch (_) {
      // Persistence failure is non-fatal — worst case the user lands on
      // home after login and has to tap the notification again.
    }
  }

  /// Read + delete the pending URL atomically. Returns null when none is
  /// stored. Callers in the post-login flow invoke this once; the
  /// returned Uri is then handed to the router for navigation.
  static Future<Uri?> consume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return null;
      await prefs.remove(_kKey);
      return Uri.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Peek at the pending URL without consuming it. Useful for tests; not
  /// used in production paths.
  static Future<Uri?> peek() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return null;
      return Uri.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Drop any pending URL. Called on logout so the next user doesn't
  /// inherit an old pending deeplink from a previous session.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kKey);
    } catch (_) {}
  }
}
