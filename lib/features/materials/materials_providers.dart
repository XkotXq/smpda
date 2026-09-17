import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/sm_catalog_api.dart';
import '../../core/api/sm_items_api.dart';
import '../../core/api/models/sm_item.dart';

/// Current sm_items, fetched once and cached - every scan resolves against
/// this in memory rather than hitting wpsApi per scan (a PDA operator can
/// scan several codes a second on a good run).
///
/// After a submit, ReceiveIssueController calls [SmItemsListNotifier.upsertLocal]
/// instead of invalidating and refetching: a full refetch's request/response
/// round trip leaves a window where `.value` reads null (Riverpod drops the
/// old data as soon as a provider goes back to loading) - wide enough that
/// scanning the very next item, right after confirming the previous one,
/// would come back "unknown" even though it's genuinely in stock. Patching
/// the cached list in place keeps every other row exactly as the server
/// last reported it (same "not live" tradeoff wps's own Materiały SM
/// already accepts, see AGENTS.md), just without that gap.
class SmItemsListNotifier extends AsyncNotifier<List<SmItem>> {
  @override
  Future<List<SmItem>> build() {
    return ref.watch(smItemsApiProvider).list();
  }

  void upsertLocal(SmItem item) {
    final current = state.value;
    if (current == null) return;
    final next = [
      for (final existing in current)
        if (existing.itemNo == item.itemNo) item else existing,
    ];
    if (!next.any((i) => i.itemNo == item.itemNo)) next.add(item);
    state = AsyncData(next);
  }
}

final smItemsListProvider = AsyncNotifierProvider<SmItemsListNotifier, List<SmItem>>(
  SmItemsListNotifier.new,
);

/// sm_catalog, same caching reasoning - only consulted for a receipt whose
/// item number isn't in current stock yet (a genuinely new item).
final smCatalogListProvider = FutureProvider<List<SmCatalogItem>>((ref) {
  return ref.watch(smCatalogApiProvider).list();
});
