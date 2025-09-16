import 'package:flutter_test/flutter_test.dart';
import 'package:eureka_app/services/deep_link_service.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';

void main() {
  group('Deep Link Service Tests', () {
    test('should parse referral links correctly', () async {
      final uri = Uri.parse('tuto://referral?code=ABC123');
      expect(uri.scheme, equals('tuto'));
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
      expect(uri.path, equals('/lesson'));
      expect(uri.queryParameters['conceptId'], equals('math101'));
      expect(uri.queryParameters['standard'], equals('8'));
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
  });
}