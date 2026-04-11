import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

Future<Map<String, dynamic>> resolveGap({
  required String conceptId,
  required String studentName,
  required int checkpointNo,
  required String conceptConversationsKey,
  required int remainingTime,
  required String gapId,
  required Map<String, dynamic> gapData,
  List<Map<String, dynamic>>? gapConversations,
  String? studentResponse,
  String? language,
  String? voice,
  File? audioFile,
  bool? firstGapConversation,
  String? userPromptType,
}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/tutor/gap-resolution';
    // const url = 'http://localhost:8080/gluta/tutor/gap-resolution';

    final uri = Uri.parse(url);

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    // Prepare JSON request object
    final Map<String, dynamic> requestData = {
      "conceptId": conceptId,
      "studentName": studentName,
      "checkpointNo": checkpointNo,
      "conceptConversationsKey": conceptConversationsKey,
      "remainingTime": remainingTime,
      "gapId": gapId,
      "gapData": gapData,
      "gapConversations": gapConversations,
      "studentResponse": studentResponse,
      "language": language,
      "voice": voice,
      "firstConversation": firstGapConversation,
      "userPromptType": userPromptType,
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
      print('❌ Gap resolution failed: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('❌ Error resolving gap (api call): $e');
    return {};
  }
}
