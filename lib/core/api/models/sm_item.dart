import 'sm_unit.dart';

/// Materiały SM current stock row - mirrors wpsapi's `sm_items` (+ its
/// `sm_units`) as returned by `GET /api/sm-items` (see wpsApi's
/// src/smItems.js `rowToApi` / wps's own lib/smItemsApi.js).
///
/// Same two shapes as the web app: an aggregate item carries [totalQuantity]
/// and no units; a [trackedIndividually] item carries [units] (and,
/// optionally, [pendingQuantity] - stock already received but not yet split
/// into numbered units, see wps's AGENTS.md "Materiały SM" section).
class SmItem {
  const SmItem({
    required this.itemNo,
    required this.itemName,
    required this.locationCode,
    required this.note,
    required this.trackedIndividually,
    this.totalQuantity,
    this.units = const [],
    this.pendingQuantity,
  });

  final String itemNo;
  final String itemName;
  final String locationCode;
  final String note;
  final bool trackedIndividually;
  final String? totalQuantity;
  final List<SmUnit> units;
  final String? pendingQuantity;

  bool get hasPendingQuantity =>
      pendingQuantity != null && (double.tryParse(pendingQuantity!) ?? 0) > 0;

  factory SmItem.fromJson(Map<String, dynamic> json) => SmItem(
        itemNo: json['itemNo'] as String,
        itemName: json['itemName'] as String? ?? '',
        locationCode: json['locationCode'] as String? ?? '',
        note: json['note'] as String? ?? '-',
        trackedIndividually: json['trackedIndividually'] as bool? ?? false,
        totalQuantity: json['totalQuantity'] as String?,
        units: (json['units'] as List<dynamic>? ?? [])
            .map((u) => SmUnit.fromJson(u as Map<String, dynamic>))
            .toList(),
        pendingQuantity: json['pendingQuantity'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'itemNo': itemNo,
        'itemName': itemName,
        'locationCode': locationCode,
        'note': note,
        'trackedIndividually': trackedIndividually,
        if (!trackedIndividually) 'totalQuantity': totalQuantity ?? '0',
        if (trackedIndividually) 'units': units.map((u) => u.toJson()).toList(),
        if (trackedIndividually && pendingQuantity != null)
          'pendingQuantity': pendingQuantity,
      };
}
