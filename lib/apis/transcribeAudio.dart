import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

Future<String> transcribeAudio(File audioFile) async {
  String apiKey = "1d792f37d0bb43f6a349ad0269d6d30b";
  final Uri url = Uri.parse(
      "https://ai-11whispermodel768701140020.cognitiveservices.azure.com/openai/deployments/whisper/audio/translations?api-version=2024-06-01");

  try {
    var request = http.MultipartRequest("POST", url)
      ..headers["api-key"] = apiKey
      ..files.add(await http.MultipartFile.fromPath("file", audioFile.path));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(responseBody);
      String transcribedText = jsonResponse["text"];
      print("Transcription: $transcribedText");
      return transcribedText;
    } else {
      print("Failed to transcribe audio: ${response.reasonPhrase}");
      return "";
    }
  } catch (e) {
    print("Error during transcription: $e");
    return "";
  }
}
