import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> giftPowerup({
  required String friendId,
  required String powerupId,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/gift-powerup?friendId=$friendId&powerupId=$powerupId';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip'
    });

    if (response.statusCode == 200) {
      print("Gifted powerup your friend");
    } else {
      print(
          'Failed to gift powerup to your friend. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to gift powerup to  your friend: $e');
  }
}
