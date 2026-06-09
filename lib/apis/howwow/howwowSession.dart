// In-memory cache of the most recent howwow user profile.
//
// /howwow/career/home returns gameplay data (stats, missions, worlds) but
// not identity (name, avatar) — those live on the profile returned by
// /howwow/auth/login. Rather than make a second call on every home render,
// we cache the profile here right after login and read from it.
//
// Scope: pure in-memory, singleton, cleared on app restart. That's fine —
// AuthGate runs /auth/login at app launch when an authKey is stored, so the
// session is repopulated naturally on every cold start.

import '../../models/howwow/howwowProfile.dart';

class HowwowSession {
  HowwowSession._();
  static final HowwowSession instance = HowwowSession._();

  HowwowProfile? _profile;

  HowwowProfile? get profile => _profile;

  /// Set after a successful /auth/login. May be replaced later by
  /// /auth/phone or /auth/refresh-style calls that return a fresh profile.
  void setProfile(HowwowProfile? profile) {
    _profile = profile;
  }

  /// Patch the cached profile with a phone-number update from the
  /// /auth/phone (no-verify) flow, which returns just the phone bits.
  /// Reuses every other field from the existing cached profile.
  void patchPhone({String? phoneNumber, bool phoneVerified = false}) {
    final p = _profile;
    if (p == null) return;
    _profile = HowwowProfile(
      userTrackingId: p.userTrackingId,
      firstName: p.firstName,
      lastName: p.lastName,
      displayName: p.displayName,
      emailId: p.emailId,
      phoneNumber: phoneNumber ?? p.phoneNumber,
      phoneVerified: phoneVerified,
      avatar: p.avatar,
      signInProvider: p.signInProvider,
      sourceApp: p.sourceApp,
      newUser: p.newUser,
      ageGroup: p.ageGroup,
      interests: p.interests,
      stats: p.stats,
      career: p.career,
      notifications: p.notifications,
    );
  }

  /// Patch the cached profile with the new-user onboarding answers so the
  /// home header can greet the user by name immediately, without waiting
  /// for the next /auth/login. If nothing is cached yet (cold resume of an
  /// interrupted onboarding) a minimal profile is created instead.
  void patchOnboarding({
    required String firstName,
    String? ageGroup,
    List<String>? interests,
  }) {
    final p = _profile;
    _profile = HowwowProfile(
      userTrackingId: p?.userTrackingId,
      firstName: firstName,
      lastName: p?.lastName,
      displayName: p?.displayName,
      emailId: p?.emailId,
      phoneNumber: p?.phoneNumber,
      phoneVerified: p?.phoneVerified ?? false,
      avatar: p?.avatar,
      signInProvider: p?.signInProvider,
      sourceApp: p?.sourceApp,
      newUser: false, // onboarding done — no longer "new"
      ageGroup: ageGroup ?? p?.ageGroup,
      interests: interests ?? p?.interests ?? const [],
      stats: p?.stats,
      career: p?.career,
      notifications: p?.notifications,
    );
  }

  void clear() {
    _profile = null;
  }
}
