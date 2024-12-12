import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
        'deviceId': androidInfo.id,
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
