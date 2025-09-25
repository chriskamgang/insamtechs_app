/// Helper class for handling backend translations
class TranslationHelper {
  /// Extract translated text from a field that might be a Map or String
  static String getTranslatedText(dynamic field, {String defaultText = ''}) {
    if (field == null) return defaultText;

    if (field is String) {
      return field;
    }

    if (field is Map<String, dynamic>) {
      // Try French first, then English, then any available language
      return field['fr'] ??
             field['en'] ??
             field.values.firstWhere((value) => value != null && value.toString().isNotEmpty, orElse: () => defaultText);
    }

    return field.toString();
  }

  /// Get price as string from translated field
  static String getPrice(dynamic priceField, {String defaultPrice = '0'}) {
    final priceText = getTranslatedText(priceField, defaultText: defaultPrice);
    // Remove any non-numeric characters except decimal point
    final cleanPrice = priceText.replaceAll(RegExp(r'[^\d.]'), '');
    return cleanPrice.isEmpty ? defaultPrice : cleanPrice;
  }

  /// Get translated description
  static String getDescription(dynamic descriptionField) {
    return getTranslatedText(descriptionField, defaultText: 'Aucune description disponible');
  }
}