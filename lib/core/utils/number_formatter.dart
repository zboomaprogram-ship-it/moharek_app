import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ArabicFormatter {
  static String number(num value, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return NumberFormat('#,##0', 'ar').format(value);
    }
    return NumberFormat('#,##0').format(value);
  }

  static String percent(double value, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return NumberFormat.percentPattern(locale == 'ar' ? 'ar' : 'en').format(value / 100);
  }

  static String currency(num value, String currencyCode, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return NumberFormat.currency(
      locale: locale == 'ar' ? 'ar' : 'en',
      symbol: currencyCode == 'EGP' ? 'ج.م' : currencyCode,
    ).format(value);
  }
}
