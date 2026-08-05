/// Client-side checks for the add-SNP form.
///
/// Pure string functions, so they can be tested on the Dart VM and so the dialog
/// itself stays a layout. Each returns null when the value is acceptable, or the
/// message to show beneath the field.
///
/// ⚠️ **None of this is a security boundary.** The server validates every address
/// again, resolves it, and refuses private networks — see `snpSourceUrlRejection`.
/// These exist so a typo is caught before a round trip, not to be relied on.
library;

/// Whether [name] looks like a bgzip-compressed VCF.
String? validateVcfName(String name) {
  if (name.isEmpty) return 'Choose a .vcf.gz file.';
  if (name.toLowerCase().endsWith('.vcf')) {
    return 'FLUMIP needs a bgzip-compressed VCF (.vcf.gz). '
        'Compress it first with: bgzip -c yourfile.vcf > yourfile.vcf.gz';
  }
  if (!name.endsWith('.vcf.gz')) return 'That is not a .vcf.gz file.';
  return null;
}

/// Whether [name] looks like a tabix index.
String? validateTbiName(String name) {
  if (name.isEmpty) return null; // optional
  if (!name.endsWith('.vcf.gz.tbi')) return 'That is not a .vcf.gz.tbi file.';
  return null;
}

/// Whether [url] is an address the server will accept as a VCF source.
String? validateVcfUrl(String url) {
  final basic = _validateUrl(url, required: true);
  if (basic != null) return basic;
  if (!_pathOf(url).endsWith('.vcf.gz')) {
    return 'The address should end in .vcf.gz';
  }
  return null;
}

/// Whether [url] is an address the server will accept as an index source.
String? validateTbiUrl(String url) {
  if (url.trim().isEmpty) return null; // optional
  final basic = _validateUrl(url, required: false);
  if (basic != null) return basic;
  if (!_pathOf(url).endsWith('.vcf.gz.tbi')) {
    return 'The address should end in .vcf.gz.tbi';
  }
  return null;
}

/// The index address implied by a VCF address, for prefilling.
///
/// By convention a tabix index sits beside its VCF under the same name plus
/// `.tbi`, which is what every one of the real sources does. Returned as a
/// suggestion the user can edit or clear, never forced.
String? suggestTbiUrl(String vcfUrl) {
  final trimmed = vcfUrl.trim();
  if (trimmed.isEmpty) return null;
  if (validateVcfUrl(trimmed) != null) return null;
  return '$trimmed.tbi';
}

String? _validateUrl(String url, {required bool required}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return required ? 'Paste a download address.' : null;

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) return 'That is not a valid address.';
  if (parsed.scheme.isEmpty) {
    return 'Start the address with https://';
  }
  if (parsed.scheme != 'http' && parsed.scheme != 'https') {
    // ftp is the one people reach for, and it is worth saying why not: the real
    // sources all serve these files over HTTPS anyway.
    return 'Only http and https addresses can be fetched. '
        'These files are usually available over https.';
  }
  if (!parsed.hasAuthority || parsed.host.isEmpty) {
    return 'That address has no host.';
  }
  if (parsed.userInfo.isNotEmpty) {
    return 'Remove the username and password from the address.';
  }
  return null;
}

/// The path part, lower-cased and without a query string.
///
/// A query string is common on generated download links and must not defeat the
/// suffix check.
String _pathOf(String url) =>
    (Uri.tryParse(url.trim())?.path ?? '').toLowerCase();
