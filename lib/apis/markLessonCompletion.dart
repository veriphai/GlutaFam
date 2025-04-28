import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> markLessonCompletion(
    {required String lessonId,
    required int attemptTime,
    required int timeToComplete,
    required int xpGained,
    required double accuracy,
    required String bookId,
    required int correctlyAnswered,
    required List<Map<String, dynamic>> report,
    required int mistakesCorrected}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/lesson-completed';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "lessonId": lessonId,
      "attemptTime": attemptTime,
      "timeToComplete": timeToComplete,
      "xpGained": xpGained,
      "accuracy": accuracy,
      "bookId": bookId,
      "report": report,
      "type": "lesson",
      "correctAnswers": correctlyAnswered,
      "mistakesCorrected": mistakesCorrected
    };

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
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      print(
          'Failed to save lesson result. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error saving lesson result: $e');
    return {};
  }
}
