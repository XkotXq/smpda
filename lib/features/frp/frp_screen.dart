import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/sm_spools_api.dart';
import '../../core/scanner/barcode_scanner_service.dart';
import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import '../../widgets/field_scroll_padding.dart';
import '../../widgets/require_online.dart';
import '../materials/scanned_code.dart';
import 'frp_label_screen.dart';

/// FRP module: the list of FRP that sits in stock without a spool number
/// (what still has to be labeled) and, on a scan of a spool's label, the
/// screen that gives it a number - see FrpLabelScreen.
class FrpScreen extends ConsumerStatefulWidget {
  const FrpScreen({super.key});

  @override
  ConsumerState<FrpScreen> createState() => _FrpScreenState();
}

class _FrpScreenState extends ConsumerState<FrpScreen> {
  final _manualEntryController = TextEditingController();
  StreamSubscription<String>? _scanSub;
  bool _scanning = false;

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
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _manualEntryController.dispose();
    super.dispose();
  }

  void _submitManualEntry() {
    final code = _manualEntryController.text.trim();
    if (code.isEmpty) return;
    ref.read(barcodeScannerServiceProvider).simulateScan(code);
    _manualEntryController.clear();
  }

  /// A scanned label: item number, batch and (last field) the spool's length.
  /// The item must still have unnumbered stock - checked against the server's
  /// current list, not what's on screen - and the next spool number is asked
  /// for right away so the label screen can show it.
  Future<void> _handleCode(String code) async {
    if (!mounted || _scanning) return;
    final t = context.t;
    FocusManager.instance.primaryFocus?.unfocus();
    final scanned = ScannedCode.parse(code);
    if (scanned.raw.isEmpty) return;
    setState(() => _scanning = true);
    try {
      // No connection: refuse the scan up front, with a message.
      if (!await requireOnline(context, ref)) return;
      final api = ref.read(smSpoolsApiProvider);
      final pending = await api.unlabeled();
      ref.invalidate(frpPendingProvider);
      final item = pending.where((p) => p.itemNo == scanned.itemNo).firstOrNull;
      if (item == null) {
        if (mounted) ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.frp.toastNotPending)));
        return;
      }
      final unitId = await api.next();
      if (!mounted) return;
      await context.push(
        frpLabelPath,
        extra: FrpLabelArgs(item: item, batch: scanned.batch, length: scanned.quantity, unitId: unitId),
      );
      ref.invalidate(frpPendingProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is SpoolApiError ? e.message : t.operations.toastLoadFailed;
      ShadToaster.of(context).show(ShadToast.destructive(description: Text(message)));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final pendingAsync = ref.watch(frpPendingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ShadInput(
                  scrollPadding: kFieldScrollPadding,
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
        if (_scanning)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShadProgress(),
                const SizedBox(height: 8),
                Text(t.operations.loadingStock, style: theme.textTheme.muted),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
          child: Row(
            children: [Expanded(child: Text(t.frp.listTitle, style: theme.textTheme.muted.copyWith(fontSize: 12)))],
          ),
        ),
        Expanded(
          child: pendingAsync.when(
            loading: () => const Center(child: ShadProgress()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.operations.toastLoadFailed, style: theme.textTheme.muted, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ShadButton.outline(onPressed: () => ref.invalidate(frpPendingProvider), child: Text(t.frp.retry)),
                  ],
                ),
              ),
            ),
            data: (items) => items.isEmpty
                ? Center(
                    child: Text(t.frp.listEmpty, style: theme.textTheme.muted, textAlign: TextAlign.center),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Container(height: 1, color: theme.colorScheme.border),
                    itemBuilder: (context, index) => _PendingRow(item: items[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.item});

  final FrpPending item;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemNo, style: theme.textTheme.p.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.itemName, style: theme.textTheme.muted.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trimQuantity(item.pendingQuantity),
                style: theme.textTheme.p.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (item.locationCode.isNotEmpty)
                Text(item.locationCode, style: theme.textTheme.muted.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
