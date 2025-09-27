import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

// Enum to match backend RetryType
enum RetryType {
  transcribeText('TRANSCRIBE_TEXT'),
  turnFeedback('TURN_FEEDBACK'),
  tutorMessage('TUTOR_MESSAGE'),
  tutorMessageAudio('TUTOR_MESSAGE_AUDIO'),
  checkpointFeedback('CHECKPOINT_FEEDBACK');

  const RetryType(this.value);
  final String value;
}

Future<Map<String, dynamic>> retryTutorResponse({
  required String conceptId,
  required String studentName,
  required int checkpointNo,
  required String conceptConversationsKey,
  required RetryType retryType,
  required int remainingTime,
  String? conversationId,
  String? conversationItemId,
  String? language,
  String? voice,
  File? audioFile,
}) async {
  try {
    // const baseUrl = 'https://glutaclass.com:8080/gluta/tutor/retry';
    const baseUrl = 'http://localhost:8080/gluta/tutor/retry';

    final uri = Uri.parse(baseUrl);

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    // Prepare JSON request body
    final Map<String, dynamic> requestData = {
      "conceptId": conceptId,
      "studentName": studentName,
      "checkpointNo": checkpointNo,
      "language": language,
      "voice": voice,
      "conceptConversationsKey": conceptConversationsKey,
      "remainingTime": remainingTime,
      "retryType": retryType.value,
    };

    // Add conversationItemId to request data if provided
    if (conversationItemId != null) {
      requestData["userConversationItemId"] = conversationItemId;
    }

    // // Add conversationId to request data if provided
    // if (conversationId != null) {
    //   requestData["conversationId"] = conversationId;
    // }

    // Use multipart request to support audio file
    var request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers['Authorization'] = 'Bearer $authToken';

    // Add request JSON as a part
    request.files.add(http.MultipartFile.fromString(
      'request',
      json.encode(requestData),
      contentType: MediaType('application', 'json'),
    ));

    // Add retryType as a separate part (required by backend)
    // Add audio file if provided
    if (audioFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
        filename: basename(audioFile.path),
      ));
    }

    // Send request with timeout
    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Request timeout after 30 seconds');
      },
    );
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final utf8DecodedBody = utf8.decode(response.bodyBytes);
      return json.decode(utf8DecodedBody);
    } else {
      print('❌ Retry tutor response failed: ${response.statusCode}');
      print('❌ Response body: ${response.body}');
      return {};
    }
  } catch (e) {
    print('❌ Error retrying tutor response: $e');
    return {};
  }
}
