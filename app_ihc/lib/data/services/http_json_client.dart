import 'dart:convert';
import 'dart:io';

abstract interface class HttpJsonClient {
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers});

  Future<dynamic> postJson(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  });
}

class DartHttpJsonClient implements HttpJsonClient {
  DartHttpJsonClient();

  final HttpClient _client = HttpClient();

  @override
  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    final request = await _client.getUrl(uri);
    headers?.forEach(request.headers.add);
    final response = await request.close();
    final body = await utf8.decodeStream(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        _errorMessage('GET', response.statusCode, body),
        uri: uri,
      );
    }

    if (body.trim().isEmpty) {
      return null;
    }

    return jsonDecode(body);
  }

  @override
  Future<dynamic> postJson(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final request = await _client.postUrl(uri);
    headers?.forEach(request.headers.add);
    request.headers.contentType = ContentType.json;

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await utf8.decodeStream(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        _errorMessage('POST', response.statusCode, responseBody),
        uri: uri,
      );
    }

    if (responseBody.trim().isEmpty) {
      return null;
    }

    return jsonDecode(responseBody);
  }

  String _errorMessage(String method, int statusCode, String responseBody) {
    final body = responseBody.trim();
    if (body.isEmpty) {
      return '$method failed with status $statusCode';
    }

    return '$method failed with status $statusCode: $body';
  }
}
