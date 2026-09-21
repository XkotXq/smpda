/// A scanned label. Supplier/warehouse labels carry several `#`-separated
/// fields in one QR code, e.g.
/// `995402000020001#110135#20260423#20280423#PO26001030902690105@2026042301#360` =
/// item number # (supplier reference) # date # date # batch # quantity.
/// Materiały SM uses the item number and the batch (5th field) - its quantity
/// is typed by the operator; the FRP module also reads [quantity] (the spool's
/// length). A plain barcode (just an item number or a spool tag) has no `#`
/// and parses to only [itemNo].
class ScannedCode {
  const ScannedCode({required this.raw, required this.itemNo, this.batch, this.quantity});

  /// The whole scan, trimmed - still what a spool tag (unitId) is matched against.
  final String raw;
  final String itemNo;
  final String? batch;

  /// The last field as text ("360"), only when the label has one and it is a
  /// positive number.
  final String? quantity;

  factory ScannedCode.parse(String rawCode) {
    final raw = rawCode.trim();
    if (!raw.contains('#')) return ScannedCode(raw: raw, itemNo: raw);

    final parts = raw.split('#').map((p) => p.trim()).toList();
    final batch = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null;
    final last = parts.length > 5 ? parts.last.replaceAll(',', '.') : '';
    final qty = double.tryParse(last);
    return ScannedCode(raw: raw, itemNo: parts.first, batch: batch, quantity: qty != null && qty > 0 ? last : null);
  }
}
