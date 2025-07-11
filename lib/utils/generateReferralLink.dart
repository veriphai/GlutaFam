import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

Future<String> generateReferralLink(String referralCode) async {
  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://tutosquad.page.link',
    link: Uri.parse('https://trytuto.com/invite?referralCode=$referralCode'),
    androidParameters: AndroidParameters(
      packageName: 'com.gluta.glutafam',
      minimumVersion: 1,
    ),
    iosParameters: IOSParameters(
        bundleId: 'com.example.eurekaApp', appStoreId: '6736943726'),
    navigationInfoParameters: NavigationInfoParameters(
      forcedRedirectEnabled: true, // Force bypassing the app preview page
    ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: 'Tuto: AI Tutor for Classes 6-12',
      description: 'Personal Tutor for All Subjects',
      imageUrl:
          Uri.parse('https://gluta.s3.ap-south-1.amazonaws.com/tuto-logo.png'),
    ),
  );
  // Generate the short dynamic link
  final ShortDynamicLink shortLink =
      await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  return shortLink.shortUrl.toString();
}

Future<String> generateProfileLink(String userId) async {
  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://glutaclass.page.link',
    link: Uri.parse('https://glutaclass.com/profile?userId=$userId'),
    androidParameters: AndroidParameters(
      packageName: 'com.gluta.glutafam',
      minimumVersion: 1,
    ),
    iosParameters: IOSParameters(
        bundleId: 'com.example.eurekaApp', appStoreId: '6736943726'),
    navigationInfoParameters: NavigationInfoParameters(
      forcedRedirectEnabled: true, // Force bypassing the app preview page
    ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: 'Tuto: AI Tutor for Classes 6-12',
      description: 'Personal Tutor for All Subjects',
      imageUrl:
          Uri.parse('https://gluta.s3.ap-south-1.amazonaws.com/tuto-logo.png'),
    ),
  );
  // Generate the short dynamic link
  final ShortDynamicLink shortLink =
      await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  return shortLink.shortUrl.toString();
}

Future<String> generateAchievementLink(
    String achievementId, int levelCriteria) async {
  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://glutaclass.page.link',
    link: Uri.parse(
        'https://glutaclass.com/achievement?achievementId=$achievementId&levelCriteria=$levelCriteria'),
    androidParameters: AndroidParameters(
      packageName: 'com.gluta.glutafam',
      minimumVersion: 1,
    ),
    iosParameters: IOSParameters(
        bundleId: 'com.example.eurekaApp', appStoreId: '6736943726'),
    navigationInfoParameters: NavigationInfoParameters(
      forcedRedirectEnabled: true, // Force bypassing the app preview page
    ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: 'Tuto: AI Tutor for Classes 6-12',
      description: 'Personal Tutor for All Subjects',
      imageUrl:
          Uri.parse('https://gluta.s3.ap-south-1.amazonaws.com/tuto-logo.png'),
    ),
  );
  // Generate the short dynamic link
  final ShortDynamicLink shortLink =
      await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  return shortLink.shortUrl.toString();
}

Future<String> generateCollectionItemLink(String itemId) async {
  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://glutaclass.page.link',
    link:
        Uri.parse('https://glutaclass.com/collection?collectionItemId=$itemId'),
    androidParameters: AndroidParameters(
      packageName: 'com.gluta.glutafam',
      minimumVersion: 1,
    ),
    iosParameters: IOSParameters(
        bundleId: 'com.example.eurekaApp', appStoreId: '6736943726'),
    navigationInfoParameters: NavigationInfoParameters(
      forcedRedirectEnabled: true, // Force bypassing the app preview page
    ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: 'Tuto: AI Tutor for Classes 6-12',
      description: 'Personal Tutor for All Subjects',
      imageUrl:
          Uri.parse('https://gluta.s3.ap-south-1.amazonaws.com/tuto-logo.png'),
    ),
  );
  // Generate the short dynamic link
  final ShortDynamicLink shortLink =
      await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  return shortLink.shortUrl.toString();
}
