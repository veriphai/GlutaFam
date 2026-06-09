// Canonical app-update check for the career app — THE single
// implementation (the three copy-pasted variants in the legacy home
// screens are unreachable since main.dart routes through AuthGate →
// CareerHomeScreen, and lib/widgets/customUpdateBottomSheet.dart is an
// orphan; none of those were deleted, just superseded).
//
// Flow (functional mirror of the legacy famV2 checkForAppUpdate):
//   1. Stamp the installed version on the user doc (fire-and-forget).
//   2. Fetch the remote toggle from GET /howwow/app-version-details
//      (doc `latest-app-build` in the howwow DB).
//   3. installed < minimumVersion          → FORCED sheet (not dismissible)
//      installed < latestVersion(platform) → sheet, dismissibility per the
//                                            backend `forceUpdate` toggle
//      otherwise                           → nothing.
//   4. UPDATE NOW → Play Store / App Store.
//
// Fails soft on any error (network, 401 before auth settles, missing doc):
// logs `update_check_failed` and skips — an update prompt is never worth
// blocking the home screen for.
//
// Call `runAppUpdateFlow(context)` once after the first authenticated
// screen mounts (CareerHomeScreen.initState does this post-frame).

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/howwow/howwowAppVersion.dart';
import '../screens/home/career/careerTheme.dart';
import 'howwowEventLogger.dart';
import 'howwowEventNames.dart';

const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.gluta.glutafam';
const String _appStoreUrl =
    'https://apps.apple.com/us/app/tuto-ai-tutor-for-class-6-12/id6736943726';

/// One check per app session — re-running on every home rebuild would
/// re-show a dismissed optional prompt and double-fire telemetry.
bool _ranThisSession = false;

/// Entry point. Safe to call unconditionally from initState (post-frame);
/// dedupes itself, never throws.
Future<void> runAppUpdateFlow(BuildContext context) async {
  if (_ranThisSession) return;
  _ranThisSession = true;

  String currentVersion = '';
  try {
    currentVersion = (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return; // no version, nothing to compare
  }

  // Installed-version stamp — independent of the prompt outcome.
  unawaited(howwowSaveAppVersion(currentVersion).catchError((_) {}));

  final HowwowAppVersionDetails details;
  try {
    details = await howwowGetAppVersionDetails();
  } catch (e) {
    HowwowEventLogger.instance.log(
      HowwowEvents.updateCheckFailed,
      props: {'error': e.toString(), 'current_version': currentVersion},
    );
    return;
  }

  final bool isAndroid = !kIsWeb && Platform.isAndroid;
  final String? latestVersion =
      isAndroid ? details.latestVersionAndroid : details.latestVersionIOS;

  // Two tiers, same as the legacy check: below the minimum floor is always
  // forced; below latest is prompted with backend-controlled dismissibility.
  final bool belowMinimum = details.minimumVersion != null &&
      isVersionLower(currentVersion, details.minimumVersion!);
  final bool belowLatest = latestVersion != null &&
      isVersionLower(currentVersion, latestVersion);
  if (!belowMinimum && !belowLatest) return;
  final bool forced = belowMinimum || details.forceUpdate;

  if (!context.mounted) return;

  HowwowEventLogger.instance.logImmediate(
    HowwowEvents.updatePromptShown,
    props: {
      'current_version': currentVersion,
      'latest_version': latestVersion,
      'is_forced': forced,
      'platform': isAndroid ? 'android' : 'ios',
    },
  );

  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: !forced,
    enableDrag: !forced,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UpdateSheet(
      forced: forced,
      message: details.message ?? 'A new version of Tuto is available.',
      updateNotes: details.updateNotes,
    ),
  );

  if (accepted == true) {
    HowwowEventLogger.instance.logImmediate(
      HowwowEvents.updateAccepted,
      props: {
        'current_version': currentVersion,
        'latest_version': latestVersion,
        'was_forced': forced,
      },
    );
    await _launchStore(isAndroid: isAndroid);
  } else {
    HowwowEventLogger.instance.log(
      HowwowEvents.updateDismissed,
      props: {
        'current_version': currentVersion,
        'latest_version': latestVersion,
      },
    );
  }
}

/// Hardened semver-ish compare: pads unequal lengths with zeros and
/// tolerates junk segments ("1.2.15-beta" → [1,2,15]), so a malformed
/// backend value can never crash the home screen. The legacy copies
/// indexed `latest` by `current`'s length (RangeError on "1.3" vs
/// "1.2.17") and used a bare int.parse — both fixed here.
@visibleForTesting
bool isVersionLower(String current, String latest) {
  List<int> parts(String v) => v
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList(growable: false);
  final c = parts(current), l = parts(latest);
  final n = c.length > l.length ? c.length : l.length;
  for (var i = 0; i < n; i++) {
    final a = i < c.length ? c[i] : 0;
    final b = i < l.length ? l[i] : 0;
    if (a < b) return true;
    if (a > b) return false;
  }
  return false;
}

Future<void> _launchStore({required bool isAndroid}) async {
  final uri = Uri.parse(isAndroid ? _playStoreUrl : _appStoreUrl);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    // ignore: avoid_print
    print('appUpdateCheck: could not launch store: $e');
  }
}

/// Career-themed update sheet. Pops with `true` when UPDATE NOW is tapped;
/// dismissal (swipe / tap-outside / "Not now") resolves the sheet future
/// with null. When [forced], PopScope blocks the back gesture and the
/// dismiss affordances are absent — the only way forward is the store.
class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({
    required this.forced,
    required this.message,
    required this.updateNotes,
  });

  final bool forced;
  final String message;
  final List<String> updateNotes;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forced,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, 20 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: CareerColors.bgMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: CareerColors.glassBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch_rounded,
                    color: CareerColors.gold, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Update Available',
                  style: GoogleFonts.poppins(
                    color: CareerColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: CareerColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (updateNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final note in updateNotes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.poppins(
                            color: CareerColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: CareerGradients.gold,
                  borderRadius: BorderRadius.circular(CareerRadii.pill),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                    ),
                  ),
                  child: Text(
                    'UPDATE NOW',
                    style: GoogleFonts.poppins(
                      color: CareerColors.onLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            if (!forced)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Not now',
                    style: GoogleFonts.poppins(
                      color: CareerColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
