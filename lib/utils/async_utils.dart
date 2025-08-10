import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class for safe async operations that prevent UI freezes
class AsyncUtils {
  /// Wraps an async operation with a timeout and error handling
  /// Returns null if the operation times out or throws an error
  static Future<T?> withTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String? timeoutMessage,
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          debugPrint('Operation timed out: ${timeoutMessage ?? 'Unknown operation'}');
          return null as T;
        },
      );
    } catch (e) {
      debugPrint('Operation failed: $e');
      return null;
    }
  }

  /// Safely executes a callback after checking if the widget is still mounted
  static void safeCallback(VoidCallback callback, {bool mounted = true}) {
    if (mounted) {
      try {
        callback();
      } catch (e) {
        debugPrint('Safe callback failed: $e');
      }
    }
  }

  /// Debounces a function call to prevent rapid successive calls
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Prevents multiple simultaneous executions of the same operation
  static bool _isExecuting = false;
  static Future<T?> preventReentrant<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    if (_isExecuting) {
      debugPrint('Operation already in progress: ${operationName ?? 'Unknown'}');
      return null;
    }

    _isExecuting = true;
    try {
      return await operation();
    } finally {
      _isExecuting = false;
    }
  }
}
