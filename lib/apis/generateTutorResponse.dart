import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart'; // for basename()

Future<Map<String, dynamic>> generateTutorResponse(
    {required String conceptId,
    required String studentName,
    required int checkpointNo,
    required String conceptConversationsKey,
    List<Map<String, dynamic>>? conversations,
    String? studentResponse,
    String? language,
    String? voice,
    bool? firstConversation,
    bool? greeting,
    File? audioFile,
    bool? newCheckpointStarted,
    bool? allCheckpointCompleted,
    Map<String, dynamic>? questionsData}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/tutor/response';
    final uri = Uri.parse(url);

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    // Prepare JSON request object
    final Map<String, dynamic> requestData = {
      "conceptId": conceptId,
      "studentName": studentName,
      "checkpointNo": checkpointNo,
      "conversations": conversations,
      "language": language,
      "voice": voice,
      "firstConversation": firstConversation,
      "greeting": greeting,
      "studentResponse": studentResponse,
      "newCheckpointStarted": newCheckpointStarted,
      "allCheckpointCompleted": allCheckpointCompleted,
      "questionsData": questionsData,
      "conceptConversationsKey": conceptConversationsKey
    };

    // Prepare multipart request
    var request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers['Authorization'] = 'Bearer $authToken';

    // Add request JSON as a part
    request.files.add(http.MultipartFile.fromString(
      'request',
      json.encode(requestData),
      contentType: MediaType('application', 'json'),
    ));

    // Add audio file if provided
    if (audioFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
        filename: basename(audioFile.path),
      ));
    }

    // Send request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

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
