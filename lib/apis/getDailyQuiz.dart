import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchDailyQuiz(
    {required String examPrep, required int standard}) async {
  final url =
      'https://glutaclass.com:8080/gluta/famV2/daily-quiz?examPrep=$examPrep&standard=$standard';

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
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception(
          "Failed to fetch daily quiz. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching daily quiz: $e");
  }
}
