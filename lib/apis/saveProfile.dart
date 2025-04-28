import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> saveProfile({
  required Map<String, dynamic> profileData,
}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/fam/profile';

    final AuthTokenService authTokenService = AuthTokenService();

    // Retrieve the auth token
    String? authToken = await authTokenService.getAuthToken();

    // Make the POST request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
      body: jsonEncode(profileData), // Use the passed profileData here
    );

    if (response.statusCode == 200) {
      print("Profile saved successfully");
    } else {
      print('Failed to save profile. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred while saving profile: $e');
  }
}
