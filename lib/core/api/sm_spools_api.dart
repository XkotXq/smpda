import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// FRP that was received without a spool number - one row of
/// `GET /api/sm-spools/unlabeled` (see wpsApi's src/smSpools.js).
class FrpPending {
  const FrpPending({
    required this.itemNo,
    required this.itemName,
    required this.locationCode,
    required this.pendingQuantity,
  });

  final String itemNo;
  final String itemName;
  final String locationCode;

  /// How much of it still has no spool number.
  final String pendingQuantity;

  factory FrpPending.fromJson(Map<String, dynamic> json) => FrpPending(
    itemNo: json['itemNo'] as String,
    itemName: json['itemName'] as String? ?? '',
    locationCode: json['locationCode'] as String? ?? '',
    pendingQuantity: json['pendingQuantity'] as String? ?? '',
  );
}

/// The spool number [LabelResult]'s request asked for was taken meanwhile
/// (another device labeled first) - [next] is the one to use instead.
class SpoolNumberTaken implements Exception {
  SpoolNumberTaken(this.message, this.next);
  final String message;
  final String next;
  @override
  String toString() => message;
}

/// Server-side message of a failed call (wpsApi answers `{ "error": "..." }`,
/// already in Polish) - shown to the operator as-is.
class SpoolApiError implements Exception {
  SpoolApiError(this.message);
  final String message;
  @override
  String toString() => message;
}

class SmSpoolsApi {
  SmSpoolsApi(this._dio);
  final Dio _dio;

  Future<List<FrpPending>> unlabeled() async {
    final res = await _dio.get<List<dynamic>>('/sm-spools/unlabeled');
    return (res.data ?? []).map((e) => FrpPending.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// The number the next spool will get. Reserves nothing: asking twice
  /// returns the same number until a spool actually takes it.
  Future<String> next() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/sm-spools/next');
      return res.data!['unitId'] as String;
    } on DioException catch (e) {
      throw _asApiError(e);
    }
  }

  /// Turns [quantity] of the item's unnumbered stock into the spool [unitId]
  /// (the number [next] gave, already shown to the operator). Returns the
  /// number actually assigned. Throws [SpoolNumberTaken] when that number was
  /// taken in the meantime, [SpoolApiError] for anything else the server
  /// refused (e.g. more than is left to label).
  Future<String> label({
    required String itemNo,
    required String quantity,
    required String unitId,
    String? productBatch,
    String? operator,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/sm-spools/label',
        data: {
          'itemNo': itemNo,
          'quantity': quantity,
          'unitId': unitId,
          'productBatch': productBatch ?? '',
          'operator': operator,
        },
      );
      return res.data!['unitId'] as String;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 && data is Map && data['next'] is String) {
        throw SpoolNumberTaken(data['error'] as String? ?? '', data['next'] as String);
      }
      throw _asApiError(e);
    }
  }

  Exception _asApiError(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? data['error'] as String? : null;
    return message != null ? SpoolApiError(message) : e;
  }
}

final smSpoolsApiProvider = Provider<SmSpoolsApi>((ref) {
  return SmSpoolsApi(ref.watch(dioProvider));
});

/// FRP still waiting for spool numbers. autoDispose: re-read every time the
/// FRP module is opened, so it's never a stale list.
final frpPendingProvider = FutureProvider.autoDispose<List<FrpPending>>((ref) {
  return ref.watch(smSpoolsApiProvider).unlabeled();
});
