// App-wide RouteObserver for ModalRoutes.
//
// Screens that need to refresh when a route they pushed pops back to them
// (e.g. ProfessionDetailScreen re-fetching the unlock chain after a lesson
// finishes) make their State `RouteAware`, subscribe in didChange
// Dependencies, and refetch in `didPopNext`.
//
// Registered once in MaterialApp.navigatorObservers (see main.dart). Kept
// in its own file so screens import just this, not all of main.dart.

import 'package:flutter/widgets.dart';

/// Single shared instance — every RouteAware screen subscribes/unsubscribes
/// against this same observer.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
