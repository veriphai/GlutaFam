// DEV-ONLY launcher for the Episode-2 ("The Long Way Home") activities, so each
// can be run individually without going through the lesson/episode flow. Reached
// from a kDebugMode-gated card on the career home; never shown in release builds.
//
// Each row pushes the activity's screen directly via the activity registry
// (buildActivityScreen) — the same widget the lesson runner would build.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/career/careerTheme.dart';
import '../missions/activityRegistry.dart';
import '../missions/activity_header.dart' show ReplayableActivity;

class _Ep2Activity {
  const _Ep2Activity(this.beat, this.title, this.id);
  final String beat;
  final String title;
  final String id; // registry activityId
}

const List<_Ep2Activity> _kEp2Activities = [
  _Ep2Activity('2.1', 'The Push and the Flow', 'voltage_and_current'),
  _Ep2Activity('2.2', 'Shape the Wire', 'what_resistance_is'),
  _Ep2Activity('2.3', 'The Hot Wire', 'current_heats_wire'),
  _Ep2Activity('2.4', 'The Squared Loss', 'squared_loss'),
  _Ep2Activity('2.5', 'The Transmission Trick', 'transmission_trick'),
  _Ep2Activity('2.6', 'The Transformer', 'the_transformer'),
  _Ep2Activity('2.7', 'The Two Currents (AC vs DC)', 'ac_vs_dc'),
  _Ep2Activity('2.8', 'War of the Currents', 'war_of_currents'),
  _Ep2Activity('CER', 'Make Your Case', 'make_your_case_ep2'),
];

class Ep2ActivitiesDevScreen extends StatelessWidget {
  const Ep2ActivitiesDevScreen({super.key});

  void _launch(BuildContext context, _Ep2Activity a) {
    final screen = buildActivityScreen(a.id);
    if (screen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No screen registered for "${a.id}"')),
      );
      return;
    }
    // Host it so the collectible "Replay" button restarts the activity in place
    // (same as inside a lesson), instead of falling back to a pop/exit.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReplayableActivity(activityName: a.title, child: screen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareerColors.bgMid,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CareerColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DEV · EPISODE 2',
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 9.5,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                    color: CareerColors.textSecondary)),
            Text('The Long Way Home',
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 19, fontWeight: FontWeight.w800, color: CareerColors.textPrimary)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: CareerGradients.page),
        child: SafeArea(
          top: false,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: _kEp2Activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _ActivityCard(
              activity: _kEp2Activities[i],
              onTap: () => _launch(context, _kEp2Activities[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onTap});
  final _Ep2Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CareerColors.glassFill,
      borderRadius: BorderRadius.circular(CareerRadii.smallCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CareerRadii.smallCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CareerRadii.smallCard),
            border: Border.all(color: CareerColors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF18213F), Color(0xFF0C1330)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3FB9F5).withValues(alpha: 0.4)),
                ),
                child: Text(activity.beat,
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7FD8FF))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(activity.title,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: CareerColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(activity.id,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 10.5,
                            letterSpacing: 0.3,
                            color: CareerColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded, color: CareerColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
