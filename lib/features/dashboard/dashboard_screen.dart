import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/server_status.dart';
import '../../core/session/module_access.dart';
import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';
import '../../router.dart';

final _digitKeys = {
  LogicalKeyboardKey.digit1: 1,
  LogicalKeyboardKey.digit2: 2,
  LogicalKeyboardKey.digit3: 3,
  LogicalKeyboardKey.digit4: 4,
  LogicalKeyboardKey.digit5: 5,
  LogicalKeyboardKey.digit6: 6,
  LogicalKeyboardKey.digit7: 7,
  LogicalKeyboardKey.digit8: 8,
  LogicalKeyboardKey.digit9: 9,
  LogicalKeyboardKey.numpad1: 1,
  LogicalKeyboardKey.numpad2: 2,
  LogicalKeyboardKey.numpad3: 3,
  LogicalKeyboardKey.numpad4: 4,
  LogicalKeyboardKey.numpad5: 5,
  LogicalKeyboardKey.numpad6: 6,
  LogicalKeyboardKey.numpad7: 7,
  LogicalKeyboardKey.numpad8: 8,
  LogicalKeyboardKey.numpad9: 9,
};

/// First screen after login (GoRouter's own `redirect`, see router.dart,
/// sends here once AppSettings.isLoggedIn) - a picker list for this app's
/// modules, with a status bar (operator + server reachability) at the
/// bottom. Only two rows exist right now (Materiały SM, FRP).
///
/// Each row shows its own list position (1, 2, ...) - a Honeywell PDA has
/// physical number keys, so an operator can jump straight to a module
/// without touching the screen at all. `Focus.onKeyEvent` below matches
/// that digit against the row list, same index a screen tap would use.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    // Only the modules this person may use, numbered 1, 2, ... in that order -
    // a hidden one leaves no gap (the numbers are the PDA's number keys too).
    final tiles = [
      for (final module in ref.watch(availableModulesProvider))
        switch (module) {
          AppModule.materialsSm => (
            icon: LucideIcons.arrowLeftRight,
            title: t.dashboard.materialsSm.title,
            subtitle: t.dashboard.materialsSm.subtitle,
            onTap: () => context.push(materialsSmPath),
          ),
          AppModule.frp => (
            icon: LucideIcons.layers,
            title: t.dashboard.frp.title,
            subtitle: t.dashboard.frp.subtitle,
            onTap: () => context.push(frpPath),
          ),
          AppModule.orders => (
            icon: LucideIcons.truck,
            title: t.dashboard.orders.title,
            subtitle: t.dashboard.orders.subtitle,
            onTap: () => context.push(ordersPath),
          ),
        },
    ];

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (_tab != 0 || event is! KeyDownEvent) return KeyEventResult.ignored;
        final digit = _digitKeys[event.logicalKey];
        if (digit == null || digit > tiles.length) return KeyEventResult.ignored;
        tiles[digit - 1].onTap();
        return KeyEventResult.handled;
      },
      child: ColoredBox(
        color: theme.colorScheme.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tab == 0 ? t.dashboard.appTitle : t.dashboard.account.title,
                        style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
                      ),
                    ),
                    ShadButton.ghost(
                      onPressed: () => context.push(settingsPath),
                      child: Icon(LucideIcons.settings, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _tab == 0
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        children: [
                          Text(
                            t.dashboard.modules.toUpperCase(),
                            style: theme.textTheme.small.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          for (var i = 0; i < tiles.length; i++) ...[
                            if (i > 0) Container(height: 1, color: theme.colorScheme.border),
                            _DashboardRow(number: i + 1, tile: tiles[i]),
                          ],
                        ],
                      )
                    : const _AccountView(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.colorScheme.border)),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      icon: LucideIcons.layoutGrid,
                      label: t.dashboard.modules,
                      active: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                    _TabButton(
                      icon: LucideIcons.user,
                      label: t.dashboard.tabAccount,
                      active: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = active ? theme.colorScheme.primary : theme.colorScheme.mutedForeground;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.small.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Konto: who's signed in, whether wpsApi is reachable right now, and the
/// way out (logout - GoRouter's redirect sends the app back to /login).
class _AccountView extends ConsumerWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final settings = ref.watch(appSettingsProvider).value;
    final online = ref.watch(serverOnlineProvider).value;

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.muted)),
          value,
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        row(t.dashboard.account.operator, Text(settings?.operatorName ?? '', style: theme.textTheme.p)),
        Container(height: 1, color: theme.colorScheme.border),
        row(
          t.dashboard.account.status,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online == null
                      ? theme.colorScheme.mutedForeground
                      : online
                      ? const Color(0xFF34D399)
                      : theme.colorScheme.destructive,
                ),
              ),
              const SizedBox(width: 8),
              Text(online == false ? t.dashboard.offline : t.dashboard.online, style: theme.textTheme.p),
            ],
          ),
        ),
        Container(height: 1, color: theme.colorScheme.border),
        row(t.dashboard.account.server, Text(settings?.apiBaseUrl ?? '', style: theme.textTheme.p)),
        const SizedBox(height: 28),
        ShadButton.outline(
          onPressed: () => ref.read(appSettingsProvider.notifier).logout(),
          leading: Icon(LucideIcons.logOut, size: 18),
          child: Text(t.settings.logout),
        ),
      ],
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({required this.number, required this.tile});

  final int number;
  final ({IconData icon, String title, String subtitle, VoidCallback onTap}) tile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tile.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: theme.colorScheme.muted, borderRadius: BorderRadius.circular(10)),
              child: Text(
                '$number',
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(tile.icon, size: 26, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tile.title, style: theme.textTheme.h4),
                  const SizedBox(height: 2),
                  Text(
                    tile.subtitle,
                    style: theme.textTheme.muted.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.mutedForeground),
          ],
        ),
      ),
    );
  }
}
