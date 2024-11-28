
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenService {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<void> setAuthToken(String token) async {
    if (kIsWeb) {
      // use shared preferences for web
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("authKey", token);
    } else {
      // use flutter secure storage for mobile
      await secureStorage.write(key: "authKey", value: token);
    }
  } 

  Future<String?> getAuthToken() async {
    try {
      if (kIsWeb) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        return prefs.getString("authKey");
      } else {
        return await secureStorage.read(key: "authKey");
      }
    } catch (e) {
      print("Error retreiving auth token: $e");
      return null;
    }
  }
}