import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../utils/navigation_utils.dart';
import '../screens/friendsProfileScreen.dart';
import '../widgets/achievementDetailsWidgetV2.dart';
import '../screens/aiTutor/aiTutorScreenV2.dart';
import '../widgets/collectionDetailsWidget.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize deep link listening
  Future<void> initialize() async {
    try {
      // Handle app launch from deep link
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }

      // Handle deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) async {
          await _handleDeepLink(uri);
        },
        onError: (err) {
          print('Deep link error: $err');
        },
      );
    } on PlatformException catch (e) {
      print('Failed to initialize deep links: $e');
    }
  }

  /// Handle incoming deep links
  Future<void> _handleDeepLink(Uri uri) async {
    print('Received deep link: $uri');

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Extract path and parameters
    final String path = uri.path;
    final Map<String, String> params = uri.queryParameters;

    // Route based on path
    switch (path) {
      case '/referral':
        await _handleReferralLink(params, prefs);
        break;
      case '/profile':
        await _handleProfileLink(params);
        break;
      case '/achievement':
        await _handleAchievementLink(params);
        break;
      case '/collection':
        await _handleCollectionLink(params);
        break;
      case '/lesson':
        await _handleLessonLink(params, prefs);
        break;
      default:
        print('Unknown deep link path: $path');
    }
  }

  Future<void> _handleReferralLink(
      Map<String, String> params, SharedPreferences prefs) async {
    final String? referralCode = params['code'];
    if (referralCode != null) {
      print('Referral Code: $referralCode');
      await prefs.setString("referralCode", referralCode);
      // Navigate to referral screen or show success message
      // You can add navigation logic here
    }
  }

  Future<void> _handleProfileLink(Map<String, String> params) async {
    final String? userId = params['userId'];
    if (userId != null) {
      print('Profile User ID: $userId');
      // Navigate to profile screen
      navigateToProfileScreen(userId);
    }
  }

  Future<void> _handleAchievementLink(Map<String, String> params) async {
    final String? achievementId = params['id'];
    final String? levelCriteria = params['level'];
    if (achievementId != null && levelCriteria != null) {
      print('Achievement: $achievementId, Level: $levelCriteria');
      // Navigate to achievement details
      navigateToAchievementDetails(achievementId, levelCriteria);
    }
  }

  Future<void> _handleCollectionLink(Map<String, String> params) async {
    final String? itemId = params['itemId'];
    if (itemId != null) {
      print('Collection Item ID: $itemId');
      // Navigate to collection item
      navigateToCollectionDetails(itemId);
    }
  }

  Future<void> _handleLessonLink(
      Map<String, String> params, SharedPreferences prefs) async {
    final String? conceptId = params['conceptId'];
    final String? conceptName = params['conceptName'];
    final String? name = params['name'];
    final String? standardStr = params['standard'];
    final String? subject = params['subject'];
    final String? bookId = params['bookId'];

    if (conceptId != null && conceptName != null) {
      final int standard = int.tryParse(standardStr ?? '') ?? 0;

      if (bookId != null) await prefs.setString("bookId", bookId);
      if (subject != null) await prefs.setString("subject", subject);

      // Navigate to lesson screen using existing logic
      // This should match your existing lesson navigation
      print('Lesson: $conceptId, $conceptName');
      // Add your existing lesson navigation logic here
      _handleLessonNavigation(conceptId, conceptName, name ?? '', standard,
          subject ?? '', bookId ?? '');
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}

// Navigation functions that use the global navigator
void navigateToProfileScreen(String userId) {
  if (navigatorKey.currentContext != null) {
    print('Navigate to profile screen for user: $userId');
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => FriendsProfileScreen(
          friendId: userId,
          following: false, // Default to not following
        ),
      ),
    );
  }
}

void navigateToAchievementDetails(String achievementId, String levelCriteria) {
  if (navigatorKey.currentContext != null) {
    print('Navigate to achievement details: $achievementId, $levelCriteria');

    // Parse levelCriteria to int, with fallback
    int level = int.tryParse(levelCriteria) ?? 1;

    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => AchievementDetailsWidgetV2(
          achievementId: achievementId,
          levelCriteria: level,
        ),
      ),
    );
  }
}

void navigateToCollectionDetails(String itemId) {
  if (navigatorKey.currentContext != null) {
    print('Navigate to collection details for item: $itemId');

    // Create a placeholder collection item for the deep link
    Map<String, dynamic> collectionItem = {
      'id': itemId,
      'type': 'shared_link',
      'title': 'Shared Collection Item',
    };

    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => CollectionDetailsWidget(
          collectionItem: collectionItem,
          feedOwner: false, // Not from feed owner
        ),
      ),
    );
  }
}

void _handleLessonNavigation(String conceptId, String conceptName, String name,
    int standard, String subject, String bookId) {
  if (navigatorKey.currentContext != null) {
    print(
        'Navigate to lesson: $conceptId, $conceptName, Standard: $standard, Subject: $subject, Book: $bookId');
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => AITutorScreenV2(
          conceptId: conceptId,
          conceptName: conceptName,
          chapterName: name, // Use name as chapterName
          maxXP: 100, // Default XP value
          name: name,
          subject: subject,
          standard: standard,
          selectedLanguage: 'English', // Default language
          selectedVoice: 'default', // Default voice
          tutorSelected: null, // No specific tutor
          dataToResume: null, // Not resuming
          resumeLesson: false, // New lesson
          viewLessonHistory: false, // Not viewing history
        ),
      ),
    );
  }
}
