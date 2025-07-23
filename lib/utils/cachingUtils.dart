import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eureka_app/apis/fetchBooks.dart';
import 'package:eureka_app/apis/fetchChaptersV2.dart';

const cacheExpiryDuration = Duration(hours: 12);

Future<List<Map<String, dynamic>>> getBooksWithCache({
  required int standard,
  required String stream,
}) async {
  final prefs = await SharedPreferences.getInstance();
  String key = stream.isEmpty ? 'books_$standard' : 'books_${standard}_$stream';
  String timeKey = '$key:timestamp';

  if (prefs.containsKey(key) && prefs.containsKey(timeKey)) {
    final cachedTime = prefs.getInt(timeKey);
    if (cachedTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cachedTime < cacheExpiryDuration.inMilliseconds) {
        // Not expired
        print("📦 Using cached books for $key");
        final cachedData = prefs.getString(key);
        if (cachedData != null) {
          final decodedList = jsonDecode(cachedData);
          return (decodedList as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
      }
    }
  }

  // Fetch from API if not cached or expired
  final booksData = await fetchBooks(standard: standard, stream: stream);
  await prefs.setString(key, jsonEncode(booksData));
  await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
  print("🌐 Fetched books from API and cached with key: $key");
  return booksData;
}

Future<List<Map<String, dynamic>>> getChaptersWithCache({
  required int standard,
  required String subject,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'chapters_${standard}_$subject';
  final timeKey = '$key:timestamp';

  if (prefs.containsKey(key) && prefs.containsKey(timeKey)) {
    final cachedTime = prefs.getInt(timeKey);
    if (cachedTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cachedTime < cacheExpiryDuration.inMilliseconds) {
        print("📦 Using cached chapters for $key");
        final cachedData = prefs.getString(key);
        if (cachedData != null) {
          final decodedList = jsonDecode(cachedData);
          if (decodedList is List && decodedList.isNotEmpty) {
            return (decodedList as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
          }
        }
      }
    }
  }

  // Fetch from API if not cached or expired
  final chapterData =
      await fetchChaptersV2(standard: standard, subject: subject);
  await prefs.setString(key, jsonEncode(chapterData));
  await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
  print("🌐 Fetched chapters from API and cached with key: $key");
  return chapterData;
}
