import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> nudgeYourFriend({
  required String friendId,
  required String message,
  required String headingMessage,
  required String image,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/nudge?friendId=$friendId&message=$message&headingMessage=$headingMessage&image=$image';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip'
    });

    if (response.statusCode == 200) {
      print("Nudged your friend");
    } else {
      print('Failed to nudge your friend. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to nudge your friend: $e');
  }
}
