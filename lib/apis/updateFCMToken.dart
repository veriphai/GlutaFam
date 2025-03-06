import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> updateFCMToken({
  required String fcmToken,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/update-fcm-token?fcmToken=$fcmToken';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      print("Updated FCMToken");
    } else {
      print('Failed to update FCMToken. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to update FCMToken: $e');
  }
}
