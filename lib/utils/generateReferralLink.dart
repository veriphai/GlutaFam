import 'dart:convert';
import 'package:http/http.dart' as http;

const String BASE_DOMAIN = 'https://glutaclass.com';

/// Generate a referral link
Future<String> generateReferralLink(String referralCode) async {
  return '$BASE_DOMAIN/referral?code=$referralCode';
}

/// Generate a profile sharing link
Future<String> generateProfileLink(String userId) async {
  return '$BASE_DOMAIN/profile?userId=$userId';
}

/// Generate a collection item sharing link
Future<String> generateCollectionItemLink(String itemId) async {
  return '$BASE_DOMAIN/collection?itemId=$itemId';
}

/// Generate an achievement sharing link
Future<String> generateAchievementLink(
    String achievementId, String levelCriteria) async {
  return '$BASE_DOMAIN/achievement?id=$achievementId&level=$levelCriteria';
}

/// Generate a lesson sharing link
Future<String> generateLessonLink({
  required String conceptId,
  required String conceptName,
  required String name,
  required int standard,
  required String subject,
  required String bookId,
}) async {
  final Map<String, String> params = {
    'conceptId': conceptId,
    'conceptName': conceptName,
    'name': name,
    'standard': standard.toString(),
    'subject': subject,
    'bookId': bookId,
  };

  final String queryString = Uri(queryParameters: params).query;
  return '$BASE_DOMAIN/lesson?$queryString';
}

/// Create short links with analytics using Java backend
Future<String> createShortLink(String originalUrl, {String? campaign}) async {
  try {
    final response = await http.post(
      Uri.parse('$BASE_DOMAIN/api/shorten'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'url': originalUrl,
        'campaign': campaign,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['shortUrl'];
    }
  } catch (e) {
    print('Failed to create short link: $e');
  }

  // Fallback to original URL
  return originalUrl;
}

/// Generate deep link programmatically using backend API
Future<String> generateDeepLinkWithBackend({
  required String linkType,
  required Map<String, dynamic> parameters,
  String? campaign,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$BASE_DOMAIN/api/deeplink/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'linkType': linkType,
        'parameters': parameters,
        'campaign': campaign,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['deepLink'];
      }
    }
  } catch (e) {
    print('Failed to generate deep link with backend: $e');
  }

  // Fallback to direct URL construction
  final String queryString = Uri(
      queryParameters: parameters
          .map((key, value) => MapEntry(key, value.toString()))).query;
  return '$BASE_DOMAIN/$linkType?$queryString';
}

/// Generate batch deep links using backend API
Future<Map<String, String>> generateBatchDeepLinks(
    Map<String, Map<String, dynamic>> requests) async {
  try {
    final Map<String, dynamic> requestBody = {};

    requests.forEach((key, value) {
      requestBody[key] = {
        'linkType': value['linkType'],
        'parameters': value['parameters'],
        'campaign': value['campaign'],
      };
    });

    final response = await http.post(
      Uri.parse('$BASE_DOMAIN/api/deeplink/generate/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final Map<String, dynamic> results = data['results'];
        return results
            .map((key, value) => MapEntry(key, value['deepLink'] as String));
      }
    }
  } catch (e) {
    print('Failed to generate batch deep links: $e');
  }

  // Fallback to individual generation
  final Map<String, String> fallbackResults = {};
  for (final entry in requests.entries) {
    fallbackResults[entry.key] = await generateDeepLinkWithBackend(
      linkType: entry.value['linkType'],
      parameters: entry.value['parameters'],
      campaign: entry.value['campaign'],
    );
  }
  return fallbackResults;
}

/// Health check for deep link service
Future<bool> checkDeepLinkServiceHealth() async {
  try {
    final response =
        await http.get(Uri.parse('$BASE_DOMAIN/api/deeplink/health'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'healthy';
    }
  } catch (e) {
    print('Deep link service health check failed: $e');
  }
  return false;
}

/// Generate Singular invite link with deferred deep linking
Future<String> generateSingularInviteLink(String inviteCode,
    {String? campaign}) async {
  // Your Singular link template - you'll get this from Singular dashboard
  const String SINGULAR_LINK_TEMPLATE =
      'trytuto.sng.link'; // Replace with actual

  // Construct the Singular link with parameters
  final Map<String, String> params = {
    'code': inviteCode,
    'deep_link_value': 'invite?code=$inviteCode', // For deferred deep linking
    'custom_campaign': campaign ?? 'invite_sharing',
  };

  final String queryString = Uri(queryParameters: params).query;
  return '$SINGULAR_LINK_TEMPLATE?$queryString';
}

/// Generate regular invite link (fallback)
Future<String> generateRegularInviteLink(String inviteCode) async {
  return '$BASE_DOMAIN/invite?code=$inviteCode';
}
