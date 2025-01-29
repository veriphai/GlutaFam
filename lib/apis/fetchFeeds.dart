import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchFeeds() async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/feeds';

    print('Fetching feeds from: $url');
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
      if (data is List) {
        // Ensure the parsed data is a list of maps
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Unexpected response format: ${response.body}');
        return [];
      }
    } else {
      print('Failed to fetch feeds. Status code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error fetching feeds: $e');
    return [];
  }
}
