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
    FocusManager.instance.primaryFocus?.unfocus();
    final outcome = ref.read(receiveIssueControllerProvider.notifier).scan(code);
    switch (outcome) {
      case ScanStarted():
        context.push(materialsSmOperationPath);
      case ScanNotIssuable():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastNotIssuable)));
      case ScanUnknown():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastUnknown)));
      case ScanNeedsPick():
        context.push(materialsSmSpoolsPath);
    }
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
      ],
    );
  }
}
