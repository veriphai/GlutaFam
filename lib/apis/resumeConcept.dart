import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';

Future<Map<String, dynamic>> resumeConcept({
  required String conceptId,
  required int checkpointsCompleted,
  required String conceptConversationsKey,
  required int checkpointNo,
  required Map<String, dynamic>? learningObjectivesStatus,
  required bool newCheckpointStarted,
  required int remainingTime,
}) async {
  try {
    const url = 'http://localhost:8080/gluta/tutor/resume-lesson';
    final uri = Uri.parse(url);

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    // Prepare JSON request object
    final body = {
      "conceptId": conceptId,
      "checkpointsCompleted": checkpointsCompleted,
      "conceptConversationKey": conceptConversationsKey,
      "checkpointNo": checkpointNo,
      "learningObjectivesStatus": learningObjectivesStatus,
      "newCheckpointStarted": newCheckpointStarted,
      "remainingTime": remainingTime
    };

    // Construct the request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken', // Use the stored auth token
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
      body: json.encode(body),
    );

    // Prepare multipart request

    if (response.statusCode == 200) {
      final utf8DecodedBody = utf8.decode(response.bodyBytes);
      return json.decode(utf8DecodedBody);
    } else {
      print('❌ Tutor response failed: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('❌ Error fetching tutor response (api call): $e');
    return {};
  }
}
