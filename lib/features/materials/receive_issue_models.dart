/// Which of the two workflows is active - switching mode clears whatever
/// operation was in progress (see ReceiveIssueController.setMode).
enum FlowMode { receive, issue }

/// Mirrors wps's own row "kind" discriminator (see AGENTS.md's Materiały
/// SM section) - a unit is always issued in full (no partial concept for
/// a single physical object), aggregate/pending can both be issued
/// partially.
enum IssueKind { unit, aggregate, pending }

/// The one in-progress receive/issue operation - a scan replaces whatever
/// was here before (there's no queue: scan, fill in the quantity, confirm,
/// scan the next one). See ReceiveIssueScreen for why: an operator's hands
/// are on the scanner trigger and a PDA keypad, not building up a batch to
/// review later.
sealed class CurrentOperation {
  CurrentOperation({required this.itemNo, required this.itemName, required this.locationCode});

  final String itemNo;
  final String itemName;

  /// sm_items.locationCode - "" for a brand-new item that only exists in
  /// the catalog so far (nothing received yet, so nowhere to issue from
  /// either - that case never reaches IssueOperation).
  final String locationCode;

  /// The typed quantity - each subclass's own field satisfies this.
  String get quantity;
}

/// [unitId] blank means "Brak" (pendingQuantity, no physical spool number
/// assigned yet), same as wps's own single-receipt form. Only meaningful
/// when [trackedIndividually]; ignored for an aggregate item.
class ReceiveOperation extends CurrentOperation {
  ReceiveOperation({
    required super.itemNo,
    required super.itemName,
    required super.locationCode,
    required this.trackedIndividually,
    this.quantity = '',
    this.unitId = '',
  }) : location = locationCode;

  final bool trackedIndividually;
  @override
  String quantity;
  String unitId;

  /// Editable location the item is received to - starts as its current
  /// location (blank for a brand-new catalog item) and, when non-blank,
  /// replaces sm_items.locationCode on submit.
  String location;
}

/// [kind] decides what [unitId]/[available]/[quantity] mean:
/// - unit: [unitId] is that spool's own tag, [quantity] always equals
///   [available] (no partial unit issue) and isn't user-editable.
/// - aggregate/pending: [unitId] is null, [quantity] starts blank and
///   must be typed, capped at [available].
class IssueOperation extends CurrentOperation {
  IssueOperation({
    required super.itemNo,
    required super.itemName,
    required super.locationCode,
    required this.kind,
    required this.available,
    this.unitId,
  }) : quantity = kind == IssueKind.unit ? available : '';

  final IssueKind kind;
  final String? unitId;
  final String available;
  @override
  String quantity;
}

/// Returned by ReceiveIssueController.scan - the screen reacts to
/// [ScanNeedsPick] by opening a bottom sheet instead of silently guessing
/// which unit/pending remainder a bare item-number scan meant to issue.
sealed class ScanOutcome {}

class ScanStarted extends ScanOutcome {}

class ScanNeedsPick extends ScanOutcome {
  ScanNeedsPick(this.itemNo, this.itemName, this.locationCode, this.units, this.pendingQuantity);
  final String itemNo;
  final String itemName;
  final String locationCode;
  final List<({String unitId, String quantity})> units;
  final String? pendingQuantity;
}

/// Catalog knows this item number but nothing is in stock yet - fine for
/// a receipt (it's exactly how a first-ever receipt is expected to work),
/// meaningless for an issue (there's nothing to issue).
class ScanNotIssuable extends ScanOutcome {}

class ScanUnknown extends ScanOutcome {}
