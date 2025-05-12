import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchLanguagesAndVoices() async {
  const url = 'https://glutaclass.com:8080/gluta/famV2/languages-and-voices';

  try {
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
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception(
          "Failed to fetch languages and voices. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching languages and voices: $e");
  }
}
