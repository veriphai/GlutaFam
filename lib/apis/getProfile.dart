import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchUserProfile() async {
  const url = 'http://localhost:8080/gluta/fam/profile';

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
      // Parse the response and return the profile data
      final Map<String, dynamic> data = json.decode(response.body);
      print("User Profile: $data");
      return data; // Return the entire profile object
    } else {
      throw Exception(
          "Failed to fetch profile data. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching user profile: $e");
  }
}
