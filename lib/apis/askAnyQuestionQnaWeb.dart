import 'dart:convert';
import "package:http/http.dart" as http;

Future <Map<String, dynamic>> askAnyQuestionQnaWeb({
  required String chapterQuestionsId,
  required int questionNumber,
  required int subQuestionNumber,
  required String base64Audio,
}) async {
  final url = Uri.parse(
    'https://glutaclass.com:8080/gluta/fam/evaluate-oral-answers-web'
  );

  final Map<String, dynamic> requestBody = {
    "chapterQuestionsId": chapterQuestionsId,
    "questionNumber": questionNumber,
    "subQuestionNumber": subQuestionNumber,
    "audio": base64Audio
  };

  try{
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to evaluate. Status Code: ${response.statusCode}");
      print("Response body: ${response.body}");
      return {};
    }
  } catch (e) {
    print("Error occured during API call: $e");
    return {};
  }
}