String formatPriceFromCents(int cents) {
  final normalizedCents = cents < 0 ? 0 : cents;
  final value = normalizedCents.toString().padLeft(3, '0');
  final reais = value.substring(0, value.length - 2);
  final centavos = value.substring(value.length - 2);
  return 'R\$ $reais,$centavos';
}

String formatPriceInput(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  final cents = int.tryParse(digitsOnly) ?? 0;
  return formatPriceFromCents(cents);
}

int? parsePriceToCents(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) {
    return null;
  }

  final cents = int.tryParse(digitsOnly);
  if (cents == null || cents <= 0) {
    return null;
  }

  return cents;
}
