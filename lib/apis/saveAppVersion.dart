import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> saveAppVersion({required String appVersion}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/save-app-version';

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "appVersion": appVersion,
    };

    // Make the POST request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print("App version sueccessfully");
    } else {
      print('Failed to save app version. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error saving app version: $e');
  }
}
