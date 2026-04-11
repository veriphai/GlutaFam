import 'package:flutter/material.dart';
import '../utils/generateReferralLink.dart';

/// Helper class for testing deep link functionality
class DeepLinkTestHelper {
  /// Test all link generation functions
  static Future<void> testLinkGeneration() async {
    print('=== Testing Deep Link Generation ===');

    try {
      // Test referral link
      final referralLink = await generateReferralLink('TEST123');
      print('Referral Link: $referralLink');

      // Test profile link
      final profileLink = await generateProfileLink('user123');
      print('Profile Link: $profileLink');

      // Test achievement link
      final achievementLink =
          await generateAchievementLink('math_master', 'gold');
      print('Achievement Link: $achievementLink');

      // Test collection link
      final collectionLink = await generateCollectionItemLink('item123');
      print('Collection Link: $collectionLink');

      // Test lesson link
      final lessonLink = await generateLessonLink(
        conceptId: 'algebra101',
        conceptName: 'Basic Algebra',
        name: 'Introduction to Algebra',
        standard: 10,
        subject: 'Mathematics',
        bookId: 'book123',
      );
      print('Lesson Link: $lessonLink');

      // Test backend health check
      final isHealthy = await checkDeepLinkServiceHealth();
      print('Backend Health: ${isHealthy ? "Healthy" : "Not Available"}');
    } catch (e) {
      print('Error testing links: $e');
    }
  }

  /// Test deep link with backend API
  static Future<void> testBackendIntegration() async {
    print('=== Testing Backend Integration ===');

    try {
      // Test programmatic link generation
      final backendLink = await generateDeepLinkWithBackend(
        linkType: 'referral',
        parameters: {'code': 'BACKEND_TEST'},
        campaign: 'test_campaign',
      );
      print('Backend Generated Link: $backendLink');

      // Test batch link generation
      final batchRequests = {
        'referral1': {
          'linkType': 'referral',
          'parameters': {'code': 'BATCH1'},
          'campaign': 'batch_test',
        },
        'profile1': {
          'linkType': 'profile',
          'parameters': {'userId': 'batch_user'},
          'campaign': 'batch_test',
        },
      };

      final batchResults = await generateBatchDeepLinks(batchRequests);
      print('Batch Results: $batchResults');
    } catch (e) {
      print('Error testing backend integration: $e');
    }
  }

  /// Create test links for manual testing
  static List<Map<String, String>> getTestLinks() {
    return [
      {
        'type': 'Referral',
        'url': 'https://share.tuto.app/referral?code=TEST123',
        'custom': 'tuto://referral?code=TEST123',
      },
      {
        'type': 'Profile',
        'url': 'https://share.tuto.app/profile?userId=user123',
        'custom': 'tuto://profile?userId=user123',
      },
      {
        'type': 'Achievement',
        'url': 'https://share.tuto.app/achievement?id=math_master&level=gold',
        'custom': 'tuto://achievement?id=math_master&level=gold',
      },
      {
        'type': 'Collection',
        'url': 'https://share.tuto.app/collection?itemId=item123',
        'custom': 'tuto://collection?itemId=item123',
      },
      {
        'type': 'Lesson',
        'url':
            'https://share.tuto.app/lesson?conceptId=algebra101&conceptName=Basic%20Algebra&name=Introduction&standard=10&subject=Math&bookId=book123',
        'custom':
            'tuto://lesson?conceptId=algebra101&conceptName=Basic%20Algebra&name=Introduction&standard=10&subject=Math&bookId=book123',
      },
    ];
  }

  /// Show test links in a debug dialog
  static void showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deep Link Test URLs'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: getTestLinks()
                .map((link) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link['type']!,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        SelectableText(
                          'Universal: ${link['url']!}',
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 2),
                        SelectableText(
                          'Custom: ${link['custom']!}',
                          style: TextStyle(fontSize: 12),
                        ),
                        Divider(),
                      ],
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
