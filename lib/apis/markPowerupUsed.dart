import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> markPowerupUsed({
  required String powerupId,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/powerup-used?powerupId=$powerupId';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      print("Marked Powerup used successfully");
    } else {
      print('Failed to mark powerup used. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to mark powerup used: $e');
  }
}
