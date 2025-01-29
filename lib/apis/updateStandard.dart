import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<String> updateStandard({required int standard, String? stream}) async {
  try {
    String url =
        'https://glutaclass.com:8080/gluta/famV2/change-standard?standard=$standard';

    if (stream != null && stream.isNotEmpty) {
      url += '&stream=$stream';
    }

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    // Construct the request
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken', // Use the stored auth token
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to update standard. Status code: ${response.statusCode}');
      return "FAILURE";
    }
  } catch (e) {
    print('Error updating standard: $e');
    return "FAILURE";
  }
}
