import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/authorization_service.dart';
import 'package:serverpod/serverpod.dart';

/// Escapes Postgres' `LIKE` metacharacters, so a typed one means itself.
///
/// ⚠️ Serverpod inlines the pattern as a quoted SQL literal — it handles quoting
/// and nothing else. Without this a query of `%` becomes `'%%%'` and matches every
/// row in three tables, which is both the fastest way to make search useless and
/// the only real correctness bug available in this feature.
///
/// Backslash first, or the escapes get escaped.
String escapeLikePattern(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

/// Finding a project, a genome or an SNP set by typing part of its name.
///
/// ## How the two predicates divide
///
/// SQL answers **what could match** — the `ILIKE`, pushed down so Postgres hands
/// back only candidate rows. Dart answers **who may see it**, through the existing
/// [AuthorizationService.visibleProjects] and [AuthorizationService.listableSnps].
/// The access rule therefore still has exactly one expression, which is the rule
/// `visibleProjects` insists on in writing.
///
/// The corollary is the trap worth naming: **no SQL `LIMIT` where a Dart filter
/// follows it.** A `LIMIT 8` would cap what Postgres returns and the visibility
/// filter would then remove some of those rows, so search would report three hits
/// while matching, visible rows went unmentioned. Genomes are capped in SQL
/// because nothing filters them afterwards; projects and SNP sets are capped in
/// Dart, after filtering. `search_endpoint_test.dart` pins this.
///
/// ## Why there is no index
///
/// A btree cannot serve `ILIKE '%x%'` at all — the leading wildcard rules it out —
/// so only a `pg_trgm` GIN index would help, and that needs `CREATE EXTENSION`,
/// a hand-edited migration and a deployment prerequisite. At tens of genomes,
/// hundreds of projects and hundreds of SNP sets the scan itself does not
/// register. This is strictly cheaper than `ProjectEndpoint.getProjects`, which
/// deserialises the whole project table on every tab load.
///
/// Measured against a development server, so the numbers below mean something:
/// a search costs **four queries at 60 ms, three at 58 ms, and zero at 0.4 ms**
/// when the query is under [minQueryLength] — while `getProjects`, at one query,
/// costs 21 ms. So it is roughly 20 ms of fixed per-call overhead plus ~13 ms per
/// round trip to Postgres, and **none of it is the scan**.
///
/// ⚠️ That is why the revisit trigger is a row count and not a latency: total
/// latency here is dominated by per-query overhead an index cannot touch, so a
/// millisecond threshold would trip on a healthy server and prove nothing.
/// **Add `pg_trgm` with a GIN index when `project` or `snp` passes ~100k rows —
/// and only then.** If search feels slow before that, count the queries in the
/// log line first; four is the ceiling, and anything more is a different bug.
///
/// There is no cache either. Keyed per principal and invalidated on every project,
/// genome and SNP write, it would cost more code and more failure modes than the
/// four queries it saves, and a search that cannot find a project created ten
/// seconds ago is a bug report.
class SearchService {
  /// Below this length everything matches and the answer is useless.
  ///
  /// Enforced here as well as in the app, because the app is not the only
  /// possible caller and a one-character query is a scan of three tables.
  static const int minQueryLength = 2;

  /// Hits per kind. A dropdown, not a report.
  static const int hitsPerKind = 8;

  /// Every project, genome and SNP set matching [query] that [session] may see.
  ///
  /// Worst case four queries and 24 rows out: three `ILIKE` finds, plus one to
  /// name the genomes the SNP hits belong to.
  Future<List<SearchHitDto>> search(Session session, String query) async {
    final needle = query.trim();
    if (needle.length < minQueryLength) return const [];
    final pattern = '%${escapeLikePattern(needle)}%';

    return [
      ...await _projects(session, pattern),
      ...await _genomes(session, pattern),
      ...await _snpSets(session, pattern),
    ];
  }

  Future<List<SearchHitDto>> _projects(Session session, String pattern) async {
    final matched = await authz.visibleProjects(
      session,
      matching: (t) => t.name.ilike(pattern) | t.description.ilike(pattern),
    );
    // Newest first, the order the projects tab itself uses — so the hit list and
    // the list it lands on agree about which of two similar projects is "the" one.
    matched.sort((a, b) => b.created.compareTo(a.created));

    return matched
        .take(hitsPerKind)
        .map(
          (p) => SearchHitDto(
            kind: SearchHitKind.project,
            id: p.id!,
            name: p.name,
            subtitle: p.description,
          ),
        )
        .toList();
  }

  Future<List<SearchHitDto>> _genomes(Session session, String pattern) async {
    final matched = await Genome.db.find(
      session,
      where: (t) => t.name.ilike(pattern) | t.description.ilike(pattern),
      orderBy: (t) => t.name,
      // Safe here, and only here: genomes carry no visibility rule, so nothing
      // filters this result and the SQL predicate is the whole predicate.
      limit: hitsPerKind,
    );

    // `active` is deliberately not filtered. The rail lists inactive genomes, and
    // a search that disagreed with the rail about what exists is the same
    // "two expressions of one rule" failure wearing a UI costume.
    return matched
        .map(
          (g) => SearchHitDto(
            kind: SearchHitKind.genome,
            id: g.id!,
            name: g.name,
            subtitle: g.description,
            genomeId: g.id,
            category: g.category,
            context: g.category ?? '',
          ),
        )
        .toList();
  }

  Future<List<SearchHitDto>> _snpSets(Session session, String pattern) async {
    final matched = await Snp.db.find(
      session,
      where: (t) => t.name.ilike(pattern) | t.description.ilike(pattern),
      // Ordered for the reason `getAllSnpForGenome` documents: an unordered find
      // returns Postgres heap order, which moves whenever a row is updated.
      orderBy: (t) => t.id,
    );
    final listable = await authz.listableSnps(session, matched);

    // An SNP whose genome was deleted is navigable to nowhere — the model already
    // says it "appears in no picker", and it does not appear here either.
    final hits = listable
        .where((s) => s.genome != null)
        .take(hitsPerKind)
        .toList();
    if (hits.isEmpty) return const [];

    // One extra query, bounded by the cap rather than by the match count — which
    // is why the take() above happens before this and not after.
    final genomes = await Genome.db.find(
      session,
      where: (t) => t.id.inSet(hits.map((s) => s.genome!).toSet()),
    );
    final byId = {for (final g in genomes) g.id!: g};

    return hits.map((s) {
      final genome = byId[s.genome!];
      return SearchHitDto(
        kind: SearchHitKind.snpSet,
        id: s.id!,
        name: s.name,
        subtitle: s.description,
        genomeId: s.genome,
        category: genome?.category,
        context: genome?.name ?? '',
      );
    }).toList();
  }
}
