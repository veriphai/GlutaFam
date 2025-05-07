import 'package:device_info_plus/device_info_plus.dart';
import 'package:eureka_app/apis/fetchQuests.dart';
import 'package:eureka_app/apis/getProfile.dart';
import 'package:eureka_app/apis/updateCredits.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      // For Android
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      // For iOS
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "Unknown Device ID";
    } else {
      return "Unsupported Platform";
    }
  } catch (e) {
    return "Error fetching Device ID: $e";
  }
}

Future<Map<String, String>> getDeviceDetails() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  try {
    if (kIsWeb) {
      // For web
      return {
        'deviceId': "Website",
        'platform': 'web',
      };
    } else if (Platform.isAndroid) {
      // For Android
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'deviceId': androidInfo.fingerprint,
        'platform': 'Android',
      };
    } else if (Platform.isIOS) {
      // For iOS
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'deviceId': iosInfo.identifierForVendor ?? "Unknown Device ID",
        'platform': 'iOS',
      };
    } else {
      return {
        'deviceId': "Unsupported Platform",
        'platform': "Unknown",
      };
    }
  } catch (e) {
    return {
      'deviceId': "Error fetching Device ID: $e",
      'platform': "Error",
    };
  }
}

Future<String> getUserIP() async {
  const url = 'https://api.ipify.org?format=json'; // Public IP service
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['ip']; // Extract IP from response
    } else {
      return "Error: Unable to fetch IP address. Status code: ${response.statusCode}";
    }
  } catch (e) {
    return "Error fetching IP address: $e";
  }
}

Future<Map<String, dynamic>> getProfile() async {
  const String profileKey = "userProfile";

  final prefs = await SharedPreferences.getInstance();

  // Check if profile exists in SharedPreferences
  if (prefs.containsKey(profileKey)) {
    final profileString = prefs.getString(profileKey);
    if (profileString != null) {
      // Return profile from SharedPreferences
      return json.decode(profileString);
    }
  }

  final profileData = await fetchUserProfile();

  await prefs.setString(profileKey, json.encode(profileData));
  updateLifelines(prefs, profileData["lifelines"]);
  updateCreditsInCache(profileData["credits"]);

  return profileData;
}

void updateLifelines(SharedPreferences prefs, int lifelines) async {
  const String lifelinesKey = "lifelines";
  await prefs.setInt(lifelinesKey, lifelines);
}

void toggleUnlimitedLifelines(SharedPreferences prefs, bool enabled) async {
  const String lifelinesKey = "unlimitedLifelines";
  await prefs.setBool(lifelinesKey, enabled);
}

void updateCreditsInCache(int credits) async {
  final prefs = await SharedPreferences.getInstance();
  const String creditsKey = "credits";
  await prefs.setInt(creditsKey, credits);
}

void updateCredits(int credits) async {
  updateCreditsInCache(credits);
  await updateCreditsAPI(credits: credits);
}

Future<int> getCredits() async {
  final prefs = await SharedPreferences.getInstance();
  const String creditsKey = "credits";
  return prefs.getInt(creditsKey) ?? 0;
}

Future<Map<String, dynamic>> refreshProfile() async {
  const String profileKey = "userProfile";

  final profileData = await fetchUserProfile();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(profileKey, json.encode(profileData));
  updateLifelines(prefs, profileData["lifelines"]);
  updateCreditsInCache(profileData["credits"]);
  // updateCredits(profileData["credits"]);

  return profileData;
}

String fetchLeague(int league) {
  switch (league) {
    case 1:
      return "Bronze";
    case 2:
      return "Silver";
    case 3:
      return "Gold";
    case 4:
      return "Platinum";
    case 5:
      return "Diamond";
    default:
      return "Unknown";
  }
}

Future<Map<String, dynamic>> getQuests() async {
  // const String questsKey = "quests";

  // final prefs = await SharedPreferences.getInstance();

  // // Check if profile exists in SharedPreferences
  // if (prefs.containsKey(questsKey)) {
  //   final questsString = prefs.getString(questsKey);
  //   if (questsString != null) {
  //     // Return profile from SharedPreferences
  //     return json.decode(questsString);
  //   }
  // }

  final quests = await fetchQuests();

  // await prefs.setString(questsKey, json.encode(quests));

  return quests;
}
