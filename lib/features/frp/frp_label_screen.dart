import 'dart:async';

import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/sm_spools_api.dart';
import '../../core/scanner/trigger_capture.dart';
import '../../core/session/numeric_keyboard.dart';
import '../../core/session/session_providers.dart';
import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';
import '../../widgets/enter_to_next.dart';
import '../../widgets/field_scroll_padding.dart';

/// What a scanned FRP label resolved to (see FrpScreen._handleCode).
class FrpLabelArgs {
  const FrpLabelArgs({required this.item, required this.unitId, this.batch, this.length});

  final FrpPending item;

  /// The spool number the server will give this spool - shown so it can be
  /// written on the spool right away.
  final String unitId;

  /// From the label's QR (may be missing on an older label).
  final String? batch;

  /// The spool's length from the label - prefilled, editable.
  final String? length;
}

/// Pushed after a scan on the FRP list: the label's data (item, batch,
/// length in an input) and the spool number to write on it. Confirming - the
/// button or the PDA's scan button - moves that length out of the item's
/// unnumbered stock into a spool with this number.
class FrpLabelScreen extends ConsumerStatefulWidget {
  const FrpLabelScreen({super.key, required this.args});

  final FrpLabelArgs args;

  @override
  ConsumerState<FrpLabelScreen> createState() => _FrpLabelScreenState();
}

class _FrpLabelScreenState extends ConsumerState<FrpLabelScreen> {
  final _lengthController = TextEditingController();
  final _lengthFocusNode = FocusNode();
  late final _unitController = TextEditingController(text: widget.args.unitId);
  late final TriggerCapture _trigger = ref.read(triggerCaptureProvider);
  StreamSubscription<void>? _triggerSub;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final length = widget.args.length;
    _lengthController.text = length == null ? '' : trimQuantity(length);
    // The scan button confirms here instead of scanning (see TriggerCapture).
    _trigger.acquire();
    _triggerSub = _trigger.onPressed.listen((_) => _confirm());
  }

  @override
  void dispose() {
    _triggerSub?.cancel();
    _trigger.release();
    _lengthController.dispose();
    _lengthFocusNode.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    final t = context.t;
    final length = sanitizeQuantityInput(_lengthController.text);
    final unitId = _unitController.text.trim();
    if ((parseQuantity(length) ?? 0) <= 0 || unitId.isEmpty) return;

    setState(() => _submitting = true);
    final item = widget.args.item;
    try {
      final operator = ref.read(appSettingsProvider).value?.operatorName;
      final assigned = await ref
          .read(smSpoolsApiProvider)
          .label(
            itemNo: item.itemNo,
            quantity: length,
            unitId: unitId,
            productBatch: widget.args.batch,
            operator: operator,
          );
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(t.frp.labeled(name: item.itemName, unitId: assigned)),
        ),
      );
      context.pop();
    } on SpoolNumberTaken catch (e) {
      // Another device took the number first: show the new one and let the
      // operator confirm again - the number may already be written down.
      if (!mounted) return;
      final taken = unitId;
      _unitController.text = e.next;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(t.frp.numberTaken(taken: taken, next: e.next)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is SpoolApiError ? e.message : t.operations.toastLoadFailed;
      ShadToaster.of(context).show(ShadToast.destructive(description: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final item = widget.args.item;
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

    TextStyle lengthStyleFor(String text) {
      final scale = text.length > 8 ? 8 / text.length : 1.0;
      return theme.textTheme.h1.copyWith(fontSize: 34 * scale, fontWeight: FontWeight.w700, height: 1.2);
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
                      onPressed: _submitting ? null : () => context.pop(),
                      child: Icon(LucideIcons.arrowLeft, size: 18, semanticLabel: t.nav.back),
                    ),
                    const SizedBox(width: 4),
                    Text(t.frp.labelTitle, style: theme.textTheme.h4),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
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
                          Text(
                            item.itemNo,
                            style: theme.textTheme.h3.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(item.itemName, style: theme.textTheme.muted.copyWith(fontSize: 16)),
                        ],
                      ),
                    ),
                    divider,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          stat(t.operations.location, item.locationCode.isEmpty ? '-' : item.locationCode),
                          stat(t.frp.toLabel, trimQuantity(item.pendingQuantity)),
                        ],
                      ),
                    ),
                    divider,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.frp.spoolNumber, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                          const SizedBox(height: 4),
                          // The number the server proposes, editable - checked
                          // (must be free) when confirmed.
                          EnterToNext(
                            child: ShadInput(
                              scrollPadding: kFieldScrollPadding,
                              controller: _unitController,
                              textCapitalization: TextCapitalization.characters,
                              style: theme.textTheme.h1.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              padding: EdgeInsets.zero,
                              decoration: ShadDecoration.none.copyWith(color: const Color(0x00000000)),
                            ),
                          ),
                          Container(height: 2, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.frp.length, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                          const SizedBox(height: 4),
                          ListenableBuilder(
                            listenable: _lengthController,
                            builder: (context, _) => EnterToNext(
                              isLast: true,
                              child: ShadInput(
                                scrollPadding: kFieldScrollPadding,
                                controller: _lengthController,
                                focusNode: _lengthFocusNode,
                                autofocus: widget.args.length == null,
                                keyboardType: numericKeyboardType(ref),
                                onChanged: (value) {
                                  final clean = sanitizeQuantityInput(value);
                                  if (clean != value) {
                                    _lengthController.value = TextEditingValue(
                                      text: clean,
                                      selection: TextSelection.collapsed(offset: clean.length),
                                    );
                                  }
                                },
                                style: lengthStyleFor(_lengthController.text),
                                padding: EdgeInsets.zero,
                                decoration: ShadDecoration.none.copyWith(color: const Color(0x00000000)),
                              ),
                            ),
                          ),
                          Container(height: 2, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    enabled: !_submitting,
                    onPressed: _submitting ? null : _confirm,
                    leading: _submitting ? null : const Icon(LucideIcons.check, size: 18),
                    child: Text(_submitting ? t.operations.submitting : t.operations.confirm),
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
