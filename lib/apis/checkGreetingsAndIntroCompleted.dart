import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';

Future<Map<String, dynamic>> checkGreetingsAndIntroCompleted({
  required List<Map<String, String>> conversations,
  required String conceptName,
  required bool greeting,
}) async {
  try {
    const url =
        'https://glutaclass.com:8080/gluta/famV2/check-greetings-completed';

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "conversations": conversations,
      "conceptName": conceptName,
      "greeting": greeting
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
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      print(
          'Failed to check status of greetings and intro. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error checking status of  greetings and intro: $e');
    return {};
  }
}
