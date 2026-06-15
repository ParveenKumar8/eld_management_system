import 'package:logger/logger.dart';

/// Centralized logging; integrate Sentry/Crashlytics in production.
abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: false,
    ),
    level: Level.debug,
  );

  static void debug(String message, [Object? error, StackTrace? stack]) {
    _logger.d(message, error: error, stackTrace: stack);
  }

  static void info(String message, [Object? error, StackTrace? stack]) {
    _logger.i(message, error: error, stackTrace: stack);
  }

  static void warning(String message, [Object? error, StackTrace? stack]) {
    _logger.w(message, error: error, stackTrace: stack);
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    _logger.e(message, error: error, stackTrace: stack);
  }

  /// Placeholder for Sentry.captureException(error, stackTrace: stack).
  static void reportCrash(Object error, StackTrace stack, {String? hint}) {
    _logger.f('CRASH REPORT: $hint', error: error, stackTrace: stack);
  }
}