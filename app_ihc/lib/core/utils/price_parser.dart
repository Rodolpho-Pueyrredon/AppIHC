int? parsePriceToCents(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }

  final parsed = double.tryParse(normalized);
  if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed <= 0) {
    return null;
  }

  return (parsed * 100).round();
}
