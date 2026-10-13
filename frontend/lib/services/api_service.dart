import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Thin REST client for the FastAPI backend.
class ApiService {
  String? token;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _send(Future<http.Response> request) async {
    final http.Response res;
    try {
      res = await request.timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException('Can’t reach the server. Check your connection and try again.');
    }
    final dynamic body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      var msg = 'Something went wrong (${res.statusCode}).';
      if (body is Map && body['detail'] is String) {
        msg = body['detail'] as String;
      } else if (body is Map && body['detail'] is List && (body['detail'] as List).isNotEmpty) {
        msg = ((body['detail'] as List).first['msg'] ?? msg).toString();
      }
      throw ApiException(msg, status: res.statusCode);
    }
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signup(String email, String password, String name) =>
      _send(http.post(_uri('/api/v1/auth/signup'),
          headers: _headers, body: jsonEncode({'email': email, 'password': password, 'name': name})));

  Future<Map<String, dynamic>> login(String email, String password) =>
      _send(http.post(_uri('/api/v1/auth/login'),
          headers: _headers, body: jsonEncode({'email': email, 'password': password})));

  Future<Map<String, dynamic>> google({String? idToken, String? accessToken}) =>
      _send(http.post(_uri('/api/v1/auth/google'),
          headers: _headers, body: jsonEncode({'id_token': idToken, 'access_token': accessToken})));

  Future<Map<String, dynamic>> me() => _send(http.get(_uri('/api/v1/auth/me'), headers: _headers));

  Future<Map<String, dynamic>> processVideo(String url) => _send(
      http.post(_uri('/api/v1/process-video'), headers: _headers, body: jsonEncode({'url': url})));

  Future<Map<String, dynamic>> getJob(String id) =>
      _send(http.get(_uri('/api/v1/jobs/$id'), headers: _headers));
}
