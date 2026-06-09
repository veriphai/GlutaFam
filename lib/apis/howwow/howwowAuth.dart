// The /howwow/auth/* client surface — the foundation for the revamped login
// flow. None of these are wired into the existing login screens yet; the
// current `sendIdTokenToBackend()` path stays intact so production login
// keeps working until we flip it over deliberately.
//
// To flip the new flow in (when ready):
//   • In otpPage.dart / loginScreen.dart, replace the call to
//     `sendIdTokenToBackend()` with `howwowLogin(idToken: …)` — the appJwt
//     is auto-stored, so subsequent calls work the same.
//   • Read the embedded `loginResponse.profile.phoneVerified` to route
//     Google/Apple users to the PhoneCollectionScreen → call
//     `howwowVerifyPhone(...)` on OTP success.

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../models/howwow/authResponses.dart';
import '../../screens/auth/onboarding/onboardingFlow.dart' show OnboardingPending;
import '../../screens/auth/phoneLinkScreen.dart' show PhoneCollectionPending;
import '../../utils/authTokenService.dart';
import '../../utils/howwowEventLogger.dart';
import '../../utils/howwowEventNames.dart';
import '../apiClient.dart';
import '../endpoints.dart';
import 'howwowProgress.dart' show howwowSetTimezone;
import 'howwowSession.dart';

/// The client identifies itself with `sourceApp = "howwow"` so the backend
/// can record which app each login came from (`GlutaUser.sourceApp`).
const String kHowwowSourceApp = 'howwow';

/// POST `/howwow/auth/login`.
///
/// Verifies the supplied Firebase ID token (Google / Apple / Phone) on the
/// backend, returns an appJwt + embedded profile. The appJwt is automatically
/// stored via [AuthTokenService] so every subsequent API call is authed.
///
/// Throws [ApiException] on any non-2xx response (e.g. status 401 when the
/// Firebase token is invalid / expired).
Future<LoginResponse> howwowLogin({
  required String idToken,
  String? appleName,
  String? appVersion,
  String? deviceId,
  String? fcmToken,
  String? provider, // "google" | "apple" | "phone" — used only for analytics
}) async {
  final body = <String, dynamic>{
    'idToken': idToken,
    'sourceApp': kHowwowSourceApp,
    'platform': _platform(),
    if (appVersion != null) 'appVersion': appVersion,
    if (deviceId != null) 'deviceId': deviceId,
    if (fcmToken != null) 'fcmToken': fcmToken,
    if (appleName != null) 'appleName': appleName,
  };

  try {
    final json = await ApiClient.instance.postJson(
      Endpoints.howwow('/auth/login'),
      body: body,
      auth: false, // login is the one call that doesn't require a Bearer token
    );

    final response = LoginResponse.fromJson(json);
    if (response.appJwt.isNotEmpty) {
      await AuthTokenService().setAuthToken(response.appJwt);
    }
    // Cache the profile so the home screen's header can show the user's name
    // and stats without a second round trip.
    HowwowSession.instance.setProfile(response.profile);
    // Now the event logger can stamp every future event with the real
    // userId (was using just the anonymousId before this point).
    HowwowEventLogger.instance.setUserId(response.profile?.userTrackingId);
    HowwowEventLogger.instance.logImmediate(
      HowwowEvents.loginSucceeded,
      props: {
        if (provider != null) 'provider': provider,
        'is_new_user': response.profile?.newUser ?? false,
        'platform': _platform(),
      },
    );
    // Fire-and-forget the device's IANA timezone so the streak day boundary
    // aligns with where the user actually is. Failures are logged and
    // ignored — login itself succeeded, this is a non-critical hint.
    // ignore: discarded_futures
    _syncDeviceTimezone();
    return response;
  } catch (e) {
    HowwowEventLogger.instance.logImmediate(
      HowwowEvents.loginFailed,
      props: {
        if (provider != null) 'provider': provider,
        'platform': _platform(),
        'error': e.toString(),
      },
    );
    rethrow;
  }
}

/// Read the device's IANA timezone via `flutter_timezone` and PUT it to
/// the backend. Called fire-and-forget from [howwowLogin]; failures are
/// swallowed because login itself has already succeeded and a missing TZ
/// just falls back to the server default ("Asia/Kolkata").
Future<void> _syncDeviceTimezone() async {
  try {
    final tz = await FlutterTimezone.getLocalTimezone();
    if (tz.isEmpty) return;
    await howwowSetTimezone(tz);
  } catch (e) {
    // ignore: avoid_print
    print('howwowAuth: timezone sync failed (non-fatal): $e');
  }
}

/// POST `/howwow/auth/phone/verify`.
///
/// Called after the Google/Apple-authed user successfully passes Firebase
/// phone OTP. The backend re-verifies the Firebase ID token from the phone
/// credential and confirms the `phone_number` claim matches [phoneNumber]
/// before linking it.
///
/// Returns a fresh [PhoneVerifyResponse.appJwt]; if present, it is auto-rotated
/// into [AuthTokenService] so the caller doesn't need to manage tokens.
///
/// Throws [ApiException] with `statusCode == 409` and `code == "PHONE_CONFLICT"`
/// when the phone is already attached to a different account.
Future<PhoneVerifyResponse> howwowVerifyPhone({
  required String phoneNumber,
  required String firebaseIdToken,
}) async {
  final json = await ApiClient.instance.postJson(
    Endpoints.howwow('/auth/phone/verify'),
    body: {
      'phoneNumber': phoneNumber,
      'firebaseIdToken': firebaseIdToken,
      'sourceApp': kHowwowSourceApp,
    },
  );

  final response = PhoneVerifyResponse.fromJson(json);
  if (response.appJwt != null && response.appJwt!.isNotEmpty) {
    await AuthTokenService().setAuthToken(response.appJwt!);
  }
  HowwowSession.instance.patchPhone(
    phoneNumber: response.phoneNumber,
    phoneVerified: response.phoneVerified,
  );
  return response;
}

/// POST `/howwow/auth/phone` — **TEMP no-verification shortcut**.
///
/// Saves the supplied phone number directly on the current HowwowUser and
/// flips `phoneVerified=true` so AuthGate routes the user into home. Real
/// Firebase-OTP verification ([howwowVerifyPhone] above) is intentionally
/// bypassed while we sort out web reCAPTCHA + account-merge UX — the real
/// path stays in place so we can flip back by switching call sites.
Future<PhoneVerifyResponse> howwowSetPhone({
  required String phoneNumber,
}) async {
  final json = await ApiClient.instance.postJson(
    Endpoints.howwow('/auth/phone'),
    body: {
      'phoneNumber': phoneNumber,
      'sourceApp': kHowwowSourceApp,
    },
  );

  final response = PhoneVerifyResponse.fromJson(json);
  if (response.appJwt != null && response.appJwt!.isNotEmpty) {
    await AuthTokenService().setAuthToken(response.appJwt!);
  }
  HowwowSession.instance.patchPhone(
    phoneNumber: response.phoneNumber,
    phoneVerified: response.phoneVerified,
  );
  return response;
}

/// POST `/howwow/auth/fcm` — push the device's current FCM token to the
/// backend so notifications keep reaching the user.
///
/// Designed to be safe to call anywhere, anytime:
///   • Empty/null token → no-op.
///   • No stored appJwt (anonymous session, debug-skip path) → no-op.
///     The next /auth/login will pick up the token via LoginRequest.fcmToken.
///   • API error (network, 500, etc.) → swallowed silently. The next launch
///     or onTokenRefresh will retry. We never want a failed token refresh
///     to surface as a user-visible error or crash the app.
///
/// Idempotent on the backend (same token → no-op).
Future<void> howwowSetFcmToken(String? fcmToken) async {
  if (fcmToken == null || fcmToken.isEmpty) return;
  final auth = await AuthTokenService().getAuthToken();
  if (auth == null || auth.isEmpty) return;
  try {
    await ApiClient.instance.postJson(
      Endpoints.howwow('/auth/fcm'),
      body: {'fcmToken': fcmToken},
    );
  } catch (_) {
    // Best-effort: ignore. Will retry on next launch / next rotation.
  }
}

/// POST `/howwow/auth/refresh` — issue a fresh appJwt for the current user.
/// Auto-rotates into [AuthTokenService] on success.
Future<String> howwowRefresh() async {
  final json = await ApiClient.instance.postJson(Endpoints.howwow('/auth/refresh'));
  final appJwt = json['appJwt'] as String? ?? '';
  if (appJwt.isNotEmpty) {
    await AuthTokenService().setAuthToken(appJwt);
  }
  return appJwt;
}

/// POST `/howwow/auth/logout` — clears the device FCM token server-side.
/// The local authKey is **not** cleared here so callers can flush analytics
/// first if they want; clear it yourself when the user is leaving the app:
///   `await AuthTokenService().setAuthToken('');`
Future<void> howwowLogout() async {
  // Fire the logout event BEFORE the network call so it's stamped under
  // the still-authenticated userId; the immediate POST path also forces
  // it onto the wire before the session ends.
  HowwowEventLogger.instance.logImmediate(HowwowEvents.logout);
  try {
    await ApiClient.instance.postJson(Endpoints.howwow('/auth/logout'));
  } finally {
    // Best-effort flush of any pending batched events before we lose the
    // userId stamp. Strip the userId so subsequent anonymous events
    // don't carry the now-stale identity.
    await HowwowEventLogger.instance.flush();
    HowwowEventLogger.instance.setUserId(null);
    // Clear signup resume markers so a fresh login doesn't inherit
    // stale "you were mid-X" state from the previous account.
    await PhoneCollectionPending.clear();
    await OnboardingPending.clear();
  }
}

String _platform() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return 'other';
  }
}
