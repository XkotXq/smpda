import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/scanner/barcode_scanner_service.dart';
import '../../l10n/strings.dart';

/// First cut of the scan screen: claims the hardware scanner, lists every
/// code read this session (newest first). Real screens (przyjęcie/wydanie
/// against wpsApi) build on top of this same onScan stream - this is here
/// so the Honeywell wiring can be smoke-tested on a real device before any
/// of that exists.
///
/// The manual-entry field at the top feeds the exact same stream a real
/// trigger-pull would (see BarcodeScannerService.simulateScan) - it's
/// always there, not just as a fallback when no hardware is found, so a
/// screen/flow built on top of onScan can be developed and clicked through
/// entirely on a PC, no PDA required, and still behaves identically once
/// real hardware is involved.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _codes = <String>[];
  final _manualEntryController = TextEditingController();
  StreamSubscription<String>? _scanSub;
  StreamSubscription<Object>? _errorSub;
  bool _hasHardwareScanner = false;

  @override
  void initState() {
    super.initState();
    _wire();
  }

  Future<void> _wire() async {
    final scanner = ref.read(barcodeScannerServiceProvider);
    final ok = await scanner.init();
    if (!mounted) return;
    setState(() => _hasHardwareScanner = ok);
    _scanSub = scanner.onScan.listen((code) {
      if (!mounted) return;
      setState(() => _codes.insert(0, code));
    });
    _errorSub = scanner.onError.listen((error) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text('$error')),
      );
    });
  }

  void _submitManualEntry() {
    final code = _manualEntryController.text.trim();
    if (code.isEmpty) return;
    ref.read(barcodeScannerServiceProvider).simulateScan(code);
    _manualEntryController.clear();
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
    final t = ref.watch(appStringsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_hasHardwareScanner)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(t('scan.noHardware'), style: theme.textTheme.muted),
                ),
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _manualEntryController,
                      placeholder: Text(t('scan.manualPlaceholder')),
                      onSubmitted: (_) => _submitManualEntry(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(
                    onPressed: _submitManualEntry,
                    child: Text(t('scan.simulate')),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _codes.isEmpty
              ? Center(
                  child: Text(
                    _hasHardwareScanner ? t('scan.waitingHardware') : t('scan.waitingManual'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _codes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return ShadCard(
                      padding: const EdgeInsets.all(12),
                      child: Text(_codes[index], style: theme.textTheme.p),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
