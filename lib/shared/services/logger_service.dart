import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error }

class LoggerService {
  static void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stack}) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = level.name.toUpperCase();
    
    final fullMessage = '[$timestamp] [$prefix] $message';
    
    if (kDebugMode) {
      debugPrint(fullMessage);
      if (error != null) debugPrint('Error: $error');
      if (stack != null) debugPrint('Stack: $stack');
    } else {
      // TODO: Integrate with Sentry or Firebase Crashlytics
      if (level == LogLevel.error) {
        // Send to crash reporting
      }
    }
  }

  static void info(String message) => log(message, level: LogLevel.info);
  static void warn(String message) => log(message, level: LogLevel.warning);
  static void error(String message, [Object? error, StackTrace? stack]) => 
      log(message, level: LogLevel.error, error: error, stack: stack);
}
