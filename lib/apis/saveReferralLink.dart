import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<void> saveReferralLink({
  required String referralLink,
}) async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/fam/save-referral-link';

    final AuthTokenService authTokenService = AuthTokenService();

    String? authToken = await authTokenService.getAuthToken();

    final body = {
      "referralLink": referralLink,
    };

    // Construct the request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken', // Use the stored auth token
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print("Referral Link saved submitted successfully.");
    } else {
      print(
          'Failed to save referral link. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error saving referral link: $e');
  }
}
