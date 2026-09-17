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
/// icon, not duplicated inside every section) - the header itself is the
/// Przyjęcie/Wydanie switch, styled like a browser's tab strip: the
/// active tab's background merges straight into the content below it,
/// the inactive one sits recessed in the strip behind it.
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
              decoration: BoxDecoration(color: theme.colorScheme.muted),
              child: Row(
                children: [
                  ShadButton.ghost(
                    onPressed: () => context.canPop() ? context.pop() : null,
                    child: Icon(LucideIcons.arrowLeft, semanticLabel: t.nav.back),
                  ),
                  _BrowserTab(
                    label: t.operations.modeReceive,
                    active: mode == FlowMode.receive,
                    onTap: () => controller.setMode(FlowMode.receive),
                  ),
                  _BrowserTab(
                    label: t.operations.modeIssue,
                    active: mode == FlowMode.issue,
                    onTap: () => controller.setMode(FlowMode.issue),
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

class _BrowserTab extends StatelessWidget {
  const _BrowserTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: active ? 0 : 6, right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.background : const Color(0x00000000),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.p.copyWith(
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? theme.colorScheme.foreground : theme.colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
