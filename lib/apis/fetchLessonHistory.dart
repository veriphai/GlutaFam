import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchLessonHistory(
    {required String conceptConversationKey}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/tutor/view-lesson-history?conceptConversationKey=$conceptConversationKey';

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
      final utf8DecodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = json.decode(utf8DecodedBody);
      return data;
    } else {
      print(
          'Failed to fetch lesson history. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error fetching lessons history: $e');
    return {};
  }
}