import 'dart:convert';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:http/http.dart' as http;

final AuthTokenService authTokenService = AuthTokenService();

Future<void> submitFeedback({
  required String chapterId,
  required String sectionId,
  required List<String> feedbackOptions,
  required String type,
  int? rating,
}) async {
  const String feedbackApiUrl =
      'https://glutaclass.com:8080/gluta/fam/submit-feedback';

  final feedbackData = {
    "chapterId": chapterId,
    "sectionId": sectionId,
    "rating": rating,
    "feedbackOptions": feedbackOptions,
    "type": type,
  };

  final authToken = await authTokenService.getAuthToken();

  try {
    final response = await http.post(
      Uri.parse(feedbackApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: json.encode(feedbackData),
    );

    if (response.statusCode == 200) {
      print("Feedback submitted successfully.");
    } else {
      print("Failed to submit feedback. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Error submitting feedback: $e");
  }
}
