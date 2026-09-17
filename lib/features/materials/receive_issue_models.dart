/// Which of the two workflows is active - switching clears the queue
/// (see ReceiveIssueController.setMode) rather than trying to support a
/// mixed batch, which would need every downstream piece (submit, the
/// queue list's own UI) to branch on top of the per-line branching it
/// already does.
enum FlowMode { receive, issue }

/// Mirrors wps's own row "kind" discriminator (see AGENTS.md's Materiały
/// SM section) - a unit is always issued in full (no partial concept for
/// a single physical object), aggregate/pending can both be issued
/// partially.
enum IssueKind { unit, aggregate, pending }

sealed class QueueLine {
  QueueLine({required this.itemNo, required this.itemName});

  final String itemNo;
  final String itemName;
}

/// A queued receipt - [unitId] blank means "Brak" (pendingQuantity, no
/// physical spool number assigned yet), same as wps's own single-receipt
/// form. Only meaningful when [trackedIndividually]; ignored for an
/// aggregate item.
class ReceiveLine extends QueueLine {
  ReceiveLine({
    required super.itemNo,
    required super.itemName,
    required this.trackedIndividually,
    this.quantity = '',
    this.unitId = '',
  });

  final bool trackedIndividually;
  String quantity;
  String unitId;
}

/// A queued issue. [kind] decides what [unitId]/[available]/[quantity]
/// mean:
/// - unit: [unitId] is that spool's own tag, [quantity] always equals
///   [available] (no partial unit issue) and isn't user-editable.
/// - aggregate/pending: [unitId] is null, [quantity] starts blank and
///   must be typed, capped at [available].
class IssueLine extends QueueLine {
  IssueLine({
    required super.itemNo,
    required super.itemName,
    required this.kind,
    required this.available,
    this.unitId,
    String? initialQuantity,
  }) : quantity = initialQuantity ?? (kind == IssueKind.unit ? available : '');

  final IssueKind kind;
  final String? unitId;
  final String available;
  String quantity;
}

/// Returned by ReceiveIssueController.scan - the screen reacts to
/// [NeedsPick] by opening a bottom sheet (see IssuePickerSheet) instead of
/// silently guessing which unit/pending remainder a bare item-number scan
/// meant to issue.
sealed class ScanOutcome {}

class ScanAdded extends ScanOutcome {}

class ScanAlreadyQueued extends ScanOutcome {}

class ScanNeedsPick extends ScanOutcome {
  ScanNeedsPick(this.itemNo, this.itemName, this.units, this.pendingQuantity);
  final String itemNo;
  final String itemName;
  final List<({String unitId, String quantity})> units;
  final String? pendingQuantity;
}

/// Catalog knows this item number but nothing is in stock yet - fine for
/// a receipt (it's exactly how a first-ever receipt is expected to work),
/// meaningless for an issue (there's nothing to issue).
class ScanNotIssuable extends ScanOutcome {}

class ScanUnknown extends ScanOutcome {}
