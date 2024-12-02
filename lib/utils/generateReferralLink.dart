import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

Future<String> generateReferralLink(String referralCode) async {
  final DynamicLinkParameters parameters = DynamicLinkParameters(
    uriPrefix: 'https://glutaclass.page.link',
    link: Uri.parse('https://glutaclass.com/invite?referralCode=$referralCode'),
    androidParameters: AndroidParameters(
      packageName: 'com.gluta.glutafam',
      minimumVersion: 1,
    ),
    iosParameters: IOSParameters(
      bundleId: 'com.example.eurekaApp',
      appStoreId: '6736943726',
      fallbackUrl: Uri.parse(
          'https://apps.apple.com/us/app/glutaclass-ai-tutor-for-ncert/id6736943726'),
    ),
    socialMetaTagParameters: SocialMetaTagParameters(
      title: 'Invite Your Friends to GlutaClass',
      description:
          'Use this referral link to join GlutaClass and earn rewards!',
      imageUrl:
          Uri.parse('https://gluta.s3.ap-south-1.amazonaws.com/logo_1.png'),
    ),
  );

  // Generate the short dynamic link
  final ShortDynamicLink shortLink =
      await FirebaseDynamicLinks.instance.buildShortLink(parameters);
  return shortLink.shortUrl.toString();
}
