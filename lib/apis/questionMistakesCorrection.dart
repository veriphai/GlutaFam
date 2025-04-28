import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';

Future<Map<String, dynamic>> fetchQuestionMistakesConversation(
    {required List<Map<String, String>> conversations,
    required Map<String, dynamic> incorrectQuestion,
    required String conceptName,
    required String query,
    required int conversationNo}) async {
  try {
    const url =
        'https://glutaclass.com:8080/gluta/famV2/question-mistakes-correction';

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "conversations": conversations,
      "question": incorrectQuestion,
      "conceptName": conceptName,
      "query": query,
      "conversationNo": conversationNo
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
          'Failed to fetch AI responses. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error fetching AI response: $e');
    return {};
  }
}
