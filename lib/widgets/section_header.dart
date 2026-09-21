import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../i18n/gen/strings.g.dart';

/// A thin top bar for a screen pushed from DashboardScreen (e.g. HomeShell,
/// FrpScreen) - back button + title, styled like the rest of the app
/// (ghost button, card background) rather than a Material AppBar, which
/// would look out of place next to shadcn_ui everywhere else.
class SectionHeader extends StatelessWidget implements PreferredSizeWidget {
  const SectionHeader({super.key, required this.title, this.actions = const []});

  final String title;

  /// Buttons at the right end of the bar (e.g. an icon-only history button).
  final List<Widget> actions;

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
                onPressed: () => context.canPop() ? context.pop() : null,
                child: Icon(LucideIcons.arrowLeft, semanticLabel: context.t.nav.back),
              ),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: theme.textTheme.h4)),
              ...actions,
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
