/// `2.40 GB`, `4.50 MB`, `912 bytes` — the same scale the server uses in the
/// notification emails, so a file is never described two different ways.
///
/// SI units (÷1000, not ÷1024), matching what a download manager and the
/// operating system's own file listing will say about the very same file.
///
/// Lifted out of `project_tile.dart`, where it started, once SNP sizes needed the
/// same treatment. The genome tab used to print sizes in gigabytes and nothing
/// else, which rendered a 150 MB SNP set as `0.15 Gb`.
String formatBytes(int bytes) {
  if (bytes < 1000) return '$bytes bytes';
  const units = ['kB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final decimals = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
  return '${value.toStringAsFixed(decimals)} ${units[unit]}';
}

/// `01:23:45` — how long a finished design run took.
///
/// Hours are not padded to two digits, because a run that takes more than 99
/// hours should read as what it is rather than wrap around; minutes and seconds
/// are, so the colons line up down a column of results.
String formatDuration(Duration duration) {
  final sign = duration.isNegative ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60).abs());
  final seconds = twoDigits(duration.inSeconds.remainder(60).abs());
  return '$sign${twoDigits(duration.inHours.abs())}:$minutes:$seconds';
}
