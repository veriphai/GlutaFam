import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchChaptersToResume() async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/tutor/resume-chapter-list';

    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    print('Fetching chapters from: $url'); // Debug log
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final utf8Body =
          utf8.decode(response.bodyBytes); // ✅ proper UTF-8 decoding
      final List<dynamic> data = json.decode(utf8Body);

      if (data is List) {
        // Ensure the parsed data is a list of maps
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Unexpected response format: $utf8Body');
        return [];
      }
    } else {
      print(
          'Failed to fetch chapters to resume. Status code: ${response.statusCode}');
      print('Response Body: ${response.body}'); // Debug log
      return [];
    }
  } catch (e) {
    print('Error fetching chapters: $e');
    return [];
  }
}
