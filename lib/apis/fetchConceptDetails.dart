import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchConceptDetails(
    {required String conceptId}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/concept-details?conceptId=$conceptId';
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
      final utf8Body = utf8.decode(response.bodyBytes);
      return jsonDecode(utf8Body) as Map<String, dynamic>;
    } else {
      print(
          'Failed to fetch concept details. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error fetching concept details: $e');
    return {};
  }
}
