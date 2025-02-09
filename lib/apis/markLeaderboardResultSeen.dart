import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<String> markLeaderboardResultSeen() async {
  try {
    const url =
        'https://glutaclass.com:8080/gluta/famV2/leaderboard-result-seen';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      return response.body;
    } else {
      print('Failed to mark result seen. Status code: ${response.statusCode}');
      return "FAILURE";
    }
  } catch (e) {
    print('Error marking result seen: $e');
    return "FAILURE";
  }
}
