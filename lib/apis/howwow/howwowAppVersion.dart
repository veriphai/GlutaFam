// App-update endpoints — howwow mirror of the legacy famV2 pair
// (`/gluta/famV2/app-version-details` + `/save-app-version`), so the career
// app no longer depends on the legacy namespace. Same JSON shapes; only the
// path and auth (appJwt via ApiClient) differ.
//
//   GET  /howwow/app-version-details
//   POST /howwow/save-app-version      body: {"appVersion": "1.2.17"}
//
// Consumed exclusively by lib/utils/appUpdateCheck.dart.

import '../apiClient.dart';
import '../endpoints.dart';

/// Remote update toggle, exactly as stored in the backend's
/// `app-version-details/latest-app-build` doc (howwow DB).
class HowwowAppVersionDetails {
  const HowwowAppVersionDetails({
    this.latestVersionIOS,
    this.latestVersionAndroid,
    this.minimumVersion,
    this.forceUpdate = false,
    this.message,
    this.updateNotes = const [],
  });

  final String? latestVersionIOS;
  final String? latestVersionAndroid;

  /// Installs below this are FORCE-prompted regardless of [forceUpdate].
  final String? minimumVersion;

  /// When true, the optional-update sheet is also non-dismissible.
  final bool forceUpdate;

  final String? message;
  final List<String> updateNotes;

  factory HowwowAppVersionDetails.fromJson(Map<String, dynamic> j) =>
      HowwowAppVersionDetails(
        latestVersionIOS: j['latestVersionIOS'] as String?,
        latestVersionAndroid: j['latestVersionAndroid'] as String?,
        minimumVersion: j['minimumVersion'] as String?,
        forceUpdate: j['forceUpdate'] == true,
        message: j['message'] as String?,
        updateNotes: (j['updateNotes'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
      );
}

/// GET `/howwow/app-version-details`. Throws [ApiException] on non-2xx —
/// the caller (appUpdateCheck) fails soft and skips the prompt.
Future<HowwowAppVersionDetails> howwowGetAppVersionDetails() async {
  final json = await ApiClient.instance.getJson(
    Endpoints.howwow('/app-version-details'),
  );
  return HowwowAppVersionDetails.fromJson(json);
}

/// POST `/howwow/save-app-version` — stamps the installed version on the
/// user doc (analytics-grade state, no side effects). Fire-and-forget from
/// the update flow.
Future<void> howwowSaveAppVersion(String appVersion) async {
  await ApiClient.instance.postJson(
    Endpoints.howwow('/save-app-version'),
    body: {'appVersion': appVersion},
  );
}
