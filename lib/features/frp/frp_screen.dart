import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';

/// Placeholder - not built yet (see DashboardScreen's own tile linking
/// here). Exists so the "FRP" destination is real and tappable rather than
/// a dead tile, honest about being unfinished instead of pretending to be
/// a working screen.
class FrpScreen extends StatelessWidget {
  const FrpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.t.frp.placeholder,
          style: theme.textTheme.muted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
