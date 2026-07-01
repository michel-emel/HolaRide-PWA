import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart';

/// Thrown for any non-2xx response, with the server's own error message
/// surfaced when available so the UI can show something meaningful
/// instead of a generic "something went wrong".
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around `package:http` that:
/// - points at the deployed HolaRide API
/// - attaches the JWT automatically once the person is logged in
/// - decodes JSON and turns error responses into ApiException
///
/// CONFIG: change [baseUrl] here if you ever move off this Vercel URL
/// (e.g. a custom domain later) — every screen goes through this one
/// class, nothing else hardcodes the host.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl = 'https://hola-ride-api-v2.vercel.app';

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await SessionService.instance.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    if (query == null || query.isEmpty) {
      return Uri.parse('$baseUrl$cleanPath');
    }
    final filtered = query.map((k, v) => MapEntry(k, v?.toString() ?? ''))
      ..removeWhere((k, v) => v.isEmpty);
    return Uri.parse('$baseUrl$cleanPath').replace(queryParameters: filtered);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Something went wrong (${res.statusCode}).';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['detail'] != null) {
        final detail = body['detail'];
        message = detail is String ? detail : detail.toString();
      }
    } catch (_) {
      // Response body wasn't JSON — keep the generic message.
    }
    throw ApiException(res.statusCode, message);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final res = await http.get(_uri(path, query), headers: await _headers(auth: auth));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await http.patch(
      _uri(path),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await http.delete(_uri(path), headers: await _headers(auth: auth));
    return _decode(res);
  }

  /// Multipart POST — used for endpoints that take files (vehicle
  /// photos). [files] is a list of (field name, local file path) pairs
  /// rather than a Map, since a Map can't hold multiple files under the
  /// same repeated field name (e.g. several 'photos' entries).
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<MapEntry<String, String>>? files,
    bool auth = true,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final headers = await _headers(auth: auth);
    headers.remove('Content-Type'); // let MultipartRequest set its own boundary header
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    if (files != null) {
      for (final entry in files) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value));
      }
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}
