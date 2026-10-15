import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import 'orders_api.dart';

/// How often this screen re-fetches - a new order taken in smVendor (or one
/// finished by a colleague on another PDA) shows up/disappears on its own,
/// no manual pull-to-refresh needed.
const _pollInterval = Duration(seconds: 3);

/// Obsługa zamówień - the working queue of "Zamówienie materiału" orders a
/// forklift driver has taken in smVendor (status in_progress or problem -
/// see wpsapi's
/// AGENTS.md "Transport orders"/takeOrder). Only material_order is listed:
/// it is the only type with real order_items backed by sm_catalog (a
/// spool_order's own items are arbitrary spool labels, not stock this
/// screen's scan-and-issue flow knows how to look up - see schema.sql's own
/// comment on order_items). Tapping an order opens its checklist
/// (OrderDetailScreen) - **and so does Enter**, because this device has
/// real keys: up/down move the selection and Enter opens it (asked
/// 2026-10-15), the same reason the dashboard answers its number keys. An
/// operator holding a scanner in one hand should not have to find a row
/// with a thumb.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _loading = true;
  bool _failed = false;
  List<TransportOrder> _orders = const [];
  Timer? _pollTimer;
  bool _polling = false;

  /// Which order the arrows are on, **by id and not by index**: this list
  /// is replaced every three seconds and an order finished on another PDA
  /// drops out of it, so an index would quietly come to mean a different
  /// order - and Enter would open the one nobody selected.
  String? _selectedId;

  /// Owned rather than left to `autofocus` alone, because focus has to be
  /// taken back when the detail screen pops: without that the arrows do
  /// nothing until the screen is tapped, which is the very tap this is
  /// here to remove.
  final _keyboardFocus = FocusNode();

  /// One per row, so the selected row can be scrolled to. Keyed by order
  /// id for the same reason the selection is.
  final _rowKeys = <String, GlobalKey>{};

  /// Which way the last move went, so the list scrolls **the least that
  /// works** - to the bottom edge going down, the top edge going up -
  /// instead of centring the row and shifting the page under the operator
  /// on every press.
  bool _movingDown = true;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _keyboardFocus.dispose();
    super.dispose();
  }

  /// Keeps the selection pointing at an order that is really there.
  ///
  /// Run on every list change: nothing selected yet selects the first, so
  /// the arrows work on the first press with no dead one to learn about,
  /// and a selection whose order is gone falls back to the first rather
  /// than to nothing.
  void _keepSelectionValid() {
    if (_orders.isEmpty) {
      _selectedId = null;
      return;
    }
    if (_selectedId == null || !_orders.any((o) => o.id == _selectedId)) {
      _selectedId = _orders.first.id;
    }
  }

  /// Move the selection by one row. Clamped at both ends, **no wrapping** -
  /// the same rule wps's own list keyboard follows, and on a queue that
  /// reorders itself wrapping would read as a jump to an unrelated order.
  void _move(int by) {
    if (_orders.isEmpty) return;
    final current = _orders.indexWhere((o) => o.id == _selectedId);
    final next = (current < 0 ? 0 : current + by).clamp(0, _orders.length - 1);
    if (next == current) return;
    setState(() {
      _movingDown = by > 0;
      _selectedId = _orders[next].id;
    });
    _scrollToSelected();
  }

  /// After the frame that moved the highlight, not during it: the row may
  /// not be laid out yet, and one scrolled out of the list has no context
  /// at all.
  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rowContext = _rowKeys[_selectedId]?.currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(
        rowContext,
        duration: const Duration(milliseconds: 120),
        alignmentPolicy: _movingDown
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  /// Open whatever is selected. Shared by Enter and a tap so the two cannot
  /// drift apart - taking focus back afterwards included.
  Future<void> _open(TransportOrder order) async {
    setState(() => _selectedId = order.id);
    await context.push(ordersDetailPathFor(order.id));
    if (!mounted) return;
    _keyboardFocus.requestFocus();
    _load();
  }

  /// 'problem' counts as in progress here on purpose: the forklift
  /// operator flagging something (smVendor's "Zgłoś problem") blocks the
  /// *delivery*, not the issuing - and the flag is quite often about the
  /// stock itself ("brakuje materiału"), which is this screen's business.
  /// Dropping a half-issued order off the warehouse's queue because
  /// somebody else reported something would be the wrong surprise.
  List<TransportOrder> _inProgressMaterialOrders(List<TransportOrder> all) => [
    for (final o in all)
      if (o.type == 'material_order' && (o.status == 'inProgress' || o.status == 'problem')) o,
  ];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final all = await ref.read(ordersApiProvider).list('active');
      if (!mounted) return;
      setState(() {
        _orders = _inProgressMaterialOrders(all);
        _loading = false;
        _keepSelectionValid();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  /// The background tick behind "od razu mają się aktualizować" - silent on
  /// failure (stays on the last good list) and never re-shows the loading
  /// state, so a poll never interrupts the operator mid-tap.
  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final all = await ref.read(ordersApiProvider).list('active');
      if (!mounted) return;
      setState(() {
        _orders = _inProgressMaterialOrders(all);
        _keepSelectionValid();
      });
    } catch (_) {
      // Stay on whatever was last shown.
    } finally {
      _polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders;

    if (_loading) return const Center(child: ShadProgress());
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.loadError, style: theme.textTheme.muted, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ShadButton.outline(onPressed: _load, child: Text(t.retry)),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(child: Text(t.empty, style: theme.textTheme.muted, textAlign: TextAlign.center));
    }

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: (node, event) {
        // Repeats count: holding an arrow walks the queue, which is what
        // a held key is for.
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowDown:
            _move(1);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowUp:
            _move(-1);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.numpadEnter:
            final selected = _orders.where((o) => o.id == _selectedId).firstOrNull;
            if (selected == null) return KeyEventResult.ignored;
            _open(selected);
            return KeyEventResult.handled;
          default:
            return KeyEventResult.ignored;
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _orders.length,
        separatorBuilder: (_, _) => Container(height: 1, color: theme.colorScheme.border),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final fulfilled = order.items.where((i) => i.isFulfilled).length;
          final selected = order.id == _selectedId;
          return GestureDetector(
            key: _rowKeys.putIfAbsent(order.id, GlobalKey.new),
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(order),
            child: Container(
              // The highlight is the whole point of the arrows: a selection
              // nothing shows is a key press that did nothing.
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: selected
                  ? BoxDecoration(
                      color: theme.colorScheme.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.primary),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderNo, style: theme.textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        if (order.to != null) Text('${t.line}: ${order.to}', style: theme.textTheme.muted.copyWith(fontSize: 13)),
                        if (order.productionOrderNo != null)
                          Text('${t.productionOrderNo}: ${order.productionOrderNo}', style: theme.textTheme.muted.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Green + a check once every item's own isFulfilled is true
                  // (same "wszystko wydane" signal as OrderDetailScreen's own
                  // banner) - a plain count the rest of the time.
                  if (fulfilled == order.items.length && order.items.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.circleCheck, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          t.allIssuedBadge,
                          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                        ),
                      ],
                    )
                  else
                    Text(
                      '$fulfilled/${order.items.length} ${t.items}',
                      style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(width: 6),
                  Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.mutedForeground),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
