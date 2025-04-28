import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<String> markLessonStart(
    {required String lessonId, required int attemptTime}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/lesson-started';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final body = {"lessonId": lessonId, "attemptTime": attemptTime};

    // Construct the request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken', // Use the stored auth token
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(
          'Failed to save leasson start. Status code: ${response.statusCode}');
      return "FAILURE";
    }
  } catch (e) {
    print('Error saving lesson start: $e');
    return "FAILURE";
  }
}
