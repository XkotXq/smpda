import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/models/sm_item.dart';
import '../../core/api/sm_catalog_api.dart';
import '../../core/api/models/sm_operation.dart';
import '../../core/api/models/sm_unit.dart';
import '../../core/api/sm_items_api.dart';
import '../../core/api/sm_operations_api.dart';
import '../../core/session/session_providers.dart';
import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';
import 'materials_providers.dart';
import 'receive_issue_models.dart';
import 'scanned_code.dart';

class ReceiveIssueState {
  const ReceiveIssueState({this.mode = FlowMode.receive, this.current, this.pick, this.submitting = false, this.error});

  final FlowMode mode;
  final CurrentOperation? current;
  final SpoolPick? pick;
  final bool submitting;
  final String? error;

  ReceiveIssueState copyWith({
    CurrentOperation? current,
    bool clearCurrent = false,
    SpoolPick? pick,
    bool clearPick = false,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) {
    return ReceiveIssueState(
      mode: mode,
      current: clearCurrent ? null : (current ?? this.current),
      pick: clearPick ? null : (pick ?? this.pick),
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the one-operation-at-a-time flow: scan -> the item's details and
/// a quantity field appear -> confirm -> the operation is saved right away
/// and the screen is ready for the next scan. See receive_issue_models.dart
/// for the CurrentOperation/ScanOutcome types this returns.
class ReceiveIssueController extends Notifier<ReceiveIssueState> {
  @override
  ReceiveIssueState build() => const ReceiveIssueState();

  void setMode(FlowMode mode) {
    if (mode == state.mode) return;
    state = ReceiveIssueState(mode: mode);
  }

  /// The item straight from wpsApi (null: not in stock), also patched into
  /// the cached list so the rest of the app sees the same numbers. Every scan
  /// and every submit goes through this - never the cache alone - so the
  /// stock on screen is the database's at that moment.
  Future<SmItem?> _fetchItem(String itemNo) async {
    final item = await ref.read(smItemsApiProvider).get(itemNo);
    final cache = ref.read(smItemsListProvider.notifier);
    if (item == null) {
      cache.removeLocal(itemNo);
    } else {
      cache.upsertLocal(item);
    }
    return item;
  }

  /// Which cached item holds a spool with this tag (the scan may be a spool's
  /// own tag rather than an item number).
  SmItem? _cachedItemWithUnit(ScannedCode scanned) {
    for (final item in ref.read(smItemsListProvider).value ?? const <SmItem>[]) {
      if (item.units.any((u) => u.unitId == scanned.raw || u.unitId == scanned.itemNo)) return item;
    }
    return null;
  }

  /// A submit re-reads the item first (the operator may have taken a while
  /// to type the quantity) - stop if what they were about to issue is gone.
  void _checkStillAvailable(SmItem item, IssueOperation op, double qty) {
    switch (op.kind) {
      case IssueKind.unit:
        if (!item.units.any((u) => u.unitId == op.unitId)) throw t.operations.errorUnitGone;
      case IssueKind.aggregate:
        if (qty > (parseQuantity(item.totalQuantity ?? '0') ?? 0)) {
          throw t.operations.errorNotEnough(available: trimQuantity(item.totalQuantity ?? '0'));
        }
      case IssueKind.pending:
        if (qty > (parseQuantity(item.pendingQuantity ?? '0') ?? 0)) {
          throw t.operations.errorNotEnough(available: trimQuantity(item.pendingQuantity ?? '0'));
        }
    }
  }

  static String? _nonEmpty(String? value) => value == null || value.trim().isEmpty ? null : value;

  /// Wydanie: reads the item from the server, then opens the operation (or the
  /// spool picker). Throws (network/API error) rather than guessing - the
  /// screen shows it. Przyjęcie goes through [startReceive]/[resolveReceive].
  Future<ScanOutcome> scan(String rawCode) async {
    final code = ScannedCode.parse(rawCode);
    if (code.raw.isEmpty) return ScanUnknown();
    return _scanForIssue(code);
  }

  /// Przyjęcie, step 1: opens the operation at once with just the scanned item
  /// number (and batch) - the screen shows it while [resolveReceive] fetches
  /// the name.
  ScanOutcome startReceive(String rawCode) {
    final scanned = ScannedCode.parse(rawCode);
    if (scanned.itemNo.isEmpty) return ScanUnknown();
    _setCurrent(
      ReceiveOperation(
        itemNo: scanned.itemNo,
        itemName: '',
        locationCode: '',
        trackedIndividually: false,
        productBatch: scanned.batch,
        loading: true,
      ),
    );
    return ScanStarted();
  }

  /// Przyjęcie, step 2: fills in what [startReceive] left open - name,
  /// location, per-spool tracking - from the server (stock first, then the
  /// catalog). Whatever the operator typed meanwhile (quantity, location, spool
  /// number) is kept. ScanUnknown: the item is nowhere. Throws on a network/API
  /// error.
  Future<ScanOutcome> resolveReceive() async {
    final pending = state.current;
    if (pending is! ReceiveOperation || !pending.loading) return ScanStarted();

    final resolved = await _lookupReceive(pending.itemNo, pending.productBatch);
    // Cancelled or replaced while waiting - nothing to fill in any more.
    if (!identical(state.current, pending)) return ScanStarted();
    if (resolved == null) return ScanUnknown();

    resolved
      ..quantity = pending.quantity
      ..unitId = pending.unitId;
    if (pending.location.trim().isNotEmpty) resolved.location = pending.location;
    state = state.copyWith(current: resolved);
    return ScanStarted();
  }

  Future<ScanOutcome> _scanForIssue(ScannedCode scanned) async {
    final code = scanned.itemNo;
    final tagOwner = _cachedItemWithUnit(scanned);
    var item = await _fetchItem(tagOwner?.itemNo ?? code);
    if (item == null && tagOwner == null) {
      // Not an item number, and no cached spool has this tag - it may have
      // been received since the cache was loaded, so look at the whole list.
      final all = await ref.read(smItemsApiProvider).list();
      ref.read(smItemsListProvider.notifier).replaceAll(all);
      item = _cachedItemWithUnit(scanned);
    }
    if (item == null) return ScanUnknown();

    for (final unit in item.units) {
      if (unit.unitId != scanned.raw && unit.unitId != code) continue;
      _setCurrent(
        IssueOperation(
          itemNo: item.itemNo,
          itemName: item.itemName,
          locationCode: item.locationCode,
          kind: IssueKind.unit,
          available: unit.quantity,
          unitId: unit.unitId,
          productBatch: scanned.batch ?? _nonEmpty(unit.productBatch),
        ),
      );
      return ScanStarted();
    }

    if (!item.trackedIndividually) {
      final qty = parseQuantity(item.totalQuantity ?? '0') ?? 0;
      if (qty <= 0) return ScanNotIssuable();
      _setCurrent(
        IssueOperation(
          itemNo: item.itemNo,
          itemName: item.itemName,
          locationCode: item.locationCode,
          kind: IssueKind.aggregate,
          available: item.totalQuantity ?? '0',
          productBatch: scanned.batch,
        ),
      );
      return ScanStarted();
    }

    final leaves = <({IssueKind kind, String? unitId, String quantity})>[
      for (final unit in item.units) (kind: IssueKind.unit, unitId: unit.unitId, quantity: unit.quantity),
      if (item.hasPendingQuantity) (kind: IssueKind.pending, unitId: null, quantity: item.pendingQuantity!),
    ];
    if (leaves.isEmpty) return ScanNotIssuable();

    // Nothing but the unmarked remainder: no spool to choose, straight to
    // typing how much of it to issue.
    if (item.units.isEmpty) {
      _setCurrent(
        IssueOperation(
          itemNo: item.itemNo,
          itemName: item.itemName,
          locationCode: item.locationCode,
          kind: IssueKind.pending,
          available: item.pendingQuantity!,
          productBatch: scanned.batch,
        ),
      );
      return ScanStarted();
    }

    state = state.copyWith(
      pick: SpoolPick(
        itemNo: item.itemNo,
        itemName: item.itemName,
        locationCode: item.locationCode,
        units: [
          for (final unit in item.units)
            (unitId: unit.unitId, quantity: unit.quantity, productBatch: unit.productBatch),
        ],
        pendingQuantity: item.hasPendingQuantity ? item.pendingQuantity : null,
        productBatch: scanned.batch,
      ),
      clearError: true,
    );
    return ScanNeedsPick();
  }

  /// The receipt for [itemNo]: an item already in stock, else a catalog entry
  /// (read fresh - someone may have just added it in wps), else null. Whether
  /// this material is spool-tracked comes from the catalog whenever it has an
  /// entry for this item number - not from whatever's already stored on the
  /// stock item - so correcting an item's category in wps's catalog editor
  /// takes effect on the very next receipt without having to fix already-
  /// received stock by hand. Falls back to the stock item's own flag only
  /// when the catalog has nothing for this item number (predates the
  /// catalog, or was received under a number the catalog import never
  /// covered). submit() honors this same resolved value, not the item's
  /// stored flag, so what's shown here is what actually gets saved.
  Future<ReceiveOperation?> _lookupReceive(String itemNo, String? productBatch) async {
    // The stock and the catalog entry of this one item are independent - asked
    // together, not the whole catalog per scan.
    final (stockItem, catalogItem) = await (_fetchItem(itemNo), ref.read(smCatalogApiProvider).get(itemNo)).wait;
    if (stockItem == null && catalogItem == null) return null;

    return ReceiveOperation(
      itemNo: itemNo,
      // The catalog names a material - wpsApi refuses to save one under a
      // different name - so its name wins over the stock row's copy.
      itemName: catalogItem?.itemName ?? stockItem!.itemName,
      locationCode: stockItem?.locationCode ?? '',
      trackedIndividually: catalogItem?.individualUnits ?? stockItem!.trackedIndividually,
      productBatch: productBatch,
    );
  }

  void cancelPick() {
    state = state.copyWith(clearPick: true, clearError: true);
  }

  /// "Brak numeru szpuli": issue from the unmarked remainder instead of a
  /// spool - it can be issued partially, so this hands over to the normal
  /// quantity screen (OperationScreen) rather than issuing right away.
  void startPendingIssue() {
    final pick = state.pick;
    if (pick == null || pick.pendingQuantity == null) return;
    state = state.copyWith(
      current: IssueOperation(
        itemNo: pick.itemNo,
        itemName: pick.itemName,
        locationCode: pick.locationCode,
        kind: IssueKind.pending,
        available: pick.pendingQuantity!,
        productBatch: pick.productBatch,
      ),
      clearPick: true,
      clearError: true,
    );
  }

  /// Issues the chosen spool in full, right away (a spool is always issued
  /// whole - there's no quantity to type). Returns like [submit].
  Future<bool> issueSpool(String unitId) {
    final pick = state.pick;
    if (pick == null) return Future.value(false);
    final unit = pick.units.where((u) => u.unitId == unitId).firstOrNull;
    if (unit == null) return Future.value(false);
    _setCurrent(
      IssueOperation(
        itemNo: pick.itemNo,
        itemName: pick.itemName,
        locationCode: pick.locationCode,
        kind: IssueKind.unit,
        available: unit.quantity,
        unitId: unitId,
        productBatch: pick.productBatch ?? _nonEmpty(unit.productBatch),
      ),
    );
    return submit();
  }

  void _setCurrent(CurrentOperation op) {
    state = state.copyWith(current: op, clearError: true);
  }

  void cancelCurrent() {
    state = state.copyWith(clearCurrent: true, clearError: true);
  }

  void updateQuantity(String value) {
    final op = state.current;
    if (op == null) return;
    if (op is ReceiveOperation) {
      op.quantity = sanitizeQuantityInput(value);
    } else if (op is IssueOperation) {
      if (op.kind == IssueKind.unit) return;
      op.quantity = _capQuantity(sanitizeQuantityInput(value), op.available);
    }
    state = state.copyWith(current: op);
  }

  void updateLocation(String value) {
    final op = state.current;
    if (op is! ReceiveOperation) return;
    op.location = value;
    state = state.copyWith(current: op);
  }

  void updateUnitId(String value) {
    final op = state.current;
    if (op is! ReceiveOperation) return;
    op.unitId = value;
    state = state.copyWith(current: op);
  }

  String _capQuantity(String value, String max) {
    final v = parseQuantity(value);
    final m = parseQuantity(max);
    if (v == null || m == null || v <= m) return value;
    return formatQuantity(m);
  }

  /// Saves the current operation as one upsert + one history entry, then
  /// clears the screen for the next scan. Mirrors wps's own reducers
  /// (BulkReceiveGrid/BulkIssuePanel): clamp-not-delete for aggregate/
  /// pending, drop the unit from the array for a full unit issue, append/
  /// increment for a receipt. Returns false (leaving the operation intact)
  /// on any API error so the operator can retry without re-scanning.
  Future<bool> submit() async {
    final op = state.current;
    if (op == null || state.submitting) return false;
    if (op is ReceiveOperation && op.loading) return false;
    final qty = parseQuantity(op.quantity) ?? 0;
    if (qty <= 0) return false;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final itemsApi = ref.read(smItemsApiProvider);
      final operationsApi = ref.read(smOperationsApiProvider);
      final operatorName = ref.read(appSettingsProvider).value?.operatorName;

      // Fresh again, not what the scan saw: the operator may have taken a
      // while to type the quantity, and the item is written back whole.
      final existing = await _fetchItem(op.itemNo);
      SmItem item;
      SmOperation operation;

      if (op is ReceiveOperation) {
        // op.trackedIndividually is what _lookupReceive resolved against the
        // catalog (see its own comment) - honored here too, so a catalog
        // correction actually changes how this receipt is saved instead of
        // being silently discarded because the stock item on record still
        // carries the old flag. Only ever upgrades aggregate -> individually
        // tracked (any leftover totalQuantity becomes the new
        // pendingQuantity - still unassigned to a spool, nothing lost) -
        // never the other way, so real per-unit data already on the item is
        // never collapsed back into one number just because the catalog
        // entry changed.
        final upgrading = existing != null && op.trackedIndividually && !existing.trackedIndividually;
        item = existing == null
            ? SmItem(
                itemNo: op.itemNo,
                itemName: op.itemName,
                locationCode: '',
                note: '-',
                trackedIndividually: op.trackedIndividually,
                totalQuantity: op.trackedIndividually ? null : '0',
              )
            : upgrading
                ? SmItem(
                    itemNo: existing.itemNo,
                    itemName: existing.itemName,
                    locationCode: existing.locationCode,
                    note: existing.note,
                    trackedIndividually: true,
                    pendingQuantity: existing.totalQuantity,
                  )
                : existing;

        final unitId = op.unitId.trim();
        if (!item.trackedIndividually) {
          final next = (parseQuantity(item.totalQuantity ?? '0') ?? 0) + qty;
          item = item.copyWith(totalQuantity: formatQuantity(next));
        } else if (unitId.isEmpty) {
          final next = (parseQuantity(item.pendingQuantity ?? '0') ?? 0) + qty;
          item = item.copyWith(pendingQuantity: formatQuantity(next));
        } else {
          item = item.copyWith(
            units: [
              ...item.units,
              SmUnit(id: '', unitId: unitId, quantity: formatQuantity(qty), productBatch: op.productBatch),
            ],
          );
        }

        // Left empty -> the default (MT); an item already elsewhere shows that
        // location prefilled, so it stays where it is unless changed.
        final typedLocation = op.location.trim();
        final location = typedLocation.isEmpty ? defaultReceiveLocation : typedLocation;
        item = item.copyWith(locationCode: location);

        operation = SmOperation(
          operation: 'receipt',
          location: location,
          itemNo: op.itemNo,
          itemName: op.itemName,
          unitId: unitId.isEmpty ? null : unitId,
          quantity: formatQuantity(qty),
          productBatch: op.productBatch,
          operator: operatorName,
        );
      } else {
        op as IssueOperation;
        if (existing == null) throw t.operations.errorNotInStock;
        item = existing;
        _checkStillAvailable(item, op, qty);

        switch (op.kind) {
          case IssueKind.unit:
            item = item.copyWith(units: item.units.where((u) => u.unitId != op.unitId).toList());
          case IssueKind.aggregate:
            final remaining = (parseQuantity(item.totalQuantity ?? '0') ?? 0) - qty;
            item = item.copyWith(totalQuantity: formatQuantity(remaining < 0 ? 0 : remaining));
          case IssueKind.pending:
            final remaining = (parseQuantity(item.pendingQuantity ?? '0') ?? 0) - qty;
            item = remaining <= 0
                ? item.copyWith(clearPendingQuantity: true)
                : item.copyWith(pendingQuantity: formatQuantity(remaining));
        }

        operation = SmOperation(
          operation: 'issue',
          itemNo: op.itemNo,
          itemName: op.itemName,
          unitId: op.unitId,
          quantity: formatQuantity(qty),
          productBatch: op.productBatch,
          operator: operatorName,
        );
      }

      final saved = await itemsApi.upsert(item);
      await operationsApi.create([operation]);

      ref.read(smItemsListProvider.notifier).upsertLocal(saved);
      state = ReceiveIssueState(mode: state.mode);
      return true;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      return false;
    }
  }
}

final receiveIssueControllerProvider = NotifierProvider<ReceiveIssueController, ReceiveIssueState>(
  ReceiveIssueController.new,
);
