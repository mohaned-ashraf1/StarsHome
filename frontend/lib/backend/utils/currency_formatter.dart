import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatterWithDecimals = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _formatterWithoutDecimals = NumberFormat('#,##0', 'en_US');

  /// Convert any Arabic/Indic numerals (٠-٩) to English numerals (0-9)
  static String toEnglishDigits(String str) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < arabicDigits.length; i++) {
      str = str.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return str;
  }

  static String format(double amount) {
    final formatted = (amount % 1 == 0)
        ? _formatterWithoutDecimals.format(amount)
        : _formatterWithDecimals.format(amount);
    return '${toEnglishDigits(formatted)} ج.م';
  }

  static String formatWithoutSymbol(double amount) {
    final formatted = (amount % 1 == 0)
        ? _formatterWithoutDecimals.format(amount)
        : _formatterWithDecimals.format(amount);
    return toEnglishDigits(formatted);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} مليون ج.م';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} ألف ج.م';
    }
    return format(amount);
  }
}
