import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/l10n/app_localizations.dart';

class ArabicDateFormatter {
  static String relative(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0 && now.day == date.day) return l10n.today;
    if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day))
      return l10n.yesterday;
    return full(date, context);
  }

  static String full(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
    }
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  static String short(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat(locale == 'ar' ? 'd MMM' : 'MMM d', locale).format(date);
  }

  static String time(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.jm(locale == 'ar' ? 'ar' : 'en').format(date);
  }
}
