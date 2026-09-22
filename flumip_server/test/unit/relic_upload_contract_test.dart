@Tags(['unit'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

/// Pins the three Relic behaviours [SnpUploadRoute] is built on.
///
/// `_receive` streams the request body straight to disk, so its two refusals —
/// oversized and truncated — are decided entirely by Relic, not by our code:
///
///   * `request.read(maxLength:)` must throw [MaxBodySizeExceeded] once the
///     stream exceeds the cap, or a client can push an unbounded file at us.
///   * [Response.contentTooLarge] must be a 413, which is what the browser
///     turns into a usable message.
///   * `body.contentLength` must be the *declared* length and must stay
///     nullable. The completeness check compares bytes written against it, so
///     a `contentLength` that started reporting the bytes actually received
///     would make `written != declared` unreachable and let a truncated file be
///     renamed into place and marked ready.
///
/// None of this is reachable from an endpoint test — nothing in the suite
/// constructs a Relic request — and the real cap is 4 GiB, so it cannot be
/// exercised over HTTP either. Hence a direct test against the contract.
///
/// It exists because a Relic major bump (1.x to 2.x, with Serverpod 4) can
/// change any of the three silently: the upload keeps returning 200 and the
/// damage only surfaces later, as mipgen dying on a corrupt archive.
void main() {
  Stream<Uint8List> chunks(int count, int size) =>
      Stream.fromIterable(List.generate(count, (_) => Uint8List(size)));

  group('read(maxLength:)', () {
    test('throws MaxBodySizeExceeded once the stream passes the cap', () {
      final body = Body.fromDataStream(chunks(4, 64));
      expect(
        body.read(maxLength: 100).drain<void>(),
        throwsA(isA<MaxBodySizeExceeded>()),
      );
    });

    test('reports the cap it was given on the exception', () async {
      final body = Body.fromDataStream(chunks(4, 64));
      await expectLater(
        body.read(maxLength: 100).drain<void>(),
        throwsA(
          isA<MaxBodySizeExceeded>().having(
            (e) => e.maxLength,
            'maxLength',
            100,
          ),
        ),
      );
    });

    test('passes a body under the cap through untouched', () async {
      final body = Body.fromDataStream(chunks(4, 64));
      var written = 0;
      await for (final chunk in body.read(maxLength: 1000)) {
        written += chunk.length;
      }
      expect(written, 256);
    });

    test('a body exactly at the cap is accepted, not refused', () async {
      final body = Body.fromDataStream(chunks(4, 64));
      var written = 0;
      await for (final chunk in body.read(maxLength: 256)) {
        written += chunk.length;
      }
      expect(written, 256);
    });
  });

  group('contentLength', () {
    test('is the declared length, not the length received', () {
      // 8 bytes declared but 256 delivered: the completeness check has to see
      // the 8, otherwise it can never spot a short upload.
      final body = Body.fromDataStream(chunks(4, 64), contentLength: 8);
      expect(body.contentLength, 8);
    });

    test('is null when nothing was declared', () {
      expect(Body.fromDataStream(chunks(1, 1)).contentLength, isNull);
    });
  });

  test('Response.contentTooLarge is a 413', () {
    expect(Response.contentTooLarge().statusCode, 413);
  });
}
