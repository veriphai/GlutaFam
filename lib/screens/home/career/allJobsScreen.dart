// "All Jobs" — the full career catalog, reached from the home page's
// "View All Jobs" action (and from a world portal on AllWorldsScreen, which
// opens it pre-filtered to that world).
//
// Layout: cosmic backdrop + glass app bar + a horizontally-scrolling row of
// world filter chips + a 2-column grid of full-bleed job cards (same visual
// language as the home rail's ProfessionCard, scaled up for grid cells).
// Unlocked careers always sort ahead of locked ones so the playable content
// is never buried.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import 'careerCommon.dart';
import 'careerModels.dart';
import 'careerTheme.dart';
import 'cosmicBackground.dart';

class AllJobsScreen extends StatefulWidget {
  const AllJobsScreen({
    super.key,
    required this.professions,
    this.worlds = const [],
    this.initialWorld,
    this.onProfessionTap,
  });

  final List<Profession> professions;

  /// Used to colour/order the filter chips; safe to leave empty (chips then
  /// derive from the professions' own world names with default accents).
  final List<CareerWorld> worlds;

  /// Pre-select a world filter (e.g. when opened from a world portal).
  final String? initialWorld;

  final void Function(Profession profession)? onProfessionTap;

  @override
  State<AllJobsScreen> createState() => _AllJobsScreenState();
}

class _AllJobsScreenState extends State<AllJobsScreen> {
  static const double _maxContentWidth = 480;

  String? _world; // null = All

  @override
  void initState() {
    super.initState();
    _world = widget.initialWorld;
  }

  /// World names in display order: the worlds list first (it carries the
  /// backend ordering + accents), then any extra world names that only
  /// appear on professions (defensive — catalog drift between endpoints).
  List<_WorldFilter> get _filters {
    final seen = <String>{};
    final filters = <_WorldFilter>[];
    for (final w in widget.worlds) {
      if (seen.add(w.name)) filters.add(_WorldFilter(w.name, w.accent));
    }
    for (final p in widget.professions) {
      if (p.world.isNotEmpty && seen.add(p.world)) {
        filters.add(_WorldFilter(p.world, p.accent));
      }
    }
    return filters;
  }

  /// Filtered + stable-sorted: recommended first, then unlocked, then locked
  /// (original order preserved inside each group).
  List<Profession> get _visible {
    final filtered = _world == null
        ? widget.professions
        : widget.professions.where((p) => p.world == _world).toList();
    return [
      ...filtered.where((p) => p.recommended && !p.locked),
      ...filtered.where((p) => !p.recommended && !p.locked),
      ...filtered.where((p) => p.locked),
    ];
  }

  void _selectWorld(String? world) {
    if (world == _world) return;
    HowwowEventLogger.instance.log(
      HowwowEvents.allJobsFilterTapped,
      props: {'world_name': world ?? 'all'},
    );
    setState(() => _world = world);
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.professions.where((p) => !p.locked).length;
    final total = widget.professions.length;

    return MediaQuery(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            CareerSpace.page, 12, CareerSpace.page, 0),
                        child: RevealOnLoad(
                          child: SubpageAppBar(
                            emoji: '⭐',
                            title: 'Amazing Jobs',
                            subtitle: unlocked == total
                                ? '$total careers to try for real'
                                : '$unlocked ready to play • ${total - unlocked} coming soon',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RevealOnLoad(
                        delay: const Duration(milliseconds: 60),
                        child: SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: CareerSpace.page),
                            children: [
                              _FilterChip(
                                label: 'All',
                                emoji: '✨',
                                accent: CareerColors.gold,
                                selected: _world == null,
                                onTap: () => _selectWorld(null),
                              ),
                              for (final f in _filters) ...[
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: f.name,
                                  accent: f.accent,
                                  selected: _world == f.name,
                                  onTap: () => _selectWorld(f.name),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        // Re-keyed per filter so switching worlds replays the
                        // fade + the cards' staggered reveal — the grid feels
                        // alive instead of snapping.
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          child: _JobsGrid(
                            key: ValueKey(_world ?? '__all__'),
                            professions: _visible,
                            onProfessionTap: widget.onProfessionTap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldFilter {
  const _WorldFilter(this.name, this.accent);
  final String name;
  final Color accent;
}

// ── grid ──────────────────────────────────────────────────────────────

class _JobsGrid extends StatelessWidget {
  const _JobsGrid({super.key, required this.professions, this.onProfessionTap});

  final List<Profession> professions;
  final void Function(Profession profession)? onProfessionTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              CareerSpace.page, 12, CareerSpace.page, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.66,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => RevealOnLoad(
                delay: Duration(milliseconds: 60 + (i % 8) * 70),
                child: _JobCard(
                  profession: professions[i],
                  onTap: onProfessionTap,
                ),
              ),
              childCount: professions.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                CareerSpace.page, 22, CareerSpace.page, 28),
            child: ComingSoonFooter(
                emoji: '🚀', message: 'New careers are landing soon!'),
          ),
        ),
      ],
    );
  }
}

/// Grid-cell variant of the home rail's ProfessionCard: same full-bleed
/// illustration + scrim + straddling icon badge language, but width-flexible
/// and with slightly larger type to suit the bigger cell.
class _JobCard extends StatelessWidget {
  const _JobCard({required this.profession, this.onTap});

  final Profession profession;
  final void Function(Profession profession)? onTap;

  @override
  Widget build(BuildContext context) {
    final p = profession;
    final borderWidth = p.recommended ? 2.0 : 1.0;

    return PressableScale(
      // Locked cards swallow navigation but still emit telemetry — which
      // locked careers users keep tapping is the strongest build-next signal.
      onTap: p.locked
          ? () => HowwowEventLogger.instance.logImmediate(
                HowwowEvents.lockedProfessionTap,
                props: {'profession_name': p.name, 'source': 'all_jobs'},
              )
          : () {
              HowwowEventLogger.instance.log(
                HowwowEvents.professionTapped,
                props: {
                  'profession_name': p.name,
                  'recommended': p.recommended,
                  'source': 'all_jobs',
                },
              );
              onTap?.call(p);
            },
      // Outer container draws border + glow; inner ClipRRect (radius minus
      // border width) clips the art — same two-layer trick as ProfessionCard
      // so the clip never notches the border corners.
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CareerRadii.smallCard),
          border: Border.all(
            color: p.recommended ? CareerColors.gold : CareerColors.glassBorder,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: p.locked
                  ? Colors.black.withValues(alpha: 0.30)
                  : (p.recommended ? CareerColors.gold : p.accent)
                      .withValues(alpha: 0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(CareerRadii.smallCard - borderWidth),
          child: Stack(
            children: [
              Positioned.fill(
                child: IllustrationPanel(gradient: p.gradient, asset: p.asset),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xD9000000)
                      ],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              if (p.recommended && !p.locked)
                const Positioned(
                    left: 12,
                    top: 10,
                    child: Text('👑', style: TextStyle(fontSize: 20))),
              // separator line at the illustration / text seam
              Positioned(
                left: 16,
                right: 16,
                bottom: 96,
                child: Container(
                    height: 1, color: Colors.white.withValues(alpha: 0.20)),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.name,
                        style: CareerText.cardTitleLg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(p.world,
                        style: CareerText.worldLabel
                            .copyWith(color: p.accent, fontSize: 10.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: Text(p.description,
                          style: CareerText.body
                              .copyWith(fontSize: 10.5, color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // activity icon — centered, straddling the separator line
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: Center(
                    child: IconBadge(icon: p.icon, color: p.accent, size: 32)),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: CareerColors.glassBorder),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      size: 19, color: Colors.white),
                ),
              ),
              if (p.locked) ...[
                Positioned.fill(
                  child:
                      ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                ),
                const Positioned(top: 10, right: 10, child: LockBadge(size: 26)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── filter chip ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.emoji,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [
                  accent,
                  Color.lerp(accent, Colors.black, 0.30)!,
                ])
              : null,
          color: selected ? null : CareerColors.glassFill,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.55)
                : CareerColors.glassBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
            ] else ...[
              // small accent dot so unselected chips still hint their world
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.7), blurRadius: 5)
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : CareerColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
