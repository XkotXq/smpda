import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_providers.dart';

/// keyboardType for a decimal number field: the touch numeric keyboard when
/// the operator wants it (Ustawienia), otherwise none - a hardware keypad
/// still types into the field, the on-screen one just doesn't pop up.
TextInputType numericKeyboardType(WidgetRef ref) {
  final show = ref.watch(appSettingsProvider.select((s) => s.value?.showNumericKeyboard ?? false));
  return show ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.none;
}
