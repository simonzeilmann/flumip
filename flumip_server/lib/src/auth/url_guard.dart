import 'dart:io';

/// Why a URL may not be fetched by the server, or null if it may.
///
/// ## Why this exists
///
/// Importing an SNP set by URL asks the **server** to make an HTTP request to an
/// address a user typed. That is server-side request forgery in its purest form:
/// the server sits inside the deployment's network and can reach things the user
/// cannot — a database on 5432, the insights server on 8081, a cloud provider's
/// metadata endpoint on 169.254.169.254 that hands out credentials, anything else
/// on the hospital or university LAN. Without a guard, "paste a download address"
/// is a request proxy.
///
/// ## Why it is pure
///
/// The caller does the DNS lookup and passes [resolved] in, exactly as
/// `projectIsAccessible` takes the facts rather than a [Session]. That is what
/// makes every reserved range testable with a synthetic address, with no network
/// and no DNS.
///
/// ## DNS rebinding, and where it is closed
///
/// ⚠️ Vetting a *name* is worth nothing on its own. A hostile DNS server can
/// answer with a public address when this guard asks and with `127.0.0.1` or
/// `169.254.169.254` a moment later when the HTTP client asks again. The guard
/// therefore only ever vets *addresses*, and `HttpSnpDownloader` dials exactly
/// the addresses it vetted (see `pinnedConnectionFactory` there) instead of
/// letting `HttpClient` resolve the name a second time. Anything else that
/// fetches a user-supplied URL must do the same, or this check is theatre.
/// [allowedHosts] (`Settings.snpSourceAllowedHosts`) is defence in depth on top.
String? snpSourceUrlRejection(
  Uri url, {
  required List<InternetAddress> resolved,
  List<String> allowedHosts = const [],
}) {
  if (url.scheme != 'http' && url.scheme != 'https') {
    return 'Only http and https addresses can be fetched.';
  }
  if (!url.hasAuthority || url.host.isEmpty) {
    return 'This address has no host.';
  }

  // ⚠️ `http://2130706433/`, `http://0x7f.1/` and `http://0177.0.0.1/` are all
  // 127.0.0.1 to a browser and to `inet_aton`, but not to [InternetAddress]'s
  // literal parser. Whether they then resolve depends on the platform's
  // resolver, which is not something a security check should depend on. A host
  // whose last label is a number is an IPv4 address by the WHATWG URL rules, so
  // it must be written the one canonical way or not at all.
  if (_looksLikeIpv4(url.host) && !_isCanonicalIpv4(url.host)) {
    return 'Write the IP address in the usual dotted form (like 192.0.2.1).';
  }

  // A `user:pass@` would be stored in `sourceVcfUrl` and rendered back in the
  // app, which is a credential leak by way of a provenance field.
  if (url.userInfo.isNotEmpty) {
    return 'Remove the username and password from the address.';
  }

  // ⚠️ Strict on purpose, and it is doing more work than it looks. Confining
  // fetches to the scheme's default port removes every "point it at Postgres on
  // 5432, Redis on 6379, the insights server on 8081" pivot in one rule, rather
  // than trying to enumerate the ports that matter. Real SNP sources — NCBI, EBI,
  // UCSC — all serve on 443. The escape hatch is the allowlist.
  final defaultPort = url.scheme == 'https' ? 443 : 80;
  if (url.hasPort && url.port != defaultPort) {
    return 'Only the standard port ($defaultPort) can be fetched.';
  }

  if (resolved.isEmpty) {
    return 'This host could not be found.';
  }

  // ⚠️ **Every** resolved address must pass, not merely the one that would be
  // dialled. A host with an A record for both a public and a private address is a
  // rebinding attack with the work already done for it.
  for (final address in resolved) {
    if (!_isGlobalUnicast(address)) {
      return 'This address resolves to a private or reserved network, which '
          'this server will not fetch from.';
    }
  }

  if (allowedHosts.isNotEmpty && !_hostIsAllowed(url.host, allowedHosts)) {
    return 'This server only fetches SNP files from: '
        '${allowedHosts.join(', ')}.';
  }

  return null;
}

/// The addresses [host] resolves to, or an empty list.
///
/// A literal address needs no lookup — and asking some resolvers for one fails —
/// so it is returned as itself. An empty result is not an error here: it is what
/// [snpSourceUrlRejection] turns into "that host could not be found", which is the
/// same refusal either way.
///
/// Lives beside the guard so that the endpoint's pre-flight check and the
/// downloader's per-hop check resolve names the same way. Two implementations
/// would be two chances to differ.
Future<List<InternetAddress>> resolveHost(String host) async {
  if (host.isEmpty) return const [];
  try {
    return [InternetAddress(host)];
  } on ArgumentError {
    // Not a literal, so it needs a lookup.
  }
  try {
    return await InternetAddress.lookup(host);
  } catch (_) {
    return const [];
  }
}

/// Whether [host] would be read as an IPv4 address by a WHATWG URL parser: its
/// last label (ignoring one trailing dot) is decimal digits or `0x` hex.
///
/// That is the rule browsers use, and it is what decides whether `0x7f.1` is a
/// name to look up or an address in disguise. A real domain never ends in a
/// number, because no top-level domain is numeric.
bool _looksLikeIpv4(String host) {
  var h = host;
  if (h.endsWith('.')) h = h.substring(0, h.length - 1);
  final last = h.split('.').last.toLowerCase();
  if (last.isEmpty) return false;
  return RegExp(r'^[0-9]+$').hasMatch(last) ||
      RegExp(r'^0x[0-9a-f]*$').hasMatch(last);
}

/// Whether [host] is a plain `a.b.c.d` with four decimal octets and no leading
/// zeros — the only spelling every parser agrees on.
bool _isCanonicalIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  for (final p in parts) {
    if (!RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(p)) return false;
    if (int.parse(p) > 255) return false;
  }
  return true;
}

/// Whether [host] is on the allowlist, either exactly or as a subdomain.
///
/// Subdomain matching is on the label boundary — `evilftp.ncbi.nlm.nih.gov.attacker.com`
/// must not match `ftp.ncbi.nlm.nih.gov`, and a plain `endsWith` would let it.
bool _hostIsAllowed(String host, List<String> allowedHosts) {
  final needle = host.toLowerCase();
  for (final raw in allowedHosts) {
    final allowed = raw.trim().toLowerCase();
    if (allowed.isEmpty) continue;
    if (needle == allowed) return true;
    if (needle.endsWith('.$allowed')) return true;
  }
  return false;
}

/// Whether [address] is a public, routable address.
///
/// Everything else — loopback, link-local, the private ranges, carrier-grade NAT,
/// multicast, the reserved blocks — is refused. Written out by hand from
/// `rawAddress` rather than leaning on `dart:io`'s predicates alone, because those
/// cover loopback, link-local and multicast but say nothing about `10/8` or
/// `169.254/16`.
bool _isGlobalUnicast(InternetAddress address) {
  if (address.isLoopback || address.isLinkLocal || address.isMulticast) {
    return false;
  }

  final bytes = address.rawAddress;

  if (address.type == InternetAddressType.IPv4) {
    return _ipv4IsGlobal(bytes);
  }

  if (bytes.length != 16) return false;

  // An IPv4-mapped address (::ffff:a.b.c.d) is an IPv4 destination wearing a
  // sixteen-byte hat. Unwrap it and apply the v4 rules, or `::ffff:127.0.0.1`
  // walks straight through every v6 check below.
  final isV4Mapped =
      bytes.take(10).every((b) => b == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (isV4Mapped) {
    return _ipv4IsGlobal(bytes.sublist(12));
  }

  // 64:ff9b::/96 and 64:ff9b:1::/48 — NAT64. The gateway translates these to
  // the IPv4 address in the low 32 bits, so judge that address instead.
  if (bytes[0] == 0x00 &&
      bytes[1] == 0x64 &&
      bytes[2] == 0xff &&
      bytes[3] == 0x9b) {
    return _ipv4IsGlobal(bytes.sublist(12));
  }
  // ::/8 — reserved. Holds `::` (connecting to it means localhost), `::1`, and
  // the deprecated IPv4-compatible form `::a.b.c.d`, which some stacks still
  // route to the embedded v4 address: `::127.0.0.1` would otherwise pass.
  if (bytes[0] == 0) return false;
  // 2002::/16 — 6to4, with the IPv4 relay address in bytes 2–5.
  if (bytes[0] == 0x20 && bytes[1] == 0x02) {
    return _ipv4IsGlobal(bytes.sublist(2, 6));
  }
  // 2001::/32 — Teredo, a tunnel whose far end is not this address at all.
  if (bytes[0] == 0x20 && bytes[1] == 0x01 && bytes[2] == 0 && bytes[3] == 0) {
    return false;
  }
  // 2001:db8::/32 — documentation only; never a real server.
  if (bytes[0] == 0x20 &&
      bytes[1] == 0x01 &&
      bytes[2] == 0x0d &&
      bytes[3] == 0xb8) {
    return false;
  }
  // 100::/64 — the discard prefix.
  if (bytes[0] == 0x01 && bytes.sublist(1, 8).every((b) => b == 0)) {
    return false;
  }
  // fc00::/7 — unique local addresses, the v6 equivalent of 10/8.
  if (bytes[0] & 0xfe == 0xfc) return false;
  // fe80::/10 — link-local. isLinkLocal covers it; kept for the same reason.
  // fec0::/10 — the deprecated site-local range, still routed inside some
  // older networks. Together: fe80::/9.
  if (bytes[0] == 0xfe && (bytes[1] & 0x80) == 0x80) return false;
  // ff00::/8 — multicast. isMulticast covers it, belt and braces.
  if (bytes[0] == 0xff) return false;

  return true;
}

bool _ipv4IsGlobal(List<int> b) {
  if (b.length != 4) return false;
  final a = b[0];
  final second = b[1];

  // 0.0.0.0/8 — "this network", and 0.0.0.0 itself means localhost when dialled.
  if (a == 0) return false;
  // 10.0.0.0/8 — private.
  if (a == 10) return false;
  // 100.64.0.0/10 — carrier-grade NAT.
  if (a == 100 && second >= 64 && second <= 127) return false;
  // 127.0.0.0/8 — loopback, the whole block and not just 127.0.0.1.
  if (a == 127) return false;
  // 169.254.0.0/16 — link-local, which is where cloud metadata services live.
  if (a == 169 && second == 254) return false;
  // 172.16.0.0/12 — private.
  if (a == 172 && second >= 16 && second <= 31) return false;
  // 192.0.0.0/24 — IETF protocol assignments.
  if (a == 192 && second == 0 && b[2] == 0) return false;
  // 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 — documentation only.
  if (a == 192 && second == 0 && b[2] == 2) return false;
  if (a == 198 && second == 51 && b[2] == 100) return false;
  if (a == 203 && second == 0 && b[2] == 113) return false;
  // 192.168.0.0/16 — private.
  if (a == 192 && second == 168) return false;
  // 198.18.0.0/15 — benchmarking.
  if (a == 198 && (second == 18 || second == 19)) return false;
  // 224.0.0.0/4 multicast and 240.0.0.0/4 reserved, which together cover
  // everything from 224 up, including the 255.255.255.255 broadcast address.
  if (a >= 224) return false;

  return true;
}
