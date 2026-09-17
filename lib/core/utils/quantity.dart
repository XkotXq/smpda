/// Mirrors wps's own lib/quantityInput.js - a quantity field only ever
/// holds digits and at most one decimal separator (comma typed as decimal
/// point, matching Polish keyboards), everything else is dropped as it's
/// typed rather than validated after the fact.
String sanitizeQuantityInput(String value) {
  final normalized = value.replaceAll(',', '.');
  final buffer = StringBuffer();
  var sawDot = false;
  for (final char in normalized.split('')) {
    if (RegExp(r'[0-9]').hasMatch(char)) {
      buffer.write(char);
    } else if (char == '.' && !sawDot) {
      sawDot = true;
      buffer.write(char);
    }
  }
  return buffer.toString();
}

double? parseQuantity(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.'));
}

/// Whole numbers print without a decimal point (e.g. "6062", not
/// "6062.0") - same formatting rule every quantity reducer in wps's own
/// SmMaterialsPanel.js follows.
String formatQuantity(num value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(3);
}
