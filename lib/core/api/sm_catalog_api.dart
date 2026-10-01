import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// One sm_catalog row - reference material list (see wpsApi's
/// src/smCatalog.js). Used to resolve/validate an item number scanned or
/// typed on the PDA, same idea as wps's own lib/smCatalogApi.js.
class SmCatalogItem {
  const SmCatalogItem({required this.itemNo, required this.itemName, required this.individualUnits, required this.unit});

  final String itemNo;
  final String itemName;
  final bool individualUnits;

  /// The catalog's own unit of measure for this material (e.g. "kg") - see
  /// wpsApi's sm_catalog.unit. Used to label a real issued quantity, unlike
  /// order_items.unit (always "szt.", the order's own piece-count) - see
  /// features/orders/order_detail_screen.dart.
  final String unit;

  factory SmCatalogItem.fromJson(Map<String, dynamic> json) => SmCatalogItem(
    itemNo: json['itemNo'] as String,
    itemName: json['itemName'] as String? ?? '',
    individualUnits: json['individualUnits'] as bool? ?? false,
    unit: json['unit'] as String? ?? '',
  );
}

class SmCatalogApi {
  SmCatalogApi(this._dio);
  final Dio _dio;

  Future<List<SmCatalogItem>> list() async {
    final res = await _dio.get<List<dynamic>>('/sm-catalog');
    return (res.data ?? []).map((e) => SmCatalogItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// One entry, read fresh from the server: the material's name and whether it
  /// is split into spools. null when the catalog doesn't know that item number.
  Future<SmCatalogItem?> get(String itemNo) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/sm-catalog/${Uri.encodeComponent(itemNo)}');
      final data = res.data;
      return data == null ? null : SmCatalogItem.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

final smCatalogApiProvider = Provider<SmCatalogApi>((ref) {
  return SmCatalogApi(ref.watch(dioProvider));
});
