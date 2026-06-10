// Career-discovery homepage.
//
// On launch, fetches `/howwow/career/home` and renders the response. If the
// call fails (e.g. transient network error or the user lost their session),
// the screen falls back to the local mock seed in `careerModels.dart` so
// the UI still renders cleanly.

import 'package:flutter/material.dart';

import '../../../apis/apiClient.dart';
import '../../../apis/howwow/howwowCareer.dart';
import '../../../apis/howwow/howwowSession.dart';
import '../../../models/howwow/howwowCareer.dart' as api;
import '../../../utils/appUpdateCheck.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import 'allJobsScreen.dart';
import 'allWorldsScreen.dart';
// Kept for the hidden "Today's Job Challenge" / "Career Passport" row.
// ignore: unused_import
import 'bottomRowCards.dart';
import 'careerBottomNav.dart';
import 'careerCommon.dart';
import 'careerHeader.dart';
import 'careerMissionCard.dart';
import 'careerModels.dart';
import 'careerTheme.dart';
import 'cosmicBackground.dart';
import 'exploreWorlds.dart';
import 'howThingsWorkSection.dart';
import 'professionDetailModels.dart';
import 'professionDetailScreen.dart';
import 'wowConcepts.dart';
import 'profileScreen.dart';
import 'featuredProfessions.dart';
// Kept for the hidden 'Play' tab branch in the bottom-nav handler.
// ignore: unused_import
import '../../activities/activities_screen.dart';

class CareerHomeScreen extends StatefulWidget {
  const CareerHomeScreen({super.key});

  @override
  State<CareerHomeScreen> createState() => _CareerHomeScreenState();
}

class _CareerHomeScreenState extends State<CareerHomeScreen> {
  static const double _maxContentWidth = 480;
  static const double _navClearance = 96;

  api.HowwowHomeBundle? _bundle;
  bool _loading = true;
  bool _usingMockFallback = false;

  // Derived view-models cached so we don't rebuild them on every frame.
  List<Profession> _professions = const [];
  List<CareerWorld> _worlds = const [];
  ContinueMission? _currentMission;

  @override
  void initState() {
    super.initState();
    _loadHome();
    // Remote update toggle — checks installed version against the backend's
    // app-version-details doc and surfaces the update sheet when behind
    // (forced below minimumVersion). Post-frame so the sheet has a mounted
    // navigator; self-dedupes per session, fails soft on any error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runAppUpdateFlow(context);
    });
  }

  Future<void> _loadHome() async {
    try {
      final bundle = await howwowGetHome();
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
        _usingMockFallback = false;
        _applyBundle(bundle);
      });
    } catch (e) {
      // Most likely a 401 from the debug-skip path (no appJwt stored) or a
      // transient network error. Either way, fall back to the local mock
      // seed so the UI still renders — the user can tell the screen is alive
      // by the "(demo)" pill in the header. We do NOT throw to the user.
      if (!mounted) return;
      // Best-effort: report into the log so we can see it in DevTools.
      // Avoid passing the raw exception via `error:` — JS-backed exceptions
      // can trip the Flutter web inspector's DiagnosticsNode renderer.
      // ignore: avoid_print
      print('careerHome: load failed, falling back to mock. err=$e'
          '${e is ApiException ? ' status=${e.statusCode}' : ''}');
      setState(() {
        _loading = false;
        _usingMockFallback = true;
        _professions = kProfessions;
        _worlds = kWorlds;
        _currentMission = kContinueMission;
      });
    }
  }

  /// Convert the API DTOs into the existing UI types in one place so each
  /// downstream widget keeps its existing contract.
  void _applyBundle(api.HowwowHomeBundle bundle) {
    final worldNamesById = {for (final w in bundle.worlds) w.worldId: w.name};
    final professionNamesById = {
      for (final p in bundle.professions) p.professionId: p.name,
    };

    _professions = bundle.professions
        .map((p) => Profession.fromApi(p, worldNamesById: worldNamesById))
        .toList();
    _worlds = bundle.worlds.map(CareerWorld.fromApi).toList();
    _currentMission = ContinueMission.fromApi(
      bundle.currentLesson,
      professionNamesById: professionNamesById,
      worldNamesById: worldNamesById,
    );

    // If the backend gave us nothing (empty catalog), keep the mock seed
    // visible rather than rendering a blank screen.
    if (_professions.isEmpty) _professions = kProfessions;
    if (_worlds.isEmpty) _worlds = kWorlds;
    _currentMission ??= kContinueMission;
  }

  /// Single navigation handler for profession taps — shared by the home
  /// rail, the All Jobs grid, and world-filtered catalogs so they all open
  /// the same detail experience.
  void _openProfession(Profession p) {
    if (p.name == 'Satellite Engineer') {
      // Open the profession-detail screen. It calls
      // /career/professions/{id}/detail and renders the response; the
      // static kSatelliteEngineerDetail seed acts only as a fallback
      // (debug-skip path with no JWT, or transient API error).
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ProfessionDetailScreen(
          professionId: 'satellite_engineer',
          fallback: kSatelliteEngineerDetail,
        ),
      ));
    }
  }

  void _openAllJobs({String? world}) {
    HowwowEventLogger.instance.log(
      HowwowEvents.viewAllJobsTapped,
      props: {if (world != null) 'world_name': world},
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AllJobsScreen(
        professions: _professions,
        worlds: _worlds,
        initialWorld: world,
        onProfessionTap: _openProfession,
      ),
    ));
  }

  void _openAllWorlds() {
    HowwowEventLogger.instance.log(HowwowEvents.viewAllWorldsTapped);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AllWorldsScreen(
        worlds: _worlds,
        professions: _professions,
        onProfessionTap: _openProfession,
      ),
    ));
  }

  /// Open a "How Things Work" concept. Reuses ProfessionDetailScreen with a
  /// local seed (no backend profession) — same timeline + lesson launcher; the
  /// concept's single-activity lesson runs through the standard lessonRunner.
  void _openConcept(WowConcept concept) {
    HowwowEventLogger.instance.log(
      HowwowEvents.professionTapped,
      props: {'profession_name': concept.title, 'source': 'concept_rail'},
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfessionDetailScreen(
        professionId: concept.id,
        localDetail: concept.detail,
      ),
    ));
  }


  @override
  Widget build(BuildContext context) {
    final profile = HowwowSession.instance.profile;
    final stats = _bundle?.stats;

    return MediaQuery(
      // Force 1.0 text scaling so type renders at exactly the designed
      // sizes, regardless of the device/browser accessibility text-size
      // setting.
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        extendBody: true,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(CareerColors.gold),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: _navClearance),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
                                child: RevealOnLoad(
                                  child: CareerHeader(
                                    name: profile?.firstName ?? profile?.displayName,
                                    xp: stats?.xp,
                                    badges: stats?.badges,
                                    streakDays: stats?.streakDays,
                                  ),
                                ),
                              ),
                              if (_usingMockFallback) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
                                  child: _DemoModeBanner(onRetry: () {
                                    setState(() {
                                      _loading = true;
                                      _usingMockFallback = false;
                                    });
                                    _loadHome();
                                  }),
                                ),
                              ],
                              const SizedBox(height: CareerSpace.section),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
                                child: RevealOnLoad(
                                  delay: const Duration(milliseconds: 70),
                                  child: ContinueMissionCard(
                                    mission: _currentMission ?? kContinueMission,
                                    onContinue: () {
                                      final mission =
                                          _currentMission ?? kContinueMission;
                                      HowwowEventLogger.instance.log(
                                        HowwowEvents.continueMissionCardTapped,
                                        props: {
                                          'mission_title': mission.missionTitle,
                                          'profession_id': mission.professionId,
                                        },
                                      );
                                      // Open the same profession-detail screen
                                      // the job card uses — single source of
                                      // truth for the lesson-timeline UI.
                                      // Falls back to satellite_engineer if
                                      // the backend hasn't populated
                                      // professionId yet (e.g. the static
                                      // fallback ContinueMission).
                                      final professionId =
                                          mission.professionId ?? 'satellite_engineer';
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => ProfessionDetailScreen(
                                          professionId: professionId,
                                          fallback: professionId == 'satellite_engineer'
                                              ? kSatelliteEngineerDetail
                                              : null,
                                        ),
                                      ));
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: CareerSpace.section),
                              FeaturedProfessionsSection(
                                professions: _professions,
                                onProfessionTap: _openProfession,
                                onViewAll: _openAllJobs,
                              ),
                              const SizedBox(height: CareerSpace.section),
                              ExploreWorldsSection(
                                worlds: _worlds,
                                onViewAll: _openAllWorlds,
                                // Tapping an unlocked world portal opens the
                                // job catalog pre-filtered to that world.
                                onWorldTap: (w) => _openAllJobs(world: w.name),
                              ),
                              const SizedBox(height: CareerSpace.section),
                              // "How Things Work" — curiosity concepts (e.g.
                              // electricity → the Hand-Crank Lamp activity).
                              // Locally seeded for now (kWowConcepts).
                              HowThingsWorkSection(
                                concepts: kWowConcepts,
                                onConceptTap: _openConcept,
                              ),
                              // "Today's Job Challenge" + "Career Passport"
                              // cards hidden for now — neither feature is
                              // live yet. Re-enable by uncommenting (widget
                              // lives in bottomRowCards.dart).
                              // const SizedBox(height: CareerSpace.section),
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
                              //   child: const RevealOnLoad(
                              //     delay: Duration(milliseconds: 220),
                              //     child: CareerBottomRow(),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            // Floating bottom nav — pinned to the very bottom of the screen.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                    child: CareerBottomNav(
                      onSelect: (label) {
                        if (label == 'Play') {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ActivitiesScreen()));
                        } else if (label == 'Worlds') {
                          _openAllWorlds();
                        } else if (label == 'Profile') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        }
                      },
                    ),
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

/// Small inline pill that surfaces when /career/home fails so we know the
/// screen is running on the local mock seed (typically the debug-skip path
/// from the login screen). Tap it to retry the API call.
class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x33FFC83D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x66FFC83D)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info_outline_rounded, size: 14, color: CareerColors.gold),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Demo mode — backend unreachable. Tap to retry.',
                style: TextStyle(color: CareerColors.gold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
