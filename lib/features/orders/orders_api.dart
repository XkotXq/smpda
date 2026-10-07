import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

/// One issue scan against an order item - see wpsApi's order_items_progress
/// (issued_entries), orders.js's own orderRowToApi (issuedEntries).
class IssuedEntry {
  const IssuedEntry({this.unitId, required this.quantity});

  factory IssuedEntry.fromJson(Map<String, dynamic> json) =>
      IssuedEntry(unitId: json['unitId'] as String?, quantity: (json['quantity'] ?? '0').toString());

  final String? unitId;
  final String quantity;
}

/// One line of a transport order, with how much of it has been issued so
/// far - see wpsapi's schema.sql `order_items_progress` view and
/// orders.js's own orderRowToApi. Whether it counts as done is the caller's
/// comparison (see [isFulfilled]) rather than a boolean from the server,
/// same "display concern, not stored" reasoning as that view's own comment.
class OrderItem {
  const OrderItem({
    required this.itemNo,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.issuedQuantity,
    this.issueCount = 0,
    required this.issuedUnit,
    required this.category,
    required this.catalogUnit,
    required this.issuedEntries,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    itemNo: json['itemNo'] as String,
    itemName: json['itemName'] as String? ?? '',
    quantity: json['quantity'] as String? ?? '0',
    unit: json['unit'] as String? ?? '',
    issuedQuantity: json['issuedQuantity'] as String? ?? '0',
    issueCount: (json['issueCount'] as num?)?.toInt() ?? 0,
    issuedUnit: json['issuedUnit'] as String? ?? '',
    category: json['category'] as String? ?? '',
    catalogUnit: json['catalogUnit'] as String? ?? '',
    issuedEntries: (json['issuedEntries'] as List? ?? const [])
        .map((e) => IssuedEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final String itemNo;
  final String itemName;
  final String quantity;
  final String unit;
  final String issuedQuantity;

  /// How many times something was issued against this line - wpsApi's own
  /// issue_count, which is now the signal for "done" everywhere rather than
  /// each client inferring it (this screen inferred it from issuedEntries).
  final int issueCount;

  /// What to label [issuedQuantity] with - the catalog's own unit (e.g.
  /// "kg"), or "szt." for FRP (order_items_progress counts scans, not a
  /// summed length, for that category - see its own comment in
  /// schema.sql). Never [unit] above, which is always "szt." regardless of
  /// category and would mislabel a real, summed weight.
  final String issuedUnit;

  /// "FRP" (sm_catalog.category), "" for everything else - see
  /// order_items_progress's own comment.
  final String category;

  /// The catalog's own real unit (e.g. "KM" for FRP), not [issuedUnit]'s
  /// own "szt." drum-count label.
  final String catalogUnit;

  /// Every individual issue scan against this line, oldest first - [] when
  /// nothing's been issued yet.
  final List<IssuedEntry> issuedEntries;

  /// Done once **anything** has been issued against this line - not once
  /// the issued amount reaches [quantity].
  ///
  /// It compared the two numbers until 2026-10-02, which was wrong here:
  /// [quantity] is always a piece count ("10 szt.") while [issuedQuantity]
  /// is the catalog's own summed amount in the catalog's own unit, so a line
  /// ordered as 10 pieces demanded 10 **kg** before it would tick. On this
  /// screen the line is a checklist entry - "I have dealt with this
  /// material" - and one issue is what deals with it; a second drum of the
  /// same material is a second issue against a line already ticked.
  ///
  /// [issuedEntries] is the signal rather than a quantity, because it is
  /// unit-independent: one scan is one issue whatever it weighed.
  bool get isFulfilled => issueCount > 0;

  /// The amount to actually show next to "Wydano" - FRP's own
  /// issuedQuantity/issuedUnit is a drum COUNT ("2 szt.", correct for
  /// [isFulfilled]'s piece-count math, since a FRP order is placed in
  /// pieces, not length) - not what the floor wants to see at a glance for
  /// cable though, so this sums issuedEntries' own quantity (always a
  /// length, in catalogUnit/km) instead, same as before FRP got its own
  /// counted issuedQuantity. Everything else keeps issuedQuantity as-is.
  String get displayIssuedQuantity {
    if (category == 'FRP' && issuedEntries.isNotEmpty) {
      final total = issuedEntries.fold<double>(0, (sum, e) => sum + (double.tryParse(e.quantity) ?? 0));
      return total.toString();
    }
    return issuedQuantity;
  }

  /// The unit [displayIssuedQuantity] is in - catalogUnit (lowercased, e.g.
  /// "km") for FRP, issuedUnit for everything else.
  String get displayIssuedUnit => category == 'FRP' ? catalogUnit.toLowerCase() : issuedUnit;
}

/// One transport order - same JSON shape as wps's/smVendor's own orders
/// clients (wpsapi's orders.js), plus the item list this one actually
/// needs (smVendor's own card list only shows a count - see that repo's
/// TransportOrder.itemCount).
class TransportOrder {
  const TransportOrder({
    required this.id,
    required this.orderNo,
    required this.type,
    required this.status,
    required this.to,
    required this.employeeNo,
    required this.details,
    required this.items,
  });

  factory TransportOrder.fromJson(Map<String, dynamic> json) => TransportOrder(
    id: json['id'] as String,
    orderNo: json['orderNo'] as String? ?? '',
    type: json['type'] as String? ?? '',
    status: json['status'] as String? ?? 'new',
    to: json['to'] as String?,
    employeeNo: json['employeeNo'] as String? ?? '',
    details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
    items: (json['items'] as List? ?? const []).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
  );

  final String id;
  final String orderNo;
  final String type;
  final String status;
  final String? to;
  final String employeeNo;
  final Map<String, dynamic> details;
  final List<OrderItem> items;

  String? get productionOrderNo => details['productionOrderNo'] as String?;
}

/// GET /orders (+ one by id) - client-side, same direct-to-wpsapi pattern
/// as every other *_api.dart here, using the shared bearer token
/// (dioProvider already attaches it - see api_client.dart).
class OrdersApi {
  OrdersApi(this._dio);
  final Dio _dio;

  Future<List<TransportOrder>> list(String scope) async {
    final res = await _dio.get<List<dynamic>>('/orders', queryParameters: {'scope': scope});
    return (res.data ?? []).map((e) => TransportOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TransportOrder> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/orders/$id');
    return TransportOrder.fromJson(res.data!);
  }
}

final ordersApiProvider = Provider<OrdersApi>((ref) => OrdersApi(ref.watch(dioProvider)));
