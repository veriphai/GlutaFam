# Flutter Deep Linking Implementation Guide

## Frontend Implementation for Universal Links/App Links

### Document Overview

This document provides a step-by-step guide for implementing the Flutter frontend components of the deep linking solution to replace Firebase Dynamic Links. The Java backend will be implemented separately.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Dependencies](#dependencies)
3. [Android Configuration](#android-configuration)
4. [iOS Configuration](#ios-configuration)
5. [Flutter Implementation](#flutter-implementation)
6. [Testing](#testing)
7. [Integration with Backend](#integration-with-backend)

---

## Quick Start

### Overview

We're implementing a deep linking solution that:

- Uses `app_links` package for Flutter deep link handling
- Supports both custom URL schemes (`tuto://`) and Universal Links/App Links (`https://share.tuto.app`)
- Replaces the deprecated Firebase Dynamic Links
- Maintains all existing deep link functionality

### Current State

- ✅ Firebase Dynamic Links removed from `pubspec.yaml`
- ✅ Stub implementations exist in `lib/utils/generateReferralLink.dart`
- ✅ Deep link routing logic exists in `main.dart`
- ❌ Need to implement new deep link service
- ❌ Need to update platform configurations

---

## Dependencies

### 1. Update pubspec.yaml

Add the required dependency:

```yaml
dependencies:
  # ... existing dependencies
  app_links: ^6.3.2 # For handling deep links
```

### 2. Install Dependencies

```bash
flutter pub get
```

---

## Android Configuration

### 1. Update AndroidManifest.xml

Replace the existing intent filter in `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="com.ryanheise.audioservice.AudioServiceActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">

    <!-- Standard app launch intent -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Custom URL scheme for fallback -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="tuto" />
    </intent-filter>

    <!-- App Links for Universal Deep Linking (will be activated once backend is ready) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https"
              android:host="share.tuto.app" />
    </intent-filter>

</activity>
```

### 2. Test Android Configuration

Test custom URL schemes:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "tuto://referral?code=test123" com.gluta.glutafam
```

---

## iOS Configuration

### 1. Update Info.plist

Add URL schemes to `ios/Runner/Info.plist` (add to existing CFBundleURLTypes array):

```xml
<!-- Add to existing CFBundleURLTypes array -->
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>tuto</string>
    </array>
</dict>

<!-- Add Associated Domains capability (will be activated once backend is ready) -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:share.tuto.app</string>
</array>
```

### 2. Update Xcode Project (When Backend is Ready)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your project target
3. Go to "Signing & Capabilities" tab
4. Add "Associated Domains" capability
5. Add domain: `applinks:share.tuto.app`

### 3. Test iOS Configuration

Test custom URL schemes:

```bash
xcrun simctl openurl booted "tuto://referral?code=test123"
```

---

## Flutter Implementation

### 1. Create Deep Link Service

Create `lib/services/deep_link_service.dart`:

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// Import your existing navigation functions or implement them
void navigateToProfileScreen(String userId) {
  // TODO: Implement navigation to profile screen
  // Use your existing navigation logic from main.dart
}

void navigateToAchievementDetails(String achievementId, String levelCriteria) {
  // TODO: Implement navigation to achievement details
  // Use your existing navigation logic from main.dart
}
```

### 2. Update Link Generation Service

Replace the stub implementations in `lib/utils/generateReferralLink.dart`:

```dart
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
```

### 3. Update Main.dart

Update your `main.dart` to use the new deep link service. Replace the existing dynamic link initialization:

```dart
// Add import at the top
import 'services/deep_link_service.dart';

// In your main() function, replace the existing dynamic link initialization:
void main() async {
  // ... existing code ...

  Future.microtask(() async {
    // ... existing notification setup ...

    // Replace these old lines:
    // initDynamicLinkListener(prefs);
    // await handleInitialDynamicLink(prefs);

    // With this new initialization:
    if (!kIsWeb) {
      final deepLinkService = DeepLinkService();
      await deepLinkService.initialize();
    }
  });

  runApp(MyApp(
    firstLaunch: firstLaunch,
    notificationService: notificationService,
  ));
}

// Keep your existing _handleDeeplinkFromFCM function as it handles FCM notifications
// The new service handles direct deep links from browsers/other apps
```

### 4. Add Navigation Helper Functions

Add these helper functions to your deep link service or create a separate navigation utility:

```dart
// Add to lib/services/deep_link_service.dart or create lib/utils/deep_link_navigation.dart

import 'package:flutter/material.dart';
// Import your existing screens

void navigateToProfileScreen(String userId) {
  if (navigatorKey.currentContext != null) {
    // Use your existing profile navigation logic
    // Example:
    // Navigator.push(
    //   navigatorKey.currentContext!,
    //   MaterialPageRoute(
    //     builder: (context) => ProfileScreen(userId: userId),
    //   ),
    // );
  }
}

void navigateToAchievementDetails(String achievementId, String levelCriteria) {
  if (navigatorKey.currentContext != null) {
    // Use your existing achievement navigation logic
    // Example:
    // Navigator.push(
    //   navigatorKey.currentContext!,
    //   MaterialPageRoute(
    //     builder: (context) => AchievementScreen(
    //       achievementId: achievementId,
    //       levelCriteria: levelCriteria,
    //     ),
    //   ),
    // );
  }
}

// Add more navigation functions as needed
```

---

## Testing

### 1. Development Testing

**Test Custom URL Schemes (works immediately):**

```bash
# Android
adb shell am start -W -a android.intent.action.VIEW -d "tuto://referral?code=test123" com.gluta.glutafam

# iOS Simulator
xcrun simctl openurl booted "tuto://referral?code=test123"
```

**Test Different Link Types:**

```bash
# Referral
adb shell am start -W -a android.intent.action.VIEW -d "tuto://referral?code=ABC123" com.gluta.glutafam

# Profile
adb shell am start -W -a android.intent.action.VIEW -d "tuto://profile?userId=12345" com.gluta.glutafam

# Achievement
adb shell am start -W -a android.intent.action.VIEW -d "tuto://achievement?id=math_master&level=gold" com.gluta.glutafam

# Lesson
adb shell am start -W -a android.intent.action.VIEW -d "tuto://lesson?conceptId=math101&conceptName=Algebra" com.gluta.glutafam
```

### 2. Manual Testing Checklist

**For each link type:**

- [ ] App closed: Link launches app with correct data
- [ ] App in background: Link brings app to foreground and navigates
- [ ] App in foreground: Link navigates to correct screen
- [ ] Parameters are correctly parsed and stored
- [ ] Navigation works as expected
- [ ] Error handling works for malformed links

### 3. Flutter Tests

Create test cases in `test/deep_link_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eureka_app/services/deep_link_service.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';

void main() {
  group('Deep Link Service Tests', () {
    test('should parse referral links correctly', () async {
      final uri = Uri.parse('tuto://referral?code=ABC123');
      expect(uri.scheme, equals('tuto'));
      expect(uri.host, equals('referral'));
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
```

---

## Integration with Backend

### When Backend is Ready

1. **Domain Verification:**

   - Backend team will deploy verification files
   - Test Universal Links: `https://share.tuto.app/referral?code=test123`
   - Verify App Links work on Android
   - Verify Universal Links work on iOS

2. **End-to-End Testing:**

   ```bash
   # Test Universal Links (once backend is deployed)
   adb shell am start -W -a android.intent.action.VIEW -d "https://share.tuto.app/referral?code=test123" com.gluta.glutafam
   xcrun simctl openurl booted "https://share.tuto.app/referral?code=test123"
   ```

3. **Fallback Testing:**
   - Test behavior when app is not installed
   - Verify redirects to correct app stores
   - Test sharing functionality

### Integration Points

The Flutter app will work with the Java backend through:

- **Universal Links/App Links**: Backend serves HTML pages that redirect to custom URL schemes
- **Link Generation**: Flutter generates `https://share.tuto.app` links
- **Analytics** (Optional): Backend can track link clicks and app opens

---

## Troubleshooting

### Common Issues

**Links not opening app:**

1. Check if custom URL scheme is registered correctly
2. Verify intent filters in AndroidManifest.xml
3. Check iOS URL schemes in Info.plist
4. Test with simple custom URL scheme first

**Parameters not being parsed:**

1. Add debug logging in `_handleDeepLink` method
2. Check URL encoding of parameters
3. Verify query parameter names match expected values

**App not launching from background:**

1. Check `android:launchMode="singleTop"` in AndroidManifest.xml
2. Verify the app isn't being killed by system
3. Test on physical device (emulator may behave differently)

### Debug Commands

```bash
# Check Android intent filters
adb shell dumpsys package com.gluta.glutafam | grep -A 5 -B 5 "filter"

# Test iOS URL schemes
xcrun simctl list devices | grep Booted
xcrun simctl openurl booted "tuto://test"
```

---

## Next Steps

1. **Implement the Flutter code** following this guide
2. **Test custom URL schemes** thoroughly on both platforms
3. **Wait for backend deployment** for Universal Links testing
4. **Submit app updates** to stores once everything is working
5. **Monitor and optimize** after production deployment

This implementation will provide a solid foundation for deep linking that works independently of the backend timeline while being ready to integrate with Universal Links once the Java backend is deployed.
