import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
/// sections. Only two rows exist right now (Materiały SM, FRP); add more
/// here as sections get built rather than growing HomeShell's own bottom
/// nav indefinitely.
///
/// Each row shows its own list position (1, 2, ...) - a Honeywell PDA has
/// physical number keys, so an operator can jump straight to a section
/// without touching the screen at all. `Focus.onKeyEvent` below matches
/// that digit against the row list, same index a screen tap would use.
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
        onTap: () => context.push(materialsSmPath),
      ),
      (
        icon: LucideIcons.layers,
        title: t.dashboard.frp.title,
        subtitle: t.dashboard.frp.subtitle,
        onTap: () => context.push(frpPath),
      ),
    ];

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
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
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(child: Text('SM', style: theme.textTheme.h3)),
                    ShadButton.ghost(
                      onPressed: () => context.push(settingsPath),
                      child: const Icon(LucideIcons.settings),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _DashboardRow(number: index + 1, tile: tiles[index]),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return ShadCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: theme.radius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tile.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$number',
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(tile.icon, size: 26, color: theme.colorScheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tile.title, style: theme.textTheme.h4),
                      Text(
                        tile.subtitle,
                        style: theme.textTheme.muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
