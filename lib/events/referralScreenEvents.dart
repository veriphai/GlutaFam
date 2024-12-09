import 'package:eureka_app/apis/logEventsApi.dart';

void logReferralScreenView(int convertedReferral) {
  logEvent(
    eventName: "referral_sv",
    screenName: "ReferralScreen",
    eventType: "screen_view",
    eventDetails: {"convertedReferral": convertedReferral},
  );
}

void logInviteButtonClick(int convertedReferral) {
  logEvent(
    eventName: "referral_invite_click",
    screenName: "ReferralScreen",
    eventType: "button_click",
    eventDetails: {"convertedReferral": convertedReferral},
  );
}

void logRedeemGiftButtonClick(int convertedReferral, bool giftRedeemed) {
  logEvent(
    eventName: "referral_redeem_gift",
    screenName: "ReferralScreen",
    eventType: "button_click",
    eventDetails: {
      "convertedReferral": convertedReferral,
      "giftRedeemed": giftRedeemed
    },
  );
}

void logRedeemGiftScreenView(int convertedReferral, bool giftRedeemed) {
  logEvent(
    eventName: "redeem_gift_sv",
    screenName: "RedeemGiftScreen",
    eventType: "screen_view",
    eventDetails: {
      "convertedReferral": convertedReferral,
      "giftRedeemed": giftRedeemed
    },
  );
}

void logRedeemButtonClick(int convertedReferral, String giftId) {
  logEvent(
    eventName: "redeem_screen_redeem_click",
    screenName: "RedeemGiftScreen",
    eventType: "button_click",
    eventDetails: {
      "convertedReferral": convertedReferral,
      "giftId": giftId,
    },
  );
}

void logPhoneNumberForRedemption(
    int convertedReferral, String giftId, String phoneNumber) {
  logEvent(
    eventName: "redeem_gift_requested",
    screenName: "RedeemGiftScreen",
    eventType: "button_click",
    eventDetails: {
      "convertedReferral": convertedReferral,
      "giftId": giftId,
      "phoneNumber": phoneNumber
    },
  );
}

void logGiftSucessfullyRedeemedContinueButtonClick(
    int convertedReferral, String giftId) {
  logEvent(
    eventName: "redeem_gift_confirmed",
    screenName: "RedeemGiftScreen",
    eventType: "button_click",
    eventDetails: {
      "convertedReferral": convertedReferral,
      "giftId": giftId,
    },
  );
}
