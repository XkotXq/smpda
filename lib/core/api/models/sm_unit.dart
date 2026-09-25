/// One physical labeled unit (spool/bigbag/thread/other) of a tracked-
/// individually item - mirrors wpsapi's `sm_units` row (see wpsApi's
/// src/smItems.js `rowToApi`).
class SmUnit {
  const SmUnit({
    required this.id,
    required this.unitId,
    required this.quantity,
    this.productBatch,
    this.note,
    this.cipStatus = 'match',
  });

  final String id;
  final String unitId;
  final String quantity;
  final String? productBatch;
  final String? note;

  /// "match" | "mismatch" - see schema.sql's sm_units.cip_status CHECK.
  final String cipStatus;

  factory SmUnit.fromJson(Map<String, dynamic> json) => SmUnit(
    id: json['id'] as String,
    unitId: json['unitId'] as String? ?? '',
    quantity: json['quantity'] as String? ?? '',
    productBatch: json['productBatch'] as String?,
    note: json['note'] as String?,
    cipStatus: json['cipStatus'] as String? ?? 'match',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'unitId': unitId,
    'quantity': quantity,
    'productBatch': productBatch,
    'note': note,
    'cipStatus': cipStatus,
  };
}
