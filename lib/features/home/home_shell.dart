import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import '../../widgets/section_header.dart';
import '../materials/receive_issue_screen.dart';
import '../settings/settings_screen.dart';

/// Materiały SM section - pushed from DashboardScreen's own tile. Two
/// destinations behind a bottom bar of plain ShadButton.ghost icons (not
/// Material's NavigationBar, which would look and animate nothing like the
/// rest of a shadcn-styled app).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final destinations = [
      (icon: LucideIcons.scanLine, label: t.nav.operations),
      (icon: LucideIcons.settings, label: t.nav.settings),
    ];
    return ColoredBox(
      color: theme.colorScheme.background,
      child: Column(
        children: [
          SectionHeader(title: t.dashboard.materialsSm.title),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [ReceiveIssueScreen(), SettingsScreen()],
            ),
          ),
          SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                border: Border(top: BorderSide(color: theme.colorScheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ShadButton.ghost(
                        onPressed: () => setState(() => _index = i),
                        leading: Icon(
                          destinations[i].icon,
                          color: i == _index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.mutedForeground,
                        ),
                        child: Text(
                          destinations[i].label,
                          style: TextStyle(
                            color: i == _index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
