import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/scanner/barcode_scanner_service.dart';
import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import 'materials_providers.dart';
import 'receive_issue_controller.dart';
import 'receive_issue_models.dart';

/// The scan-first landing screen for a mode (Przyjęcie/Wydanie, picked in
/// HomeShell's own header above this). Scan (or type) a code and, once it
/// resolves, this pushes OperationScreen - its own full page for filling in
/// the quantity and confirming - rather than showing anything inline here.
class ReceiveIssueScreen extends ConsumerStatefulWidget {
  const ReceiveIssueScreen({super.key});

  @override
  ConsumerState<ReceiveIssueScreen> createState() => _ReceiveIssueScreenState();
}

class _ReceiveIssueScreenState extends ConsumerState<ReceiveIssueScreen> {
  final _manualEntryController = TextEditingController();
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
        context.push(materialsSmOperationPath);
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

  Future<void> _openPicker({
    required String itemNo,
    required String itemName,
    required String locationCode,
    required List<({String unitId, String quantity})> units,
    required String? pendingQuantity,
  }) async {
    final t = context.t;
    var picked = false;
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
                      picked = true;
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
                      picked = true;
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
    if (!mounted || !picked) return;
    await context.push(materialsSmOperationPath);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _errorSub?.cancel();
    _manualEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    ref.watch(smItemsListProvider);
    ref.watch(smCatalogListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: _manualEntryController,
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(t.operations.idle, textAlign: TextAlign.center, style: theme.textTheme.muted),
            ),
          ),
        ),
      ],
    );
  }
}
