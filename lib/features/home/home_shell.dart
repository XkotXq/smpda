import 'package:flutter/services.dart' show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import '../materials/receive_issue_controller.dart';
import '../materials/receive_issue_models.dart';
import '../materials/receive_issue_screen.dart';

/// Materiały SM section - pushed from DashboardScreen's own tile. No
/// bottom nav here (Settings is reached from the dashboard's own gear
/// icon, not duplicated inside every section). A short title bar (back
/// button + section name) sits above a compact Przyjęcie/Wydanie switch
/// - two plain rows kept small on purpose, this screen runs on a small
/// PDA panel and the scan/queue content below needs the space more.
///
/// The PDA's arrow keys switch the mode without touching the screen: left =
/// Przyjęcie (the left button), right = Wydanie (the right one).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    // A global handler rather than a Focus widget: the manual-entry field on
    // this screen would otherwise swallow the arrows (caret movement).
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Only while this screen is the one being shown - not under the
    // operation / spool screens pushed on top of it.
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    final FlowMode mode;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      mode = FlowMode.receive;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      mode = FlowMode.issue;
    } else {
      return false;
    }
    ref.read(receiveIssueControllerProvider.notifier).setMode(mode);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final mode = ref.watch(receiveIssueControllerProvider.select((s) => s.mode));
    final controller = ref.read(receiveIssueControllerProvider.notifier);

    return _keyGuard(
      ColoredBox(
        color: theme.colorScheme.background,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // The title bar and mode buttons take taps only - never keyboard focus,
              // so the PDA's arrow/number keys don't draw a focus ring on them.
              ExcludeFocus(
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
                            Expanded(child: Text(t.dashboard.materialsSm.title, style: theme.textTheme.h4)),
                            ShadButton.ghost(
                              size: ShadButtonSize.sm,
                              onPressed: () => context.push(historyIssuesPath),
                              child: Icon(LucideIcons.history, size: 18, semanticLabel: t.history.issuesTitle),
                            ),
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
                              icon: LucideIcons.arrowLeft,
                              iconFirst: true,
                              active: mode == FlowMode.receive,
                              onTap: () => controller.setMode(FlowMode.receive),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ModeButton(
                              label: t.operations.modeIssue,
                              icon: LucideIcons.arrowRight,
                              iconFirst: false,
                              active: mode == FlowMode.issue,
                              onTap: () => controller.setMode(FlowMode.issue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: ReceiveIssueScreen()),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps the arrow keys from also moving keyboard focus (Flutter's default:
  /// arrows = directional focus) - that focus would land on the manual-entry
  /// field and pop up the on-screen keyboard. Something on this screen holds
  /// focus at all times so the keys reach this guard.
  Widget _keyGuard(Widget child) {
    return Focus(
      autofocus: true,
      skipTraversal: true,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationIntent(),
        },
        child: child,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.active,
    required this.onTap,
  });

  final String label;

  /// The arrow key that picks this mode - shown as a hint on the button.
  final IconData icon;
  final bool iconFirst;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadButton(
      size: ShadButtonSize.sm,
      backgroundColor: active ? null : ShadTheme.of(context).colorScheme.secondary,
      foregroundColor: active ? null : ShadTheme.of(context).colorScheme.secondaryForeground,
      onPressed: onTap,
      leading: iconFirst ? Icon(icon, size: 16) : null,
      trailing: iconFirst ? null : Icon(icon, size: 16),
      child: Text(label),
    );
  }
}
