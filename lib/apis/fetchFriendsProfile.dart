import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchFriendsProfile(
    {required String friendsId}) async {
  final url =
      'https://glutaclass.com:8080/gluta/famV2/other-user-profile?otherUserId=$friendsId';

  try {
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
      // Parse the response and return the profile data
      final Map<String, dynamic> data = json.decode(response.body);
      return data; // Return the entire profile object
    } else {
      throw Exception(
          "Failed to fetch friend's profile data. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching friend's profile: $e");
  }
}
