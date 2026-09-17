import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import 'receive_issue_controller.dart';
import 'receive_issue_models.dart';

/// Pushed (via go_router - see materialsSmOperationPath in router.dart) the
/// moment a scan resolves to a receive/issue candidate - its own full
/// screen so there's nothing else on it: which mode this is under (title),
/// then the item's number, name, [available quantity for an issue] and the
/// quantity to confirm.
class OperationScreen extends ConsumerStatefulWidget {
  const OperationScreen({super.key});

  @override
  ConsumerState<OperationScreen> createState() => _OperationScreenState();
}

class _OperationScreenState extends ConsumerState<OperationScreen> {
  final _quantityController = TextEditingController();
  final _quantityFocusNode = FocusNode();
  final _unitIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final op = ref.read(receiveIssueControllerProvider).current;
    _quantityController.text = op?.quantity ?? '';
    _unitIdController.text = op is ReceiveOperation ? op.unitId : '';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    _unitIdController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final t = context.t;
    final ok = await ref.read(receiveIssueControllerProvider.notifier).submit();
    if (!mounted) return;
    if (ok) {
      ShadToaster.of(context).show(ShadToast(description: Text(t.operations.submitted)));
      context.pop();
    } else {
      final error = ref.read(receiveIssueControllerProvider).error;
      if (error != null) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(error)));
      }
    }
  }

  void _cancel() {
    ref.read(receiveIssueControllerProvider.notifier).cancelCurrent();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final state = ref.watch(receiveIssueControllerProvider);
    final op = state.current;

    // Normally never hit while this screen is visible (submit/cancel both
    // pop it themselves) - guards the one edge case where something else
    // clears `current` first, e.g. a hot reload during development.
    if (op == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.canPop()) context.pop();
      });
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
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
                      onPressed: _cancel,
                      child: Icon(LucideIcons.arrowLeft, size: 18, semanticLabel: t.nav.back),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.mode == FlowMode.receive ? t.operations.modeReceive : t.operations.modeIssue,
                      style: theme.textTheme.h4,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _OperationFields(
                  op: op,
                  quantityController: _quantityController,
                  quantityFocusNode: _quantityFocusNode,
                  unitIdController: _unitIdController,
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    ShadButton.outline(onPressed: state.submitting ? null : _cancel, child: Text(t.operations.cancel)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShadButton(
                        enabled: !state.submitting,
                        onPressed: state.submitting ? null : _confirm,
                        child: Text(state.submitting ? t.operations.submitting : t.operations.confirm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationFields extends ConsumerWidget {
  const _OperationFields({
    required this.op,
    required this.quantityController,
    required this.quantityFocusNode,
    required this.unitIdController,
  });

  final CurrentOperation op;
  final TextEditingController quantityController;
  final FocusNode quantityFocusNode;
  final TextEditingController unitIdController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final controller = ref.read(receiveIssueControllerProvider.notifier);

    Widget fields;
    if (op is ReceiveOperation) {
      final receiveOp = op as ReceiveOperation;
      fields = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.operations.quantityLabel, style: theme.textTheme.small),
          const SizedBox(height: 6),
          ShadInput(
            controller: quantityController,
            focusNode: quantityFocusNode,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: controller.updateQuantity,
          ),
          if (receiveOp.trackedIndividually) ...[
            const SizedBox(height: 12),
            Text(t.operations.unitOptional, style: theme.textTheme.small),
            const SizedBox(height: 6),
            ShadInput(controller: unitIdController, onChanged: controller.updateUnitId),
          ],
        ],
      );
    } else {
      final issueOp = op as IssueOperation;
      fields = issueOp.kind == IssueKind.unit
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t.operations.unitLabel}: ${issueOp.unitId}', style: theme.textTheme.muted),
                Text(issueOp.quantity, style: theme.textTheme.h4),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.operations.quantityLabel, style: theme.textTheme.small),
                const SizedBox(height: 6),
                ShadInput(
                  controller: quantityController,
                  focusNode: quantityFocusNode,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: controller.updateQuantity,
                ),
              ],
            );
    }

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(op.itemNo, style: theme.textTheme.h3),
          Text(op.itemName, style: theme.textTheme.muted),
          if (op.locationCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${t.operations.location}: ${op.locationCode}', style: theme.textTheme.muted),
          ],
          if (op case IssueOperation(kind: != IssueKind.unit, :final available)) ...[
            const SizedBox(height: 4),
            Text(t.operations.available(value: available), style: theme.textTheme.muted),
          ],
          const SizedBox(height: 16),
          fields,
        ],
      ),
    );
  }
}
