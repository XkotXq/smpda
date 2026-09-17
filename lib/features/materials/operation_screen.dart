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
        children: [
          _BigQuantityField(
            controller: quantityController,
            focusNode: quantityFocusNode,
            label: t.operations.quantityLabel,
            onChanged: controller.updateQuantity,
          ),
          if (receiveOp.trackedIndividually) ...[
            const SizedBox(height: 20),
            Text(t.operations.unitOptional, style: theme.textTheme.small, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            ShadInput(controller: unitIdController, onChanged: controller.updateUnitId, textAlign: TextAlign.center),
          ],
        ],
      );
    } else {
      final issueOp = op as IssueOperation;
      fields = issueOp.kind == IssueKind.unit
          ? _BigQuantityDisplay(value: issueOp.quantity, label: '${t.operations.unitLabel} ${issueOp.unitId}')
          : _BigQuantityField(
              controller: quantityController,
              focusNode: quantityFocusNode,
              label: t.operations.quantityLabel,
              onChanged: controller.updateQuantity,
            );
    }

    return Column(
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
        const SizedBox(height: 32),
        fields,
      ],
    );
  }
}

/// The quantity to type - a big centered number with only an underline
/// (no box/border around it), the way a PDA screen has room to make the one
/// thing an operator actually needs to focus on the most prominent thing on
/// screen, and a small caption naming it underneath.
class _BigQuantityField extends StatelessWidget {
  const _BigQuantityField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      children: [
        ShadInput(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          textAlign: TextAlign.center,
          style: theme.textTheme.h1.copyWith(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShadDecoration.none.copyWith(color: const Color(0x00000000)),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.small, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Same look as [_BigQuantityField] for the one case a quantity isn't
/// editable (a unit is always issued in full) - a fixed number, not a field.
class _BigQuantityDisplay extends StatelessWidget {
  const _BigQuantityDisplay({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.h1.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.small, textAlign: TextAlign.center),
      ],
    );
  }
}
