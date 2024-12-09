import 'package:eureka_app/apis/logEventsApi.dart';

void logOnboardingScreenView(
    String deviceId, String devicePlatform, String userIp, int screenNumber) {
  logEvent(
    eventName: "onboarding_sv",
    screenName: "OnboardingScreen",
    eventType: "screen_view",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "userIp": userIp,
      "screenNumber": screenNumber
    },
  );
}

void logNextButtonClick(
    String deviceId, String devicePlatform, String userIp, int screenNumber) {
  logEvent(
    eventName: "onboarding_sv",
    screenName: "OnboardingScreen",
    eventType: "button_click",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "userIp": userIp,
      "screenNumber": screenNumber
    },
  );
}

void logLoginScreenView(String deviceId, String devicePlatform, String userIp) {
  logEvent(
    eventName: "login_sv",
    screenName: "LoginScreen",
    eventType: "screen_view",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "userIp": userIp,
    },
  );
}

void logGoogleAuthButtonClick(
    String deviceId, String devicePlatform, String userIp) {
  logEvent(
    eventName: "login_gauth",
    screenName: "LoginScreen",
    eventType: "button_click",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "userIp": userIp,
    },
  );
}

void logGoogleAuthSuccess(
    String userId, String deviceId, String devicePlatform, String userIp) {
  logEvent(
    eventName: "login_gauth_success",
    screenName: "LoginScreen",
    eventType: "auto",
    eventDetails: {
      "userId": userId,
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "userIp": userIp,
    },
  );
}

void logPhoneAuthButtonClick(
    String deviceId, String devicePlatform, String userIp) {
  logEvent(
    eventName: "login_phone_auth",
    screenName: "LoginScreen",
    eventType: "button_click",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "userIp": userIp,
    },
  );
}

void logPhoneLoginScreenView(
    String deviceId, String devicePlatform, String userIp) {
  logEvent(
    eventName: "login_phone_auth",
    screenName: "PhoneLoginScreen",
    eventType: "screen_view",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "userIp": userIp,
    },
  );
}

void logContinueButtonClickForOtp(
    String deviceId, String devicePlatform, String phoneNumber) {
  logEvent(
    eventName: "login_phone_auth",
    screenName: "PhoneLoginScreen",
    eventType: "button_click",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "phoneNumber": phoneNumber,
    },
  );
}

void logCountryCodeClick(
    String deviceId, String devicePlatform, String countryCode) {
  logEvent(
    eventName: "login_phone_auth",
    screenName: "PhoneLoginScreen",
    eventType: "button_click",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "countryCode": countryCode,
    },
  );
}

void logPhoneLoginOtpScreenView(
    String deviceId, String devicePlatform, String phoneNumber) {
  logEvent(
    eventName: "login_phone_auth_otp",
    screenName: "PhoneLoginOtpScreen",
    eventType: "screen_view",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "phoneNumber": phoneNumber,
    },
  );
}

void logContinueButtonClickForLogin(
    String deviceId, String devicePlatform, String phoneNumber) {
  logEvent(
    eventName: "login_phone_auth_otp_login",
    screenName: "PhoneLoginOtpScreen",
    eventType: "button_click",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "phoneNumber": phoneNumber,
    },
  );
}

void logClassSelectionScreenView() {
  logEvent(
    eventName: "class_selection_sv",
    screenName: "ClassSelectionScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logClassSelecletedOnOnboarding(String deviceId, String devicePlatform,
    int selectedStandard, String refereeCode) {
  logEvent(
    eventName: "class_selection_button_click",
    screenName: "ClassSelectionScreen",
    eventType: "button_click",
    eventDetails: {
      "deviceId": deviceId,
      "devicePlatform": devicePlatform,
      "standard": selectedStandard,
      "refereeCode": refereeCode
    },
  );
}
