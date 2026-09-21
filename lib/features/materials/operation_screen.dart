import 'dart:async';

import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/scanner/trigger_capture.dart';
import '../../core/session/numeric_keyboard.dart';
import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';
import '../../widgets/enter_to_next.dart';
import '../../widgets/field_scroll_padding.dart';
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
  final _locationController = TextEditingController();
  late final TriggerCapture _trigger = ref.read(triggerCaptureProvider);
  StreamSubscription<void>? _triggerSub;

  @override
  void initState() {
    super.initState();
    final op = ref.read(receiveIssueControllerProvider).current;
    _quantityController.text = op?.quantity ?? '';
    _unitIdController.text = op is ReceiveOperation ? op.unitId : '';
    _locationController.text = op is ReceiveOperation ? op.location : '';
    // While this screen is up the scan button is "Potwierdź", not a scanner
    // (see TriggerCapture) - and no second scan can start another operation.
    _trigger.acquire();
    _triggerSub = _trigger.onPressed.listen((_) {
      if (!ref.read(receiveIssueControllerProvider).submitting) _confirm();
    });
  }

  @override
  void dispose() {
    _triggerSub?.cancel();
    _trigger.release();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    _unitIdController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final t = context.t;
    // Read before submit(), which clears the current operation.
    final op = ref.read(receiveIssueControllerProvider).current;
    final ok = await ref.read(receiveIssueControllerProvider.notifier).submit();
    if (!mounted) return;
    if (ok) {
      final message = switch (op) {
        IssueOperation() => t.operations.issued(name: op.itemName),
        ReceiveOperation() => t.operations.received(name: op.itemName),
        null => t.operations.submitted,
      };
      ShadToaster.of(context).show(ShadToast(description: Text(message)));
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

    // The scan opened this screen before the server answered: when the
    // location comes in, put it in the field - unless something was typed there.
    ref.listen(receiveIssueControllerProvider.select((s) => s.current), (previous, next) {
      if (previous is ReceiveOperation &&
          previous.loading &&
          next is ReceiveOperation &&
          !next.loading &&
          _locationController.text.trim().isEmpty) {
        _locationController.text = next.location;
      }
    });
    // Nothing to confirm until the item is known.
    final loading = op is ReceiveOperation && op.loading;

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
              child: op is IssueOperation
                  ? _IssueBody(op: op, quantityController: _quantityController, quantityFocusNode: _quantityFocusNode)
                  : _ReceiveBody(
                      op: op as ReceiveOperation,
                      quantityController: _quantityController,
                      quantityFocusNode: _quantityFocusNode,
                      unitIdController: _unitIdController,
                      locationController: _locationController,
                    ),
            ),
            if (op is IssueOperation)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.colorScheme.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: ShadButton(
                      width: double.infinity,
                      enabled: !state.submitting,
                      onPressed: state.submitting ? null : _confirm,
                      leading: state.submitting ? null : const Icon(LucideIcons.check, size: 18),
                      child: Text(state.submitting ? t.operations.submitting : t.operations.confirm),
                    ),
                  ),
                ),
              )
            else
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      ShadButton.outline(
                        onPressed: state.submitting ? null : _cancel,
                        child: Text(t.operations.cancel),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShadButton(
                          enabled: !state.submitting && !loading,
                          onPressed: state.submitting || loading ? null : _confirm,
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

/// Wydanie: what's being issued (item number, name, where it is, how much
/// is on hand) on top, and the quantity to issue as the one big thing in
/// the middle - a large centered number with an accent underline.
class _IssueBody extends ConsumerWidget {
  const _IssueBody({required this.op, required this.quantityController, required this.quantityFocusNode});

  final IssueOperation op;
  final TextEditingController quantityController;
  final FocusNode quantityFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final controller = ref.read(receiveIssueControllerProvider.notifier);
    // The quantity to issue sits right under the item details, left-aligned -
    // a modest size (it shrinks for long numbers) rather than a giant centered one.
    TextStyle quantityStyleFor(String text) {
      final scale = text.length > 8 ? 8 / text.length : 1.0;
      return theme.textTheme.h1.copyWith(fontSize: 34 * scale, fontWeight: FontWeight.w700, height: 1.2);
    }

    final divider = Container(height: 1, color: theme.colorScheme.border);

    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.muted.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.p.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.operations.material, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(op.itemNo, style: theme.textTheme.h3.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(child: Text(op.itemName, style: theme.textTheme.muted.copyWith(fontSize: 16))),
                        if (op.kind == IssueKind.pending)
                          Text(t.operations.noSpoolTag, style: theme.textTheme.muted.copyWith(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              divider,
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stat(t.operations.location, op.locationCode.isEmpty ? '-' : op.locationCode),
                    stat(t.operations.onStock, trimQuantity(op.available)),
                    if (op.kind == IssueKind.unit) stat(t.operations.unitLabel, op.unitId ?? ''),
                  ],
                ),
              ),
              divider,
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.operations.issueQuantity, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                if (op.kind == IssueKind.unit)
                  Text(op.quantity, style: quantityStyleFor(op.quantity))
                else
                  ListenableBuilder(
                    listenable: quantityController,
                    builder: (context, _) => ShadInput(
                      scrollPadding: kFieldScrollPadding,
                      controller: quantityController,
                      focusNode: quantityFocusNode,
                      autofocus: true,
                      keyboardType: numericKeyboardType(ref),
                      onChanged: controller.updateQuantity,
                      style: quantityStyleFor(quantityController.text),
                      padding: EdgeInsets.zero,
                      decoration: ShadDecoration.none.copyWith(color: const Color(0x00000000)),
                    ),
                  ),
                Container(height: 2, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Przyjęcie: the item on top (same block as Wydanie's), then the fields under
/// it - quantity, location and, for a spool item, the spool number - all in
/// Wydanie's look: a small caption, the value left-aligned in a modest size and
/// an accent underline. Scrolls, so a field stays reachable with the keyboard up.
class _ReceiveBody extends ConsumerWidget {
  const _ReceiveBody({
    required this.op,
    required this.quantityController,
    required this.quantityFocusNode,
    required this.unitIdController,
    required this.locationController,
  });

  final ReceiveOperation op;
  final TextEditingController quantityController;
  final FocusNode quantityFocusNode;
  final TextEditingController unitIdController;
  final TextEditingController locationController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final controller = ref.read(receiveIssueControllerProvider.notifier);
    final divider = Container(height: 1, color: theme.colorScheme.border);

    TextStyle styleFor(String text, double size) {
      final scale = text.length > 8 ? 8 / text.length : 1.0;
      return theme.textTheme.h1.copyWith(fontSize: size * scale, fontWeight: FontWeight.w700, height: 1.2);
    }

    Widget field({
      required String label,
      required TextEditingController textController,
      required ValueChanged<String> onChanged,
      required double size,
      bool isLast = false,
      String? placeholder,
      FocusNode? focusNode,
      bool autofocus = false,
      TextInputType? keyboardType,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.muted.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            ListenableBuilder(
              listenable: textController,
              builder: (context, _) => EnterToNext(
                isLast: isLast,
                child: ShadInput(
                  scrollPadding: kFieldScrollPadding,
                  controller: textController,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  keyboardType: keyboardType,
                  placeholder: placeholder == null ? null : Text(placeholder),
                  placeholderStyle: placeholder == null
                      ? null
                      : styleFor('', size).copyWith(color: theme.colorScheme.mutedForeground.withValues(alpha: 0.5)),
                  textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
                  onChanged: onChanged,
                  style: styleFor(textController.text, size),
                  padding: EdgeInsets.zero,
                  decoration: ShadDecoration.none.copyWith(color: const Color(0x00000000)),
                ),
              ),
            ),
            Container(height: 2, color: theme.colorScheme.primary),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.operations.material, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Text(op.itemNo, style: theme.textTheme.h3.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  op.loading ? t.operations.loadingName : op.itemName,
                  style: theme.textTheme.muted.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          divider,
          field(
            label: t.operations.quantityLabel,
            textController: quantityController,
            focusNode: quantityFocusNode,
            autofocus: true,
            keyboardType: numericKeyboardType(ref),
            onChanged: controller.updateQuantity,
            size: 34,
          ),
          field(
            label: t.operations.location,
            textController: locationController,
            onChanged: controller.updateLocation,
            placeholder: defaultReceiveLocation,
            size: 26,
            isLast: !op.trackedIndividually,
          ),
          if (op.trackedIndividually)
            field(
              label: t.operations.unitOptional,
              textController: unitIdController,
              onChanged: controller.updateUnitId,
              size: 26,
              isLast: true,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
