import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchSchools(
    {required String state, required String city}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/schools?state=$state&city=$city';

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
      return List<Map<String, dynamic>>.from(data);
    } else {
      print(
          'Failed to fetch schools list. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetching schools: $e');
    return [];
  }
}
