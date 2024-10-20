import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> logPageOpenEvent({
  required String screenName,
  required Map<String, dynamic> eventDetails,
}) async {
  int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await logEvent(
    eventType: "screenView",
    screenName: screenName,
    eventDetails: eventDetails,
    eventTime: currentTimestamp,
  );
}

Future<void> logEvent({
  required String eventType,
  required String screenName,
  required Map<String, dynamic> eventDetails,
  required int eventTime,
}) async {
  const String apiUrl = 'https://glutaclass.com:8080/gluta/fam/log-event';
  final secureStorage = const FlutterSecureStorage();

  // Retrieve the auth token from secure storage
  final authToken = await secureStorage.read(key: 'authKey');

  if (authToken == null) {
    throw Exception("Authorization token is missing.");
  }

  final body = {
    "eventType": eventType,
    "screenName": screenName,
    "eventDetails": eventDetails,
    "eventTime": eventTime,
  };

  // Construct the request
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $authToken', // Use the stored auth token
      'Content-Type': 'application/json',
    },
    body: json.encode(body),
  );

  if (response.statusCode == 200) {
    print("Event logged successfully: $body");
  } else {
    throw Exception("Failed to log event. Status code: ${response.statusCode}");
  }
}
