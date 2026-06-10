// Maps a backend `activityId` string to its Flutter screen widget. Single
// source of truth — when a new activity ships, register it here and the
// lesson runner ({@link lessonRunner.dart}) picks it up automatically.
//
// Lesson sequencing (intro video → activity → outro video) lives entirely
// in {@code lessonRunner.dart}; this file knows nothing about it. That
// keeps the activity registry small, the activities themselves oblivious
// to whether they're inside a lesson, and the runner the single owner of
// the multi-screen Navigator dance.

import 'package:flutter/material.dart';

import 'build_satellite/build_satellite_intro_screen.dart';
import 'choose_right_satellite/choose_right_satellite_screen.dart';
import 'code_satellite/code_satellite_screen.dart';
import 'earth_detective/earth_detective_screen.dart';
import 'hand_crank_lamp/hand_crank_lamp_screen.dart';
import 'how_much_can_you_see/how_much_can_you_see_screen.dart';
import 'leaky_bucket/leaky_bucket_screen.dart';
import 'make_your_case/make_your_case_screen.dart';
import 'orbit_launcher/orbit_launcher_screen.dart';
import 'power_balance/power_balance_screen.dart';
import 'recipe_creature/recipe_creature_screen.dart';
import 'restore_earth/restore_earth_intro_screen.dart';
import 'satellite_doctor/satellite_doctor_screen.dart';
import 'save_coastal_city/save_coastal_city_screen.dart';
import 'signal_rescue/signal_rescue_screen.dart';
import 'source_personalities/source_personalities_screen.dart';
import 'trace_it_back/trace_it_back_screen.dart';

/// Build the activity widget for the given backend [activityId]. Returns
/// null when the id isn't recognised — callers (the lesson runner) surface
/// a "not available yet" snackbar in that case.
Widget? buildActivityScreen(String? activityId) {
  switch (activityId) {
    case 'restore_earth':
      return const RestoreEarthIntroScreen();
    case 'build_satellite':
      return const BuildSatelliteIntroScreen();
    case 'choose_right_satellite':
      return const ChooseRightSatelliteScreen();
    case 'code_satellite':
      return const CodeSatelliteScreen();
    case 'earth_detective':
      return const EarthDetectiveScreen();
    case 'hand_crank_lamp':
      return const HandCrankLampScreen();
    case 'how_much_can_you_see':
      return const HowMuchCanYouSeeScreen();
    case 'leaky_bucket':
      return const LeakyBucketScreen();
    case 'make_your_case':
      return const MakeYourCaseScreen();
    case 'orbit_launcher':
      return const OrbitLauncherScreen();
    case 'power_balance':
      return const PowerBalanceScreen();
    case 'recipe_creature':
      return const RecipeCreatureScreen();
    case 'satellite_doctor':
      return const SatelliteDoctorScreen();
    case 'save_coastal_city':
      return const SaveCoastalCityMissionScreen();
    case 'signal_rescue':
      return const SignalRescueScreen();
    case 'source_personalities':
      return const SourcePersonalitiesScreen();
    case 'trace_it_back':
      return const TraceItBackScreen();
    default:
      return null;
  }
}
