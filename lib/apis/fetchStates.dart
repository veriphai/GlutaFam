import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchStates() async {
  const url = 'https://glutaclass.com:8080/gluta/famV2/states';

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
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception(
          "Failed to fetch list of states. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching list of states: $e");
  }
}
