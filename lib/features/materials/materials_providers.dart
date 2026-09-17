import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/sm_catalog_api.dart';
import '../../core/api/sm_items_api.dart';
import '../../core/api/models/sm_item.dart';

/// Current sm_items, fetched once and cached - every scan resolves against
/// this in memory rather than hitting wpsApi per scan (a PDA operator can
/// scan several codes a second on a good run). `ref.invalidate(
/// smItemsListProvider)` after a submit (ReceiveIssueController) refetches
/// it, same "not live" tradeoff wps's own Materiały SM already accepts
/// (see AGENTS.md).
final smItemsListProvider = FutureProvider<List<SmItem>>((ref) {
  return ref.watch(smItemsApiProvider).list();
});

/// sm_catalog, same caching reasoning - only consulted for a receipt whose
/// item number isn't in current stock yet (a genuinely new item).
final smCatalogListProvider = FutureProvider<List<SmCatalogItem>>((ref) {
  return ref.watch(smCatalogApiProvider).list();
});
