import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats amount as `₹1,250.00` or `₹500.00`
  static String format(double amount, {bool trimZeroDecimals = false, bool showSign = false}) {
    final absAmount = amount.abs();
    String formatted = _formatter.format(absAmount);
    
    if (trimZeroDecimals && formatted.endsWith('.00')) {
      formatted = formatted.substring(0, formatted.length - 3);
    }

    if (showSign) {
      if (amount > 0) return '+$formatted';
      if (amount < 0) return '-$formatted';
    } else if (amount < 0) {
      return '-$formatted';
    }

    return formatted;
  }

  /// Compact format for large numbers (e.g., `₹12.5k`)
  static String formatCompact(double amount) {
    return _compactFormatter.format(amount);
  }
}
