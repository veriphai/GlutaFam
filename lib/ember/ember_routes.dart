// Ember — ember_routes.dart
//
// The module's INTERNAL navigation surface. Ember owns its own Navigator (inside
// ember_app's MaterialApp) and never couples to the host app's router. Routes are
// plain named constants + push helpers so the world screen, codex, and
// site-selection navigate without string-typos. The activity "route" is NOT a
// Navigator route — an activity is a Flame world swapped in by the ActivityHost
// and framed by an in-place Flutter overlay (so the canvas stays mounted).

import 'package:flutter/material.dart';

import 'ui/codex/codex_screen.dart';

/// Stable internal route names (used for the MaterialApp routes table + pushes).
class EmberRoutes {
  const EmberRoutes._();

  /// The world map screen (home).
  static const String world = '/';

  /// First-run site selection (shown before the world when no site is chosen).
  static const String siteSelection = '/site';

  /// The codex browser.
  static const String codex = '/codex';
}

/// Push helpers that keep navigation intent in one place.
class EmberNav {
  const EmberNav._();

  /// Opens the codex, optionally jumping straight to [entryId]'s detail.
  static Future<void> openCodex(BuildContext context, {String? entryId}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => CodexScreen(initialEntryId: entryId),
      ),
    );
  }
}
