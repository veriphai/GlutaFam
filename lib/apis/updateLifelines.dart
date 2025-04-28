import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> updateLifelines({
  required int lifelines,
}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/lifelines?lifelines=$lifelines';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();
    final response = await http.post(Uri.parse(url), headers: {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip'
    });

    if (response.statusCode == 200) {
      print("Updated lifelines");
    } else {
      print('Failed to update lifelines. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Failed to update lifelines: $e');
  }
}
