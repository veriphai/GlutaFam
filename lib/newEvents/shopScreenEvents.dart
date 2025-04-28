import 'package:eureka_app/apis/logEventsApi.dart';

void logShopScreenView() {
  logEvent(
    eventName: "shop_sv",
    screenName: "ShopScreen",
    eventType: "screen_view",
    eventDetails: {},
  );
}

void logPowerupClicked(String powerupId) {
  logEvent(
    eventName: "powerup_clicked",
    screenName: "ShopScreen",
    eventType: "button_click",
    eventDetails: {"powerupId": powerupId},
  );
}

void logPowerupPurchased(String powerupId) {
  logEvent(
    eventName: "powerup_purchased",
    screenName: "ShopScreen",
    eventType: "button_click",
    eventDetails: {"powerupId": powerupId},
  );
}

void logPowerupApplied(String powerupId) {
  logEvent(
    eventName: "powerup_applied",
    screenName: "ShopScreen",
    eventType: "button_click",
    eventDetails: {"powerupId": powerupId},
  );
}
