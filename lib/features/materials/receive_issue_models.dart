import '../../core/utils/quantity.dart';

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

/// Where a receipt goes when the operator leaves the location empty - shown as
/// the field's placeholder, so it is only typed when the goods go elsewhere.
const defaultReceiveLocation = 'MT';

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
    this.productBatch,
    this.loading = false,
  }) : location = locationCode == defaultReceiveLocation ? '' : locationCode;

  final bool trackedIndividually;
  @override
  String quantity;
  String unitId;

  /// Batch number read from a multi-field label (see ScannedCode), if any.
  final String? productBatch;

  /// Only the scanned item number is known so far - name, location and whether
  /// it is tracked per spool are still being read from the server (see
  /// ReceiveIssueController.startReceive / resolveReceive).
  final bool loading;

  /// Editable location the item is received to - starts as its current
  /// location (blank for a brand-new catalog item) and, when non-blank,
  /// replaces sm_items.locationCode on submit.
  String location;
}

/// [kind] decides what [unitId]/[available]/[quantity] mean:
/// - unit: [unitId] is that spool's own tag, [quantity] always equals
///   [available] (no partial unit issue) and isn't user-editable.
/// - aggregate: [unitId] is null, [quantity] starts blank and
///   must be typed, capped at [available].
/// - pending (unmarked stock): [unitId] is null, [quantity] starts blank
///   like an aggregate and must be typed, capped at [available].
class IssueOperation extends CurrentOperation {
  IssueOperation({
    required super.itemNo,
    required super.itemName,
    required super.locationCode,
    required this.kind,
    required this.available,
    this.unitId,
    this.productBatch,
  }) : quantity = kind == IssueKind.unit ? trimQuantity(available) : '';

  final IssueKind kind;
  final String? unitId;
  final String available;

  /// Batch from the scanned label (see ScannedCode), or - for a spool picked
  /// by its tag - the batch it was received with. Goes into the history.
  final String? productBatch;
  @override
  String quantity;
}

/// Returned by ReceiveIssueController.scan - the screen reacts to
/// [ScanNeedsPick] by opening the spool picker (the details are in
/// ReceiveIssueState.pick) instead of silently guessing which spool/
/// unmarked remainder a bare item-number scan meant to issue.
sealed class ScanOutcome {}

class ScanStarted extends ScanOutcome {}

class ScanNeedsPick extends ScanOutcome {}

/// What the spool picker screen lists: an item issued from numbered spools
/// (plus, optionally, its still-unmarked remainder) - set by
/// ReceiveIssueController.scan, cleared once a spool is issued or the
/// operator backs out.
class SpoolPick {
  SpoolPick({
    required this.itemNo,
    required this.itemName,
    required this.locationCode,
    required this.units,
    required this.pendingQuantity,
    this.productBatch,
  });
  final String itemNo;
  final String itemName;
  final String locationCode;
  final List<({String unitId, String quantity, String? productBatch})> units;
  final String? pendingQuantity;

  /// Batch of the scanned label, if it carried one.
  final String? productBatch;
}

/// Catalog knows this item number but nothing is in stock yet - fine for
/// a receipt (it's exactly how a first-ever receipt is expected to work),
/// meaningless for an issue (there's nothing to issue).
class ScanNotIssuable extends ScanOutcome {}

class ScanUnknown extends ScanOutcome {}
