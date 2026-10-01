import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/models/sm_item.dart';
import '../../core/api/sm_catalog_api.dart';
import '../../core/api/models/sm_operation.dart';
import '../../core/api/models/sm_unit.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/sm_items_api.dart';
import '../../core/api/sm_operations_api.dart';
import '../../core/session/cip_session.dart';
import '../../core/session/session_providers.dart';
import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';
import 'materials_providers.dart';
import 'receive_issue_models.dart';
import 'scanned_code.dart';

class ReceiveIssueState {
  const ReceiveIssueState({
    this.mode = FlowMode.receive,
    this.current,
    this.pick,
    this.submitting = false,
    this.error,
    this.orderId,
    this.orderItemQuantities = const {},
  });

  final FlowMode mode;
  final CurrentOperation? current;
  final SpoolPick? pick;
  final bool submitting;
  final String? error;

  /// Set while "Obsługa zamówień" (features/orders/) has this controller
  /// scoped to one order's own scan-and-issue flow - see setOrderContext.
  /// Carried onto every issue's own SmOperation (see submit) so that
  /// order's checklist can auto-check the item off; null the rest of the
  /// time, unchanged from before this existed.
  final String? orderId;

  /// That order's own item_no -> "quantity unit" (e.g. "5 szt.", already
  /// formatted by OrderDetailScreen from its own order_items_progress row) -
  /// scanning something real but not a key here is refused (see
  /// _scanForIssue's own gate) rather than issued against the wrong order;
  /// scanning something that IS a key carries its value onto the built
  /// IssueOperation as orderRequiredQuantity, shown on OperationScreen so
  /// the operator sees what the order actually asked for while confirming
  /// how much to issue. Empty whenever [orderId] is null.
  final Map<String, String> orderItemQuantities;

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
      orderId: orderId,
      orderItemQuantities: orderItemQuantities,
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

  /// Scopes this controller to one order's own "Obsługa zamówień" flow
  /// (features/orders/order_scan_screen.dart) - forces issue mode (a
  /// material order is only ever fulfilled by issuing, never received) and
  /// clears whatever operation/pick was mid-flight, same reset setMode
  /// already does on a plain mode switch.
  void setOrderContext(String orderId, Map<String, String> itemQuantities) {
    state = ReceiveIssueState(mode: FlowMode.issue, orderId: orderId, orderItemQuantities: itemQuantities);
  }

  /// Leaving the order-scoped scan screen - see its own dispose(). Keeps
  /// whatever mode was active (unlike setOrderContext, this isn't a mode
  /// switch), just drops the order tag so a later, ordinary issue never
  /// accidentally carries a stale orderId.
  void clearOrderContext() {
    if (state.orderId == null) return;
    state = ReceiveIssueState(mode: state.mode);
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
  /// screen shows it. Przyjęcie goes through [scanReceive].
  Future<ScanOutcome> scan(String rawCode) async {
    final code = ScannedCode.parse(rawCode);
    if (code.raw.isEmpty) return ScanUnknown();
    return _scanForIssue(code);
  }

  /// Przyjęcie: reads the item from the server first, same shape as [scan]
  /// (Wydanie) - the operation screen only ever opens once the item is
  /// confirmed to exist, so an unknown code shows the "nieznany kod" toast
  /// without ever flashing the screen open only to close it again a moment
  /// later (the previous startReceive/resolveReceive two-step opened it
  /// immediately, before knowing that). Throws on a network/API error, same
  /// as [scan].
  Future<ScanOutcome> scanReceive(String rawCode) async {
    final scanned = ScannedCode.parse(rawCode);
    if (scanned.itemNo.isEmpty) return ScanUnknown();
    final resolved = await _lookupReceive(scanned.itemNo, scanned.batch, scanned.quantity);
    if (resolved == null) return ScanUnknown();
    _setCurrent(resolved);
    return ScanStarted();
  }

  /// The scanned label's own quantity field (see ScannedCode), capped at
  /// what's actually available - same cap updateQuantity already applies to
  /// anything typed by hand, reused here so a label overstating what's on
  /// the shelf can't be issued past it either. Null (quantity starts blank,
  /// same as before this existed) when the label carried none - a plain
  /// item-number-only scan, or a spool tag (see ScannedCode's own comment:
  /// only a multi-field label has this at all).
  String? _scannedQuantity(String? scanned, String available) {
    if (scanned == null) return null;
    return _capQuantity(scanned, available);
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
    // "Obsługa zamówień" (see setOrderContext) - a real, in-stock item, but
    // not one of this order's own items. Checked before any of the
    // kind-specific branches below (unit/aggregate/pending) so a spool tag
    // belonging to the wrong item is refused the same way a plain wrong
    // item number is. `orderQty` (this order's own "quantity unit" for the
    // item, e.g. "5 szt.") rides along on whichever IssueOperation gets
    // built below - see its own orderRequiredQuantity comment.
    final orderQty = state.orderItemQuantities[item.itemNo];
    if (state.orderId != null && orderQty == null) return ScanNotInOrder();

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
          orderRequiredQuantity: orderQty,
        ),
      );
      return ScanStarted();
    }

    if (!item.trackedIndividually) {
      final qty = parseQuantity(item.totalQuantity ?? '0') ?? 0;
      if (qty <= 0) return ScanNotIssuable();
      final available = item.totalQuantity ?? '0';
      _setCurrent(
        IssueOperation(
          itemNo: item.itemNo,
          itemName: item.itemName,
          locationCode: item.locationCode,
          kind: IssueKind.aggregate,
          available: available,
          productBatch: scanned.batch,
          placeholderQuantity: _scannedQuantity(scanned.quantity, available),
          orderRequiredQuantity: orderQty,
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
          placeholderQuantity: _scannedQuantity(scanned.quantity, item.pendingQuantity!),
          orderRequiredQuantity: orderQty,
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
        orderRequiredQuantity: orderQty,
        scannedQuantity: scanned.quantity,
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
  Future<ReceiveOperation?> _lookupReceive(String itemNo, String? productBatch, String? scannedQuantity) async {
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
      // The scanned label's own quantity field (see ScannedCode), as the
      // quantity input's placeholder in place of "1" - not prefilled text
      // (quantity itself stays blank, its own default) - see
      // ReceiveOperation.placeholderQuantity's own comment. A receipt has
      // no "available" ceiling to cap it against (unlike an issue, there's
      // nothing on the shelf yet to overstate), so this is used as-is.
      placeholderQuantity: scannedQuantity,
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
        placeholderQuantity: _scannedQuantity(pick.scannedQuantity, pick.pendingQuantity!),
        orderRequiredQuantity: pick.orderRequiredQuantity,
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
        orderRequiredQuantity: pick.orderRequiredQuantity,
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
    // A receipt left blank defaults to its own placeholderQuantity (the
    // scanned label's own quantity, shown as the field's placeholder - see
    // ReceiveOperation's own comment) if it has one, else the fixed
    // defaultReceiveQuantity ("1") the placeholder falls back to instead.
    // Wydanie is the mirror: blank defaults to its own placeholderQuantity
    // when the label carried one (same reasoning - the operator was shown
    // it and chose not to overtype it), otherwise stays a no-op exactly as
    // before this existed (issuing the wrong amount because nothing was
    // typed, with nothing to fall back to, is a real stock mistake - only
    // safe to default when the label itself said how much).
    final quantityText = switch (op) {
      ReceiveOperation() when op.quantity.trim().isEmpty => op.placeholderQuantity ?? defaultReceiveQuantity,
      IssueOperation() when op.quantity.trim().isEmpty => op.placeholderQuantity ?? '',
      _ => op.quantity,
    };
    final qty = parseQuantity(quantityText) ?? 0;
    if (qty <= 0) return false;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final itemsApi = ref.read(smItemsApiProvider);
      final operationsApi = ref.read(smOperationsApiProvider);
      final settings = ref.read(appSettingsProvider).value;
      final operatorName = settings?.operatorName;

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
          // "Obsługa zamówień" context (see setOrderContext) - null for an
          // ordinary issue, unchanged from before this existed.
          orderId: state.orderId,
        );
      }

      // CIP-gated: wpsApi pushes this receipt/issue to CIP (using the
      // operator's own CIP session) before writing anything, and refuses the
      // whole save if CIP does - see SmItemsApi.upsert.
      // The token is renewed first when (nearly) expired, and once more if CIP
      // refuses it anyway - see CipSessionService. Not logged in at all: no CIP task.
      final cipSession = ref.read(cipSessionProvider);
      Future<SmItem> save({bool forceNewToken = false}) async {
        if ((settings?.authToken ?? '').isEmpty) return itemsApi.upsert(item);
        final token = await cipSession.freshToken(force: forceNewToken);
        return itemsApi.upsert(
          item,
          cip: CipWriteTask(operation: operation.operation, quantity: formatQuantity(qty), cipToken: token),
        );
      }

      SmItem saved;
      try {
        saved = await save();
      } on SmItemApiError catch (e) {
        if (e.code != 'session_expired') rethrow;
        saved = await save(forceNewToken: true);
      }
      await operationsApi.create([operation]);

      ref.read(smItemsListProvider.notifier).upsertLocal(saved);
      // Keeps orderId across the reset - "Obsługa zamówień" scans several
      // items in a row for the same order, unlike every other reset of this
      // state (setMode, clearOrderContext) which is a deliberate context
      // switch away from it.
      state = ReceiveIssueState(mode: state.mode, orderId: state.orderId, orderItemQuantities: state.orderItemQuantities);
      return true;
    } on AuthFailure catch (e) {
      // The session could not be renewed (and the operator is now logged out).
      state = state.copyWith(
        submitting: false,
        error: e.code == 'session_expired' ? t.operations.errorSessionExpired : e.message,
      );
      return false;
    } on SmItemApiError catch (e) {
      // CIP still refused the renewed token: nothing more to try but a login.
      if (e.code == 'session_expired') await ref.read(appSettingsProvider.notifier).logout();
      state = state.copyWith(
        submitting: false,
        error: e.code == 'session_expired' ? t.operations.errorSessionExpired : e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      return false;
    }
  }
}

final receiveIssueControllerProvider = NotifierProvider<ReceiveIssueController, ReceiveIssueState>(
  ReceiveIssueController.new,
);
