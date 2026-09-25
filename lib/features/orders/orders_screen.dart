import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';

/// Obsługa zamówień - transport orders for the forklift drivers. Placeholder:
/// the orders backend (wpsApi's orders module) is still a draft, so there is
/// nothing to list or take yet. Exists so the module is real and tappable
/// (with its own place in the dashboard's numbering and access rules) rather
/// than added later in one go.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(context.t.orders.placeholder, style: theme.textTheme.muted, textAlign: TextAlign.center),
      ),
    );
  }
}
