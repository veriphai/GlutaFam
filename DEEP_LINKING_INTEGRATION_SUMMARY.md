# Deep Linking Integration Summary

## ✅ Integration Complete

Your Java backend has been successfully integrated with the Flutter app for deep linking functionality. Here's what has been implemented:

## 🔧 What Was Updated

### 1. **Link Generation Service** (`lib/utils/generateReferralLink.dart`)

- ✅ Updated to work with your Java backend endpoints
- ✅ Added support for `/api/shorten` endpoint for short links
- ✅ Added `generateDeepLinkWithBackend()` for programmatic link generation
- ✅ Added `generateBatchDeepLinks()` for bulk link creation
- ✅ Added `checkDeepLinkServiceHealth()` for backend health checks
- ✅ All functions include proper error handling and fallbacks

### 2. **Deep Link Service** (`lib/services/deep_link_service.dart`)

- ✅ Already existed and was working
- ✅ Updated navigation functions to use correct screen constructors
- ✅ Added proper imports for all navigation screens
- ✅ Fixed parameter types and error handling

### 3. **Platform Configurations**

- ✅ **Android**: `AndroidManifest.xml` already configured correctly

  - Custom URL scheme: `tuto://`
  - App Links: `https://share.tuto.app`
  - Auto-verify enabled for domain verification

- ✅ **iOS**: `Info.plist` already configured correctly
  - Custom URL scheme: `tuto://`
  - Associated domains: `applinks:share.tuto.app`

### 4. **Dependencies**

- ✅ `app_links: ^6.3.2` already present in `pubspec.yaml`
- ✅ All required imports and configurations in place

### 5. **Main App Integration**

- ✅ `DeepLinkService` already integrated in `main.dart`
- ✅ Proper initialization and error handling

## 🔗 Backend Endpoints Integration

Your Flutter app now integrates with these Java backend endpoints:

### Link Handling Endpoints

- `GET /referral?code={code}` ✅
- `GET /profile?userId={userId}` ✅
- `GET /achievement?id={id}&level={level}` ✅
- `GET /collection?itemId={itemId}` ✅
- `GET /lesson?conceptId={id}&conceptName={name}&...` ✅

### API Endpoints

- `POST /api/shorten` - Create short links ✅
- `POST /api/deeplink/generate` - Generate single deep link ✅
- `POST /api/deeplink/generate/batch` - Generate multiple deep links ✅
- `GET /api/deeplink/health` - Health check ✅

### Domain Verification Files

- `GET /.well-known/assetlinks.json` - Android verification ✅
- `GET /.well-known/apple-app-site-association` - iOS verification ✅

## 📱 Supported Deep Link Types

All link types from your backend are supported:

1. **Referral Links**: `https://share.tuto.app/referral?code=ABC123`
2. **Profile Links**: `https://share.tuto.app/profile?userId=12345`
3. **Achievement Links**: `https://share.tuto.app/achievement?id=math_master&level=gold`
4. **Collection Links**: `https://share.tuto.app/collection?itemId=item123`
5. **Lesson Links**: `https://share.tuto.app/lesson?conceptId=algebra101&conceptName=Basic%20Algebra&...`

## 🧪 Testing

A test helper has been created: `lib/utils/deep_link_test_helper.dart`

### Test Functions Available:

- `DeepLinkTestHelper.testLinkGeneration()` - Test all link generation
- `DeepLinkTestHelper.testBackendIntegration()` - Test backend API calls
- `DeepLinkTestHelper.showTestDialog(context)` - Show test URLs in app

### Manual Testing Commands:

**Android:**

```bash
# Test custom URL scheme
adb shell am start -W -a android.intent.action.VIEW -d "tuto://referral?code=test123" com.gluta.glutafam

# Test Universal Links (once backend is deployed)
adb shell am start -W -a android.intent.action.VIEW -d "https://share.tuto.app/referral?code=test123" com.gluta.glutafam
```

**iOS:**

```bash
# Test custom URL scheme
xcrun simctl openurl booted "tuto://referral?code=test123"

# Test Universal Links (once backend is deployed)
xcrun simctl openurl booted "https://share.tuto.app/referral?code=test123"
```

## 🚀 Next Steps

### 1. **Deploy Your Java Backend**

- Deploy your Spring Boot application to a server
- Ensure it's accessible at `https://share.tuto.app`
- Verify all endpoints are working

### 2. **Domain Verification Files**

Your backend should serve these files:

**Android** (`/.well-known/assetlinks.json`):

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

**iOS** (`/.well-known/apple-app-site-association`):

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

### 3. **Get Required Certificates**

**For Android** (SHA256 fingerprints):

```bash
# Release key
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias

# Debug key
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For iOS**: Get your Team ID from Apple Developer Console

### 4. **Test End-to-End**

1. Deploy backend to `https://share.tuto.app`
2. Update domain verification files with correct certificates
3. Build and install app on devices
4. Test all link types work correctly

## 🔍 How It Works

1. **User clicks link** → Backend detects device type
2. **Backend serves HTML** → JavaScript tries to open app
3. **If app installed** → Opens directly to correct screen
4. **If app not installed** → Redirects to app store
5. **Deep link handled** → App navigates to appropriate content

## 📋 Files Modified

- ✅ `lib/utils/generateReferralLink.dart` - Updated with backend integration
- ✅ `lib/services/deep_link_service.dart` - Fixed navigation functions
- ✅ `lib/utils/deep_link_test_helper.dart` - Added for testing
- ✅ `android/app/src/main/AndroidManifest.xml` - Already configured
- ✅ `ios/Runner/Info.plist` - Already configured
- ✅ `pubspec.yaml` - Dependencies already present

## 🎯 Key Features

- **Universal Links/App Links**: Work seamlessly when app is installed
- **Fallback Support**: Custom URL schemes for older devices
- **Store Redirects**: Automatic redirect to app stores when app not installed
- **Error Handling**: Graceful fallbacks if backend is unavailable
- **Analytics Ready**: Backend endpoints support campaign tracking
- **Batch Processing**: Generate multiple links efficiently

## ⚠️ Important Notes

1. **Domain**: Ensure `https://share.tuto.app` points to your backend
2. **HTTPS Required**: Universal Links only work with HTTPS
3. **Certificate Verification**: Domain verification files must be accessible
4. **Testing**: Test on real devices for best results (simulators have limitations)

Your deep linking system is now ready! Once you deploy the backend and update the verification files, users will be able to share and open deep links seamlessly across both platforms.
