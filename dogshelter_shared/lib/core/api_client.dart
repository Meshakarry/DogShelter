import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart' show lookupMimeType;

import 'api_exception.dart';

/// Builds a multipart file part with its content-type set from the file's extension.
///
/// `http.MultipartFile.fromPath` does NOT do this itself - per its own doc comment, it defaults
/// to `application/octet-stream` unless `contentType` is passed explicitly. The backend's upload
/// validation (`FileUploadService`) rejects anything outside image/jpeg|png|webp, so every image
/// upload call site must use this helper instead of calling `MultipartFile.fromPath` directly.
Future<http.MultipartFile> imageMultipartFile(String field, String path) {
  final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
  return http.MultipartFile.fromPath(field, path, contentType: MediaType.parse(mimeType));
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.getToken, required this.onUnauthorized}) : _client = http.Client();

  final String baseUrl;
  final String? Function() getToken;
  final void Function() onUnauthorized;
  final http.Client _client;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> delete(String path) {
    return _send('DELETE', path);
  }

  /// Multipart upload (e.g. image files) - fields are form values, files are the attachments.
  Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest(method, uri);

    final token = getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    request.files.addAll(files);

    final response = await http.Response.fromStream(await _client.send(request));
    return _handleResponse(response);
  }

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? query, Object? body}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      final stringQuery = <String, String>{};
      query.forEach((key, value) {
        if (value != null) stringQuery[key] = value.toString();
      });
      uri = uri.replace(queryParameters: stringQuery);
    }

    final headers = <String, String>{'Accept': 'application/json'};
    final token = getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await http.Response.fromStream(await _client.send(request));
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized();
    }

    final decodedBody = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponseBody(response.statusCode, decodedBody);
    }

    return decodedBody;
  }
}
