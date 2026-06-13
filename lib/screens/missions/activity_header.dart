// Shared activity header — a single, consistent top bar for every lesson
// activity (Prologue / Ep1 / Ep2 …): a back button + the activity's name on
// one line. Replaces the bespoke, inconsistent per-screen headers that used
// to show sometimes the activity name, sometimes the episode, sometimes
// nothing.
//
// The name is the SAME one the lesson runner shows on the pre-roll title card
// (the backend resource `caption`). It's delivered via [LessonActivityScope],
// which the runner wraps around each activity — so screens don't need a
// constructor param. For standalone/dev launches (no scope) the header falls
// back to [ActivityNameHeader.fallbackName].

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/career/careerCommon.dart' show PressableScale;
import 'leaveLessonDialog.dart';

/// Inherited carrier for the current activity's display name. The lesson
/// runner sets this (from the backend resource `caption`) when it pushes an
/// activity; activities read it via [nameOf]. Null when launched outside a
/// lesson (e.g. the dev launcher) or when the resource has no caption.
class LessonActivityScope extends InheritedWidget {
  const LessonActivityScope({
    super.key,
    required this.activityName,
    this.onReplay,
    this.complete,
    required super.child,
  });

  final String? activityName;

  /// Restart THIS activity from scratch, in place (recreates the activity
  /// subtree → fresh controller/state) with no navigation. Provided by
  /// [ReplayableActivity]; null when launched without that host.
  final VoidCallback? onReplay;

  /// Mark THIS activity FINISHED → pop the route with `true` so the lesson
  /// runner advances to the next beat. Non-null only when the host is guarding
  /// back (concept lessons): the activity's completion calls it so it bypasses
  /// the back-confirm guard. Null otherwise → callers fall back to maybePop.
  final VoidCallback? complete;

  static String? nameOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LessonActivityScope>()
      ?.activityName;

  /// The in-place restart callback, if the activity is hosted by a
  /// [ReplayableActivity]. Read in an event handler (a Replay tap), so it does
  /// NOT register a build dependency.
  static VoidCallback? replayOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<LessonActivityScope>()
      ?.onReplay;

  /// The finish callback (pop true / advance), if the host is guarding back.
  static VoidCallback? completeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<LessonActivityScope>()
      ?.complete;

  @override
  bool updateShouldNotify(LessonActivityScope oldWidget) =>
      oldWidget.activityName != activityName ||
      oldWidget.onReplay != onReplay ||
      oldWidget.complete != complete;
}

/// Hosts a lesson activity:
///   • "Replay" restarts it IN PLACE — recreating the activity subtree (fresh
///     controller/state) by bumping a keyed nonce, with NO navigation.
///   • When [guardLeave] is set (concept lessons), a back gesture / header-back
///     (both `maybePop`) is intercepted and the leave-confirm modal is shown —
///     confirming pops the route with `false` so the runner STOPS (leaves the
///     lesson), exactly like the intro video. Completion bypasses this guard via
///     [LessonActivityScope.complete] (an imperative `pop(true)`).
/// Works identically inside a lesson run and standalone (dev launcher), and
/// never disturbs the runner's route stack.
class ReplayableActivity extends StatefulWidget {
  const ReplayableActivity({
    super.key,
    required this.activityName,
    required this.child,
    this.guardLeave = false,
  });

  final String? activityName;
  final Widget child;
  final bool guardLeave;

  @override
  State<ReplayableActivity> createState() => _ReplayableActivityState();
}

class _ReplayableActivityState extends State<ReplayableActivity> {
  int _nonce = 0;
  bool _leaving = false; // guards against stacking the modal

  // Imperative pop bypasses the PopScope back-guard → the runner sees `true`
  // and advances to the next beat.
  void _complete() {
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _confirmLeave() async {
    if (_leaving) return;
    _leaving = true;
    final leave = await showLeaveLessonDialog(context, generic: true);
    _leaving = false;
    if (leave && mounted) Navigator.of(context).pop(false); // runner stops → leave
  }

  @override
  Widget build(BuildContext context) {
    // The key change discards the old activity element + its State and inflates
    // a fresh one — a clean restart from the activity's initState.
    Widget child = KeyedSubtree(key: ValueKey(_nonce), child: widget.child);
    if (widget.guardLeave) {
      child = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave();
        },
        child: child,
      );
    }
    return LessonActivityScope(
      activityName: widget.activityName,
      onReplay: () {
        if (mounted) setState(() => _nonce++);
      },
      complete: widget.guardLeave ? _complete : null,
      child: child,
    );
  }
}

/// The standard activity header: `[← back]  Activity Name`.
///
/// Title text resolves to the [LessonActivityScope] name (the backend
/// caption) when inside a lesson, else [fallbackName]. [trailing] hosts any
/// per-screen control that used to live in the header (e.g. a sound toggle).
/// [foreground] tints the back icon + title — defaults to white for the
/// dark-themed activities; light/parchment screens pass a dark colour.
class ActivityNameHeader extends StatelessWidget {
  const ActivityNameHeader({
    super.key,
    required this.onBack,
    this.fallbackName,
    this.trailing,
    this.foreground = Colors.white,
  });

  final VoidCallback onBack;
  final String? fallbackName;
  final Widget? trailing;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final name = LessonActivityScope.nameOf(context) ?? fallbackName ?? '';
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: foreground.withValues(alpha: 0.14)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.arrow_back_rounded, color: foreground, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.05,
              color: foreground,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
