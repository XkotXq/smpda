import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import '../materials/receive_issue_controller.dart';
import '../materials/receive_issue_models.dart';
import '../materials/receive_issue_screen.dart';

/// Materiały SM section - pushed from DashboardScreen's own tile. No
/// bottom nav here (Settings is reached from the dashboard's own gear
/// icon, not duplicated inside every section). A short title bar (back
/// button + section name) sits above a compact Przyjęcie/Wydanie switch
/// - two plain rows kept small on purpose, this screen runs on a small
/// PDA panel and the scan/queue content below needs the space more.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final mode = ref.watch(receiveIssueControllerProvider.select((s) => s.mode));
    final controller = ref.read(receiveIssueControllerProvider.notifier);

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
              ),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () => context.canPop() ? context.pop() : null,
                      child: Icon(LucideIcons.arrowLeft, size: 18, semanticLabel: t.nav.back),
                    ),
                    const SizedBox(width: 4),
                    Text(t.dashboard.materialsSm.title, style: theme.textTheme.h4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: t.operations.modeReceive,
                      active: mode == FlowMode.receive,
                      onTap: () => controller.setMode(FlowMode.receive),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeButton(
                      label: t.operations.modeIssue,
                      active: mode == FlowMode.issue,
                      onTap: () => controller.setMode(FlowMode.issue),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: ReceiveIssueScreen()),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadButton(
      size: ShadButtonSize.sm,
      backgroundColor: active ? null : ShadTheme.of(context).colorScheme.secondary,
      foregroundColor: active ? null : ShadTheme.of(context).colorScheme.secondaryForeground,
      onPressed: onTap,
      child: Text(label),
    );
  }
}
