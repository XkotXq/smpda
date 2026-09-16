import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// One sm_catalog row - reference material list (see wpsApi's
/// src/smCatalog.js). Used to resolve/validate an item number scanned or
/// typed on the PDA, same idea as wps's own lib/smCatalogApi.js.
class SmCatalogItem {
  const SmCatalogItem({
    required this.itemNo,
    required this.itemName,
    required this.individualUnits,
  });

  final String itemNo;
  final String itemName;
  final bool individualUnits;

  factory SmCatalogItem.fromJson(Map<String, dynamic> json) =>
      SmCatalogItem(
        itemNo: json['itemNo'] as String,
        itemName: json['itemName'] as String? ?? '',
        individualUnits: json['individualUnits'] as bool? ?? false,
      );
}

class SmCatalogApi {
  SmCatalogApi(this._dio);
  final Dio _dio;

  Future<List<SmCatalogItem>> list() async {
    final res = await _dio.get<List<dynamic>>('/sm-catalog');
    return (res.data ?? [])
        .map((e) => SmCatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final smCatalogApiProvider = Provider<SmCatalogApi>((ref) {
  return SmCatalogApi(ref.watch(dioProvider));
});
