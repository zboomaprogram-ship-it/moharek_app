import 'package:intl/intl.dart';

class ArabicFormatter {
  static const Map<String, String> _englishToArabicMap = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  /// Converts English numerals to Arabic numerals.
  /// Example: 123 -> ١٢٣
  static String number(dynamic val, {bool isAr = true}) {
    if (!isAr) return val.toString();
    final String input = val.toString();
    return input.split('').map((char) => _englishToArabicMap[char] ?? char).join();
  }

  /// Formats currency with Arabic numerals.
  /// Example: 1500 AED -> ١,٥٠٠ د.إ
  static String currency(num amount, String symbol, {bool isAr = true}) {
    final formatter = NumberFormat('#,###', isAr ? 'ar' : 'en');
    final formatted = formatter.format(amount);
    if (!isAr) return '$formatted $symbol';
    
    // Convert numerals to Arabic if needed (though ar locale should do it, 
    // sometimes fonts or environments need manual mapping)
    final arabicNumerals = number(formatted, isAr: true);
    return '$arabicNumerals $symbol';
  }

  /// Formats date to Arabic.
  /// Example: 2026-05-12 -> ١٢ مايو ٢٠٢٦
  static String date(DateTime date, {bool isAr = true}) {
    if (!isAr) return DateFormat('dd MMM yyyy').format(date);
    final day = number(date.day, isAr: true);
    final year = number(date.year, isAr: true);
    final monthName = _getArabicMonthName(date.month);
    return '$day $monthName $year';
  }

  static String _getArabicMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }
}
