# Deep Linking Implementation Guide

## Replacing Firebase Dynamic Links with Universal Links/App Links

### Document Overview

This document provides a comprehensive guide for implementing deep linking using Universal Links (iOS) and App Links (Android) to replace the deprecated Firebase Dynamic Links functionality in the Tuto app.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technical Architecture](#technical-architecture)
3. [Prerequisites](#prerequisites)
4. [Backend Implementation](#backend-implementation)
5. [Domain Configuration](#domain-configuration)
6. [Android Implementation](#android-implementation)
7. [iOS Implementation](#ios-implementation)
8. [Flutter Code Implementation](#flutter-code-implementation)
9. [Testing Strategy](#testing-strategy)
10. [Deployment Checklist](#deployment-checklist)
11. [Troubleshooting](#troubleshooting)

---

## Project Overview

### Current State

- Firebase Dynamic Links has been deprecated and removed from the project
- Stub implementations exist in `lib/utils/generateReferralLink.dart`
- Deep link handling logic is functional in `main.dart`
- Basic custom URL scheme (`glutaclass://`) is partially configured

### Goal

Implement a robust deep linking solution that:

- Replaces Firebase Dynamic Links functionality
- Works seamlessly across iOS and Android
- Provides fallback to app stores for non-installed users
- Maintains existing deep link routing logic
- Supports all current link types: referrals, profiles, achievements, lessons, collections

### Supported Deep Link Types

1. **Referral Links**: `https://share.tuto.app/referral?code=ABC123`
2. **Profile Links**: `https://share.tuto.app/profile?userId=12345`
3. **Achievement Links**: `https://share.tuto.app/achievement?id=math_master&level=gold`
4. **Collection Links**: `https://share.tuto.app/collection?itemId=item123`
5. **Lesson Links**: `https://share.tuto.app/lesson?conceptId=algebra101&conceptName=Basic%20Algebra`

---

## Technical Architecture

### High-Level Flow

```
User clicks link → Domain verification → App opens (if installed) → Deep link handled
                                    → Redirect to store (if not installed)
```

### Components

1. **Web Backend**: Handles link redirects and fallbacks
2. **Domain Verification Files**: `.well-known` files for platform verification
3. **Mobile App Configuration**: Intent filters (Android) and Associated Domains (iOS)
4. **Flutter Deep Link Handler**: Processes incoming links and routes to appropriate screens

---

## Prerequisites

### Required Resources

- **Domain**: A domain you control (e.g., `share.tuto.app` or `links.tuto.app`)
- **Web Server**: To host redirect logic and verification files
- **SSL Certificate**: HTTPS is required for Universal Links/App Links
- **Developer Accounts**: Active Apple Developer and Google Play Console accounts

### Required Tools

- Web server with HTTPS support
- Text editor for configuration files
- Access to DNS management for your domain

---

## Backend Requirements

**Note:** The backend will be implemented separately using Java Spring Boot. This section outlines the requirements for the backend team.

### Required Endpoints

The Java backend should provide the following endpoints:

1. **`GET /{linkType}`** - Handle deep link redirects

   - Parameters: `linkType` (referral, profile, achievement, etc.)
   - Query parameters: All link-specific parameters
   - Response: HTML page with JavaScript redirect logic

2. **`GET /.well-known/assetlinks.json`** - Android App Links verification

   - Response: JSON file for Android domain verification

3. **`GET /.well-known/apple-app-site-association`** - iOS Universal Links verification

   - Response: JSON file for iOS domain verification

4. **`POST /api/shorten`** (Optional) - Create short links with analytics
   - Request: `{"url": "...", "campaign": "..."}`
   - Response: `{"shortUrl": "..."}`

### Expected Backend Behavior

1. **User Agent Detection:**

   - Detect Android, iOS, or web browsers
   - Generate appropriate fallback URLs

2. **Deep Link Generation:**

   - Create custom URL scheme links: `tuto://linkType?params`
   - Handle URL encoding for parameters

3. **Fallback Logic:**

   - Android: Redirect to Google Play Store
   - iOS: Redirect to Apple App Store
   - Web: Redirect to website

4. **Domain Verification Files:**
   - Serve verification files with correct MIME types
   - Ensure HTTPS accessibility

### Example Response Format

The backend should return HTML pages with JavaScript that:

- Immediately attempts to open the app via custom URL scheme
- Shows loading indicator to user
- Redirects to appropriate app store after 3-5 seconds if app doesn't open
- Handles page visibility changes to detect if user returned to browser

---

## Domain Configuration

### 1. Android App Links Configuration

Create `.well-known/assetlinks.json` in your web server's root:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.gluta.glutafam",
      "sha256_cert_fingerprints": [
        "YOUR_RELEASE_KEY_SHA256_FINGERPRINT",
        "YOUR_DEBUG_KEY_SHA256_FINGERPRINT"
      ]
    }
  }
]
```

**How to get SHA256 fingerprints:**

```bash
# For release key
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias

# For debug key (usually located at ~/.android/debug.keystore)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 2. iOS Universal Links Configuration

Create `.well-known/apple-app-site-association` (no file extension):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.gluta.glutafam",
        "paths": [
          "/referral",
          "/profile",
          "/achievement",
          "/collection",
          "/lesson"
        ]
      }
    ]
  }
}
```

**Replace TEAM_ID with your Apple Developer Team ID**

### 3. Verify Domain Files

Ensure both files are accessible:

- `https://share.tuto.app/.well-known/assetlinks.json`
- `https://share.tuto.app/.well-known/apple-app-site-association`

Both files should:

- Be served with HTTPS
- Return proper JSON content
- Have correct MIME types (application/json)

---

## Android Implementation

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

    <!-- App Links for Universal Deep Linking -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https"
              android:host="share.tuto.app" />
    </intent-filter>

</activity>
```

### 2. Test App Links Verification

Use Android's App Links Assistant or command line:

```bash
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "https://share.tuto.app/referral?code=test123" \
  com.gluta.glutafam
```

---

## iOS Implementation

### 1. Update Info.plist

Add URL schemes and associated domains to `ios/Runner/Info.plist`:

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

<!-- Add Associated Domains capability -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:share.tuto.app</string>
</array>
```

### 2. Update iOS Project Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your project target
3. Go to "Signing & Capabilities" tab
4. Add "Associated Domains" capability
5. Add domain: `applinks:share.tuto.app`

### 3. Test Universal Links

Use iOS Simulator or device:

```bash
xcrun simctl openurl booted "https://share.tuto.app/referral?code=test123"
```

---

## Flutter Code Implementation

### 1. Add Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  app_links: ^6.3.2 # For handling deep links
  url_launcher: ^6.2.5 # Already present
```

### 2. Create Deep Link Service

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

      // Navigate to lesson screen
      // Use your existing navigation logic here
      print('Lesson: $conceptId, $conceptName');
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}

// Import your existing navigation functions
void navigateToProfileScreen(String userId) {
  // Implement navigation to profile screen
}

void navigateToAchievementDetails(String achievementId, String levelCriteria) {
  // Implement navigation to achievement details
}
```

### 3. Update Link Generation Service

Replace the stub implementations in `lib/utils/generateReferralLink.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

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

/// Optional: Create short links with analytics
Future<String> createShortLink(String originalUrl, {String? campaign}) async {
  // If you want to implement your own link shortening service
  // This is optional and can be added later

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
```

### 4. Update Main.dart

Update your `main.dart` to use the new deep link service:

```dart
// Add import
import 'services/deep_link_service.dart';

// In your main() function, replace the existing dynamic link initialization:
void main() async {
  // ... existing code ...

  Future.microtask(() async {
    // ... existing notification setup ...

    // Initialize deep link service
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

// Remove or comment out these old functions:
// initDynamicLinkListener(prefs);
// await handleInitialDynamicLink(prefs);
```

---

## Testing Strategy

### 1. Development Testing

**Test Custom URL Schemes:**

```bash
# Android
adb shell am start -W -a android.intent.action.VIEW -d "tuto://referral?code=test123" com.gluta.glutafam

# iOS Simulator
xcrun simctl openurl booted "tuto://referral?code=test123"
```

**Test Universal Links/App Links:**

```bash
# Android
adb shell am start -W -a android.intent.action.VIEW -d "https://share.tuto.app/referral?code=test123" com.gluta.glutafam

# iOS Simulator
xcrun simctl openurl booted "https://share.tuto.app/referral?code=test123"
```

### 2. Manual Testing Checklist

**For each link type:**

- [ ] App installed: Link opens app directly
- [ ] App not installed: Link redirects to appropriate store
- [ ] App in background: Link brings app to foreground
- [ ] App in foreground: Link navigates to correct screen
- [ ] Parameters are correctly parsed and handled
- [ ] Fallback behavior works on unsupported devices

**Test Scenarios:**

- [ ] Fresh app install → click link → app opens with correct data
- [ ] Share link via SMS → recipient clicks → correct behavior
- [ ] Share link via WhatsApp → recipient clicks → correct behavior
- [ ] Share link via email → recipient clicks → correct behavior
- [ ] Copy link and paste in browser → correct behavior

### 3. Automated Testing

Create test cases in `test/deep_link_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eureka_app/services/deep_link_service.dart';

void main() {
  group('Deep Link Service Tests', () {
    test('should parse referral links correctly', () async {
      final uri = Uri.parse('https://share.tuto.app/referral?code=ABC123');
      // Test your parsing logic
    });

    test('should generate correct referral links', () async {
      final link = await generateReferralLink('TEST123');
      expect(link, equals('https://share.tuto.app/referral?code=TEST123'));
    });

    // Add more test cases for each link type
  });
}
```

---

## Deployment Checklist

### Pre-deployment

- [ ] Domain configured with SSL certificate
- [ ] `.well-known` files uploaded and accessible
- [ ] Android App Links verification successful
- [ ] iOS Universal Links verification successful
- [ ] All link generation functions updated
- [ ] Deep link service integrated and tested
- [ ] Fallback URLs point to correct app store listings

### Android Deployment

- [ ] `AndroidManifest.xml` updated with correct intent filters
- [ ] `assetlinks.json` contains correct SHA256 fingerprints
- [ ] App signed with release key
- [ ] Google Play Console listing updated (if needed)

### iOS Deployment

- [ ] `Info.plist` updated with URL schemes and associated domains
- [ ] Xcode project configured with Associated Domains capability
- [ ] `apple-app-site-association` contains correct Team ID and Bundle ID
- [ ] App Store listing updated (if needed)

### Backend Deployment

- [ ] Web server deployed and accessible
- [ ] Redirect logic handles all link types
- [ ] Fallback URLs tested
- [ ] Analytics tracking implemented (optional)

### Post-deployment Testing

- [ ] Test on production builds
- [ ] Verify domain verification status
- [ ] Test sharing functionality in production
- [ ] Monitor deep link analytics

---

## Troubleshooting

### Common Issues

**Android App Links not working:**

1. Verify `assetlinks.json` is accessible via HTTPS
2. Check SHA256 fingerprints match your app's signing key
3. Use `adb shell dumpsys package domain-preferred-apps` to check verification status
4. Clear app data and reinstall to retry verification

**iOS Universal Links not working:**

1. Verify `apple-app-site-association` is accessible via HTTPS
2. Check Team ID and Bundle ID are correct
3. Ensure Associated Domains capability is properly configured
4. Test on physical device (simulator may have limitations)

**Links opening in browser instead of app:**

1. Verify domain verification is successful
2. Check intent filters/associated domains configuration
3. Test with fresh app install
4. Ensure HTTPS is used for all links

**Parameters not being parsed:**

1. Check URL encoding of parameters
2. Verify deep link handler is processing all query parameters
3. Add debug logging to trace parameter flow

### Debug Tools

**Android:**

```bash
# Check App Links verification status
adb shell dumpsys package domain-preferred-apps

# Check intent filter resolution
adb shell am start -W -a android.intent.action.VIEW -d "https://share.tuto.app/test"
```

**iOS:**

```bash
# Test Universal Links in simulator
xcrun simctl openurl booted "https://share.tuto.app/test"

# Check associated domains in device logs
# Look for "swcd" logs in Console app
```

### Support Resources

- [Android App Links Documentation](https://developer.android.com/training/app-links)
- [iOS Universal Links Documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [App Links Flutter Package](https://pub.dev/packages/app_links)

---

## Implementation Timeline

### Phase 1: Flutter Frontend Setup (Week 1)

- Add required Flutter dependencies (`app_links`)
- Update Android and iOS configurations
- Implement Flutter deep link service
- Basic testing with custom URL schemes

### Phase 2: Core Flutter Implementation (Week 2)

- Update link generation functions
- Replace stub implementations in `generateReferralLink.dart`
- Integrate deep link service with main.dart
- Comprehensive testing on both platforms

### Phase 3: Platform Configuration (Week 3)

- Configure Android App Links intent filters
- Set up iOS Universal Links and Associated Domains
- Test domain verification (once backend is ready)
- Submit app updates to stores

### Phase 4: Integration & Testing (Week 4)

- Integrate with Java backend (once ready)
- End-to-end testing with production links
- Monitor and fix any issues
- Performance optimizations and documentation

**Note:** Domain setup and backend deployment will be handled separately by the backend team.

---

## Conclusion

This implementation will provide a robust, future-proof deep linking solution that replaces Firebase Dynamic Links. The solution offers better performance, full control over the linking experience, and no dependency on third-party services.

Remember to test thoroughly on both platforms and monitor the implementation after deployment to ensure all use cases are working correctly.

For questions or issues during implementation, refer to the troubleshooting section or consult the official documentation links provided.
