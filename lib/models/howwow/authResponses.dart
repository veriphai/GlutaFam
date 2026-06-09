// Typed responses for the /howwow/auth/* endpoints.

import 'howwowProfile.dart';

/// 200 OK body of `POST /howwow/auth/login`.
class LoginResponse {
  const LoginResponse({
    required this.appJwt,
    required this.newUser,
    this.userTrackingId,
    this.profile,
  });

  final String appJwt;
  final bool newUser;
  final String? userTrackingId;
  final HowwowProfile? profile;

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        appJwt: j['appJwt'] as String? ?? '',
        newUser: j['newUser'] == true,
        userTrackingId: j['userTrackingId'] as String?,
        profile: j['profile'] is Map
            ? HowwowProfile.fromJson(Map<String, dynamic>.from(j['profile']))
            : null,
      );
}

/// 200 OK body of `POST /howwow/auth/phone/verify`.
class PhoneVerifyResponse {
  const PhoneVerifyResponse({
    this.phoneNumber,
    this.phoneVerified = false,
    this.appJwt,
  });

  final String? phoneNumber;
  final bool phoneVerified;
  final String? appJwt;

  factory PhoneVerifyResponse.fromJson(Map<String, dynamic> j) => PhoneVerifyResponse(
        phoneNumber: j['phoneNumber'] as String?,
        phoneVerified: j['phoneVerified'] == true,
        appJwt: j['appJwt'] as String?,
      );
}
