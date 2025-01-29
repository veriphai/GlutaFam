import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchQuests() async {
  try {
    const url = 'https://glutaclass.com:8080/gluta/famV2/quests';

    final AuthTokenService authTokenService = AuthTokenService();
    final String? authToken = await authTokenService.getAuthToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      return {
        "dailyQuests": (data["dailyQuests"] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        "friendQuest": (data["friendQuest"] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        "monthlyQuest": (data["monthlyQuest"] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      };
    } else {
      print('Failed to fetch quests. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error fetching quests: $e');
    return {};
  }
}
