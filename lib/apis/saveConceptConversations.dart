import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> saveConceptConversations(
    {required List<Map<String, String>> conversations,
    required String conversationsKey,
    required String conceptId,
    required String language}) async {
  try {
    const url =
        'https://glutaclass.com:8080/gluta/famV2/save-concept-conversations';

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "id": conversationsKey,
      "conversations": conversations,
      "conceptId": conceptId,
      "language": language,
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
      print("Concept Conversations saved sueccessfully");
    } else {
      print(
          'Failed to save concept conversations. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error saving concept conversations: $e');
  }
}
