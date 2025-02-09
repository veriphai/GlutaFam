import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> startFriendQuest({
  required String friendId,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/start-friend-quest?friendId=$friendId';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      print("Started friend quest");
    } else {
      print(
          'Failed to start friend quest. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to start friend quest: $e');
  }
}
