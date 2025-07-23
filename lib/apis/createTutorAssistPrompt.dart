import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';

Future<Map<String, dynamic>> createTutorAssistPrompt(
    {required List<Map<String, String>> conversations,
    required String conceptName,
    required Map<String, dynamic> conceptCheckpoint}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/tutor-assist-prompt';

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "conversations": conversations,
      "conceptName": conceptName,
      "conceptCheckpoint": conceptCheckpoint,
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
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data);
    } else {
      print(
          'Failed to create tutor prompt. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error creating tutor prompt: $e');
    return {};
  }
}
