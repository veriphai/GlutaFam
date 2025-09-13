import 'package:flutter_test/flutter_test.dart';
import 'package:eureka_app/services/deep_link_service.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';

void main() {
  group('Deep Link Service Tests', () {
    test('should parse referral links correctly', () async {
      final uri = Uri.parse('tuto://referral?code=ABC123');
      expect(uri.scheme, equals('tuto'));
      expect(uri.host, equals(''));
      expect(uri.path, equals('/referral'));
      expect(uri.queryParameters['code'], equals('ABC123'));
    });

    test('should parse universal links correctly', () async {
      final uri = Uri.parse('https://share.tuto.app/referral?code=ABC123');
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('share.tuto.app'));
      expect(uri.path, equals('/referral'));
      expect(uri.queryParameters['code'], equals('ABC123'));
    });

    test('should generate correct referral links', () async {
      final link = await generateReferralLink('TEST123');
      expect(link, equals('https://share.tuto.app/referral?code=TEST123'));
    });

    test('should generate correct profile links', () async {
      final link = await generateProfileLink('user456');
      expect(link, equals('https://share.tuto.app/profile?userId=user456'));
    });

    test('should generate correct achievement links', () async {
      final link = await generateAchievementLink('math_master', 'gold');
      expect(link, equals('https://share.tuto.app/achievement?id=math_master&level=gold'));
    });

    test('should generate correct collection links', () async {
      final link = await generateCollectionItemLink('item123');
      expect(link, equals('https://share.tuto.app/collection?itemId=item123'));
    });

    test('should generate correct lesson links', () async {
      final link = await generateLessonLink(
        conceptId: 'math101',
        conceptName: 'Basic Algebra',
        name: 'Introduction to Variables',
        standard: 8,
        subject: 'Mathematics',
        bookId: 'book123',
      );

      final uri = Uri.parse(link);
      expect(uri.host, equals('share.tuto.app'));
      expect(uri.path, equals('/lesson'));
      expect(uri.queryParameters['conceptId'], equals('math101'));
      expect(uri.queryParameters['conceptName'], equals('Basic Algebra'));
      expect(uri.queryParameters['name'], equals('Introduction to Variables'));
      expect(uri.queryParameters['standard'], equals('8'));
      expect(uri.queryParameters['subject'], equals('Mathematics'));
      expect(uri.queryParameters['bookId'], equals('book123'));
    });
  });

  group('Link Generation Tests', () {
    test('should handle special characters in parameters', () async {
      final link = await generateReferralLink('TEST@123');
      expect(link, contains('TEST%40123'));
    });

    test('should generate valid URIs', () async {
      final link = await generateProfileLink('user123');
      final uri = Uri.parse(link);
      expect(uri.isScheme('https'), isTrue);
      expect(uri.host, equals('share.tuto.app'));
    });

    test('should handle URL encoding properly', () async {
      final link = await generateLessonLink(
        conceptId: 'concept with spaces',
        conceptName: 'Algebra & Geometry',
        name: 'Test & Learn',
        standard: 10,
        subject: 'Math & Science',
        bookId: 'book@123',
      );

      final uri = Uri.parse(link);
      expect(uri.queryParameters['conceptId'], equals('concept with spaces'));
      expect(uri.queryParameters['conceptName'], equals('Algebra & Geometry'));
      expect(uri.queryParameters['name'], equals('Test & Learn'));
      expect(uri.queryParameters['subject'], equals('Math & Science'));
      expect(uri.queryParameters['bookId'], equals('book@123'));
    });

    test('should create short link placeholder', () async {
      final originalUrl = 'https://share.tuto.app/referral?code=TEST123';
      final shortLink = await createShortLink(originalUrl);
      expect(shortLink, equals(originalUrl)); // Should return original URL for now
    });

    test('should create short link with campaign', () async {
      final originalUrl = 'https://share.tuto.app/referral?code=TEST123';
      final shortLink = await createShortLink(originalUrl, campaign: 'summer2024');
      expect(shortLink, equals(originalUrl)); // Should return original URL for now
    });
  });

  group('URI Parsing Tests', () {
    test('should parse custom scheme URLs correctly', () {
      final testCases = [
        'tuto://referral?code=ABC123',
        'tuto://profile?userId=user456',
        'tuto://achievement?id=math_master&level=gold',
        'tuto://collection?itemId=item123',
        'tuto://lesson?conceptId=math101&conceptName=Algebra',
      ];

      for (final testCase in testCases) {
        final uri = Uri.parse(testCase);
        expect(uri.scheme, equals('tuto'));
        expect(uri.queryParameters.isNotEmpty, isTrue);
      }
    });

    test('should parse universal link URLs correctly', () {
      final testCases = [
        'https://share.tuto.app/referral?code=ABC123',
        'https://share.tuto.app/profile?userId=user456',
        'https://share.tuto.app/achievement?id=math_master&level=gold',
        'https://share.tuto.app/collection?itemId=item123',
        'https://share.tuto.app/lesson?conceptId=math101&conceptName=Algebra',
      ];

      for (final testCase in testCases) {
        final uri = Uri.parse(testCase);
        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('share.tuto.app'));
        expect(uri.queryParameters.isNotEmpty, isTrue);
      }
    });

    test('should handle empty query parameters gracefully', () {
      final uri = Uri.parse('tuto://referral');
      expect(uri.scheme, equals('tuto'));
      expect(uri.path, equals('/referral'));
      expect(uri.queryParameters.isEmpty, isTrue);
    });

    test('should handle multiple query parameters', () {
      final uri = Uri.parse('tuto://lesson?conceptId=math101&conceptName=Algebra&standard=8&subject=Mathematics');
      expect(uri.queryParameters.length, equals(4));
      expect(uri.queryParameters['conceptId'], equals('math101'));
      expect(uri.queryParameters['conceptName'], equals('Algebra'));
      expect(uri.queryParameters['standard'], equals('8'));
      expect(uri.queryParameters['subject'], equals('Mathematics'));
    });
  });
}