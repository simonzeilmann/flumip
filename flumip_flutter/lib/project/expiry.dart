import 'package:flumip_client/flumip_client.dart';

import '../auth/auth_controller.dart';

/// When [project] will be deleted — always a midnight, the end of its last
/// day — or null when this server keeps projects indefinitely.
///
/// Mirrors the server's `deletionDeadline`: the stored `expires`, but never
/// earlier than the end of the day creation plus the retention window falls
/// in. The floor is what the cleanup call itself applies, so a project from
/// before `expires` existed — or one whose window an administrator has since
/// raised — shows the date it will actually go.
///
/// ⚠️ The floor's midnight is the browser's, the server's is the server's. The
/// two agree wherever both sit in one time zone, which is the case this is
/// built for; a stored `expires` — every project created since — is the
/// server's answer and is shown as it is.
///
/// Also null for a project an administrator has exempted
/// ([Project.keptIndefinitely]): it has no date to show.
DateTime? deletionDate(Project project, AuthConfigSnapshot config) {
  final retention = config.projectRetention;
  if (retention == null || project.keptIndefinitely) return null;
  final floor = endOfDay(project.created.add(retention));
  final expires = project.expires?.toUtc();
  return expires != null && expires.isAfter(floor) ? expires : floor;
}

/// The last day a project with [deadline] is kept: the day that ends at it.
///
/// What the app shows, rather than the deadline itself, which is the midnight
/// *after* that day and would read as one day too late.
DateTime lastDayKept(DateTime deadline) =>
    deadline.toLocal().subtract(const Duration(minutes: 1));

/// The first local midnight at or after [moment] — the end of its day.
DateTime endOfDay(DateTime moment) {
  final local = moment.toLocal();
  final midnight = DateTime(local.year, local.month, local.day);
  if (local.isAtSameMomentAs(midnight)) return midnight.toUtc();
  return DateTime(local.year, local.month, local.day + 1).toUtc();
}

/// Whether "Keep longer" would move [project]'s deletion any later.
///
/// False once it is at the server's maximum, which is when the button is
/// disabled. Compared to the minute: the server caps at exactly the end of the
/// day `created + maxLifetime` falls in, and a stored timestamp can come back a
/// few microseconds either side of that.
bool canExtend(Project project, AuthConfigSnapshot config) {
  final deadline = deletionDate(project, config);
  final max = config.maxProjectLifetime;
  if (deadline == null || max == null) return false;
  final cap = endOfDay(project.created.add(max));
  return cap.difference(deadline) >= const Duration(minutes: 1);
}

/// A retention window in words: "7 days", "36 hours", "1 day".
String describeRetention(Duration duration) {
  if (duration.inHours % 24 == 0) {
    final days = duration.inDays;
    return days == 1 ? '1 day' : '$days days';
  }
  final hours = duration.inHours;
  return hours == 1 ? '1 hour' : '$hours hours';
}
