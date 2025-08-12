import 'package:flutter/material.dart';
import 'dart:async';

mixin AsyncOperationMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  Timer? _operationTimer;

  bool get isLoading => _isLoading;

  @protected
  Future<void> performAsyncOperation({
    required Future<void> Function() operation,
    Duration timeout = const Duration(seconds: 30),
    String? timeoutMessage,
    VoidCallback? onSuccess,
    Function(dynamic)? onError,
  }) async {
    if (_isLoading) return;

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      _operationTimer?.cancel();
      _operationTimer = Timer(timeout, () {
        throw TimeoutException(timeoutMessage ?? 'Operation timed out');
      });

      await operation();
      _operationTimer?.cancel();

      if (mounted) {
        onSuccess?.call();
      }
    } catch (e) {
      _operationTimer?.cancel();
      if (mounted) {
        onError?.call(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _operationTimer?.cancel();
    super.dispose();
  }
}