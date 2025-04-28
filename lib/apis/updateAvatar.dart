import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<String> updateAvatar({required String avatarId}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/avatar?avatarId=$avatarId';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    // Construct the request
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip'
    });

    if (response.statusCode == 200) {
      return response.body;
    } else {
      print('Failed to update avatar. Status code: ${response.statusCode}');
      return "FAILURE";
    }
  } catch (e) {
    print('Error updating avatar: $e');
    return "FAILURE";
  }
}
