import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/sm_catalog_api.dart';
import '../../core/api/sm_items_api.dart';
import '../../core/api/models/sm_item.dart';

/// Current sm_items as last seen. A scan does NOT trust this: it re-reads the
/// scanned item from wpsApi (see ReceiveIssueController) so the stock shown
/// and issued against is the database's, then patches the result in here.
/// What's left of this cache is finding which item a scanned spool tag
/// belongs to, and the full list shown elsewhere.
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

  void replaceAll(List<SmItem> items) {
    state = AsyncData(items);
  }

  void removeLocal(String itemNo) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final item in current)
        if (item.itemNo != itemNo) item,
    ]);
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

final smItemsListProvider = AsyncNotifierProvider<SmItemsListNotifier, List<SmItem>>(SmItemsListNotifier.new);

/// sm_catalog, kept in memory and refreshed whenever it changes on the server.
/// wpsApi bumps a version counter on every catalog change; this asks for that
/// one number (every 30s while the app runs, and right before a scan needs the
/// catalog - see [refreshIfChanged]) and downloads the list only when the
/// number moved. So a receipt never pays for a full list download, and a
/// corrected name or per-spool flag reaches the PDA without a restart.
class SmCatalogNotifier extends AsyncNotifier<List<SmCatalogItem>> {
  int? _version;

  @override
  Future<List<SmCatalogItem>> build() async {
    final api = ref.watch(smCatalogApiProvider);
    _version = await api.version();
    final timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshIfChanged());
    ref.onDispose(timer.cancel);
    return api.list();
  }

  /// Downloads the list again when the server's version differs from the one
  /// this copy was read at. No connection: keeps the copy it has. A server
  /// that doesn't have the version endpoint yet (version always null) is
  /// reloaded every time, as before this existed.
  Future<void> refreshIfChanged() async {
    final api = ref.read(smCatalogApiProvider);
    final latest = await api.version();
    if (latest != null && latest == _version) return;
    if (latest == null && _version != null) return;
    try {
      final list = await api.list();
      if (!ref.mounted) return;
      _version = latest;
      state = AsyncData(list);
    } catch (_) {
      // Keep the copy that is already here.
    }
  }
}

final smCatalogListProvider = AsyncNotifierProvider<SmCatalogNotifier, List<SmCatalogItem>>(SmCatalogNotifier.new);
