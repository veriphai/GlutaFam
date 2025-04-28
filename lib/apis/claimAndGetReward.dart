import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> claimAndGetReward(
    {required String rewardFor, required String taskId}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/claim-rewards?rewardFor=$rewardFor&taskId=$taskId';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    // Construct the request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip'
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      print('Failed to claim reward. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Failed to claim reward: $e');
    return {};
  }
}
