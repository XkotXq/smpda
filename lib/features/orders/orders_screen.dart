import 'dart:async';

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
/// (OrderDetailScreen).
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

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
      setState(() => _orders = _inProgressMaterialOrders(all));
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _orders.length,
      separatorBuilder: (_, _) => Container(height: 1, color: theme.colorScheme.border),
      itemBuilder: (context, index) {
        final order = _orders[index];
        final fulfilled = order.items.where((i) => i.isFulfilled).length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await context.push(ordersDetailPathFor(order.id));
            if (mounted) _load();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}
