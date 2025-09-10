import 'package:logger/logger.dart';

/// A null-safe logger wrapper that allows logging to be completely optional
///
/// This class provides a safe way to handle logging throughout the RAGify package
/// without requiring a logger instance. When no logger is provided, all logging
/// operations become no-ops.
class RAGifyLogger {
  final Logger? _logger;
  final bool _enabled;

  /// Get the underlying logger instance (can be null)
  Logger? get underlyingLogger => _logger;

  /// Create a nullable logger
  ///
  /// [logger] - The actual logger instance, can be null
  /// [enabled] - Whether logging is enabled (defaults to true if logger is provided)
  const RAGifyLogger(this._logger, {bool? enabled})
    : _enabled = enabled ?? (_logger != null);

  /// Create a disabled logger (no logging)
  const RAGifyLogger.disabled() : _logger = null, _enabled = false;

  /// Create a logger from a Logger instance
  factory RAGifyLogger.fromLogger(Logger logger, {bool enabled = true}) {
    return RAGifyLogger(logger, enabled: enabled);
  }

  /// Check if logging is enabled
  bool get isEnabled => _enabled && _logger != null;

  /// Log a debug message
  void d(String message, {Object? error, StackTrace? stackTrace}) {
    if (isEnabled) {
      _logger!.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log an info message
  void i(String message, {Object? error, StackTrace? stackTrace}) {
    if (isEnabled) {
      _logger!.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a warning message
  void w(String message, {Object? error, StackTrace? stackTrace}) {
    if (isEnabled) {
      _logger!.w(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log an error message
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (isEnabled) {
      _logger!.e(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a fatal message
  void f(String message, {Object? error, StackTrace? stackTrace}) {
    if (isEnabled) {
      _logger!.f(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a trace message (replaces deprecated verbose)
  void t(String message, {Object? error, StackTrace? stackTrace}) {
    if (isEnabled) {
      _logger!.t(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a verbose message (deprecated, use t instead)
  @Deprecated(
    'Use t() instead. v() is deprecated in favor of t() for trace messages.',
  )
  void v(String message, {Object? error, StackTrace? stackTrace}) {
    t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a wtf message (deprecated, use f instead)
  @Deprecated(
    'Use f() instead. wtf() is deprecated in favor of f() for fatal messages.',
  )
  void wtf(String message, {Object? error, StackTrace? stackTrace}) {
    f(message, error: error, stackTrace: stackTrace);
  }

  /// Close the logger
  void close() {
    _logger?.close();
  }
}
