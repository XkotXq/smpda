import 'dart:async';

import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/models/sm_item.dart';
import '../../core/api/sm_catalog_api.dart';
import '../../core/scanner/barcode_scanner_service.dart';
import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import '../../widgets/enter_to_next.dart';
import '../../widgets/field_scroll_padding.dart';
import '../../widgets/require_online.dart';
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

  /// Which suggestion the up/down arrows have moved to, or -1 for none -
  /// Enter (via EnterToNext -> _submitManualEntry) picks this one instead of
  /// falling back to the "exactly one match"/raw-code logic. Reset whenever
  /// the typed text changes, since the suggestion list itself changes too.
  int _selectedIndex = -1;
  final _suggestionKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _manualEntryController.addListener(_onQueryChanged);
    _wire();
  }

  void _onQueryChanged() {
    if (_selectedIndex != -1) setState(() => _selectedIndex = -1);
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

  /// Items matching what's typed so far: the typed text anywhere in the item
  /// number - or, when it isn't only digits, in the name. Przyjęcie looks in
  /// the whole catalog (anything can be received), Wydanie only in what is in
  /// stock. Read from the lists already loaded; the scan that follows a pick
  /// re-reads the item from the server as always.
  List<({String itemNo, String itemName})> _suggestions() {
    final query = _manualEntryController.text.trim().toLowerCase();
    if (query.length < 2) return const [];
    final byName = query.contains(RegExp(r'[^0-9]'));
    final mode = ref.read(receiveIssueControllerProvider).mode;
    final all = mode == FlowMode.issue
        ? [
            for (final item in ref.read(smItemsListProvider).value ?? const <SmItem>[])
              (itemNo: item.itemNo, itemName: item.itemName),
          ]
        : [
            for (final entry in ref.read(smCatalogListProvider).value ?? const <SmCatalogItem>[])
              (itemNo: entry.itemNo, itemName: entry.itemName),
          ];
    final matches = all.where(
      (e) => e.itemNo.toLowerCase().contains(query) || (byName && e.itemName.toLowerCase().contains(query)),
    );
    // Item numbers starting with the text first.
    final sorted = matches.toList()
      ..sort((a, b) {
        final aStarts = a.itemNo.toLowerCase().startsWith(query) ? 0 : 1;
        final bStarts = b.itemNo.toLowerCase().startsWith(query) ? 0 : 1;
        return aStarts != bStarts ? aStarts - bStarts : a.itemNo.compareTo(b.itemNo);
      });
    return sorted.take(8).toList();
  }

  void _scanItemNo(String code) {
    ref.read(barcodeScannerServiceProvider).simulateScan(code);
    _manualEntryController.clear();
  }

  void _submitManualEntry() {
    final matches = _suggestions();
    // The arrows picked one - that wins over everything else below.
    if (_selectedIndex >= 0 && _selectedIndex < matches.length) {
      _scanItemNo(matches[_selectedIndex].itemNo);
      return;
    }
    final code = _manualEntryController.text.trim();
    if (code.isEmpty) return;
    // A partial number that leaves exactly one candidate is that item.
    if (matches.length == 1 && matches.first.itemNo != code) {
      _scanItemNo(matches.first.itemNo);
      return;
    }
    _scanItemNo(code);
  }

  /// The PDA's up/down arrows move the highlighted suggestion (no
  /// wrap-around; with nothing highlighted yet, down picks the first
  /// suggestion, up the last) - same rule as the spool picker's own arrow
  /// handling. Left/right (mode switch on the modules screen above this one)
  /// and everything else is left alone.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    if (!down && event.logicalKey != LogicalKeyboardKey.arrowUp) return KeyEventResult.ignored;

    final matches = _suggestions();
    if (matches.isEmpty) return KeyEventResult.ignored;
    final next = _selectedIndex == -1
        ? (down ? 0 : matches.length - 1)
        : (_selectedIndex + (down ? 1 : -1)).clamp(0, matches.length - 1);
    setState(() => _selectedIndex = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rowContext = _suggestionKeys[matches[next].itemNo]?.currentContext;
      if (rowContext != null) Scrollable.ensureVisible(rowContext, duration: const Duration(milliseconds: 120));
    });
    return KeyEventResult.handled;
  }

  /// One scan at a time - the item is re-read from the server (a moment,
  /// shown as a loading bar), and a second trigger pull meanwhile must not
  /// start another.
  bool _scanning = false;

  Future<void> _handleCode(String code) async {
    if (!mounted || _scanning) return;
    final t = context.t;
    FocusManager.instance.primaryFocus?.unfocus();
    // No connection: nothing can be read (name, stock) or saved, so the scan is
    // refused here, with a message, instead of failing halfway through.
    setState(() => _scanning = true);
    final online = await requireOnline(context, ref);
    if (mounted) setState(() => _scanning = false);
    if (!online || !mounted) return;
    if (ref.read(receiveIssueControllerProvider).mode == FlowMode.receive) return _handleReceive(code);
    setState(() => _scanning = true);
    final ScanOutcome outcome;
    try {
      outcome = await ref.read(receiveIssueControllerProvider.notifier).scan(code);
    } catch (_) {
      if (mounted) ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastLoadFailed)));
      return;
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
    if (!mounted) return;
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

  /// Przyjęcie: the operation opens right away with the scanned item number;
  /// the name (and the rest) is filled in as soon as the server answers. An
  /// item that turns out to be unknown closes it again with a message.
  Future<void> _handleReceive(String code) async {
    final t = context.t;
    final controller = ref.read(receiveIssueControllerProvider.notifier);
    if (controller.startReceive(code) is! ScanStarted) {
      ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastUnknown)));
      return;
    }
    _scanning = true;
    context.push(materialsSmOperationPath);
    final toaster = ShadToaster.of(context);
    try {
      if (await controller.resolveReceive() is ScanUnknown) {
        controller.cancelCurrent();
        toaster.show(ShadToast.destructive(description: Text(t.operations.toastUnknown)));
      }
    } catch (_) {
      controller.cancelCurrent();
      toaster.show(ShadToast.destructive(description: Text(t.operations.toastLoadFailed)));
    } finally {
      _scanning = false;
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _errorSub?.cancel();
    _manualEntryController.removeListener(_onQueryChanged);
    _manualEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    ref.watch(smItemsListProvider);
    ref.watch(smCatalogListProvider);
    // Rebuild on a mode switch too: the suggestions come from a different list.
    ref.watch(receiveIssueControllerProvider.select((s) => s.mode));

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: EnterToNext(
                    isLast: true,
                    onLast: _submitManualEntry,
                    child: ShadInput(
                      scrollPadding: kFieldScrollPadding,
                      controller: _manualEntryController,
                      placeholder: Text(t.operations.scanPlaceholder),
                      onSubmitted: (_) => _submitManualEntry(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ShadButton(onPressed: _submitManualEntry, child: Icon(LucideIcons.scanLine)),
              ],
            ),
          ),
          if (_scanning)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShadProgress(),
                  const SizedBox(height: 8),
                  Text(t.operations.loadingStock, style: ShadTheme.of(context).textTheme.muted),
                ],
              ),
            ),
          // Matching items under the input as it's typed - tap one to open it.
          Expanded(
            child: ListenableBuilder(
              listenable: _manualEntryController,
              builder: (context, _) {
                final matches = _suggestions();
                if (matches.isEmpty) return const SizedBox.shrink();
                final theme = ShadTheme.of(context);
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => Container(height: 1, color: theme.colorScheme.border),
                  itemBuilder: (context, index) {
                    final selected = index == _selectedIndex;
                    return GestureDetector(
                      key: _suggestionKeys.putIfAbsent(matches[index].itemNo, GlobalKey.new),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _scanItemNo(matches[index].itemNo),
                      child: Container(
                        color: selected ? theme.colorScheme.muted : null,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              matches[index].itemNo,
                              style: theme.textTheme.p.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(matches[index].itemName, style: theme.textTheme.muted.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
