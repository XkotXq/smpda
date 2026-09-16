import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../scan/scan_screen.dart';
import '../settings/settings_screen.dart';

/// Simplest possible shell for now: three destinations behind a bottom bar
/// of plain ShadButton.ghost icons (not Material's NavigationBar, which
/// would look and animate nothing like the rest of a shadcn-styled app).
/// Swap this out once there's a real navigation structure (przyjęcie/
/// wydanie flows, most likely a proper router) - it's a placeholder for
/// "there are screens and you can move between them", not a final IA.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (icon: LucideIcons.scanLine, label: 'Skanuj'),
    (icon: LucideIcons.settings, label: 'Ustawienia'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [ScanScreen(), SettingsScreen()],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                border: Border(top: BorderSide(color: theme.colorScheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < _destinations.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ShadButton.ghost(
                        onPressed: () => setState(() => _index = i),
                        leading: Icon(
                          _destinations[i].icon,
                          color: i == _index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.mutedForeground,
                        ),
                        child: Text(
                          _destinations[i].label,
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
          ],
        ),
      ),
    );
  }
}
