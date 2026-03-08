import 'package:diacritic/diacritic.dart';

String normalizeStoreName(String value) {
  final withoutDiacritics = removeDiacritics(value);
  final trimmedLower = withoutDiacritics.trim().toLowerCase();
  return trimmedLower.replaceAll(RegExp(r'\s+'), ' ');
}
