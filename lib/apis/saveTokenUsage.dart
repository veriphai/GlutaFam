import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> saveTokenUsage(
    {required Map<String, dynamic> tokenUsageData,
    required String conceptId}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/token-usage';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "usageData": tokenUsageData,
      "conceptId": conceptId,
      "time": DateTime.now().millisecondsSinceEpoch ~/ 1000
    };

    // Make the POST request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print("Token usage sueccessfully");
    } else {
      print(
          'Failed to save usage of tokens. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error occurred while token usage: $e');
  }
}
