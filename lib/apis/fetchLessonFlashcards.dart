import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> fetchLessonFlashcards(
    {required String lessonId}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/flashcards?lessonId=$lessonId';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(
          'Failed to fetch lesson flashcards. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching lesson flashcards: $e');
    return null;
  }
}
