import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../utils/navigation_utils.dart';
import '../screens/friendsProfileScreen.dart';
import '../widgets/achievementDetailsWidgetV2.dart';

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

  Future<void> _handleReferralLink(Map<String, String> params, SharedPreferences prefs) async {
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
      // Add navigation logic here
    }
  }

  Future<void> _handleLessonLink(Map<String, String> params, SharedPreferences prefs) async {
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
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}

// Navigation helper functions using the existing navigation logic from main.dart
void navigateToProfileScreen(String userId) {
  if (navigatorKey.currentContext != null) {
    // Use Navigator to push the ProfileScreen with the userId
    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => FriendsProfileScreen(
          friendId: userId,
          following: false,
        ),
      ),
    );
  }
}

void navigateToAchievementDetails(String achievementId, String levelCriteria) {
  if (navigatorKey.currentContext != null) {
    int levelCriteriaInt = int.tryParse(levelCriteria) ?? 0;

    Navigator.push(
      navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => AchievementDetailsWidgetV2(
          achievementId: achievementId,
          levelCriteria: levelCriteriaInt,
        ),
      ),
    );
  }
}

// Add more navigation functions as needed