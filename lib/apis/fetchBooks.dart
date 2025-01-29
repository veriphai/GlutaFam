import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchBooks({required int standard}) async {
  try {
    final url =
        'https://glutaclass.com:8080/gluta/famV2/books?standard=$standard';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data is List) {
        // Ensure the parsed data is a list of maps
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Unexpected response format: ${response.body}');
        return [];
      }
    } else {
      print('Failed to fetch books. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetching books: $e');
    return [];
  }
}
