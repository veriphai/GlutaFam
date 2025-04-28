import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> addFriend({
  required String friendId,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/add-friend?friendId=$friendId';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip'
    });

    if (response.statusCode == 200) {
      print("Added your friend");
    } else {
      print('Failed to add your friend. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to add your friend: $e');
  }
}
