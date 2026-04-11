import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/navigation_utils.dart';
import '../screens/friendsProfileScreen.dart';
import '../widgets/achievementDetailsWidgetV2.dart';
import '../screens/aiTutor/aiTutorScreenV2.dart';
import '../widgets/collectionDetailsWidget.dart';
import '../main.dart';

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
        await handleDeepLink(initialLink);
      }

      // Handle deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) async {
          await handleDeepLink(uri);
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
  Future<void> handleDeepLink(Uri uri) async {
    print('Received deep link: $uri');

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Extract path and parameters
    // For custom schemes (tuto://), the route is in the host
    // For HTTPS (https://share.tuto.app/route), the route is in the path
    final String route = uri.scheme == 'tuto' ? uri.host : uri.path;
    final Map<String, String> params = uri.queryParameters;

    print('Route: $route, Params: $params');

    // Route based on path/host
    switch (route) {
      case 'referral':
      case '/referral':
        await _handleReferralLink(params, prefs);
        break;
      case 'profile':
      case '/profile':
        await _handleProfileLink(params);
        break;
      case 'achievement':
      case '/achievement':
        await _handleAchievementLink(params);
        break;
      case 'collection':
      case '/collection':
        await _handleCollectionLink(params);
        break;
      case 'lesson':
      case '/lesson':
        await _handleLessonLink(params, prefs);
        break;
      case 'invite':
      case '/invite':
        await _handleInviteLink(params, prefs);
        break;
      // case 'quests':
      // case '/quests':
      //   await _handleQuestsLink();
      //   break;
      // case 'leaderboard':
      // case '/leaderboard':
      //   await _handleLeaderboardLink();
      //   break;
      // case 'update':
      // case '/update':
      //   await _handleUpdateLink();
      //   break;
      default:
        print('Unknown deep link route: $route');
    }
  }

  Future<void> _handleReferralLink(
      Map<String, String> params, SharedPreferences prefs) async {
    // Support both old and new parameter names
    final String? referralCode = params['referralCode'] ?? params['code'];
    if (referralCode != null) {
      print('✅ Referral Code received: $referralCode');
      await prefs.setString("referralCode", referralCode);
      print('✅ Referral Code saved to SharedPreferences');
      // Navigate to referral screen or show success message
      // You can add navigation logic here
    } else {
      print('❌ No referral code found in params: $params');
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
    // Support both old and new parameter names
    final String? achievementId = params['achievementId'] ?? params['id'];
    final String? levelCriteria = params['levelCriteria'] ?? params['level'];
    if (achievementId != null && levelCriteria != null) {
      print('Achievement: $achievementId, Level: $levelCriteria');
      // Navigate to achievement details
      navigateToAchievementDetails(achievementId, levelCriteria);
    }
  }

  Future<void> _handleCollectionLink(Map<String, String> params) async {
    // Support both old and new parameter names
    final String? itemId = params['collectionItemId'] ?? params['itemId'];
    if (itemId != null) {
      print('Collection Item ID: $itemId');
      // Navigate to collection item
      // navigateToCollectionItem(itemId);
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

  Future<void> _handleInviteLink(
      Map<String, String> params, SharedPreferences prefs) async {
    // Support both 'code' and 'inviteCode' parameter names
    final String? inviteCode = params['code'] ?? params['inviteCode'];
    if (inviteCode != null) {
      print('✅ Invite Code received: $inviteCode');
      await prefs.setString("inviteCode", inviteCode);
      print('✅ Invite Code saved to SharedPreferences');

      // Optional: Show invite success dialog or navigate to specific screen
      // You can add navigation logic here

      // Track the invite event for analytics
      print('📊 Invite link opened with code: $inviteCode');
    } else {
      print('❌ No invite code found in params: $params');
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

  Future<void> _handleQuestsLink() async {
    print('Navigating to quests');
    if (navigatorKey.currentContext != null) {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => MainPage(initialIndex: 1),
        ),
      );
    }
  }

  Future<void> _handleLeaderboardLink() async {
    print('Navigating to leaderboard');
    if (navigatorKey.currentContext != null) {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => MainPage(initialIndex: 2),
        ),
      );
    }
  }

  Future<void> _handleUpdateLink() async {
    print('Navigating to app store for update');
    final url = Platform.isAndroid
        ? Uri.parse(
            'https://play.google.com/store/apps/details?id=com.gluta.glutafam')
        : Uri.parse(
            'https://apps.apple.com/us/app/tuto-ai-tutor-for-class-6-12/id6736943726');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch app store URL");
    }
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
