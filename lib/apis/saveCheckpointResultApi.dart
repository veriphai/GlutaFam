import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<String> saveCheckpointResultApi({
  required String chapterId,
  required String episodeId,
  required String checkpointId,
  required int score,
  required List<String?> userAnswers,
}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/fam/save-checkpoint-result';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "chapterId": chapterId,
      "episodeId": episodeId,
      "checkpointId": checkpointId,
      "userAnswers": userAnswers,
      "score": score,
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

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(
          'Failed to save checkpoint result. Status code: ${response.statusCode}');
      return "FAILURE";
    }
  } catch (e) {
    print('Error fetching checkpoint result: $e');
    return "FAILURE";
  }
}
