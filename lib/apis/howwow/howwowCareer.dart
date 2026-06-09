// The /howwow/career/* client surface — gameplay data for the career
// home screen. Auth via the appJwt stored by AuthTokenService (injected
// automatically by ApiClient).

import '../../models/howwow/howwowCareer.dart';
import '../apiClient.dart';
import '../endpoints.dart';

/// GET `/howwow/career/home`.
///
/// One-shot bundle the home screen needs: stats, current mission,
/// featured professions, worlds, daily challenge, passport, notifications.
/// Throws [ApiException] on any non-2xx (e.g. 401 when no appJwt is stored,
/// which the home screen catches and falls back to local mock data for the
/// debug-skip path).
Future<HowwowHomeBundle> howwowGetHome() async {
  final json = await ApiClient.instance.getJson(Endpoints.howwow('/career/home'));
  return HowwowHomeBundle.fromJson(json);
}

/// GET `/howwow/career/professions/{id}/detail`.
///
/// Single-shot payload for the profession-detail screen: header, hero card
/// copy, full ordered mission timeline with per-user lock/completion flags,
/// reward badges, and certificate. Anonymous calls (no Bearer) succeed but
/// return a "fresh user" view; the detail screen catches errors and falls
/// back to its local mock seed when this call fails.
Future<HowwowProfessionDetail> howwowGetProfessionDetail(String professionId) async {
  // auth: true (default) attaches the Bearer when available, omits it when
  // not — the endpoint is optionally-authed, so personalised view for
  // signed-in users and a "fresh user" view for everyone else.
  final json = await ApiClient.instance.getJson(
    Endpoints.howwow('/career/professions/$professionId/detail'),
  );
  return HowwowProfessionDetail.fromJson(json);
}
