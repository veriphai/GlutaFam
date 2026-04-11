import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> updateTaskStatus(
    String taskId, String status, String journeyId) async {
  try {
    final url = 'https://glutaclass.com:8080/gluta/api/tasks/$taskId/status';

    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    print('Updating task status for $taskId to $status at: $url'); // Debug log

    final requestBody = {
      'taskId': taskId,
      'status': status,
      'journeyId': journeyId,
    };

    final response = await http
        .put(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
            'Accept-Encoding': 'gzip'
          },
          body: json.encode(requestBody),
        )
        .timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final utf8Body =
          utf8.decode(response.bodyBytes); // ✅ proper UTF-8 decoding
      return json.decode(utf8Body);
    } else {
      print(
          'Failed to update task status. Status code: ${response.statusCode}');
      print('Response Body: ${response.body}'); // Debug log
      return {
        'success': false,
        'error': 'Failed to update task status',
        'statusCode': response.statusCode,
      };
    }
  } catch (e) {
    print('Error updating task status: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
