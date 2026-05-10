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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'GET failed with status ${response.statusCode}',
        uri: uri,
      );
    }

    final body = await utf8.decodeStream(response);
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'POST failed with status ${response.statusCode}',
        uri: uri,
      );
    }

    final responseBody = await utf8.decodeStream(response);
    if (responseBody.trim().isEmpty) {
      return null;
    }

    return jsonDecode(responseBody);
  }
}
