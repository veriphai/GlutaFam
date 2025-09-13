import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchRecommendedLessons() async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/tutor/recommended-lessons';

    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    print('Fetching recommended lessons from: $url'); // Debug log
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
    ).timeout(Duration(seconds: 50));

    if (response.statusCode == 200) {
      final utf8Body =
          utf8.decode(response.bodyBytes); // ✅ proper UTF-8 decoding
      return json.decode(utf8Body);
    } else {
      print(
          'Failed to fetch recommended lessons. Status code: ${response.statusCode}');
      print('Response Body: ${response.body}'); // Debug log
      return {};
    }
  } catch (e) {
    print('Error fetching recommended lessons: $e');
    return {};
  }
}
