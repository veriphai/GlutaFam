import 'dart:convert';
import 'package:http/http.dart' as http;


Future<String> sendAudioToBackendWeb({
  required String base64Audio,
  required String chapterId,
  required int sectionNumber,
}) async {
  final url = Uri.parse("https://glutaclass.com:8080/gluta/fam/ask-any-questions-web");

  final headers = {
    'Content-type': 'application/json',
  };

  final body = jsonEncode({
    'chapterId': chapterId,
    'sectionNumber': sectionNumber,
    'audio': base64Audio,
  });


  try {
    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      // print("Audio successfully sent to the backend: Response: ${response.body}");
      final responseBody = jsonDecode(response.body);
      final String base64Audio = responseBody['evaluationResponse']['audioMessage'];
      return base64Audio;
    } else {
      print("Failed to send audio to the backend. Status: ${response.statusCode}, body: ${response.body}");
    } 
    } catch (e) {
      print('Error while sending audio to the backend: $e');
    }
    return base64Audio;
  }