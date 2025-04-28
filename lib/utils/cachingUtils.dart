import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eureka_app/apis/fetchBooks.dart';
import 'package:eureka_app/apis/fetchChaptersV2.dart';

Future<List<Map<String, dynamic>>> getBooksWithCache({
  required int standard,
  required String stream,
}) async {
  final prefs = await SharedPreferences.getInstance();

  // Build cache key
  String key = stream.isEmpty ? 'books_$standard' : 'books_${standard}_$stream';

  // Check if cached
  if (prefs.containsKey(key)) {
    print("📦 Using cached books for $key");
    final cachedData = prefs.getString(key);
    if (cachedData != null) {
      final decodedList = jsonDecode(cachedData);
      return (decodedList as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
  }

  // Fetch from API if not cached
  final booksData = await fetchBooks(standard: standard, stream: stream);
  await prefs.setString(key, jsonEncode(booksData));
  print("🌐 Fetched books from API and cached with key: $key");
  return booksData;
}

Future<List<Map<String, dynamic>>> getChaptersWithCache({
  required int standard,
  required String subject,
}) async {
  final prefs = await SharedPreferences.getInstance();

  // Build cache key
  final key = 'chapters_${standard}_$subject';

  if (prefs.containsKey(key)) {
    print("📦 Using cached chapters for $key");
    final cachedData = prefs.getString(key);
    if (cachedData != null) {
      final decodedList = jsonDecode(cachedData);
      return (decodedList as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
  }

  // Fetch from API if not cached
  final chapterData =
      await fetchChaptersV2(standard: standard, subject: subject);
  await prefs.setString(key, jsonEncode(chapterData));
  print("🌐 Fetched chapters from API and cached with key: $key");
  return chapterData;
}
