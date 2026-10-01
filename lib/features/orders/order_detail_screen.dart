import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/scanner/barcode_scanner_service.dart';
import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import '../../widgets/field_scroll_padding.dart';
import '../../widgets/require_online.dart';
import '../../widgets/section_header.dart';
import '../materials/receive_issue_controller.dart';
import '../materials/receive_issue_models.dart';
import 'orders_api.dart';

/// How often this screen re-fetches the order while it's on screen (on top
/// of the immediate refresh right after this device's own scan - see
/// _handleCode) - picks up a colleague's scan against the same order from
/// another PDA too, not just this one's.
const _pollInterval = Duration(seconds: 3);

/// One material_order's own checklist AND its scan-and-issue input in one
/// place (see orders_screen.dart's own comment on why only material_order
/// is listed) - required vs already-issued quantity per item, straight off
/// wpsapi's order_items_progress view (schema.sql), with a scan
/// input+button right above it, same idea as the ordinary Wydanie screen
/// (HomeShell/ReceiveIssueScreen) but scoped to this one order:
/// ReceiveIssueController.setOrderContext refuses (ScanNotInOrder) any
/// scan that resolves to a real, in-stock item that isn't one of this
/// order's own items, with its own toast - see that method's own comment.
/// A successful issue here tags its sm_operations row with this order's id,
/// which is what lets the checklist below auto-check the item off, no
/// manual mark needed.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _loading = true;
  bool _failed = false;
  TransportOrder? _order;
  Timer? _pollTimer;
  bool _polling = false;
  // setOrderContext resets the controller's whole state (see its own
  // comment) - fine once, right after the order's own item list is first
  // known, but must never run again on every poll tick after that: it
  // would wipe out whatever scan/pick is mid-flight the moment a poll
  // happens to land during it.
  bool _contextSet = false;

  final _manualController = TextEditingController();
  StreamSubscription<String>? _scanSub;
  StreamSubscription<Object>? _errorSub;
  bool _scanning = false;

  // Read once in initState (still safe - a normal build, not a teardown)
  // and kept for dispose()'s own sake, same pattern operation_screen.dart
  // already uses for its own TriggerCapture. Deliberately assigned here,
  // not as a lazy `late final = ref.read(...)` field: a lazy field's
  // initializer only runs on its *first* read, which - if that first read
  // happened to be from dispose() itself - would reproduce the exact same
  // crash confirmed live on device ("Using 'ref' when a widget is about to
  // or has been unmounted is unsafe"). Eagerly assigning it here instead
  // guarantees that first read always happens while the widget is safely
  // mounted, regardless of what _load()/_handleCode do or don't call
  // afterwards.
  late final ReceiveIssueController _receiveIssueController;

  @override
  void initState() {
    super.initState();
    _receiveIssueController = ref.read(receiveIssueControllerProvider.notifier);
    _load();
    _wireScanner();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scanSub?.cancel();
    _errorSub?.cancel();
    _manualController.dispose();
    // Leaving this screen - see ReceiveIssueController.clearOrderContext's
    // own comment on why this is safe to call unconditionally.
    _receiveIssueController.clearOrderContext();
    super.dispose();
  }

  Future<void> _wireScanner() async {
    final scanner = ref.read(barcodeScannerServiceProvider);
    await scanner.init();
    if (!mounted) return;
    _scanSub = scanner.onScan.listen(_handleCode);
    _errorSub = scanner.onError.listen((error) {
      if (!mounted) return;
      ShadToaster.of(context).show(ShadToast.destructive(description: Text('$error')));
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final order = await ref.read(ordersApiProvider).get(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
      _ensureOrderContext(order);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  /// The background tick behind "od razu mają się aktualizować" - unlike
  /// _load(), a failure here is silent (stays on whatever was last shown)
  /// and the loading state is never re-shown, so a poll never interrupts a
  /// scan in progress.
  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final order = await ref.read(ordersApiProvider).get(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
      _ensureOrderContext(order);
    } catch (_) {
      // Stay on whatever was last shown.
    } finally {
      _polling = false;
    }
  }

  void _ensureOrderContext(TransportOrder order) {
    if (_contextSet) return;
    _contextSet = true;
    _receiveIssueController.setOrderContext(widget.orderId, {
          // Already formatted ("5 szt.") - see ReceiveIssueState.
          // orderItemQuantities' own comment; shown as-is on
          // OperationScreen while confirming an issue from this order.
          for (final item in order.items) item.itemNo: '${item.quantity} ${item.unit}'.trim(),
        });
  }

  void _scanItemNo(String code) {
    ref.read(barcodeScannerServiceProvider).simulateScan(code);
    _manualController.clear();
  }

  void _submitManual() {
    final code = _manualController.text.trim();
    if (code.isNotEmpty) _scanItemNo(code);
  }

  Future<void> _handleCode(String code) async {
    if (!mounted || _scanning) return;
    final t = context.t;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _scanning = true);
    final online = await requireOnline(context, ref);
    if (mounted) setState(() => _scanning = false);
    if (!online || !mounted) return;

    setState(() => _scanning = true);
    final ScanOutcome outcome;
    try {
      outcome = await _receiveIssueController.scan(code);
    } catch (_) {
      if (mounted) ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastLoadFailed)));
      return;
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
    if (!mounted) return;
    switch (outcome) {
      case ScanStarted():
        await context.push(materialsSmOperationPath);
        if (mounted) _load();
      case ScanNeedsPick():
        await context.push(materialsSmSpoolsPath);
        if (mounted) _load();
      case ScanNotIssuable():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastNotIssuable)));
      case ScanUnknown():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastUnknown)));
      case ScanNotInOrder():
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(t.operations.toastNotInOrder)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;

    Widget body;
    if (_loading) {
      body = const Center(child: ShadProgress());
    } else if (_failed || _order == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.orders.loadError, style: theme.textTheme.muted, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ShadButton.outline(onPressed: _load, child: Text(t.orders.retry)),
            ],
          ),
        ),
      );
    } else {
      final order = _order!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.to != null)
                  Text('${t.orders.line}: ${order.to}', style: theme.textTheme.muted.copyWith(fontSize: 13)),
                if (order.productionOrderNo != null)
                  Text('${t.orders.productionOrderNo}: ${order.productionOrderNo}', style: theme.textTheme.muted.copyWith(fontSize: 13)),
              ],
            ),
          ),
          // Scan input + button, same idea as HomeShell's own Wydanie
          // input (ReceiveIssueScreen) - just without that one's
          // whole-catalog suggestion dropdown, which would only tempt a
          // pick that gets refused anyway (see ScanNotInOrder).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    scrollPadding: kFieldScrollPadding,
                    controller: _manualController,
                    placeholder: Text(t.operations.scanPlaceholder),
                    onSubmitted: (_) => _submitManual(),
                  ),
                ),
                const SizedBox(width: 8),
                ShadButton(onPressed: _submitManual, child: const Icon(LucideIcons.scanLine)),
              ],
            ),
          ),
          if (_scanning)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShadProgress(),
                  const SizedBox(height: 8),
                  Text(t.operations.loadingStock, style: theme.textTheme.muted),
                ],
              ),
            ),
          // "po zeskanowaniu wszystkich materiałów w zamówieniu ma być
          // stosowny status" - a clear banner once every item's own
          // isFulfilled is true, on top of each item's own checkmark below.
          // Nothing to press here - "Dostarczone" (in_progress -> delivered)
          // is smVendor's own action, not smpda's; this just tells the
          // operator they're done here.
          if (order.items.isNotEmpty && order.items.every((i) => i.isFulfilled))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.circleCheck, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.orders.detail.allIssued,
                        style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(t.orders.detail.itemsTitle, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: order.items.length,
              separatorBuilder: (_, _) => Container(height: 1, color: theme.colorScheme.border),
              itemBuilder: (context, index) => _OrderItemRow(item: order.items[index]),
            ),
          ),
        ],
      );
    }

    return ColoredBox(
      color: theme.colorScheme.background,
      child: Column(
        children: [
          SectionHeader(title: _order?.orderNo ?? '...'),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.detail;
    final fulfilled = item.isFulfilled;
    final required = '${item.quantity} ${item.unit}'.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            fulfilled ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 20,
            color: fulfilled ? theme.colorScheme.primary : theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: theme.textTheme.p.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: fulfilled ? TextDecoration.lineThrough : null,
                    color: fulfilled ? theme.colorScheme.mutedForeground : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.itemNo, style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // order_items.unit is always "szt." (a piece-count the order
              // itself asked for - purely informational, kept as-is here)
              // - but what actually gets scanned/issued through this
              // screen is real stock, labeled with item.displayIssuedUnit
              // instead (the catalog's own unit - km for FRP, since the
              // floor wants to see the actual length issued here, not the
              // drum count isFulfilled uses - see that getter's own
              // comment).
              Text(required, style: theme.textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
              if ((double.tryParse(item.issuedQuantity) ?? 0) > 0) ...[
                const SizedBox(height: 2),
                Text(
                  t.issued(value: '${trimQuantity(item.displayIssuedQuantity)} ${item.displayIssuedUnit}'.trim()),
                  style: theme.textTheme.muted.copyWith(fontSize: 12, color: theme.colorScheme.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
