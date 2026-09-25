import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/sm_item.dart';

/// Server error message thrown by [SmItemsApi.upsert] when wpsApi (or CIP,
/// relayed through it) refuses the write - e.g. "W CIP jest tylko 12.4" for a
/// CIP quantity refusal, or a validation error. Shown to the operator as-is.
class SmItemApiError implements Exception {
  SmItemApiError(this.message, {this.code});
  final String message;

  /// wpsApi's stable error code, when it sent one - `session_expired`: CIP
  /// refused the operator's token (see CipSessionService).
  final String? code;
  @override
  String toString() => message;
}

/// Backs sm_items/sm_units (see wpsApi's src/smItems.js) - Materiały SM's
/// current stock. `upsert` always sends the *whole* item (item fields +
/// every unit); the server replaces that item's units wholesale on every
/// call - same contract as wps's own lib/smItemsApi.js.
class SmItemsApi {
  SmItemsApi(this._dio);
  final Dio _dio;

  Future<List<SmItem>> list() async {
    final res = await _dio.get<List<dynamic>>('/sm-items');
    return (res.data ?? []).map((e) => SmItem.fromJson(e as Map<String, dynamic>)).toList();
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

  /// [cip], when given, makes this write CIP-gated: wpsApi pushes
  /// `cip.operation` ("receipt" | "issue") for `cip.quantity` to CIP - using
  /// `cip.cipToken` (the operator's own CIP session, see AppSettings.authToken)
  /// - *before* touching our database, and refuses the whole write (throwing
  /// [SmItemApiError]) if CIP does. Omitted entirely, this behaves exactly as
  /// it always did - a plain save with no CIP involvement (e.g. a location/note
  /// edit, or when CIP_SYNC is off on the server).
  Future<SmItem> upsert(SmItem item, {CipWriteTask? cip}) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/sm-items/${Uri.encodeComponent(item.itemNo)}',
        data: {
          ...item.toJson(),
          if (cip != null) ...{'cipOperation': cip.operation, 'cipQuantity': cip.quantity},
        },
        options: cip == null ? null : Options(headers: {'X-Cip-Token': cip.cipToken}),
      );
      return SmItem.fromJson(res.data!);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['error'] as String? : null;
      final code = data is Map ? data['code'] as String? : null;
      throw message != null ? SmItemApiError(message, code: code) : e;
    }
  }

  Future<void> remove(String itemNo) {
    return _dio.delete('/sm-items/${Uri.encodeComponent(itemNo)}');
  }
}

final smItemsApiProvider = Provider<SmItemsApi>((ref) {
  return SmItemsApi(ref.watch(dioProvider));
});

/// A receive/issue's own delta, plus who's doing it - see [SmItemsApi.upsert].
class CipWriteTask {
  const CipWriteTask({required this.operation, required this.quantity, required this.cipToken});
  final String operation;
  final String quantity;
  final String cipToken;
}
