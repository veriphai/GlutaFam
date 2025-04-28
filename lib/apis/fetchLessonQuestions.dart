import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchLessonQuestions(
    {required String lessonId}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/questions?lessonId=$lessonId';

    final response =
        await http.get(Uri.parse(url), headers: {'Accept-Encoding': 'gzip'});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(
          'Failed to fetch lesson questions. Status code: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Error fetching lesson questions: $e');
    return {};
  }
}
