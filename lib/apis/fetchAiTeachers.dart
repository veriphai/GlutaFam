import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchAITeachers() async {
  try {
    String url = 'https://glutaclass.com:8080/gluta/famV2/ai-teachers';

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
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Unexpected response format: ${response.body}');
        return [];
      }
    } else {
      print('Failed to fetch ai teachers. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetching ai teachers: $e');
    return [];
  }
}
