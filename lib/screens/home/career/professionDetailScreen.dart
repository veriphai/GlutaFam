// ProfessionDetailScreen — opened when the user taps a profession card on
// the career home. Mirrors the design mock: app bar + hero "career series"
// card + next-episode card + vertical episode timeline + rewards row +
// certificate + footer hint.
//
// All section widgets live in this file as private classes since none of
// them are reused elsewhere yet. Data comes from a typed
// {@link ProfessionDetail} so the screen is decoupled from where the data
// is sourced (today: static seed; tomorrow: /howwow/career/professions/{id}).

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../apis/apiClient.dart';
import '../../../apis/howwow/howwowCareer.dart' as api;
import '../../../apis/howwow/howwowSession.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import '../../../utils/routeObserver.dart';
import '../../missions/lessonRunner.dart';
import 'nextEpisodeDialog.dart';
import 'resumeLessonDialog.dart';
import 'careerCommon.dart';
import 'careerTheme.dart';
import 'cosmicBackground.dart';
import 'professionDetailModels.dart';

class ProfessionDetailScreen extends StatefulWidget {
  const ProfessionDetailScreen({
    super.key,
    required this.professionId,
    this.fallback,
    this.localDetail,
    this.highlightLessonId,
    this.autoStartLessonId,
  });

  /// Backend profession id (e.g. "satellite_engineer"). The screen calls
  /// `/howwow/career/professions/{id}/detail` and renders the response.
  final String professionId;

  /// LOCAL-ONLY detail. When non-null, the screen renders this directly and
  /// skips the profession API entirely (no network call, no silent refresh) —
  /// used by the "How Things Work" concept cards, which reuse this same
  /// timeline + lesson-launch chain but have no backend profession behind them.
  /// Their single-activity lesson carries a null lessonId, so openLesson simply
  /// skips the progress writes.
  final ProfessionDetail? localDetail;

  /// Local seed used when the API call fails (most commonly: debug-skip
  /// path with no JWT, or the backend isn't reachable). When omitted, the
  /// screen shows an error state instead.
  final ProfessionDetail? fallback;

  /// When set, the timeline row matching this lesson id is visually
  /// highlighted (extra ring) so a deeplinked user can find their
  /// target lesson at a glance. No scroll-into-view yet; the timeline
  /// is short enough to fit on one screen for now.
  final String? highlightLessonId;

  /// When set, after the detail loads the screen auto-fires
  /// {@code _launchEpisode} for this lesson, but ONLY if it's unlocked
  /// (per design option A — locked lessons stay locked, the deeplink
  /// just lands the user on the page so they see the path).
  final String? autoStartLessonId;

  @override
  State<ProfessionDetailScreen> createState() => _ProfessionDetailScreenState();
}

class _ProfessionDetailScreenState extends State<ProfessionDetailScreen>
    with RouteAware {
  static const double _maxContentWidth = 480;
  static const double _pagePadding = CareerSpace.page;

  ProfessionDetail? _detail;
  bool _loading = true;
  bool _autoStartConsumed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes so didPopNext fires when a route we
    // pushed (the lesson runner's video/activity routes) pops back to us.
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Fires when a route pushed on top of this screen is popped, revealing
  /// it again — i.e. the user finished (or backed out of) a lesson. We
  /// silently re-fetch the unlock chain so a freshly-completed lesson's
  /// successor flips from locked to tappable, regardless of HOW the lesson
  /// was launched. This replaces the old fragile
  /// findAncestorStateOfType + reloadAfterLesson hop in _launchEpisode.
  @override
  void didPopNext() {
    _refreshSilently();
  }

  Future<void> _load() async {
    // Local concept: render the seed directly, no API call.
    if (widget.localDetail != null) {
      setState(() {
        _detail = widget.localDetail;
        _loading = false;
      });
      _maybeAutoStart();
      return;
    }
    try {
      final response = await api.howwowGetProfessionDetail(widget.professionId);
      if (!mounted) return;
      setState(() {
        _detail = ProfessionDetail.fromApi(response);
        _loading = false;
      });
      _maybeAutoStart();
    } catch (e) {
      // ignore: avoid_print
      print('professionDetail: load failed, falling back. err=$e'
          '${e is ApiException ? ' status=${e.statusCode}' : ''}');
      if (!mounted) return;
      setState(() {
        _detail = widget.fallback;
        _loading = false;
      });
      _maybeAutoStart();
    }
  }

  /// Re-fetch the profession detail in place (no loading spinner) so the
  /// unlock chain advances and a freshly-completed lesson's successor
  /// becomes tappable. Driven by [didPopNext] — fires whenever a pushed
  /// route (a lesson's video/activity) pops back to this screen, so it's
  /// independent of how the lesson was launched. Safe to call repeatedly.
  ///
  /// Logs the new lesson state on each call so we can diagnose unlock-
  /// chain bugs by greping logcat for `[howwow-lesson]`.
  Future<void> _refreshSilently() async {
    // Local concept detail has no server-side unlock chain to re-read.
    if (widget.localDetail != null) return;
    // ignore: avoid_print
    print('[howwow-lesson] refreshSilently → profession=${widget.professionId}');
    final stopwatch = Stopwatch()..start();
    try {
      final response = await api.howwowGetProfessionDetail(widget.professionId);
      stopwatch.stop();
      if (!mounted) return;
      final detail = ProfessionDetail.fromApi(response);
      // One-char-per-lesson summary: C = completed, L = locked, > = current,
      // · = unlocked-but-not-current.
      final summary = detail.lessons.map((l) {
        final lid = l.lessonId ?? '?';
        final mark = l.isCompleted ? 'C' : (l.isLocked ? 'L' : (l.isCurrent ? '>' : '·'));
        return '$lid=$mark';
      }).join(' ');
      // ignore: avoid_print
      print('[howwow-lesson] refreshSilently ✓ '
          '(${stopwatch.elapsedMilliseconds}ms) '
          'completed=${detail.completed}/${detail.total} '
          '[$summary]');
      setState(() {
        _detail = detail;
      });
    } catch (e) {
      stopwatch.stop();
      // ignore: avoid_print
      print('[howwow-lesson] refreshSilently ✗ '
          '(${stopwatch.elapsedMilliseconds}ms) error=$e');
    }
  }

  /// Launch a lesson and handle what happens when it ends. Shared by every
  /// CTA (Start Episode button, Next Episode card, timeline rows — they
  /// reach it via [_DetailLaunchScope]) and the deeplink auto-start.
  ///
  /// After the runner pops back: refresh the timeline (the completion POSTs
  /// are committed by the time openLesson returns, so the unlock chain is
  /// current), then — if the lesson fully completed and a next episode
  /// exists — prompt it. Tapping "Start" on that prompt launches the next
  /// lesson (chaining straight through the season).
  Future<void> _launchEpisode(Lesson lesson) async {
    var startFromIndex = lesson.lastCompletedResourceIndex + 1;
    // Resume prompt: when the lesson is partially done (e.g. the user
    // watched the intro and left), ask whether to pick up where they left
    // off or start over — instead of silently dropping them mid-lesson.
    final isPartial =
        !lesson.isCompleted && lesson.lastCompletedResourceIndex >= 0;
    if (isPartial) {
      final choice = await showResumeLessonDialog(context, lesson: lesson);
      if (!mounted) return;
      if (choice == null) return; // dismissed → don't launch
      if (choice == ResumeChoice.startOver) startFromIndex = 0;
    }
    HowwowEventLogger.instance.log(
      HowwowEvents.lessonCardTapped,
      props: {
        'lesson_id': lesson.lessonId,
        'lesson_number': lesson.number,
        'lesson_title': lesson.title,
        'is_resume': isPartial && startFromIndex > 0,
      },
    );
    final result = await openLesson(
      context,
      lesson.resources,
      lessonId: lesson.lessonId,
      startFromIndex: startFromIndex,
    );
    if (!mounted) return;
    if (!result.launchedAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A1340),
          behavior: SnackBarBehavior.floating,
          content: Text(
            "This lesson isn't available yet — check back soon!",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
        ),
      );
      return;
    }

    // Refresh the unlock chain in place. didPopNext already fires per
    // resource pop, but those race the final completion POST; this one runs
    // after openLesson awaited the whole completion chain, so it's the
    // authoritative post-completion read.
    await _refreshSilently();
    if (!mounted) return;

    // Prompt the next episode only when the lesson actually completed (the
    // server confirmed it on the final resource's POST) and the chain has a
    // now-unlocked successor.
    if (!result.lessonCompleted) return;
    final detail = _detail;
    if (detail == null) return;
    Lesson? nextLesson;
    if (result.nextLessonId != null) {
      for (final l in detail.lessons) {
        if (l.lessonId == result.nextLessonId) {
          nextLesson = l;
          break;
        }
      }
    }
    nextLesson ??= detail.nextLesson; // fall back to first not-completed
    if (nextLesson == null || nextLesson.isLocked || nextLesson.isCompleted) {
      return; // final episode of the season, or nothing left to prompt
    }
    final start = await showNextEpisodeDialog(context, next: nextLesson);
    if (start && mounted) {
      // Chain straight into the next lesson; its own completion will
      // prompt the one after, all the way down the season.
      await _launchEpisode(nextLesson);
    }
  }

  /// Honour the deeplink's {@code ?action=start} ONLY when the targeted
  /// lesson is currently unlocked. Locked lessons silently skip — the
  /// user still sees the page with the lesson visibly locked.
  void _maybeAutoStart() {
    final targetId = widget.autoStartLessonId;
    if (targetId == null || _autoStartConsumed) return;
    final detail = _detail;
    if (detail == null) return;
    Lesson? match;
    for (final l in detail.lessons) {
      if (l.lessonId == targetId) {
        match = l;
        break;
      }
    }
    if (match == null || match.isLocked) return;
    _autoStartConsumed = true;
    // Defer to the next frame so the build tree has finished mounting
    // before we push another route on top of it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _launchEpisode(match!);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: const Stack(
          children: [
            Positioned.fill(child: CosmicBackground()),
            Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(CareerColors.gold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'We could not load this career.',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _load();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final next = detail.nextLesson;
    final profileStats = HowwowSession.instance.profile?.stats;
    final xp = profileStats?.xp ?? 0;
    final streakDays = profileStats?.streakDays ?? 0;

    return _DetailLaunchScope(
      onLaunch: _launchEpisode,
      child: MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              _pagePadding, 12, _pagePadding, 0),
                          child: _DetailAppBar(
                            title: detail.name,
                            world: detail.world,
                            worldEmoji: detail.worldEmoji,
                            accent: detail.accentColor,
                            xp: xp,
                            streakDays: streakDays,
                          ),
                        ),
                        const SizedBox(height: CareerSpace.section),
                        // ── Hero "Career Series" card — HIDDEN FOR NOW ─────
                        // Re-enable by removing the /* ... */ wrap. The
                        // _HeroSeriesCard widget itself is still defined
                        // below (line ~372) so this is purely a build-tree
                        // toggle, not a code deletion.
                        /*
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _pagePadding),
                          child: _HeroSeriesCard(detail: detail),
                        ),
                        const SizedBox(height: CareerSpace.section),
                        */
                        // "Next Episode" card — only shown if there's one
                        // not yet completed.
                        if (next != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _pagePadding),
                            child: _NextEpisodeCard(
                              episode: next,
                              accent: detail.accentColor,
                            ),
                          ),
                          const SizedBox(height: CareerSpace.section),
                        ],
                        // "Your Path" timeline
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _pagePadding),
                          child: _YourPathSection(
                            episodes: detail.lessons,
                            accent: detail.accentColor,
                            highlightLessonId: widget.highlightLessonId,
                          ),
                        ),
                        // ── Rewards row + Certificate card — HIDDEN FOR NOW ─
                        // Re-enable by removing the /* ... */ wrap. The
                        // _RewardsSection widget itself is still defined
                        // below (line ~1057) so this is purely a build-tree
                        // toggle, not a code deletion.
                        /*
                        const SizedBox(height: CareerSpace.section),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _pagePadding),
                          child: _RewardsSection(
                            rewards: detail.rewards,
                            certificate: detail.certificate,
                          ),
                        ),
                        */
                        const SizedBox(height: 18),
                        // Footer hint pill
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _pagePadding),
                          child: _FooterHint(text: detail.footerHint),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// 1. App bar — back button + title + world subtitle + stat pills
// ────────────────────────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({
    required this.title,
    required this.world,
    required this.worldEmoji,
    required this.accent,
    required this.xp,
    required this.streakDays,
  });

  final String title;
  final String world;
  final String worldEmoji;
  final Color accent;
  final int xp;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        PressableScale(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CareerColors.glassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CareerColors.glassBorder),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        // Title + world
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(worldEmoji,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(world,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // XP pill hidden for now — uncomment when the XP-earning model is
        // live. Day Streak stays since streaks already increment server-
        // side on each lesson completion. Mirrors the same change on
        // careerHeader.dart so the two surfaces stay aligned.
        // _StatPill(
        //   iconEmoji: '⭐',
        //   value: xp.toString(),
        //   label: 'XP',
        //   labelColor: CareerColors.gold,
        // ),
        // const SizedBox(width: 6),
        _StatPill(
          iconEmoji: '🔥',
          value: streakDays.toString(),
          label: 'Day Streak',
        ),
      ],
    );
  }
}

// labelColor on _StatPill is temporarily unreferenced because the XP
// pill (its only caller that uses gold) is commented out in
// _DetailAppBar above. Keep the param so the re-enable is a one-line
// uncomment instead of also widening this ctor again.
// ignore_for_file: unused_element_parameter

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.iconEmoji,
    required this.value,
    required this.label,
    this.labelColor,
  });

  final String iconEmoji;
  final String value;
  final String label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 14,
      blur: true,
      padding: const EdgeInsets.fromLTRB(8, 5, 9, 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(iconEmoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(value, style: CareerText.statValue),
          ]),
          const SizedBox(height: 1),
          Text(label,
              style: CareerText.statLabel.copyWith(
                  color: labelColor ?? CareerColors.textSecondary)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// 2. Hero "Career Series" card — thick purple gradient border, big title,
//    progress bar, primary CTA, side illustration.
//
// CURRENTLY HIDDEN from the build tree (see comment at line ~178). The
// class definition is preserved so we can re-enable it later by removing
// the /* ... */ wrap there. `unused_element` is suppressed to keep the
// analyzer quiet while it's parked.
// ────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _HeroSeriesCard extends StatelessWidget {
  const _HeroSeriesCard({required this.detail});

  final ProfessionDetail detail;

  static const _innerTop = Color(0xFF18244F);
  static const _innerBottom = Color(0xFF0C1430);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CareerRadii.card),
        gradient: CareerGradients.heroBorder,
        boxShadow: [
          BoxShadow(
              color: detail.accentColor.withValues(alpha: 0.32),
              blurRadius: 26,
              offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(1.6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CareerRadii.card - 1.6),
        child: Stack(
          children: [
            // Inner gradient background
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_innerTop, _innerBottom],
                  ),
                ),
              ),
            ),
            // Right-side illustration (full-bleed, slightly to the right
            // of center so the text on the left is unobstructed).
            if (detail.heroAsset != null)
              Positioned.fill(
                left: 140,
                child: Image.asset(
                  detail.heroAsset!,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            // Subtle dark scrim on the left so text reads against the
            // illustration's right edge.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xCC0C1430),
                      Color(0x660C1430),
                      Color(0x00000000),
                    ],
                    stops: [0.0, 0.35, 0.62],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SeriesBadge(label: detail.seriesLabel, color: detail.accentColor),
                  const SizedBox(height: 14),
                  Text(detail.name,
                      style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0)),
                  const SizedBox(height: 8),
                  Text(detail.seasonTitle,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: detail.accentColor)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 220,
                    child: Text(detail.tagline,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.35),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 14),
                  _ProgressRow(detail: detail),
                  const SizedBox(height: 14),
                  _StartEpisodeButton(detail: detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesBadge extends StatelessWidget {
  const _SeriesBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 5, 13, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0)),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.detail});
  final ProfessionDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded,
            color: CareerColors.gold, size: 18),
        const SizedBox(width: 6),
        Text('${detail.completed} / ${detail.total} Episodes Completed',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 7,
              color: Colors.white.withValues(alpha: 0.12),
              child: FractionallySizedBox(
                widthFactor: detail.progress,
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: CareerColors.gold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartEpisodeButton extends StatelessWidget {
  const _StartEpisodeButton({required this.detail});
  final ProfessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final next = detail.nextLesson;
    final label = next == null
        ? 'Series complete!'
        : (detail.completed == 0
            ? 'Start Episode ${next.number}'
            : 'Continue Episode ${next.number}');

    return PressableScale(
      onTap: next == null
          ? null
          : () => _DetailLaunchScope.launch(context, next),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: CareerColors.gold,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(
                color: CareerColors.gold.withValues(alpha: 0.55),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded,
                color: CareerColors.onLight, size: 22),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CareerColors.onLight)),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// 3. Next Episode card — thumbnail + title + description + Discover/Reward
//    columns + full-width "Start Episode" button.
// ────────────────────────────────────────────────────────────────────

class _NextEpisodeCard extends StatelessWidget {
  const _NextEpisodeCard({required this.episode, required this.accent});
  final Lesson episode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12184A).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(CareerRadii.card),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeriesBadge(label: 'NEXT EPISODE', color: accent),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SquareThumbnail(
                icon: episode.thumbnailIcon,
                accent: episode.thumbnailColor ?? accent,
                asset: episode.thumbnailAsset,
                size: 96,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(episode.number == 0 ? 'PROLOGUE' : 'EPISODE ${episode.number}',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    Text(episode.title,
                        style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15)),
                    const SizedBox(height: 6),
                    Text(
                      episode.longDescription ?? episode.shortDescription,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.white70,
                          height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
              height: 1, color: Colors.white.withValues(alpha: 0.10)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabelledBlock(
                  iconEmoji: '✨',
                  label: "You'll Discover",
                  labelColor: CareerColors.cyan,
                  body: episode.discoverHook ?? episode.shortDescription,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabelledBlock(
                        label: 'Reward',
                        labelColor: accent,
                        body: episode.rewardName ?? '—',
                      ),
                    ),
                    if (episode.rewardName != null) ...[
                      const SizedBox(width: 6),
                      _HexBadge(
                        color: accent,
                        icon: episode.thumbnailIcon,
                        size: 38,
                        imageUrl: episode.rewardImageUrl,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StartEpisodeWideButton(accent: accent, episode: episode),
        ],
      ),
    );
  }
}

class _LabelledBlock extends StatelessWidget {
  const _LabelledBlock({
    required this.label,
    required this.body,
    required this.labelColor,
    this.iconEmoji,
  });
  final String label;
  final String body;
  final Color labelColor;
  final String? iconEmoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (iconEmoji != null) ...[
              Text(iconEmoji!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                    letterSpacing: 0.4)),
          ],
        ),
        const SizedBox(height: 4),
        Text(body,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3)),
      ],
    );
  }
}

class _StartEpisodeWideButton extends StatelessWidget {
  const _StartEpisodeWideButton({required this.accent, required this.episode});
  final Color accent;
  final Lesson episode;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => _DetailLaunchScope.launch(context, episode),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text('Start Episode',
                style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// 4. Your Path — vertical episode timeline with dotted connector line.
// ────────────────────────────────────────────────────────────────────

class _YourPathSection extends StatelessWidget {
  const _YourPathSection({
    required this.episodes,
    required this.accent,
    this.highlightLessonId,
  });
  final List<Lesson> episodes;
  final Color accent;
  /// When non-null, the row whose lessonId matches gets an extra accent
  /// ring so a deeplinked user can immediately see which lesson the
  /// notification was about.
  final String? highlightLessonId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('Your Path', style: CareerText.sectionTitle),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < episodes.length; i++)
          _PathRow(
            episode: episodes[i],
            accent: accent,
            isLast: i == episodes.length - 1,
            highlighted: highlightLessonId != null &&
                episodes[i].lessonId == highlightLessonId,
          ),
      ],
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.episode,
    required this.accent,
    required this.isLast,
    this.highlighted = false,
  });
  final Lesson episode;
  final Color accent;
  final bool isLast;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isCurrent = episode.isCurrent;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left rail: numbered circle + vertical connector line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _NumberCircle(
                  number: episode.number,
                  active: isCurrent,
                  accent: accent,
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Tile
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PathTile(
                episode: episode,
                accent: accent,
                highlighted: highlighted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberCircle extends StatelessWidget {
  const _NumberCircle({
    required this.number,
    required this.active,
    required this.accent,
  });
  final int number;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fill = active
        ? accent.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.05);
    final stroke = active
        ? accent
        : Colors.white.withValues(alpha: 0.25);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: stroke, width: 2),
        boxShadow: active
            ? [
                BoxShadow(
                    color: accent.withValues(alpha: 0.55),
                    blurRadius: 14)
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text('$number',
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7))),
    );
  }
}

class _PathTile extends StatelessWidget {
  const _PathTile({
    required this.episode,
    required this.accent,
    this.highlighted = false,
  });
  final Lesson episode;
  final Color accent;
  /// True when this tile is the deeplink target — draws a thicker accent
  /// border so the user can find it instantly.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isCurrent = episode.isCurrent;
    // The whole row is the tap target when the episode is unlocked. Locked
    // rows pass null so PressableScale doesn't fire — no scale animation,
    // no navigation.
    return PressableScale(
      onTap: episode.isLocked
          ? () => HowwowEventLogger.instance.logImmediate(
                HowwowEvents.lockedLessonTap,
                props: {
                  'lesson_id': episode.lessonId,
                  'lesson_number': episode.number,
                  'lesson_title': episode.title,
                },
              )
          : () => _DetailLaunchScope.launch(context, episode),
      child: Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111733).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(CareerRadii.smallCard),
        border: Border.all(
            color: highlighted
                ? accent
                : (isCurrent
                    ? accent.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.08)),
            width: highlighted ? 2.0 : (isCurrent ? 1.3 : 1)),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SquareThumbnail(
            icon: episode.thumbnailIcon,
            accent: episode.thumbnailColor ?? accent,
            asset: episode.thumbnailAsset,
            size: 50,
            dim: episode.isLocked,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (episode.tag != null) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(7, 2, 8, 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                      border: Border.all(color: accent.withValues(alpha: 0.55)),
                    ),
                    child: Text(episode.tag!,
                        style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.6)),
                  ),
                  const SizedBox(height: 4),
                ],
                // maxLines: 1 + ellipsis so the layout calc (which assumes
                // 1-line intrinsic height) matches actual rendering — the
                // root cause of the 3-pixel bottom overflow on rows with
                // longer titles like "Choose the Right Satellite".
                Text(episode.title,
                    style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(episode.shortDescription,
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (episode.isLocked)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5)),
            )
          else ...[
            // Reward badge intentionally NOT shown on path rows — the medal
            // art competed with the chevron CTA. Rewards still surface in
            // the "Rewards in this Series" section below.
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: 10)
                ],
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    ),  // close PressableScale
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// 5. Rewards in this Series — row of hex badges + certificate card.
//
// CURRENTLY HIDDEN from the build tree (see comment at line ~214). The
// class definition is preserved so we can re-enable it later by removing
// the /* ... */ wrap there. `unused_element` is suppressed to keep the
// analyzer quiet while it's parked.
// ────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _RewardsSection extends StatelessWidget {
  const _RewardsSection({required this.rewards, required this.certificate});
  final List<RewardBadge> rewards;
  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('Rewards in this Series',
                style: CareerText.sectionTitle),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badges grid — first 3 in the left column visually, but the
              // mock has all 5 in a single row; we wrap to keep them
              // readable on narrow screens.
              Expanded(
                flex: 5,
                child: _BadgesGrid(rewards: rewards),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: _CertificateCard(certificate: certificate),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  const _BadgesGrid({required this.rewards});
  final List<RewardBadge> rewards;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final r in rewards) _BadgeTile(badge: r),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});
  final RewardBadge badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HexBadge(color: badge.color, icon: badge.icon, size: 52),
          const SizedBox(height: 6),
          Text(badge.name,
              style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.certificate});
  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1230),
        borderRadius: BorderRadius.circular(CareerRadii.smallCard),
        border: Border.all(color: CareerColors.gold.withValues(alpha: 0.7), width: 1.4),
        boxShadow: [
          BoxShadow(
              color: CareerColors.gold.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(certificate.requirementLine,
              style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3)),
          const SizedBox(height: 4),
          Text(certificate.title,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: CareerColors.gold,
                  height: 1.2)),
          const SizedBox(height: 8),
          // Placeholder certificate visual when no asset is provided.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE6A2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: CareerColors.gold.withValues(alpha: 0.8)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.workspace_premium_rounded,
                    size: 22, color: Color(0xFFB07A1F)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('🧑‍🎓',
                    style: TextStyle(fontSize: 36),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// 6. Footer hint pill.
// ────────────────────────────────────────────────────────────────────

class _FooterHint extends StatelessWidget {
  const _FooterHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8))),
          ),
          const SizedBox(width: 6),
          const Text('✨', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Shared primitives.
// ────────────────────────────────────────────────────────────────────

/// Square illustration tile used in the "Next Episode" card and timeline.
class _SquareThumbnail extends StatelessWidget {
  const _SquareThumbnail({
    required this.icon,
    required this.accent,
    this.asset,
    this.size = 60,
    this.dim = false,
  });

  final IconData icon;
  final Color accent;
  final String? asset;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.55),
            Color.lerp(accent, Colors.black, 0.55)!,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        image: asset == null
            ? null
            : DecorationImage(
                // Episode art comes as an S3 URL; static seeds may still
                // pass bundled asset paths — pick the provider by prefix.
                image: asset!.startsWith('http')
                    ? NetworkImage(asset!)
                    : AssetImage(asset!) as ImageProvider,
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
      ),
      alignment: Alignment.center,
      child: asset == null
          ? Icon(icon, size: size * 0.46, color: Colors.white)
          : null,
    );
    if (!dim) return inner;
    return Opacity(opacity: 0.55, child: inner);
  }
}

/// Filled hex badge (used inline next to text and in the rewards grid).
class _HexBadge extends StatelessWidget {
  const _HexBadge({
    required this.color,
    required this.icon,
    this.size = 40,
    this.imageUrl,
  });
  final Color color;
  final IconData icon;
  final double size;

  /// When set, the widget renders the badge artwork at [imageUrl]
  /// instead of drawing the icon-themed hex. The activity badges
  /// already ship with their own silhouettes (shields, medallions,
  /// circles), so we don't force-clip them to a hex — that would just
  /// crop the art. Falls back to the icon hex when null or when the
  /// image fails to load.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 220),
          // While the badge bytes are in flight, render the
          // colour-themed hex so the row doesn't pop in empty.
          placeholder: (_, __) => _iconHex(),
          // Network error → fall back permanently to the icon hex
          // (same as the missing-art case below).
          errorWidget: (_, __, ___) => _iconHex(),
        ),
      );
    }
    return _iconHex();
  }

  Widget _iconHex() {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexPainter(color: color),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.45, color: Colors.white),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final r = w / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final x = cx + r * 0.96 * math.cos(angle);
      final y = cy + r * 0.96 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          Color.lerp(color, Colors.black, 0.45)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) => old.color != color;
}

// ────────────────────────────────────────────────────────────────────
// Episode-launch scope.
//
// The CTAs (hero "Start Episode N" button, the Next Episode card button,
// and each unlocked timeline row) live in extracted StatelessWidgets far
// from the State. Rather than reach up the tree with findAncestorStateOf
// Type (fragile — silently null on some paths), the State publishes its
// _launchEpisode method through this InheritedWidget; the CTAs resolve it
// with _DetailLaunchScope.of(context). One definition, all paths, no
// post-completion refresh/modal logic duplicated.
// ────────────────────────────────────────────────────────────────────

class _DetailLaunchScope extends InheritedWidget {
  const _DetailLaunchScope({required this.onLaunch, required super.child});

  /// Launches the given lesson (and handles the end-of-lesson refresh +
  /// next-episode prompt — see _ProfessionDetailScreenState._launchEpisode).
  final void Function(Lesson lesson) onLaunch;

  /// Resolve the nearest scope and launch [lesson].
  static void launch(BuildContext context, Lesson lesson) {
    final scope =
        context.getInheritedWidgetOfExactType<_DetailLaunchScope>();
    assert(scope != null, 'No _DetailLaunchScope above this widget');
    scope?.onLaunch(lesson);
  }

  @override
  bool updateShouldNotify(_DetailLaunchScope oldWidget) => false;
}
