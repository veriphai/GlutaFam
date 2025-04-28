import 'package:eureka_app/apis/logEventsApi.dart';

void logCollectionScreenView(String collectionItemId) {
  logEvent(
    eventName: "collection_item_sv",
    screenName: "CollectionScreen",
    eventType: "screen_view",
    eventDetails: {"collectionItemId": collectionItemId},
  );
}

void logCollectionItemSharedViaLink(String collectionItemId) {
  logEvent(
    eventName: "collection_item_shared_via_link",
    screenName: "CollectionScreen",
    eventType: "button_click",
    eventDetails: {"collectionItemId": collectionItemId},
  );
}

void logCollectionItemSharedOnFeed(String collectionItemId) {
  logEvent(
    eventName: "collection_item_shared",
    screenName: "CollectionScreen",
    eventType: "button_click",
    eventDetails: {"collectionItemId": collectionItemId},
  );
}
