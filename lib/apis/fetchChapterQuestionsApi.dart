import 'dart:convert';
import 'package:http/http.dart' as http;

// Function to fetch chapter questions from API
Future<Map<String, dynamic>?> fetchChapterQuestions(
    {required int standard,
    required int chapterNo,
    required String subject}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/fam/fetch-chapter-questions?standard=$standard&chapterNo=$chapterNo&subject=$subject';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to fetch questions. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching questions: $e');
    return null;
  }
}
