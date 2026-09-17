import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/scanner/barcode_scanner_service.dart';
import '../../i18n/gen/strings.g.dart';
import 'materials_providers.dart';
import 'receive_issue_controller.dart';
import 'receive_issue_models.dart';

/// The przyjęcie/wydanie workflow: scan (or type) a code, it resolves to a
/// queued line automatically wherever that's unambiguous, review/edit the
/// queue, then confirm as one batch. See ReceiveIssueController for the
/// scan-resolution and submit-reducer logic this screen just renders.
class ReceiveIssueScreen extends ConsumerStatefulWidget {
  const ReceiveIssueScreen({super.key});

  @override
  ConsumerState<ReceiveIssueScreen> createState() => _ReceiveIssueScreenState();
}

class _ReceiveIssueScreenState extends ConsumerState<ReceiveIssueScreen> {
  final _manualEntryController = TextEditingController();
  final _focusNode = FocusNode();
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
      case ScanAdded():
        break;
      case ScanAlreadyQueued():
        ShadToaster.of(context).show(ShadToast(description: Text(t.operations.toastAlready)));
      case ScanNotIssuable():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastNotIssuable)));
      case ScanUnknown():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastUnknown)));
      case ScanNeedsPick(:final itemNo, :final itemName, :final units, :final pendingQuantity):
        _openPicker(itemNo: itemNo, itemName: itemName, units: units, pendingQuantity: pendingQuantity);
    }
  }

  Future<void> _openPicker({
    required String itemNo,
    required String itemName,
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
                      ref.read(receiveIssueControllerProvider.notifier).addIssuePick(
                            itemNo: itemNo,
                            itemName: itemName,
                            kind: IssueKind.unit,
                            available: unit.quantity,
                            unitId: unit.unitId,
                          );
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
                      ref.read(receiveIssueControllerProvider.notifier).addIssuePick(
                            itemNo: itemNo,
                            itemName: itemName,
                            kind: IssueKind.pending,
                            available: pendingQuantity,
                          );
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
  }

  Future<void> _submitQueue() async {
    final t = context.t;
    final ok = await ref.read(receiveIssueControllerProvider.notifier).submit();
    if (!mounted) return;
    if (ok) {
      ShadToaster.of(context).show(ShadToast(description: Text(t.operations.submitted)));
    } else {
      final error = ref.read(receiveIssueControllerProvider).error;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(error ?? t.operations.toastUnknown)),
      );
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _errorSub?.cancel();
    _manualEntryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final state = ref.watch(receiveIssueControllerProvider);
    ref.watch(smItemsListProvider);
    ref.watch(smCatalogListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _manualEntryController,
                      focusNode: _focusNode,
                      placeholder: Text(t.operations.scanPlaceholder),
                      onSubmitted: (_) => _submitManualEntry(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(onPressed: _submitManualEntry, child: Icon(LucideIcons.scanLine)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: state.lines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      t.operations.queueEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.muted,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: state.lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _QueueLineCard(index: index, line: state.lines[index]),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ShadButton(
              width: double.infinity,
              enabled: state.lines.isNotEmpty && !state.submitting,
              onPressed: state.lines.isEmpty || state.submitting ? null : _submitQueue,
              child: Text(
                state.submitting
                    ? t.operations.submitting
                    : '${t.operations.submit} (${state.lines.length})',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QueueLineCard extends ConsumerWidget {
  const _QueueLineCard({required this.index, required this.line});

  final int index;
  final QueueLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final controller = ref.read(receiveIssueControllerProvider.notifier);

    Widget fields;
    if (line is ReceiveLine) {
      final receiveLine = line as ReceiveLine;
      fields = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInput(
            key: ValueKey('qty-$index'),
            initialValue: receiveLine.quantity,
            placeholder: Text(t.operations.quantityLabel),
            keyboardType: TextInputType.number,
            onChanged: (v) => controller.updateReceiveQuantity(index, v),
          ),
          if (receiveLine.trackedIndividually) ...[
            const SizedBox(height: 8),
            ShadInput(
              key: ValueKey('unit-$index'),
              initialValue: receiveLine.unitId,
              placeholder: Text(t.operations.unitOptional),
              onChanged: (v) => controller.updateReceiveUnitId(index, v),
            ),
          ],
        ],
      );
    } else {
      final issueLine = line as IssueLine;
      fields = issueLine.kind == IssueKind.unit
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t.operations.unitLabel}: ${issueLine.unitId}', style: theme.textTheme.muted),
                Text(issueLine.quantity, style: theme.textTheme.p),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.operations.available(value: issueLine.available), style: theme.textTheme.muted),
                const SizedBox(height: 8),
                ShadInput(
                  key: ValueKey('issue-qty-$index'),
                  initialValue: issueLine.quantity,
                  placeholder: Text(t.operations.quantityLabel),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => controller.updateIssueQuantity(index, v),
                ),
              ],
            );
    }

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.itemName, style: theme.textTheme.p),
                    Text(line.itemNo, style: theme.textTheme.muted),
                  ],
                ),
              ),
              ShadButton.ghost(
                onPressed: () => controller.removeLine(index),
                child: Icon(LucideIcons.trash2, color: theme.colorScheme.destructive),
              ),
            ],
          ),
          const SizedBox(height: 8),
          fields,
        ],
      ),
    );
  }
}
