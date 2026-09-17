import 'package:flutter/material.dart' show InkWell, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import '../../widgets/section_scaffold.dart';
import '../frp/frp_screen.dart';
import '../home/home_shell.dart';
import '../settings/settings_screen.dart';

/// First screen after login (see AuthGate in app.dart) - a tile picker for
/// this app's sections. Only two tiles exist right now (Materiały SM,
/// FRP); add more here as sections get built rather than growing
/// HomeShell's own bottom nav indefinitely.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final tiles = [
      (
        icon: LucideIcons.arrowLeftRight,
        title: t.dashboard.materialsSm.title,
        subtitle: t.dashboard.materialsSm.subtitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        ),
      ),
      (
        icon: LucideIcons.layers,
        title: t.dashboard.frp.title,
        subtitle: t.dashboard.frp.subtitle,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SectionScaffold(title: t.dashboard.frp.title, body: const FrpScreen()),
          ),
        ),
      ),
    ];

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(child: Text('SM', style: theme.textTheme.h3)),
                  ShadButton.ghost(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: const Icon(LucideIcons.settings),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
                children: [for (final tile in tiles) _DashboardTile(tile: tile)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.tile});

  final ({IconData icon, String title, String subtitle, VoidCallback onTap}) tile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: theme.radius,
        child: InkWell(
          onTap: tile.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tile.icon, size: 36, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(tile.title, style: theme.textTheme.h4, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  tile.subtitle,
                  style: theme.textTheme.muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
