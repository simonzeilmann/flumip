import 'dart:io';

import 'package:flumip_server/src/auth/url_guard.dart';
import 'package:test/test.dart';

/// Pure tests: [snpSourceUrlRejection] takes the resolved addresses as an
/// argument, so every reserved range can be exercised with a synthetic address
/// and no network.
///
/// This is the guard between "paste a download address" and a request proxy that
/// runs inside the deployment's own network, so the interesting cases are the
/// refusals rather than the happy path.
void main() {
  final public = [InternetAddress('93.184.216.34')];

  String? reject(
    String url, {
    List<InternetAddress>? resolved,
    List<String> allowedHosts = const [],
  }) => snpSourceUrlRejection(
    Uri.parse(url),
    resolved: resolved ?? public,
    allowedHosts: allowedHosts,
  );

  group('the happy path', () {
    test('a real dbSNP URL is accepted', () {
      expect(
        reject(
          'https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/'
          '00-common_all.vcf.gz',
        ),
        isNull,
      );
    });

    test('plain http is accepted', () {
      expect(reject('http://hgdownload.soe.ucsc.edu/x.vcf.gz'), isNull);
    });

    test('an explicit standard port is accepted', () {
      expect(reject('https://example.org:443/x.vcf.gz'), isNull);
      expect(reject('http://example.org:80/x.vcf.gz'), isNull);
    });

    test('a query string does not matter', () {
      expect(reject('https://example.org/get?file=x.vcf.gz&v=2'), isNull);
    });
  });

  group('schemes', () {
    test('file: is refused', () {
      // The classic: read /etc/passwd through the importer.
      expect(reject('file:///etc/passwd'), isNotNull);
    });

    test('ftp: is refused', () {
      // Not a loss. setup-mipgen.sh fetches from a host *named* ftp.ncbi.nih.gov
      // over HTTPS; NCBI, EBI and UCSC all serve these over HTTPS.
      expect(reject('ftp://ftp.ncbi.nih.gov/x.vcf.gz'), isNotNull);
    });

    test('gopher:, data: and jar: are refused', () {
      expect(reject('gopher://example.org/x'), isNotNull);
      expect(reject('data:text/plain,hello'), isNotNull);
      expect(reject('jar:https://example.org/a.zip!/b'), isNotNull);
    });

    test('a bare hostname with no scheme is refused', () {
      expect(reject('example.org/x.vcf.gz'), isNotNull);
    });
  });

  group('credentials in the URL', () {
    test('userinfo is refused', () {
      // It would be stored in sourceVcfUrl and rendered back in the app.
      expect(reject('https://user:secret@example.org/x.vcf.gz'), isNotNull);
      expect(reject('https://user@example.org/x.vcf.gz'), isNotNull);
    });
  });

  group('ports', () {
    test('a non-standard port is refused', () {
      // One rule that removes "point it at Postgres / Redis / the insights
      // server" without having to enumerate the ports that matter.
      for (final port in [5432, 6379, 8080, 8081, 8082, 9090, 22, 25]) {
        expect(
          reject('https://example.org:$port/x.vcf.gz'),
          isNotNull,
          reason: 'port $port should be refused',
        );
      }
    });

    test('http on 443 and https on 80 are both refused', () {
      expect(reject('http://example.org:443/x'), isNotNull);
      expect(reject('https://example.org:80/x'), isNotNull);
    });
  });

  group('IPv4 reserved ranges', () {
    for (final address in [
      '0.0.0.0',
      '0.1.2.3',
      '10.0.0.1',
      '10.255.255.255',
      '100.64.0.1',
      '100.127.255.255',
      '127.0.0.1',
      '127.1.2.3',
      '169.254.169.254', // cloud metadata — hands out credentials
      '172.16.0.1',
      '172.31.255.255',
      '192.0.0.1',
      '192.168.0.1',
      '192.168.1.1',
      '198.18.0.1',
      '198.19.255.255',
      '224.0.0.1',
      '239.255.255.255',
      '240.0.0.1',
      '255.255.255.255',
    ]) {
      test('$address is refused', () {
        expect(
          reject(
            'https://example.org/x.vcf.gz',
            resolved: [InternetAddress(address)],
          ),
          isNotNull,
        );
      });
    }

    test('addresses just outside the private ranges are allowed', () {
      // The boundaries are worth pinning: an off-by-one here either lets a
      // private address through or blocks a legitimate public one.
      for (final address in [
        '9.255.255.255',
        '11.0.0.0',
        '100.63.255.255',
        '100.128.0.0',
        '126.255.255.255',
        '128.0.0.1',
        '169.253.255.255',
        '169.255.0.0',
        '172.15.255.255',
        '172.32.0.0',
        '192.167.255.255',
        '192.169.0.0',
        '198.17.255.255',
        '198.20.0.0',
        '223.255.255.255',
      ]) {
        expect(
          reject(
            'https://example.org/x.vcf.gz',
            resolved: [InternetAddress(address)],
          ),
          isNull,
          reason: '$address is public and should be allowed',
        );
      }
    });
  });

  group('IPv6 reserved ranges', () {
    for (final address in [
      '::1', // loopback
      '::', // unspecified — dialling it means localhost
      'fc00::1', // unique local
      'fd12:3456::1', // unique local
      'fe80::1', // link-local
      'ff02::1', // multicast
    ]) {
      test('$address is refused', () {
        expect(
          reject(
            'https://example.org/x.vcf.gz',
            resolved: [InternetAddress(address)],
          ),
          isNotNull,
        );
      });
    }

    test('a public IPv6 address is allowed', () {
      expect(
        reject(
          'https://example.org/x.vcf.gz',
          resolved: [InternetAddress('2606:2800:220:1:248:1893:25c8:1946')],
        ),
        isNull,
      );
    });

    test('an IPv4-mapped loopback is refused', () {
      // ⚠️ ::ffff:127.0.0.1 is an IPv4 destination wearing a sixteen-byte hat.
      // Without unwrapping it, none of the v6 checks match and it sails through.
      expect(
        reject(
          'https://example.org/x.vcf.gz',
          resolved: [InternetAddress('::ffff:127.0.0.1')],
        ),
        isNotNull,
      );
    });

    test('an IPv4-mapped private address is refused', () {
      expect(
        reject(
          'https://example.org/x.vcf.gz',
          resolved: [InternetAddress('::ffff:169.254.169.254')],
        ),
        isNotNull,
      );
    });

    test('an IPv4-mapped public address is allowed', () {
      expect(
        reject(
          'https://example.org/x.vcf.gz',
          resolved: [InternetAddress('::ffff:93.184.216.34')],
        ),
        isNull,
      );
    });
  });

  group('mixed answers', () {
    test('one private address among public ones refuses the whole URL', () {
      // ⚠️ A host with both a public and a private A record is a rebinding attack
      // with the work already done. Checking only the address that would be
      // dialled is not enough.
      expect(
        reject(
          'https://example.org/x.vcf.gz',
          resolved: [
            InternetAddress('93.184.216.34'),
            InternetAddress('127.0.0.1'),
          ],
        ),
        isNotNull,
      );
    });

    test('a host that resolves to nothing is refused', () {
      expect(reject('https://example.org/x.vcf.gz', resolved: []), isNotNull);
    });
  });

  group('the allowlist', () {
    const allowed = ['ftp.ncbi.nlm.nih.gov', 'hgdownload.soe.ucsc.edu'];

    test('an exact host matches', () {
      expect(
        reject('https://ftp.ncbi.nlm.nih.gov/x.vcf.gz', allowedHosts: allowed),
        isNull,
      );
    });

    test('a subdomain matches', () {
      expect(
        reject(
          'https://sub.ftp.ncbi.nlm.nih.gov/x.vcf.gz',
          allowedHosts: allowed,
        ),
        isNull,
      );
    });

    test('a host not on the list is refused', () {
      expect(
        reject('https://example.org/x.vcf.gz', allowedHosts: allowed),
        isNotNull,
      );
    });

    test('a suffix that is not a label boundary is refused', () {
      // ⚠️ A plain endsWith would accept this. The attacker controls
      // attacker.com and can name a subdomain anything they like.
      expect(
        reject(
          'https://ftp.ncbi.nlm.nih.gov.attacker.com/x.vcf.gz',
          allowedHosts: allowed,
        ),
        isNotNull,
      );
      expect(
        reject(
          'https://evilftp.ncbi.nlm.nih.gov/x.vcf.gz',
          allowedHosts: const ['ftp.ncbi.nlm.nih.gov'],
        ),
        isNotNull,
      );
    });

    test('matching ignores case', () {
      expect(
        reject('https://FTP.NCBI.NLM.NIH.GOV/x.vcf.gz', allowedHosts: allowed),
        isNull,
      );
    });

    test('an empty list means any host that passes the other checks', () {
      expect(
        reject('https://example.org/x.vcf.gz', allowedHosts: const []),
        isNull,
      );
    });

    test('blank entries are ignored rather than matching everything', () {
      // A trailing comma in the settings field produces one of these.
      expect(
        reject(
          'https://example.org/x.vcf.gz',
          allowedHosts: const ['', '  ', 'ftp.ncbi.nlm.nih.gov'],
        ),
        isNotNull,
      );
    });

    test('the allowlist does not override the address check', () {
      // Being named on the list is not a licence to resolve to localhost.
      expect(
        reject(
          'https://ftp.ncbi.nlm.nih.gov/x.vcf.gz',
          resolved: [InternetAddress('127.0.0.1')],
          allowedHosts: allowed,
        ),
        isNotNull,
      );
    });
  });

  group('IP literals in disguise', () {
    // ⚠️ All of these are 127.0.0.1 to `inet_aton` and to a browser. Whether
    // the platform resolver agrees is not something to rely on, so the guard
    // refuses every spelling but the canonical one before any lookup.
    for (final host in [
      '2130706433',
      '0x7f000001',
      '0x7f.1',
      '0177.0.0.1',
      '127.1',
      '127.0.0.1.',
      '017700000001',
      '127.000.000.001',
      '1.2.3.256',
      'example.123',
    ]) {
      test('http://$host/ is refused', () {
        expect(reject('http://$host/x.vcf.gz'), isNotNull);
      });
    }

    test('a canonical public literal is accepted', () {
      expect(reject('http://93.184.216.34/x.vcf.gz'), isNull);
    });

    test('a name that merely looks hexadecimal is still a name', () {
      expect(reject('https://deadbeef.cafe/x.vcf.gz'), isNull);
      expect(reject('https://0x7f.example/x.vcf.gz'), isNull);
    });
  }, tags: ['unit']);

  group('more IPv6 ranges', () {
    for (final address in [
      '::127.0.0.1', // IPv4-compatible, deprecated but sometimes still routed
      '::a9fe:a9fe', // the same, for 169.254.169.254
      '64:ff9b::7f00:1', // NAT64 of 127.0.0.1
      '64:ff9b::a9fe:a9fe', // NAT64 of 169.254.169.254
      '2002:7f00:1::1', // 6to4 via 127.0.0.1
      '2002:a00:1::1', // 6to4 via 10.0.0.1
      '2001::1', // Teredo
      '2001:db8::1', // documentation
      '100::1', // discard
      'fec0::1', // site-local
      'ff02::1', // multicast
    ]) {
      test('$address is refused', () {
        expect(
          reject(
            'https://example.org/x.vcf.gz',
            resolved: [InternetAddress(address)],
          ),
          isNotNull,
        );
      });
    }

    test('NAT64 of a public address is allowed', () {
      // On an IPv6-only network with DNS64, every IPv4-only source looks like
      // this; refusing it would break the feature there.
      expect(
        reject(
          'https://example.org/x.vcf.gz',
          resolved: [InternetAddress('64:ff9b::5db8:d822')],
        ),
        isNull,
      );
    });

    test('documentation IPv4 ranges are refused', () {
      for (final a in ['192.0.2.1', '198.51.100.1', '203.0.113.1']) {
        expect(
          reject(
            'https://example.org/x.vcf.gz',
            resolved: [InternetAddress(a)],
          ),
          isNotNull,
          reason: a,
        );
      }
    });
  }, tags: ['unit']);
}
