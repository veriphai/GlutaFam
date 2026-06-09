// Thin singleton wrapper around package:http used by every new (`/howwow/*`)
// API call. Replaces the per-file boilerplate of building headers, decoding
// UTF-8, parsing JSON, and translating non-2xx responses.
//
// Behaviour:
//   • Injects `Authorization: Bearer <authKey>` (from AuthTokenService) on
//     authed calls, `Content-Type: application/json`, `Accept-Encoding: gzip`.
//   • Decodes the response body as UTF-8 → JSON Map.
//   • Surfaces the backend's typed `{ code, message }` error envelope as a
//     thrown {@link ApiException} on non-2xx responses, so call sites can
//     branch on `e.statusCode` / `e.code` without re-parsing.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/authTokenService.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final AuthTokenService _auth = AuthTokenService();

  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> getJson(String url, {bool auth = true}) async {
    final resp = await http
        .get(Uri.parse(url), headers: await _headers(auth: auth))
        .timeout(_timeout);
    return _parse(resp);
  }

  Future<Map<String, dynamic>> postJson(
    String url, {
    Object? body,
    bool auth = true,
  }) async {
    final resp = await http
        .post(
          Uri.parse(url),
          headers: await _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(resp);
  }

  Future<Map<String, dynamic>> putJson(
    String url, {
    Object? body,
    bool auth = true,
  }) async {
    final resp = await http
        .put(
          Uri.parse(url),
          headers: await _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(resp);
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip',
    };
    if (auth) {
      final token = await _auth.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Map<String, dynamic> _parse(http.Response resp) {
    final status = resp.statusCode;
    if (status >= 200 && status < 300) {
      if (resp.bodyBytes.isEmpty) return const {};
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      // Defensive: a top-level JSON list comes back wrapped so callers can
      // still pull it from a known key.
      return {'_data': decoded};
    }
    String? errCode;
    String? errMsg;
    try {
      final err = jsonDecode(utf8.decode(resp.bodyBytes));
      if (err is Map) {
        errCode = err['code']?.toString();
        errMsg = err['message']?.toString();
      }
    } catch (_) {
      // body wasn't JSON; fall back to the raw body string below.
    }
    throw ApiException(
      statusCode: status,
      code: errCode,
      message: errMsg ?? 'Request failed with status $status',
    );
  }
}

/// Thrown by {@link ApiClient} on any non-2xx response. The backend's
/// `{ code, message }` envelope is parsed when present.
class ApiException implements Exception {
  ApiException({required this.statusCode, this.code, this.message});

  final int statusCode;
  final String? code;
  final String? message;

  @override
  String toString() {
    final parts = <String>['ApiException $statusCode'];
    if (code != null) parts.add(code!);
    if (message != null) parts.add(message!);
    return parts.join(' · ');
  }
}
