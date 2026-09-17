import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/scanner/barcode_scanner_service.dart';
import '../../i18n/gen/strings.g.dart';
import 'materials_providers.dart';
import 'receive_issue_controller.dart';
import 'receive_issue_models.dart';

/// One operation at a time: scan (or type) a code, the item's details and a
/// quantity field appear, confirm, and the screen is immediately ready for
/// the next scan - no batch/queue to review. See ReceiveIssueController for
/// the scan-resolution and submit logic this screen just renders.
class ReceiveIssueScreen extends ConsumerStatefulWidget {
  const ReceiveIssueScreen({super.key});

  @override
  ConsumerState<ReceiveIssueScreen> createState() => _ReceiveIssueScreenState();
}

class _ReceiveIssueScreenState extends ConsumerState<ReceiveIssueScreen> {
  final _manualEntryController = TextEditingController();
  final _manualEntryFocusNode = FocusNode();
  final _quantityController = TextEditingController();
  final _quantityFocusNode = FocusNode();
  final _unitIdController = TextEditingController();
  StreamSubscription<String>? _scanSub;
  StreamSubscription<Object>? _errorSub;

  @override
  void initState() {
    super.initState();
    _wire();
  }

  Future<void> _wire() async {
    final scanner = ref.read(barcodeScannerServiceProvider);
    await scanner.init();
    if (!mounted) return;
    _scanSub = scanner.onScan.listen(_handleCode);
    _errorSub = scanner.onError.listen((error) {
      if (!mounted) return;
      ShadToaster.of(context).show(ShadToast.destructive(description: Text('$error')));
    });
  }

  void _submitManualEntry() {
    final code = _manualEntryController.text.trim();
    if (code.isEmpty) return;
    ref.read(barcodeScannerServiceProvider).simulateScan(code);
    _manualEntryController.clear();
  }

  void _handleCode(String code) {
    if (!mounted) return;
    final t = context.t;
    final outcome = ref.read(receiveIssueControllerProvider.notifier).scan(code);
    switch (outcome) {
      case ScanStarted():
        _syncFieldsFromCurrent();
        _quantityFocusNode.requestFocus();
      case ScanNotIssuable():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastNotIssuable)));
      case ScanUnknown():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastUnknown)));
      case ScanNeedsPick(:final itemNo, :final itemName, :final locationCode, :final units, :final pendingQuantity):
        _openPicker(
          itemNo: itemNo,
          itemName: itemName,
          locationCode: locationCode,
          units: units,
          pendingQuantity: pendingQuantity,
        );
    }
  }

  /// The quantity/unit-id text fields are stable controllers owned by this
  /// State (so they can keep focus across a rebuild) - this pushes the
  /// freshly scanned operation's starting values into them.
  void _syncFieldsFromCurrent() {
    final op = ref.read(receiveIssueControllerProvider).current;
    _quantityController.text = op?.quantity ?? '';
    _unitIdController.text = op is ReceiveOperation ? op.unitId : '';
  }

  Future<void> _openPicker({
    required String itemNo,
    required String itemName,
    required String locationCode,
    required List<({String unitId, String quantity})> units,
    required String? pendingQuantity,
  }) async {
    final t = context.t;
    await showShadSheet<void>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (sheetContext) {
        final theme = ShadTheme.of(sheetContext);
        return ShadSheet(
          title: Text(itemName),
          description: Text(itemNo),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final unit in units)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ShadButton.outline(
                    onPressed: () {
                      ref.read(receiveIssueControllerProvider.notifier).pickIssueLeaf(
                            itemNo: itemNo,
                            itemName: itemName,
                            locationCode: locationCode,
                            kind: IssueKind.unit,
                            available: unit.quantity,
                            unitId: unit.unitId,
                          );
                      _syncFieldsFromCurrent();
                      Navigator.of(sheetContext).pop();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.operations.pickUnit(unitId: unit.unitId)),
                        Text(unit.quantity, style: theme.textTheme.muted),
                      ],
                    ),
                  ),
                ),
              if (pendingQuantity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ShadButton.outline(
                    onPressed: () {
                      ref.read(receiveIssueControllerProvider.notifier).pickIssueLeaf(
                            itemNo: itemNo,
                            itemName: itemName,
                            locationCode: locationCode,
                            kind: IssueKind.pending,
                            available: pendingQuantity,
                          );
                      _syncFieldsFromCurrent();
                      Navigator.of(sheetContext).pop();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.operations.pickPending),
                        Text(pendingQuantity, style: theme.textTheme.muted),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (mounted) _quantityFocusNode.requestFocus();
  }

  Future<void> _confirm() async {
    final t = context.t;
    final ok = await ref.read(receiveIssueControllerProvider.notifier).submit();
    if (!mounted) return;
    if (ok) {
      _quantityController.clear();
      _unitIdController.clear();
      ShadToaster.of(context).show(ShadToast(description: Text(t.operations.submitted)));
      _manualEntryFocusNode.requestFocus();
    } else {
      final error = ref.read(receiveIssueControllerProvider).error;
      if (error != null) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(error)));
      }
    }
  }

  void _cancel() {
    ref.read(receiveIssueControllerProvider.notifier).cancelCurrent();
    _quantityController.clear();
    _unitIdController.clear();
    _manualEntryFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _errorSub?.cancel();
    _manualEntryController.dispose();
    _manualEntryFocusNode.dispose();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    _unitIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final state = ref.watch(receiveIssueControllerProvider);
    ref.watch(smItemsListProvider);
    ref.watch(smCatalogListProvider);
    final op = state.current;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: _manualEntryController,
                  focusNode: _manualEntryFocusNode,
                  placeholder: Text(t.operations.scanPlaceholder),
                  onSubmitted: (_) => _submitManualEntry(),
                ),
              ),
              const SizedBox(width: 8),
              ShadButton(onPressed: _submitManualEntry, child: Icon(LucideIcons.scanLine)),
            ],
          ),
        ),
        Expanded(
          child: op == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(t.operations.idle, textAlign: TextAlign.center, style: theme.textTheme.muted),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _OperationCard(
                    op: op,
                    quantityController: _quantityController,
                    quantityFocusNode: _quantityFocusNode,
                    unitIdController: _unitIdController,
                  ),
                ),
        ),
        if (op != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  ShadButton.outline(onPressed: state.submitting ? null : _cancel, child: Text(t.operations.cancel)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ShadButton(
                      enabled: !state.submitting,
                      onPressed: state.submitting ? null : _confirm,
                      child: Text(state.submitting ? t.operations.submitting : t.operations.confirm),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OperationCard extends ConsumerWidget {
  const _OperationCard({
    required this.op,
    required this.quantityController,
    required this.quantityFocusNode,
    required this.unitIdController,
  });

  final CurrentOperation op;
  final TextEditingController quantityController;
  final FocusNode quantityFocusNode;
  final TextEditingController unitIdController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final controller = ref.read(receiveIssueControllerProvider.notifier);

    Widget fields;
    if (op is ReceiveOperation) {
      final receiveOp = op as ReceiveOperation;
      fields = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.operations.quantityLabel, style: theme.textTheme.small),
          const SizedBox(height: 6),
          ShadInput(
            controller: quantityController,
            focusNode: quantityFocusNode,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: controller.updateQuantity,
          ),
          if (receiveOp.trackedIndividually) ...[
            const SizedBox(height: 12),
            Text(t.operations.unitOptional, style: theme.textTheme.small),
            const SizedBox(height: 6),
            ShadInput(controller: unitIdController, onChanged: controller.updateUnitId),
          ],
        ],
      );
    } else {
      final issueOp = op as IssueOperation;
      fields = issueOp.kind == IssueKind.unit
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t.operations.unitLabel}: ${issueOp.unitId}', style: theme.textTheme.muted),
                Text(issueOp.quantity, style: theme.textTheme.h4),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.operations.available(value: issueOp.available), style: theme.textTheme.muted),
                const SizedBox(height: 8),
                Text(t.operations.quantityLabel, style: theme.textTheme.small),
                const SizedBox(height: 6),
                ShadInput(
                  controller: quantityController,
                  focusNode: quantityFocusNode,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: controller.updateQuantity,
                ),
              ],
            );
    }

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(op.itemName, style: theme.textTheme.h3),
          Text(op.itemNo, style: theme.textTheme.muted),
          if (op.locationCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${t.operations.location}: ${op.locationCode}', style: theme.textTheme.muted),
          ],
          const SizedBox(height: 16),
          fields,
        ],
      ),
    );
  }
}
