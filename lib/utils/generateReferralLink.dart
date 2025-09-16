const String BASE_DOMAIN = 'https://share.tuto.app';

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
Future<String> generateAchievementLink(String achievementId, String levelCriteria) async {
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

/// Optional: Create short links with analytics (to be implemented with backend)
Future<String> createShortLink(String originalUrl, {String? campaign}) async {
  // TODO: Implement with Java backend when ready
  // For now, return the original URL
  return originalUrl;
}
