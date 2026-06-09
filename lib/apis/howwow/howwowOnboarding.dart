// Onboarding profile submission — called once from BuildingUniverseScreen
// at the end of the new-user onboarding flow (Name → Age group → Interests).
//
// ── Backend contract (proposed; mirror of what the client sends) ─────────
//
//   PUT /howwow/profile/onboarding          (Bearer appJwt required)
//   {
//     "firstName": "Aarav",                 // 2–20 chars, trimmed
//     "ageGroup":  "11-13",                 // "under-11" | "11-13" | "14-16" | "17-plus"
//     "interests": ["space-rockets", ...],  // 3+ ids from the fixed client list
//     "sourceApp": "howwow"
//   }
//
//   200 → { "profile": { ...full HowwowProfile incl. the new fields... } }
//         (profile is optional — the client patches its session cache
//          locally either way, so an empty 200 body is also fine)
//
// The interest ids the client can send are defined in
// `screens/auth/onboarding/onboardingFlow.dart` (kOnboardingInterests).

import '../../models/howwow/howwowProfile.dart';
import '../apiClient.dart';
import '../endpoints.dart';
import 'howwowAuth.dart' show kHowwowSourceApp;
import 'howwowSession.dart';

/// PUT `/howwow/profile/onboarding`.
///
/// Persists the new-user onboarding answers on the HowwowUser and patches
/// the in-memory session profile so the home header greets the user by
/// name without another round trip.
///
/// Throws [ApiException] on any non-2xx response — the caller
/// (BuildingUniverseScreen) owns the retry / skip UX.
Future<void> howwowOnboardProfile({
  required String firstName,
  required String ageGroup,
  required List<String> interests,
}) async {
  final json = await ApiClient.instance.putJson(
    Endpoints.howwow('/profile/onboarding'),
    body: {
      'firstName': firstName,
      'ageGroup': ageGroup,
      'interests': interests,
      'sourceApp': kHowwowSourceApp,
    },
  );

  // Prefer the server's echo of the full profile when present; otherwise
  // patch the cached one with what we just sent.
  final profileJson = json['profile'];
  if (profileJson is Map) {
    HowwowSession.instance
        .setProfile(HowwowProfile.fromJson(Map<String, dynamic>.from(profileJson)));
  } else {
    HowwowSession.instance.patchOnboarding(
      firstName: firstName,
      ageGroup: ageGroup,
      interests: interests,
    );
  }
}
