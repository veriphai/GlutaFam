import 'package:eureka_app/apis/logEventsApi.dart';

void logNotificationReceived() {
  logEvent(
    eventName: "notification_received",
    screenName: "Notification Received",
    eventType: "notification",
    eventDetails: {},
  );
}

void logNotificationTapped() {
  logEvent(
    eventName: "notification_tapped",
    screenName: "Notification Tapped",
    eventType: "notification",
    eventDetails: {},
  );
}
