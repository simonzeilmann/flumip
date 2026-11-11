import 'dart:convert';
import 'dart:io';

/// A throwaway certificate authority and one server certificate, for TLS tests
/// that must not touch the internet.
///
/// ⚠️ **Test-only key material, published on purpose.** The private key below is
/// in the repository and therefore worthless as a secret; nothing outside
/// `test/` may trust [testCaPem]. It exists so a test can stand up an HTTPS
/// server on 127.0.0.1 and show that a client verifies the certificate against
/// the *hostname* it was asked for, not the address it dialled.
///
/// The leaf certificate names only `snp.example.test` (`.test` is reserved by
/// RFC 2606 and never resolves on the public internet), valid for a century.
/// Regenerate with `openssl req -x509 …` if it ever needs changing; any CA plus a
/// leaf with that single DNS SAN will do.

/// The name [testServerCertPem] is valid for.
const testServerHost = 'snp.example.test';

const testCaPem = '''
-----BEGIN CERTIFICATE-----
MIIBvjCCAWOgAwIBAgIUX7vysf45sy/niEA5vWabaQyfpoowCgYIKoZIzj0EAwIw
KzEpMCcGA1UEAwwgRkxVTUlQIHRlc3QgQ0EgKHVuaXQgdGVzdHMgb25seSkwIBcN
MjYxMTExMTcwMjIwWhgPMjEyNjEwMTgxNzAyMjBaMCsxKTAnBgNVBAMMIEZMVU1J
UCB0ZXN0IENBICh1bml0IHRlc3RzIG9ubHkpMFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAEeRqJEIMi+vX2q2yg5pAmagKTuIIzk4l2hkgVIrEcDDTHmLkqAwftDsOF
95ZWTovlKyxCANdFFDLanV2SVzQRwqNjMGEwHQYDVR0OBBYEFGOdhSq6AnNxef6B
pr1lgIsysJuyMB8GA1UdIwQYMBaAFGOdhSq6AnNxef6Bpr1lgIsysJuyMA8GA1Ud
EwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMCA0kAMEYCIQC3
8nMPq7gRUWk4Fr/KMEsU2CAo6lWAGK6oI3WS4obkcQIhANQna4hhXh74TAseEY+i
JMqdanBHpaQEdSeOlB2HFDx4
-----END CERTIFICATE-----
''';

const testServerCertPem = '''
-----BEGIN CERTIFICATE-----
MIIByTCCAW+gAwIBAgIUVOqn3d/IRJ+0pVPgPSCfHr2lyz0wCgYIKoZIzj0EAwIw
KzEpMCcGA1UEAwwgRkxVTUlQIHRlc3QgQ0EgKHVuaXQgdGVzdHMgb25seSkwIBcN
MjYxMTExMTcwMjIwWhgPMjEyNjEwMTgxNzAyMjBaMBsxGTAXBgNVBAMMEHNucC5l
eGFtcGxlLnRlc3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQg7mOq+n2BjCHc
xZfFVU9BS3hytAJxVm0hGIeBGCnjAx65b0Zd3mdWWgFURKt906ap9UewxXeGtBEQ
5vM0pn8Yo38wfTAbBgNVHREEFDASghBzbnAuZXhhbXBsZS50ZXN0MAkGA1UdEwQC
MAAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwHQYDVR0OBBYEFE5tohNFJ+zYWu+GlOWy
hvIjjth8MB8GA1UdIwQYMBaAFGOdhSq6AnNxef6Bpr1lgIsysJuyMAoGCCqGSM49
BAMCA0gAMEUCIQCu+HIVX06Pj3BTCJf7PF5L495+ip7oAE9xv662hgQxnAIgV9A2
psmzyiXBM7bTCtLYifpfH9+9WDeNH2/8IsnO7fI=
-----END CERTIFICATE-----
''';

const testServerKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg/7q5NWQQyayP2iFj
BByhkosHsgCz7nMlHGJkAAHini+hRANCAAQg7mOq+n2BjCHcxZfFVU9BS3hytAJx
Vm0hGIeBGCnjAx65b0Zd3mdWWgFURKt906ap9UewxXeGtBEQ5vM0pn8Y
-----END PRIVATE KEY-----
''';

/// A server context presenting the `snp.example.test` certificate.
SecurityContext testServerContext() => SecurityContext()
  ..useCertificateChainBytes(utf8.encode(testServerCertPem))
  ..usePrivateKeyBytes(utf8.encode(testServerKeyPem));

/// A client context that trusts only the test CA — not the system roots, so a
/// test cannot accidentally pass against a real certificate.
SecurityContext testClientContext() =>
    SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(utf8.encode(testCaPem));
