import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';

Future<List<Map<String, dynamic>>> fetchChatResponse(
    {required List<Map<String, String>> conversations,
    required List<String> characters,
    required String conceptName,
    required String query}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/chat-query';

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "conversations": conversations,
      "characters": characters,
      "conceptName": conceptName,
      "query": query
    };

    // Make the POST request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      print(
          'Failed to fetch AI responses. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetching AI response: $e');
    return [];
  }
}
