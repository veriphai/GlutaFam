import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchLessonStory(
    {required String lessonId}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/lesson-story?lessonId=$lessonId';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(
          'Failed to fetch lesson story. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error fetching lesson story: $e');
    return {};
  }
}
