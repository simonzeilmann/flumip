import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/endpoints/flumip_endpoint.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/search_service.dart';
import 'package:serverpod/serverpod.dart';

/// Finding a project, a genome or an SNP set by typing part of its name.
///
/// Extends [FlumipEndpoint], so it is gated exactly as the three list endpoints it
/// draws on — and it reuses their visibility rules rather than restating them; see
/// [SearchService] for how the SQL and Dart predicates divide.
class SearchEndpoint extends FlumipEndpoint {
  SearchService get searchService => sl<SearchService>();

  /// Every project, genome and SNP set matching [query] that this caller may see.
  ///
  /// Grouped by the client, not here: the order is projects, then genomes, then
  /// SNP sets, each capped at [SearchService.hitsPerKind]. A query shorter than
  /// [SearchService.minQueryLength] answers with nothing rather than everything.
  ///
  /// ⚠️ **The query is not logged, unlike every other endpoint in this package.**
  /// This one is called on a debounce tick while somebody types, and its only
  /// argument is free text a user typed — a line per query would be both the
  /// noisiest and the least appropriate entry in the log. Failures are logged;
  /// queries are not. So silence here is the healthy state.
  ///
  /// \param session The current session.
  /// \param query What the user typed.
  Future<List<SearchHitDto>> search(Session session, String query) async {
    try {
      return await searchService.search(session, query);
    } catch (e) {
      session.log('Search failed', level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}
