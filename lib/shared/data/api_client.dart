import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/environment.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _send('GET', path);
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('POST', path, body: body);
    return _decodeJson(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _resolveUri(path);
    final session = Supabase.instance.client.auth.currentSession;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (session?.accessToken != null) 'Authorization': 'Bearer ${session!.accessToken}',
    };

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    throw ApiException(
      message: 'Request to ${uri.path} failed with status ${response.statusCode}',
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Uri _resolveUri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    final base = EnvironmentConfig.apiBaseUrl;
    return Uri.parse(base).resolve(path);
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ApiException(message: 'Unexpected response shape');
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.body,
  });

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'ApiException($message, statusCode: $statusCode)';
}
