import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/models/sm_item.dart';
import '../../core/api/models/sm_operation.dart';
import '../../core/api/models/sm_unit.dart';
import '../../core/api/sm_catalog_api.dart';
import '../../core/api/sm_items_api.dart';
import '../../core/api/sm_operations_api.dart';
import '../../core/session/session_providers.dart';
import '../../core/utils/quantity.dart';
import 'materials_providers.dart';
import 'receive_issue_models.dart';

class ReceiveIssueState {
  const ReceiveIssueState({
    this.mode = FlowMode.receive,
    this.current,
    this.submitting = false,
    this.error,
  });

  final FlowMode mode;
  final CurrentOperation? current;
  final bool submitting;
  final String? error;

  ReceiveIssueState copyWith({
    CurrentOperation? current,
    bool clearCurrent = false,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) {
    return ReceiveIssueState(
      mode: mode,
      current: clearCurrent ? null : (current ?? this.current),
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

  SmItem? _findItem(String itemNo) {
    for (final item in ref.read(smItemsListProvider).value ?? const <SmItem>[]) {
      if (item.itemNo == itemNo) return item;
    }
    return null;
  }

  SmCatalogItem? _findCatalog(String itemNo) {
    for (final entry in ref.read(smCatalogListProvider).value ?? const <SmCatalogItem>[]) {
      if (entry.itemNo == itemNo) return entry;
    }
    return null;
  }

  ScanOutcome scan(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return ScanUnknown();
    return state.mode == FlowMode.issue ? _scanForIssue(code) : _scanForReceive(code);
  }

  ScanOutcome _scanForIssue(String code) {
    for (final item in ref.read(smItemsListProvider).value ?? const <SmItem>[]) {
      for (final unit in item.units) {
        if (unit.unitId != code) continue;
        _setCurrent(IssueOperation(
          itemNo: item.itemNo,
          itemName: item.itemName,
          locationCode: item.locationCode,
          kind: IssueKind.unit,
          available: unit.quantity,
          unitId: unit.unitId,
        ));
        return ScanStarted();
      }
    }

    final item = _findItem(code);
    if (item == null) return ScanUnknown();

    if (!item.trackedIndividually) {
      final qty = parseQuantity(item.totalQuantity ?? '0') ?? 0;
      if (qty <= 0) return ScanNotIssuable();
      _setCurrent(IssueOperation(
        itemNo: item.itemNo,
        itemName: item.itemName,
        locationCode: item.locationCode,
        kind: IssueKind.aggregate,
        available: item.totalQuantity ?? '0',
      ));
      return ScanStarted();
    }

    final leaves = <({IssueKind kind, String? unitId, String quantity})>[
      for (final unit in item.units) (kind: IssueKind.unit, unitId: unit.unitId, quantity: unit.quantity),
      if (item.hasPendingQuantity) (kind: IssueKind.pending, unitId: null, quantity: item.pendingQuantity!),
    ];
    if (leaves.isEmpty) return ScanNotIssuable();

    if (leaves.length == 1) {
      final leaf = leaves.first;
      _setCurrent(IssueOperation(
        itemNo: item.itemNo,
        itemName: item.itemName,
        locationCode: item.locationCode,
        kind: leaf.kind,
        available: leaf.quantity,
        unitId: leaf.unitId,
      ));
      return ScanStarted();
    }

    return ScanNeedsPick(
      item.itemNo,
      item.itemName,
      item.locationCode,
      [for (final unit in item.units) (unitId: unit.unitId, quantity: unit.quantity)],
      item.hasPendingQuantity ? item.pendingQuantity : null,
    );
  }

  ScanOutcome _scanForReceive(String code) {
    final stockItem = _findItem(code);
    if (stockItem != null) {
      _setCurrent(ReceiveOperation(
        itemNo: stockItem.itemNo,
        itemName: stockItem.itemName,
        locationCode: stockItem.locationCode,
        trackedIndividually: stockItem.trackedIndividually,
      ));
      return ScanStarted();
    }

    final catalogItem = _findCatalog(code);
    if (catalogItem != null) {
      _setCurrent(ReceiveOperation(
        itemNo: catalogItem.itemNo,
        itemName: catalogItem.itemName,
        locationCode: '',
        trackedIndividually: catalogItem.individualUnits,
      ));
      return ScanStarted();
    }

    return ScanUnknown();
  }

  /// Called once the operator resolves a ScanNeedsPick from the picker sheet.
  void pickIssueLeaf({
    required String itemNo,
    required String itemName,
    required String locationCode,
    required IssueKind kind,
    required String available,
    String? unitId,
  }) {
    _setCurrent(IssueOperation(
      itemNo: itemNo,
      itemName: itemName,
      locationCode: locationCode,
      kind: kind,
      available: available,
      unitId: unitId,
    ));
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
    final qty = parseQuantity(op.quantity) ?? 0;
    if (qty <= 0) return false;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final itemsApi = ref.read(smItemsApiProvider);
      final operationsApi = ref.read(smOperationsApiProvider);
      final operatorName = ref.read(appSettingsProvider).value?.operatorName;

      final existing = _findItem(op.itemNo);
      SmItem item;
      SmOperation operation;

      if (op is ReceiveOperation) {
        item = existing ??
            SmItem(
              itemNo: op.itemNo,
              itemName: op.itemName,
              locationCode: '',
              note: '-',
              trackedIndividually: op.trackedIndividually,
              totalQuantity: op.trackedIndividually ? null : '0',
            );

        final unitId = op.unitId.trim();
        if (!item.trackedIndividually) {
          final next = (parseQuantity(item.totalQuantity ?? '0') ?? 0) + qty;
          item = item.copyWith(totalQuantity: formatQuantity(next));
        } else if (unitId.isEmpty) {
          final next = (parseQuantity(item.pendingQuantity ?? '0') ?? 0) + qty;
          item = item.copyWith(pendingQuantity: formatQuantity(next));
        } else {
          item = item.copyWith(units: [
            ...item.units,
            SmUnit(id: '', unitId: unitId, quantity: formatQuantity(qty)),
          ]);
        }

        final location = op.location.trim();
        if (location.isNotEmpty) item = item.copyWith(locationCode: location);

        operation = SmOperation(
          operation: 'receipt',
          location: location.isEmpty ? null : location,
          itemNo: op.itemNo,
          itemName: op.itemName,
          unitId: unitId.isEmpty ? null : unitId,
          quantity: formatQuantity(qty),
          operator: operatorName,
        );
      } else {
        op as IssueOperation;
        if (existing == null) return false;
        item = existing;

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

final receiveIssueControllerProvider =
    NotifierProvider<ReceiveIssueController, ReceiveIssueState>(ReceiveIssueController.new);
