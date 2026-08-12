import 'dart:convert';

import 'package:http/http.dart' as http;

/// Raised when a request to the identity provider fails.
///
/// Carries the status and body because OAuth error responses put the actual
/// reason in the body (`{"error": "invalid_grant", ...}`) while the status is an
/// uninformative 400. Surfacing both is the difference between a debuggable
/// setup and a shrug.
class HttpJsonException implements Exception {
  HttpJsonException(this.statusCode, this.url, this.body);

  final int statusCode;
  final String url;
  final String body;

  @override
  String toString() {
    final trimmed = body.length > 500 ? '${body.substring(0, 500)}…' : body;
    return 'HTTP $statusCode from $url: $trimmed';
  }
}

/// Thin abstraction over the JSON calls this server makes to an OIDC provider.
///
/// The OIDC logic depends on this rather than on `package:http` directly, so
/// tests can substitute a fake (see `test/support/fake_http_json_client.dart`)
/// and exercise discovery, the code exchange and the userinfo fallback without a
/// running identity provider. Same reasoning as [MailSender].
abstract class HttpJsonClient {
  /// GETs [url] and decodes a JSON object.
  ///
  /// [bearer], when given, is sent as `Authorization: Bearer` — needed for the
  /// userinfo endpoint.
  Future<Map<String, dynamic>> getJson(String url, {String? bearer});

  /// POSTs [fields] as `application/x-www-form-urlencoded` and decodes a JSON
  /// object.
  ///
  /// [basicAuth] is the `(clientId, clientSecret)` pair for the token endpoint's
  /// `client_secret_basic` authentication.
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, String> fields,
    (String, String)? basicAuth,
  });
}

/// Default [HttpJsonClient], used in production; delegates to `package:http`.
class PackageHttpJsonClient implements HttpJsonClient {
  const PackageHttpJsonClient({this.timeout = const Duration(seconds: 15)});

  /// Bounded so that an unreachable provider degrades within one refresh tick
  /// instead of holding a request open indefinitely.
  final Duration timeout;

  @override
  Future<Map<String, dynamic>> getJson(String url, {String? bearer}) async {
    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            if (bearer != null) 'Authorization': 'Bearer $bearer',
          },
        )
        .timeout(timeout);
    return _decode(response, url);
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, String> fields,
    (String, String)? basicAuth,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    if (basicAuth != null) {
      final (id, secret) = basicAuth;
      // RFC 6749 §2.3.1: the client id and secret are form-urlencoded before
      // being base64'd, which matters for secrets containing punctuation.
      final credentials =
          '${Uri.encodeQueryComponent(id)}:${Uri.encodeQueryComponent(secret)}';
      headers['Authorization'] =
          'Basic ${base64.encode(utf8.encode(credentials))}';
    }

    final response = await http
        .post(Uri.parse(url), headers: headers, body: fields)
        .timeout(timeout);
    return _decode(response, url);
  }

  Map<String, dynamic> _decode(http.Response response, String url) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpJsonException(response.statusCode, url, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw HttpJsonException(
        response.statusCode,
        url,
        'Expected a JSON object, got ${decoded.runtimeType}',
      );
    }
    return decoded;
  }
}
