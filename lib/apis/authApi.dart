import "dart:convert";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> sendIdTokenToBackend() async {
  final secureStorage = new FlutterSecureStorage();
  final idToken = await secureStorage.read(key: "IdToken");

  final url = 'https://glutaclass.com:8080/gluta/fam/auth?idToken=$idToken';

  if (idToken != null) {
    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        print("Auth api:$data");

        await secureStorage.write(key: "authKey", value: data['token']);

        // await prefs.setBool("newUser", data['newUser']);
        // await prefs.setString("token", data['token']);
        // await prefs.setBool('isSuccess', data['isSuccess']);

        return data;
      } else {
        throw Exception("Failed to load IdToken");
      }
    } catch (e) {
      throw Exception("Failed to fetch data: $e");
    }
  } else {
    throw Exception("IdToken is null");
  }
}
