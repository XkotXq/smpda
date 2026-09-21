import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/sm_item.dart';

/// Backs sm_items/sm_units (see wpsApi's src/smItems.js) - Materiały SM's
/// current stock. `upsert` always sends the *whole* item (item fields +
/// every unit); the server replaces that item's units wholesale on every
/// call - same contract as wps's own lib/smItemsApi.js.
class SmItemsApi {
  SmItemsApi(this._dio);
  final Dio _dio;

  Future<List<SmItem>> list() async {
    final res = await _dio.get<List<dynamic>>('/sm-items');
    return (res.data ?? [])
        .map((e) => SmItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The item as the database has it right now, or null if there's no such
  /// item - what a scan reads so the stock shown is never a stale copy.
  Future<SmItem?> get(String itemNo) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/sm-items/${Uri.encodeComponent(itemNo)}');
      return SmItem.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<SmItem> upsert(SmItem item) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/sm-items/${Uri.encodeComponent(item.itemNo)}',
      data: item.toJson(),
    );
    return SmItem.fromJson(res.data!);
  }

  Future<void> remove(String itemNo) {
    return _dio.delete('/sm-items/${Uri.encodeComponent(itemNo)}');
  }
}

final smItemsApiProvider = Provider<SmItemsApi>((ref) {
  return SmItemsApi(ref.watch(dioProvider));
});
