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
    this.lines = const [],
    this.submitting = false,
    this.error,
  });

  final FlowMode mode;
  final List<QueueLine> lines;
  final bool submitting;
  final String? error;

  ReceiveIssueState copyWith({
    List<QueueLine>? lines,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) {
    return ReceiveIssueState(
      mode: mode,
      lines: lines ?? this.lines,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the scan -> queue -> review -> submit flow (see
/// receive_issue_models.dart for the line/outcome types this returns).
class ReceiveIssueController extends Notifier<ReceiveIssueState> {
  @override
  ReceiveIssueState build() => const ReceiveIssueState();

  /// Switching mode starts a fresh queue rather than trying to keep a
  /// mixed batch (see FlowMode's own doc comment).
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

  bool _alreadyQueued({String? itemNo, String? unitId, IssueKind? kind}) {
    return state.lines.any((line) {
      if (line is IssueLine) {
        if (kind == null) return false;
        if (kind == IssueKind.unit) {
          return line.kind == IssueKind.unit && line.unitId == unitId;
        }
        return line.itemNo == itemNo && line.kind == kind;
      }
      if (line is ReceiveLine) return kind == null && line.itemNo == itemNo;
      return false;
    });
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
        if (_alreadyQueued(unitId: code, kind: IssueKind.unit)) return ScanAlreadyQueued();
        _addLine(IssueLine(
          itemNo: item.itemNo,
          itemName: item.itemName,
          kind: IssueKind.unit,
          available: unit.quantity,
          unitId: unit.unitId,
        ));
        return ScanAdded();
      }
    }

    final item = _findItem(code);
    if (item == null) return ScanUnknown();

    if (!item.trackedIndividually) {
      final qty = parseQuantity(item.totalQuantity ?? '0') ?? 0;
      if (qty <= 0) return ScanNotIssuable();
      if (_alreadyQueued(itemNo: item.itemNo, kind: IssueKind.aggregate)) return ScanAlreadyQueued();
      _addLine(IssueLine(
        itemNo: item.itemNo,
        itemName: item.itemName,
        kind: IssueKind.aggregate,
        available: item.totalQuantity ?? '0',
      ));
      return ScanAdded();
    }

    final leaves = <({IssueKind kind, String? unitId, String quantity})>[
      for (final unit in item.units) (kind: IssueKind.unit, unitId: unit.unitId, quantity: unit.quantity),
      if (item.hasPendingQuantity) (kind: IssueKind.pending, unitId: null, quantity: item.pendingQuantity!),
    ];
    if (leaves.isEmpty) return ScanNotIssuable();

    if (leaves.length == 1) {
      final leaf = leaves.first;
      if (_alreadyQueued(itemNo: item.itemNo, unitId: leaf.unitId, kind: leaf.kind)) {
        return ScanAlreadyQueued();
      }
      _addLine(IssueLine(
        itemNo: item.itemNo,
        itemName: item.itemName,
        kind: leaf.kind,
        available: leaf.quantity,
        unitId: leaf.unitId,
      ));
      return ScanAdded();
    }

    return ScanNeedsPick(
      item.itemNo,
      item.itemName,
      [for (final unit in item.units) (unitId: unit.unitId, quantity: unit.quantity)],
      item.hasPendingQuantity ? item.pendingQuantity : null,
    );
  }

  ScanOutcome _scanForReceive(String code) {
    if (_alreadyQueued(itemNo: code)) return ScanAlreadyQueued();

    final stockItem = _findItem(code);
    if (stockItem != null) {
      _addLine(ReceiveLine(
        itemNo: stockItem.itemNo,
        itemName: stockItem.itemName,
        trackedIndividually: stockItem.trackedIndividually,
      ));
      return ScanAdded();
    }

    final catalogItem = _findCatalog(code);
    if (catalogItem != null) {
      _addLine(ReceiveLine(
        itemNo: catalogItem.itemNo,
        itemName: catalogItem.itemName,
        trackedIndividually: catalogItem.individualUnits,
      ));
      return ScanAdded();
    }

    return ScanUnknown();
  }

  /// Called once the operator resolves a ScanNeedsPick from the picker sheet.
  void addIssuePick({
    required String itemNo,
    required String itemName,
    required IssueKind kind,
    required String available,
    String? unitId,
  }) {
    if (_alreadyQueued(itemNo: itemNo, unitId: unitId, kind: kind)) return;
    _addLine(IssueLine(itemNo: itemNo, itemName: itemName, kind: kind, available: available, unitId: unitId));
  }

  void _addLine(QueueLine line) {
    state = state.copyWith(lines: [...state.lines, line], clearError: true);
  }

  void removeLine(int index) {
    final next = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: next);
  }

  void updateReceiveQuantity(int index, String value) {
    final line = state.lines[index];
    if (line is! ReceiveLine) return;
    line.quantity = sanitizeQuantityInput(value);
    state = state.copyWith(lines: [...state.lines]);
  }

  void updateReceiveUnitId(int index, String value) {
    final line = state.lines[index];
    if (line is! ReceiveLine) return;
    line.unitId = value;
    state = state.copyWith(lines: [...state.lines]);
  }

  void updateIssueQuantity(int index, String value) {
    final line = state.lines[index];
    if (line is! IssueLine || line.kind == IssueKind.unit) return;
    line.quantity = _capQuantity(sanitizeQuantityInput(value), line.available);
    state = state.copyWith(lines: [...state.lines]);
  }

  String _capQuantity(String value, String max) {
    final v = parseQuantity(value);
    final m = parseQuantity(max);
    if (v == null || m == null || v <= m) return value;
    return formatQuantity(m);
  }

  /// Batches the whole queue into one upsert per touched item plus a
  /// single history call - mirrors wps's own reducers (BulkReceiveGrid /
  /// BulkIssuePanel): clamp-not-delete for aggregate/pending, drop the
  /// unit from the array for a full unit issue, append/increment for a
  /// receipt. Returns false (leaving the queue intact) on any API error.
  Future<bool> submit() async {
    if (state.lines.isEmpty || state.submitting) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final itemsApi = ref.read(smItemsApiProvider);
      final operationsApi = ref.read(smOperationsApiProvider);
      final operatorName = ref.read(appSettingsProvider).value?.operatorName;

      final working = <String, SmItem>{
        for (final item in ref.read(smItemsListProvider).value ?? const <SmItem>[]) item.itemNo: item,
      };
      final operations = <SmOperation>[];

      for (final line in state.lines) {
        if (line is ReceiveLine) {
          final qty = parseQuantity(line.quantity) ?? 0;
          if (qty <= 0) continue;

          var item = working[line.itemNo] ??
              SmItem(
                itemNo: line.itemNo,
                itemName: line.itemName,
                locationCode: '',
                note: '-',
                trackedIndividually: line.trackedIndividually,
                totalQuantity: line.trackedIndividually ? null : '0',
              );

          final unitId = line.unitId.trim();
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
          working[line.itemNo] = item;

          operations.add(SmOperation(
            operation: 'receipt',
            itemNo: line.itemNo,
            itemName: line.itemName,
            unitId: unitId.isEmpty ? null : unitId,
            quantity: formatQuantity(qty),
            operator: operatorName,
          ));
        } else if (line is IssueLine) {
          final item = working[line.itemNo];
          if (item == null) continue;
          final qty = parseQuantity(line.quantity) ?? 0;
          if (qty <= 0) continue;

          SmItem next;
          switch (line.kind) {
            case IssueKind.unit:
              next = item.copyWith(units: item.units.where((u) => u.unitId != line.unitId).toList());
            case IssueKind.aggregate:
              final remaining = (parseQuantity(item.totalQuantity ?? '0') ?? 0) - qty;
              next = item.copyWith(totalQuantity: formatQuantity(remaining < 0 ? 0 : remaining));
            case IssueKind.pending:
              final remaining = (parseQuantity(item.pendingQuantity ?? '0') ?? 0) - qty;
              next = remaining <= 0
                  ? item.copyWith(clearPendingQuantity: true)
                  : item.copyWith(pendingQuantity: formatQuantity(remaining));
          }
          working[line.itemNo] = next;

          operations.add(SmOperation(
            operation: 'issue',
            itemNo: line.itemNo,
            itemName: line.itemName,
            unitId: line.unitId,
            quantity: formatQuantity(qty),
            operator: operatorName,
          ));
        }
      }

      final touchedItemNos = state.lines.map((l) => l.itemNo).toSet();
      for (final itemNo in touchedItemNos) {
        final item = working[itemNo];
        if (item != null) await itemsApi.upsert(item);
      }
      if (operations.isNotEmpty) await operationsApi.create(operations);

      ref.invalidate(smItemsListProvider);
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
