import 'dart:async';
import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchCheckpointFeedback({
  required String conceptConversationsKey,
  required int checkpointNumber,
  bool retry = false,
}) async {
  try {
    // String url = 'http://192.168.165.204:8080/gluta/tutor/checkpoint-feedback'
    //     '?conceptConversationKey=$conceptConversationsKey&checkpointNo=$checkpointNumber';
    String url = 'https://glutaclass.com:8080/gluta/tutor/checkpoint-feedback'
        '?conceptConversationKey=$conceptConversationsKey&checkpointNo=$checkpointNumber'
        '${retry ? '&retry=true' : ''}';

    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException(
            'Checkpoint feedback request timeout after 30 seconds');
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
