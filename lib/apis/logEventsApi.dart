import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final AuthTokenService authTokenService = AuthTokenService();

Future<void> logPageOpenEvent({
  required String screenName,
  required Map<String, dynamic> eventDetails,
}) async {
  await logEvent(
    eventType: "screenView",
    screenName: screenName,
    eventDetails: eventDetails,
  );
}

Future<void> logEvent(
    {required String eventType,
    required String screenName,
    required Map<String, dynamic> eventDetails,
    String? eventName}) async {
  const String apiUrl = 'https://glutaclass.com:8080/gluta/fam/log-event';

  // Retrieve the auth token from secure storage
  String? authToken = await authTokenService.getAuthToken();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? firstLaunchBool = prefs.getBool('firstLaunch');
  bool firstLaunch = firstLaunchBool ?? true;
  if (firstLaunch) {
    authToken = "app-first-launch";
  }
  int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if (authToken != null) {
    final body = {
      "eventName": eventName,
      "eventType": eventType,
      "screenName": screenName,
      "eventDetails": eventDetails,
      "eventTime": currentTimestamp,
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
      print("Failed to log event. Status code: ${response.statusCode}");
    }
  }
}
