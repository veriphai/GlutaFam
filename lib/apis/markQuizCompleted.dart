import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<String> markQuizCompletion(
    {required String quizId,
    required int attemptTime,
    required int timeToComplete,
    required int xpGained,
    required double accuracy,
    required int correctAnswers,
    required List<Map<String, dynamic>> report}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/quiz-completed';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "quizId": quizId,
      "attemptTime": attemptTime,
      "timeToComplete": timeToComplete,
      "xpGained": xpGained,
      "accuracy": accuracy,
      "report": report,
      "correctAnswers": correctAnswers
    };

    // Construct the request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken', // Use the stored auth token
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to save quiz result. Status code: ${response.statusCode}');
      return "FAILURE";
    }
  } catch (e) {
    print('Error saving quiz result: $e');
    return "FAILURE";
  }
}
