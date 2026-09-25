import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/sm_operation.dart';

/// Backs sm_operations - Historia operacji SM (see wpsApi's
/// src/smOperations.js). Same shape as wps's own lib/smItemsApi.js
/// `smOperationsApi`.
class SmOperationsApi {
  SmOperationsApi(this._dio);
  final Dio _dio;

  /// [operator] (employee number) and [operation] ('issue' | 'receipt' |
  /// 'labeling') narrow the list on the server - e.g. "my issues".
  Future<({List<SmOperation> rows, int total})> list({
    int? limit,
    int? offset,
    String? operator,
    String? operation,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/sm-operations',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (operator != null) 'operator': operator,
        if (operation != null) 'operation': operation,
      },
    );
    final rows = (res.data?['rows'] as List<dynamic>? ?? [])
        .map((e) => SmOperation.fromJson(e as Map<String, dynamic>))
        .toList();
    return (rows: rows, total: res.data?['total'] as int? ?? rows.length);
  }

  Future<List<SmOperation>> create(List<SmOperation> entries) async {
    final res = await _dio.post<List<dynamic>>(
      '/sm-operations',
      data: {'entries': entries.map((e) => e.toJson()).toList()},
    );
    return (res.data ?? []).map((e) => SmOperation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// One item's full history, oldest first - powers a "stan w czasie" style
  /// view the same way SmMaterialStockChart does on the web dashboard.
  Future<List<SmOperation>> history(String itemNo) async {
    final res = await _dio.get<List<dynamic>>('/sm-operations/item/${Uri.encodeComponent(itemNo)}');
    return (res.data ?? []).map((e) => SmOperation.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final smOperationsApiProvider = Provider<SmOperationsApi>((ref) {
  return SmOperationsApi(ref.watch(dioProvider));
});
