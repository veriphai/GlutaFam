import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchCheckpointFeedback({
  required String conceptConversationsKey,
  required int checkpointNumber,
}) async {
  try {
    String url = 'https://glutaclass.com:8080/gluta/tutor/checkpoint-feedback'
        '?conceptConversationKey=$conceptConversationsKey&checkpointNo=$checkpointNumber';

    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
    );

    if (response.statusCode == 200) {
      final utf8Body =
          utf8.decode(response.bodyBytes); // ✅ proper UTF-8 decoding
      final Map<String, dynamic> data = json.decode(utf8Body);
      return data;
    } else {
      throw Exception(
          "Failed to fetch checkpoint feedback. Status code: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error fetching checkpoint feedback: $e");
  }
}
