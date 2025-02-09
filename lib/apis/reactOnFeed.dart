import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> reactOnFeed({
  required String feedId,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/feed-react?feedId=$feedId';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      print("Reacted on feed successfully");
    } else {
      print('Failed to react on feed. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to react on feed: $e');
  }
}
