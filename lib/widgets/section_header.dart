import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../i18n/gen/strings.g.dart';

/// A thin top bar for a screen pushed from DashboardScreen (e.g. HomeShell,
/// FrpScreen) - back button + title, styled like the rest of the app
/// (ghost button, card background) rather than a Material AppBar, which
/// would look out of place next to shadcn_ui everywhere else.
class SectionHeader extends StatelessWidget implements PreferredSizeWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              ShadButton.ghost(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Icon(LucideIcons.arrowLeft, semanticLabel: context.t.nav.back),
              ),
              const SizedBox(width: 4),
              Text(title, style: theme.textTheme.h4),
            ],
          ),
        ),
      ),
    );
  }
}
