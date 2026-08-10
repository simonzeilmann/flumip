/// How often to ask the server again, for anything that polls.
///
/// Moved out of `snp/snp_status.dart` once the genome tab needed the same rule.
/// It was never SNP-specific — it is the answer to "something might be changing
/// on the server, how often do I look?" — and having the genome tab keep its own
/// unconditional `Timer.periodic(5s)` while the SNP list next to it backed off
/// politely was the kind of inconsistency that only survives while the two live
/// in different files.
library;

/// How long to wait before asking the server again.
///
/// Tight while something can still move, because two seconds is about the pace of
/// a byte counter somebody is actually watching. Slow otherwise: 20 seconds is
/// the cost of noticing an SNP a colleague has just shared.
///
/// [consecutiveFailures] backs the interval off so that a server that has gone
/// away is not hammered, capped so it always recovers within a minute or so.
Duration pollInterval({required bool anyLive, int consecutiveFailures = 0}) {
  final base = anyLive
      ? const Duration(seconds: 2)
      : const Duration(seconds: 20);
  return base * (1 << consecutiveFailures.clamp(0, 3));
}

/// How long to wait before re-reading a genome, or null to stop polling.
///
/// ⚠️ **Returning null is the point.** The genome tab used to re-fetch the
/// selected genome every five seconds for as long as it was selected, which
/// rebuilt the whole tab twelve times a minute for data that cannot change on
/// its own — a genome's `active` flag is toggled here, and indexing is started
/// here. The one thing that does progress without us is an index being built, so
/// that is the only thing worth watching.
///
/// It also fixed a bug rather than just saving work: the poll wrote back into the
/// tab's state, so it could land in the middle of a user's Active toggle and put
/// the switch back.
Duration? genomePollInterval({
  required bool indexing,
  int consecutiveFailures = 0,
}) {
  if (!indexing) return null;
  return pollInterval(anyLive: true, consecutiveFailures: consecutiveFailures);
}
