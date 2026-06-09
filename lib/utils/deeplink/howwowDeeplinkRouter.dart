// Single entry point for routing every howwow deeplink.
//
// Inputs:
//   • app_links cold-start URI (passed in from main.dart after init).
//   • app_links foreground stream (one event per URL while the app is running).
//   • FCM notification taps — NotificationService extracts the `data.url`
//     and hands it here.
//   • Manually-fired URLs (e.g. dev tools / debug menu).
//
// Behaviour:
//   1. Parse the URL via [parseHowwowDeeplink]. Unknown URLs return null
//      and we silently no-op.
//   2. Fire the `notification_tapped` analytics event (immediate) before
//      doing anything else, so we capture intent even if navigation
//      bails out below.
//   3. If the destination requires auth and there's no stored Bearer,
//      stash the URL in [PendingDeeplink] and route to the login screen.
//   4. Otherwise navigate via the global [navigatorKey].
//
// Locked-lesson policy (per design option A): URLs targeting a lesson the
// user hasn't unlocked land on the profession-detail screen with the
// lesson visibly locked. {@code ?action=start} on a locked lesson is
// honoured only on unlocked lessons — the screen's auto-start hook checks
// the unlock state and silently no-ops when locked.

import 'package:flutter/material.dart';

import '../../screens/auth/howwowLoginScreen.dart';
import '../../screens/home/career/careerHomeScreen.dart';
import '../../screens/home/career/professionDetailScreen.dart';
import '../authTokenService.dart';
import '../howwowEventLogger.dart';
import '../howwowEventNames.dart';
import '../navigation_utils.dart';
import 'howwowDeeplink.dart';
import 'pendingDeeplink.dart';

class HowwowDeeplinkRouter {
  HowwowDeeplinkRouter._();

  /// Public entry point. Safe to call from any thread; the actual
  /// navigation runs through the global navigator on the main isolate.
  /// {@code defaultSource} is "push" for FCM tap origin, "external" for
  /// app_links (custom-scheme launch), etc. — used only for analytics
  /// when the URL itself doesn't carry a `?source=...` param.
  static Future<void> handle(Uri uri, {String defaultSource = 'external'}) async {
    final dl = parseHowwowDeeplink(uri);
    if (dl == null) {
      debugPrint('howwow deeplink: unrecognised URL — $uri');
      return;
    }

    // Analytics first so we capture intent even if downstream navigation
    // bails out (no navigator, no context, etc.).
    HowwowEventLogger.instance.logImmediate(
      HowwowEvents.notificationTapped,
      props: {
        'url': uri.toString(),
        'deeplink_id': dl.deeplinkId,
        'source': dl.source ?? defaultSource,
        'target_type': _targetType(dl),
      },
    );

    // Auth-gate.
    if (dl.requiresAuth) {
      final hasToken = await _hasAuthToken();
      if (!hasToken) {
        await PendingDeeplink.set(uri);
        _routeToLogin();
        return;
      }
    }

    await _navigate(dl);
  }

  /// Called from the auth flow after a successful login. Consumes any
  /// pending URL stored by a prior auth-gate redirect and navigates to
  /// it. Returns true if a pending URL was found and routed; false
  /// otherwise (caller should fall through to the default home route).
  static Future<bool> consumePending() async {
    final uri = await PendingDeeplink.consume();
    if (uri == null) return false;
    await handle(uri, defaultSource: 'pending');
    return true;
  }

  // ── internals ──────────────────────────────────────────────────────

  static Future<void> _navigate(HowwowDeeplink dl) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      // Navigator not yet attached (e.g. cold-launch arrived before
      // runApp's first frame). Defer by one frame and retry once.
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigate(dl));
      return;
    }

    switch (dl) {
      case HomeDeeplink():
        // Pop to the root, then ensure CareerHomeScreen is on top.
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/career-home'),
            builder: (_) => const CareerHomeScreen(),
          ),
          (route) => false,
        );

      case WorldDeeplink():
        // No world-detail screen exists yet — fall through to home so
        // the user lands somewhere sensible. Logged here for analytics.
        debugPrint('howwow deeplink: world detail not yet built, '
            'falling back to home. worldId=${dl.worldId}');
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/career-home'),
            builder: (_) => const CareerHomeScreen(),
          ),
          (route) => false,
        );

      case CareerDeeplink():
        Navigator.of(ctx).push(MaterialPageRoute(
          settings: const RouteSettings(name: '/profession-detail'),
          builder: (_) => ProfessionDetailScreen(
            professionId: dl.professionId,
          ),
        ));

      case LessonDeeplink():
        Navigator.of(ctx).push(MaterialPageRoute(
          settings: const RouteSettings(name: '/profession-detail'),
          builder: (_) => ProfessionDetailScreen(
            professionId: dl.professionId,
            highlightLessonId: dl.lessonId,
            autoStartLessonId: dl.autoStart ? dl.lessonId : null,
          ),
        ));
    }
  }

  static void _routeToLogin() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/howwow-login'),
        builder: (_) => const HowwowLoginScreen(),
      ),
      (route) => false,
    );
  }

  static Future<bool> _hasAuthToken() async {
    try {
      final t = await AuthTokenService().getAuthToken();
      return t != null && t.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String _targetType(HowwowDeeplink dl) {
    switch (dl) {
      case HomeDeeplink():
        return 'home';
      case WorldDeeplink():
        return 'world';
      case CareerDeeplink():
        return 'career';
      case LessonDeeplink():
        return 'lesson';
    }
  }
}
