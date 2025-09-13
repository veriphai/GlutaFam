import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchAllFeedbacks() async {
  // final response = await http.get(Uri.parse(url),
  //     headers: {'Accept-Encoding': 'gzip'}).timeout(Duration(seconds: 10));

  const url = "https://glutaclass.com:8080/gluta/tutor/fetch-all-feedbacks";

  final res = await http.get(Uri.parse(url), headers: {
    'Accept': 'application/json',
    'Accept-Encoding': 'gzip',
  }).timeout(const Duration(seconds: 120));

  if (res.statusCode == 200) {
    final body = res.body;
    final decoded = json.decode(body);
    if (decoded is List) return decoded;
    // Some servers return an object with a field that holds the list:
    if (decoded is Map && decoded['data'] is List)
      return decoded['data'] as List;
    throw StateError('Unexpected JSON shape from $url');
  }
  throw StateError('HTTP ${res.statusCode} ${res.reasonPhrase}');
}
