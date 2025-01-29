import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchQuizzes() async {
  const url = 'https://glutaclass.com:8080/gluta/famV2/quizzes';

  try {
    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
          "Failed to fetch quizzes. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching quizzes: $e");
  }
}
