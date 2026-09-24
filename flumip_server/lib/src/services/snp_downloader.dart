import 'dart:async';
import 'dart:io';

import 'package:flumip_server/src/auth/url_guard.dart';

/// Why a download could not be completed, in words fit to show a user.
///
/// ⚠️ [message] is deliberately short and written here rather than taken from the
/// remote server. A fetched error page can contain anything at all, and this
/// string ends up rendered in the app as an SNP's `statusMessage`.
class SnpDownloadException implements Exception {
  SnpDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Streams a remote file to disk, with progress.
///
/// A seam rather than a direct `HttpClient` call, registered in
/// `service_locator.dart` alongside [HttpJsonClient], [ProcessRunner] and
/// [MailSender], so tests can substitute a fake and exercise a truncated
/// response, a redirect into a private network, or a size-cap overrun without a
/// network. Same convention as the rest.
///
/// Deliberately **not** [HttpJsonClient]: that one is JSON-only and decodes the
/// whole body into a map, which is exactly wrong for a 1.5 GB VCF.
abstract class SnpDownloader {
  /// Streams [url] into [target] and returns the number of bytes written.
  ///
  /// [onProgress] is called as bytes arrive, with the running count and the total
  /// if the server declared one. Implementations must not call it per chunk — a
  /// 1 GB download at 64 kB a chunk is sixteen thousand calls.
  ///
  /// Throws [SnpDownloadException] for every failure. Implementations must delete
  /// a partial [target] before throwing.
  Future<int> download(
    Uri url,
    File target, {
    required int maxBytes,
    required List<String> allowedHosts,
    required FutureOr<void> Function(int received, int? total) onProgress,
  });
}

/// The real [SnpDownloader]: `dart:io`'s [HttpClient], following redirects by hand.
///
/// ## Why redirects are followed manually
///
/// ⚠️ **This is the whole reason this is not `wget` or `curl` through
/// [ProcessRunner].** Neither of those can be told to refuse a private address,
/// and both follow redirects into one by default — so a URL that passes every
/// check at the front door can still land on `http://169.254.169.254/`. With
/// `followRedirects = false` each hop is re-validated through
/// [snpSourceUrlRejection] before it is dialled.
///
/// What is given up is `wget -c` resume. Accepted: on failure the partial file is
/// deleted and the import starts over, because a half-download that silently
/// resumes against a *changed* remote file produces a corrupt archive — worse
/// than transferring 800 MB twice.
class HttpSnpDownloader implements SnpDownloader {
  const HttpSnpDownloader({
    this.maxRedirects = 5,
    this.connectTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(minutes: 5),
  });

  final int maxRedirects;
  final Duration connectTimeout;

  /// How long the transfer may stall before it is abandoned.
  ///
  /// Not a total timeout: a legitimate multi-gigabyte fetch over a slow link can
  /// take hours, and capping that would break the feature for exactly the people
  /// who need it. This bounds *silence*, which is what a dead connection looks
  /// like.
  final Duration idleTimeout;

  /// Progress is reported at most this often, no matter the chunk size.
  static const progressInterval = Duration(seconds: 2);

  @override
  Future<int> download(
    Uri url,
    File target, {
    required int maxBytes,
    required List<String> allowedHosts,
    required FutureOr<void> Function(int received, int? total) onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = connectTimeout;

    IOSink? sink;
    try {
      final response = await _fetchFollowingRedirects(
        client,
        url,
        allowedHosts: allowedHosts,
      );

      final declared = response.contentLength;
      final total = declared > 0 ? declared : null;

      // Refuse before a single byte is written when the server was honest about
      // an oversized file.
      if (total != null && total > maxBytes) {
        throw SnpDownloadException(
          'That file is ${_gb(total)}, over the ${_gb(maxBytes)} limit.',
        );
      }

      sink = target.openWrite();
      var received = 0;
      var lastReport = DateTime.now();

      await for (final chunk in response.timeout(
        idleTimeout,
        onTimeout: (sink) {
          sink.addError(
            SnpDownloadException(
              'The connection went quiet for '
              '${idleTimeout.inMinutes} minutes and was given up on.',
            ),
          );
          sink.close();
        },
      )) {
        received += chunk.length;
        // A server that lied about Content-Length, or sent none at all, is
        // caught here instead: the cap holds either way.
        if (received > maxBytes) {
          throw SnpDownloadException(
            'That file is larger than the ${_gb(maxBytes)} limit.',
          );
        }
        sink.add(chunk);

        if (DateTime.now().difference(lastReport) >= progressInterval) {
          lastReport = DateTime.now();
          await onProgress(received, total);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (total != null && received != total) {
        throw SnpDownloadException(
          'The download stopped early, after ${_gb(received)} of ${_gb(total)}.',
        );
      }

      await onProgress(received, total ?? received);
      return received;
    } catch (e) {
      // Close the sink before deleting, or the file stays open and on some
      // filesystems undeletable.
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (await target.exists()) await target.delete();
      } catch (_) {}
      if (e is SnpDownloadException) rethrow;
      // Never surface a raw socket or TLS error: it is unreadable, and for a
      // redirect chain it can name an internal host.
      throw SnpDownloadException('Could not reach that address.');
    } finally {
      client.close(force: true);
    }
  }

  /// Walks the redirect chain by hand, re-validating every hop.
  Future<HttpClientResponse> _fetchFollowingRedirects(
    HttpClient client,
    Uri url, {
    required List<String> allowedHosts,
  }) async {
    var current = url;

    for (var hop = 0; hop <= maxRedirects; hop++) {
      // ⚠️ The check happens on every hop, not just the first. A URL that passes
      // at the front door can still redirect into the deployment's own network.
      final addresses = await resolveHost(current.host);
      final refusal = snpSourceUrlRejection(
        current,
        resolved: addresses,
        allowedHosts: allowedHosts,
      );
      if (refusal != null) {
        throw SnpDownloadException(
          hop == 0 ? refusal : 'This address redirected somewhere refused.',
        );
      }

      final request = await client.getUrl(current)
        // ⚠️ Off, so that each hop comes back here to be re-validated before it
        // is dialled. Letting HttpClient follow them itself is exactly the hole
        // that makes `wget` and `curl` unusable for this — see the class doc.
        ..followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      final response = await request.close();

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        // Drain, or the connection is left half-read in the pool.
        await response.drain<void>();
        if (location == null || location.isEmpty) {
          throw SnpDownloadException(
            'This address redirected without saying where to.',
          );
        }
        current = current.resolve(location);
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw SnpDownloadException(
          'This address answered ${response.statusCode} '
          '${_reason(response.statusCode)}.',
        );
      }

      return response;
    }

    throw SnpDownloadException(
      'This address redirected more than $maxRedirects times.',
    );
  }

  static String _gb(int bytes) =>
      '${(bytes / 1000000000).toStringAsFixed(2)} GB';

  static String _reason(int status) => switch (status) {
    401 || 403 => '(access denied)',
    404 => '(not found)',
    >= 500 => '(server error)',
    _ => '',
  };
}
