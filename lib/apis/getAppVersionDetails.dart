import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getLatestAppVersinDetails() async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/app-version-details';

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
      return json.decode(response.body);
    } else {
      print(
          'Failed to fetch latest app version details. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error fetching latest app version details: $e');
    return {};
  }
}
