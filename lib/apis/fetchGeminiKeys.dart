import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<String>> fetchGeminiKeys() async {
  try {
    String url = 'https://glutaclass.com:8080/gluta/famV2/get-gemini-keys';

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
      return List<String>.from(data);
    } else {
      print('Failed to fetch gemini keys. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetching gemini keys: $e');
    return [];
  }
}
