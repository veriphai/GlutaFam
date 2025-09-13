import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchLessonHistoryList(
    {required String onlyIncompleteLessons}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/tutor/lesson-history?onlyIncompleteLessons=$onlyIncompleteLessons';

    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      print(
          'Failed to fetch lesson history. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetching lessons history: $e');
    return [];
  }
}