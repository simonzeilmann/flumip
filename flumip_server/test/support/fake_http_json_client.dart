import 'dart:convert';

import 'package:flumip_server/src/services/http_client.dart';

/// A single recorded call to [FakeHttpJsonClient].
class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.url,
    this.fields,
    this.bearer,
    this.basicAuth,
  });

  final String method;
  final String url;

  /// Form fields for a POST, so tests can assert what was actually sent to the
  /// token endpoint — the parameters are the protocol, and a missing
  /// `code_verifier` or a wrong `redirect_uri` is the usual bug.
  final Map<String, String>? fields;
  final String? bearer;
  final (String, String)? basicAuth;
}

/// In-memory [HttpJsonClient] for tests: answers from a canned response map
/// instead of talking to an identity provider. Mirrors [FakeMailSender].
///
/// Register responses with [stubGet] / [stubPost], or set [getError] /
/// [postError] to make a call fail. Unstubbed URLs throw, so a test that
/// accidentally depends on a call it did not set up fails loudly rather than
/// silently receiving an empty object.
class FakeHttpJsonClient implements HttpJsonClient {
  final List<RecordedRequest> requests = [];
  final Map<String, Map<String, dynamic>> _getResponses = {};
  final Map<String, Map<String, dynamic>> _postResponses = {};

  Object? getError;
  Object? postError;

  /// Clears every stub and recording.
  ///
  /// `withServerpod` group bodies run at collection time, so a group that shares
  /// one fake instance must call this from `setUp` or state leaks between tests.
  void reset() {
    requests.clear();
    _getResponses.clear();
    _postResponses.clear();
    getError = null;
    postError = null;
  }

  void stubGet(String url, Map<String, dynamic> response) {
    _getResponses[url] = response;
  }

  void stubPost(String url, Map<String, dynamic> response) {
    _postResponses[url] = response;
  }

  /// Stubs a complete, working provider at [issuer].
  ///
  /// Covers the discovery document, the token endpoint and userinfo, so most
  /// tests need one line of setup. [idTokenClaims], when given, is encoded as an
  /// unsigned JWT payload.
  void stubProvider({
    required String issuer,
    Map<String, dynamic>? idTokenClaims,
    Map<String, dynamic>? userinfo,
    String accessToken = 'access-token',
  }) {
    stubGet('$issuer/.well-known/openid-configuration', {
      'issuer': issuer,
      'authorization_endpoint': '$issuer/authorize',
      'token_endpoint': '$issuer/token',
      'userinfo_endpoint': '$issuer/userinfo',
      'code_challenge_methods_supported': ['S256'],
    });
    if (idTokenClaims != null) {
      stubPost('$issuer/token', {
        'id_token': unsignedJwt(idTokenClaims),
        'access_token': accessToken,
        'token_type': 'Bearer',
      });
    }
    if (userinfo != null) {
      stubGet('$issuer/userinfo', userinfo);
    }
  }

  RecordedRequest? get lastRequest => requests.isEmpty ? null : requests.last;

  /// The last POST to [url], or null.
  RecordedRequest? lastPostTo(String url) =>
      requests.where((r) => r.method == 'POST' && r.url == url).lastOrNull;

  @override
  Future<Map<String, dynamic>> getJson(String url, {String? bearer}) async {
    requests.add(RecordedRequest(method: 'GET', url: url, bearer: bearer));
    if (getError != null) throw getError!;
    final response = _getResponses[url];
    if (response == null) {
      throw HttpJsonException(404, url, 'FakeHttpJsonClient: no stub for GET');
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, String> fields,
    (String, String)? basicAuth,
  }) async {
    requests.add(
      RecordedRequest(
        method: 'POST',
        url: url,
        fields: Map.of(fields),
        basicAuth: basicAuth,
      ),
    );
    if (postError != null) throw postError!;
    final response = _postResponses[url];
    if (response == null) {
      throw HttpJsonException(404, url, 'FakeHttpJsonClient: no stub for POST');
    }
    return response;
  }
}

/// Builds an unsigned JWT with [claims] as its payload.
///
/// The signature is a placeholder: this server does not verify it, because the
/// token arrives directly from the token endpoint over TLS (see [IdTokenClaims]).
/// That is exactly why tests can hand-build tokens instead of needing a signing
/// key.
String unsignedJwt(Map<String, dynamic> claims) {
  String segment(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${segment({'alg': 'RS256', 'typ': 'JWT'})}'
      '.${segment(claims)}'
      '.not-a-real-signature';
}

/// Seconds since the epoch, as JWT `exp` / `iat` claims are encoded.
int epochSeconds(DateTime time) => time.toUtc().millisecondsSinceEpoch ~/ 1000;
