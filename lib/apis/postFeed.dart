import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<String> postFeed(
    {String? image,
    required String type,
    required Map<String, dynamic> feedData}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/feed';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final body = {"feedData": feedData, "type": type};

    // Construct the request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken', // Use the stored auth token
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to post feed. Status code: ${response.statusCode}');
      return "FAILURE";
    }
  } catch (e) {
    print('Error posting feed: $e');
    return "FAILURE";
  }
}
