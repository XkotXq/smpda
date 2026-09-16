/// One row of Historia operacji SM - mirrors wpsapi's `sm_operations`
/// (see wpsApi's src/smOperations.js `rowToApi`).
class SmOperation {
  const SmOperation({
    required this.operation,
    required this.itemNo,
    required this.itemName,
    required this.quantity,
    this.id,
    this.unitId,
    this.location,
    this.productBatch,
    this.operator,
    this.time,
  });

  final String? id;

  /// "receipt" | "issue" | "labeling" - see schema.sql's
  /// sm_operations.operation CHECK.
  final String operation;
  final String itemNo;
  final String itemName;
  final String? unitId;
  final String quantity;
  final String? location;
  final String? productBatch;
  final String? operator;
  final String? time;

  factory SmOperation.fromJson(Map<String, dynamic> json) => SmOperation(
        id: json['id'] as String?,
        operation: json['operation'] as String,
        itemNo: json['itemNo'] as String,
        itemName: json['itemName'] as String? ?? '',
        unitId: json['unitId'] as String?,
        quantity: json['quantity'] as String? ?? '',
        location: json['location'] as String?,
        productBatch: json['productBatch'] as String?,
        operator: json['operator'] as String?,
        time: json['time'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'operation': operation,
        'itemNo': itemNo,
        'itemName': itemName,
        'unitId': unitId,
        'quantity': quantity,
        'location': location,
        'productBatch': productBatch,
        'operator': operator,
      };
}
