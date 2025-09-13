import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> updateLearningGapStatus({
  required String gapId,
  required bool resolved,
  String? chapterId,
  String? episodeId,
  String? checkpointId,
}) async {
  try {
    const url =
        'https://glutaclass.com:8080/gluta/fam/update-learning-gap-status';

    final AuthTokenService authTokenService = AuthTokenService();
    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "gapId": gapId,
      "resolved": resolved,
      if (chapterId != null) "chapterId": chapterId,
      if (episodeId != null) "episodeId": episodeId,
      if (checkpointId != null) "checkpointId": checkpointId,
    };

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to update learning gap status. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error updating learning gap status: $e');
  }
}
