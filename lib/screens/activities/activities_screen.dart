// Activities hub — the launch point for the career mini-games, reached from the
// career bottom nav. Lists each activity as a card; tapping opens it. New
// activities just add an entry to [_activities].

import 'package:flutter/material.dart';

import '../home/career/careerCommon.dart';
import '../home/career/careerTheme.dart';
import '../home/career/cosmicBackground.dart';
import '../missions/build_satellite/build_satellite_intro_screen.dart';
import '../missions/choose_right_satellite/choose_right_satellite_screen.dart';
import '../missions/code_satellite/code_satellite_screen.dart';
import '../missions/earth_detective/earth_detective_screen.dart';
import '../missions/hand_crank_lamp/hand_crank_lamp_screen.dart';
import '../missions/how_much_can_you_see/how_much_can_you_see_screen.dart';
import '../missions/leaky_bucket/leaky_bucket_screen.dart';
import '../missions/orbit_launcher/orbit_launcher_screen.dart';
import '../missions/power_balance/power_balance_screen.dart';
import '../missions/recipe_creature/recipe_creature_screen.dart';
import '../missions/restore_earth/restore_earth_intro_screen.dart';
import '../missions/satellite_doctor/satellite_doctor_screen.dart';
import '../missions/save_coastal_city/save_coastal_city_screen.dart';
import '../missions/signal_rescue/signal_rescue_screen.dart';
import '../missions/source_personalities/source_personalities_screen.dart';
import '../missions/trace_it_back/trace_it_back_screen.dart';

class _ActivityEntry {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final List<Color> gradient;
  final WidgetBuilder builder;
  const _ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.gradient,
    required this.builder,
  });
}

final List<_ActivityEntry> _activities = [
  _ActivityEntry(
    title: 'The One Thing You Need',
    subtitle: 'Build a creature from its instructions, lose it, then discover the one thing that brings it back.',
    tag: 'HOW DE-EXTINCTION WORKS · PROLOGUE',
    icon: Icons.biotech_rounded,
    gradient: const [Color(0xFF13331F), Color(0xFF101A30)],
    builder: (_) => const RecipeCreatureScreen(),
  ),
  _ActivityEntry(
    title: 'Power for a Day',
    subtitle: 'Run a whole town on one source at a time across a day — and feel why none of them is perfect.',
    tag: 'HOW THINGS WORK · ELECTRICITY · EP 1.2',
    icon: Icons.location_city_rounded,
    gradient: const [Color(0xFF2A1E3E), Color(0xFF14233F)],
    builder: (_) => const SourcePersonalitiesScreen(),
  ),
  _ActivityEntry(
    title: 'The Leaky Bucket',
    subtitle: 'Send a power plant’s energy down the chain and watch most of it escape as heat — then try to do better.',
    tag: 'HOW THINGS WORK · ELECTRICITY · EP 1.3',
    icon: Icons.local_fire_department_rounded,
    gradient: const [Color(0xFF3A2412), Color(0xFF1A1330)],
    builder: (_) => const LeakyBucketScreen(),
  ),
  _ActivityEntry(
    title: 'Trace It Back',
    subtitle: 'Spin a magnet, clip on a turbine, swap the source — find the one trick behind every power plant.',
    tag: 'HOW THINGS WORK · ELECTRICITY · EP 1',
    icon: Icons.bolt_rounded,
    gradient: const [Color(0xFF3A2C12), Color(0xFF1A1330)],
    builder: (_) => const TraceItBackScreen(),
  ),
  _ActivityEntry(
    title: 'Hand-Crank Lamp',
    subtitle: 'Crank a generator and watch the lamp live and die with your effort — nothing is stored.',
    tag: 'HOW THINGS WORK · ELECTRICITY · PROLOGUE',
    icon: Icons.flashlight_on_rounded,
    gradient: const [Color(0xFF2C2A12), Color(0xFF161330)],
    builder: (_) => const HandCrankLampScreen(),
  ),
  _ActivityEntry(
    title: 'Build Your Satellite',
    subtitle: 'Assemble a working satellite, part by part.',
    tag: 'SATELLITE ENGINEER',
    icon: Icons.satellite_alt_rounded,
    gradient: const [Color(0xFF3A2C7A), Color(0xFF1A2566)],
    builder: (_) => const BuildSatelliteIntroScreen(),
  ),
  _ActivityEntry(
    title: 'Restore Earth',
    subtitle: 'Use satellite powers to fix Earth’s broken systems.',
    tag: 'SATELLITE ENGINEER · EP 1',
    icon: Icons.public_rounded,
    gradient: const [Color(0xFF0E4C8A), Color(0xFF0B2A66)],
    builder: (_) => const RestoreEarthIntroScreen(),
  ),
  _ActivityEntry(
    title: 'How Much Can You See?',
    subtitle: 'Raise a camera from the ground to space and watch the view grow.',
    tag: 'SATELLITE ENGINEER · EP 2',
    icon: Icons.travel_explore_rounded,
    gradient: const [Color(0xFF0B5C7A), Color(0xFF0B2A66)],
    builder: (_) => const HowMuchCanYouSeeScreen(),
  ),
  _ActivityEntry(
    title: 'Orbit Launcher',
    subtitle: 'Give the satellite enough sideways speed to fall around Earth.',
    tag: 'SATELLITE ENGINEER · EP 3',
    icon: Icons.rocket_launch_rounded,
    gradient: const [Color(0xFF5A2C9E), Color(0xFF241A66)],
    builder: (_) => const OrbitLauncherScreen(),
  ),
  _ActivityEntry(
    title: 'Choose the Right Satellite',
    subtitle: 'Dispatch the right satellite to solve each Earth emergency.',
    tag: 'SATELLITE ENGINEER · EP 5',
    icon: Icons.satellite_alt_rounded,
    gradient: const [Color(0xFF0E3A6E), Color(0xFF0B1F4A)],
    builder: (_) => const ChooseRightSatelliteScreen(),
  ),
  _ActivityEntry(
    title: 'Keep the Satellite Alive',
    subtitle: 'Balance sunlight, battery and tools to capture cyclones and survive Earth’s shadow.',
    tag: 'SATELLITE ENGINEER · EP 6',
    icon: Icons.battery_charging_full_rounded,
    gradient: const [Color(0xFF0E4C8A), Color(0xFF0B2A66)],
    builder: (_) => const PowerBalanceScreen(),
  ),
  _ActivityEntry(
    title: 'Signal Rescue Mission',
    subtitle: 'Aim the antenna, catch the window, and send the cyclone image to Earth.',
    tag: 'SATELLITE ENGINEER · EP 7',
    icon: Icons.settings_input_antenna_rounded,
    gradient: const [Color(0xFF0E5C8A), Color(0xFF0B2A66)],
    builder: (_) => const SignalRescueScreen(),
  ),
  _ActivityEntry(
    title: 'Earth Detective Mission',
    subtitle: 'Study satellite images to find clues and protect Earth.',
    tag: 'SATELLITE ENGINEER · EP 8',
    icon: Icons.travel_explore_rounded,
    gradient: const [Color(0xFF0E4C8A), Color(0xFF09244F)],
    builder: (_) => const EarthDetectiveScreen(),
  ),
  _ActivityEntry(
    title: 'Code the Satellite',
    subtitle: 'Arrange command blocks so the satellite captures and sends a cyclone warning.',
    tag: 'SATELLITE ENGINEER · EP 10',
    icon: Icons.terminal_rounded,
    gradient: const [Color(0xFF1B2A66), Color(0xFF0B1633)],
    builder: (_) => const CodeSatelliteScreen(),
  ),
  _ActivityEntry(
    title: 'Satellite Doctor',
    subtitle: 'Diagnose system alerts and repair the satellite, fault by fault.',
    tag: 'SATELLITE ENGINEER · EP 9',
    icon: Icons.medical_services_rounded,
    gradient: const [Color(0xFF0E5C7A), Color(0xFF0B2A66)],
    builder: (_) => const SatelliteDoctorScreen(),
  ),
  _ActivityEntry(
    title: 'Save the Coastal City',
    subtitle: 'FINAL BOSS — run the full mission chain and warn the city before the cyclone hits.',
    tag: 'SATELLITE ENGINEER · EP 11 · FINAL',
    icon: Icons.warning_amber_rounded,
    gradient: const [Color(0xFF7A1E3A), Color(0xFF1A2566)],
    builder: (_) => const SaveCoastalCityMissionScreen(),
  ),
];

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        PressableScale(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: GlassSurface(
                            radius: 14,
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.arrow_back_rounded,
                                size: 20, color: CareerColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Activities', style: CareerText.greeting.copyWith(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('Pick a mission to play',
                          style: CareerText.subtitle.copyWith(color: CareerColors.textMuted)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _activities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => RevealOnLoad(
                          delay: Duration(milliseconds: 80 + i * 80),
                          child: _ActivityCard(
                            entry: _activities[i],
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: _activities[i].builder)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entry, required this.onTap});

  final _ActivityEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: entry.gradient,
          ),
          borderRadius: BorderRadius.circular(CareerRadii.card),
          border: Border.all(color: CareerColors.glassBorder),
          boxShadow: [
            BoxShadow(color: entry.gradient.last.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            IconBadge(icon: entry.icon, color: CareerColors.cyan, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.tag,
                      style: CareerText.label.copyWith(color: CareerColors.cyan, fontSize: 8)),
                  const SizedBox(height: 4),
                  Text(entry.title,
                      style: CareerText.cardTitleLg.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(entry.subtitle,
                      style: CareerText.body.copyWith(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_fill_rounded, size: 34, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
