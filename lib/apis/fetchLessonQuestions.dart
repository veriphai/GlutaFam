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
      final utf8Body = utf8.decode(response.bodyBytes);
      return jsonDecode(utf8Body) as Map<String, dynamic>;
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
