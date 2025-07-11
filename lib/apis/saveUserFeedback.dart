import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> saveUserFeedback(
    {required Map<String, dynamic> lessonFeedback}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/lesson-feedback';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    // Make the POST request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
      body: json.encode(lessonFeedback),
    );

    if (response.statusCode == 200) {
      print("Lesson feedback saved successfully.");
    } else {
      print(
          'Failed to save lesson feedback. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred while saving lesson feedback: $e');
  }
}
