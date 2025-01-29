import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchChaptersV2(
    {required String subject, required int standard}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/chapters?subject=$subject&standard=$standard';

    print('Fetching chapters from: $url'); // Debug log
    final response =
        await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data is List) {
        // Ensure the parsed data is a list of maps
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Unexpected response format: ${response.body}');
        return [];
      }
    } else {
      print('Failed to fetch chapters. Status code: ${response.statusCode}');
      print('Response Body: ${response.body}'); // Debug log
      return [];
    }
  } catch (e) {
    print('Error fetching chapters: $e');
    return [];
  }
}
