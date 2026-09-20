import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';
import '../../router.dart';
import 'receive_issue_controller.dart';

/// Wydanie of an item that lives on numbered spools (FRP): pick which spool
/// and issue it in one tap - a spool always goes out whole, so there's no
/// quantity to type. "Brak numeru szpuli" is the way out for stock that was
/// received without a spool number (the unmarked remainder), which can be
/// issued partially and so continues on the normal quantity screen.
class SpoolPickerScreen extends ConsumerStatefulWidget {
  const SpoolPickerScreen({super.key});

  @override
  ConsumerState<SpoolPickerScreen> createState() => _SpoolPickerScreenState();
}

class _SpoolPickerScreenState extends ConsumerState<SpoolPickerScreen> {
  String? _selected;

  /// Set right before this screen leaves by itself (spool issued, or handed
  /// over to the quantity screen) - both clear `pick`, which must not also
  /// trigger the "nothing to show, pop" fallback in build().
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final units = ref.read(receiveIssueControllerProvider).pick?.units ?? const [];
    if (units.length == 1) _selected = units.first.unitId;
  }

  void _back() {
    ref.read(receiveIssueControllerProvider.notifier).cancelPick();
    context.pop();
  }

  Future<void> _issue() async {
    final selected = _selected;
    if (selected == null) return;
    final t = context.t;
    _leaving = true;
    final ok = await ref.read(receiveIssueControllerProvider.notifier).issueSpool(selected);
    if (!ok) _leaving = false;
    if (!mounted) return;
    if (ok) {
      ShadToaster.of(context).show(ShadToast(description: Text(t.operations.submitted)));
      context.pop();
    } else {
      final error = ref.read(receiveIssueControllerProvider).error;
      if (error != null) ShadToaster.of(context).show(ShadToast.destructive(description: Text(error)));
    }
  }

  void _noSpoolNumber() {
    _leaving = true;
    ref.read(receiveIssueControllerProvider.notifier).startPendingIssue();
    context.pushReplacement(materialsSmOperationPath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final state = ref.watch(receiveIssueControllerProvider);
    final pick = state.pick;

    if (pick == null) {
      if (_leaving) return const SizedBox.shrink();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.canPop()) context.pop();
      });
      return const SizedBox.shrink();
    }

    final divider = Container(height: 1, color: theme.colorScheme.border);

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      onPressed: _back,
                      child: Icon(LucideIcons.arrowLeft, size: 18, semanticLabel: t.nav.back),
                    ),
                    const SizedBox(width: 4),
                    Text(t.operations.modeIssue, style: theme.textTheme.h4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.operations.material, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(pick.itemNo, style: theme.textTheme.h3.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(pick.itemName, style: theme.textTheme.muted.copyWith(fontSize: 16)),
                ],
              ),
            ),
            divider,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(t.operations.pickSpool, style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: pick.units.length,
                separatorBuilder: (_, __) => divider,
                itemBuilder: (context, index) {
                  final unit = pick.units[index];
                  final selected = unit.unitId == _selected;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selected = unit.unitId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.muted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unit.unitId,
                              style: theme.textTheme.p.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          Text(trimQuantity(unit.quantity), style: theme.textTheme.muted.copyWith(fontSize: 18)),
                          const SizedBox(width: 12),
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? theme.colorScheme.primary : theme.colorScheme.foreground,
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.border))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pick.pendingQuantity != null) ...[
                        ShadButton.outline(
                          onPressed: state.submitting ? null : _noSpoolNumber,
                          leading: const Icon(LucideIcons.circleSlash, size: 18),
                          child: Text(t.operations.noSpoolNumber),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ShadButton(
                        enabled: _selected != null && !state.submitting,
                        onPressed: _selected == null || state.submitting ? null : _issue,
                        leading: state.submitting ? null : const Icon(LucideIcons.check, size: 18),
                        child: Text(state.submitting ? t.operations.submitting : t.operations.confirm),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
