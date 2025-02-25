import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final errorBoundaryProvider = Provider<ErrorBoundary>((ref) {
  return ErrorBoundary();
});

class ErrorBoundary {
  Future<T> runWithBoundary<T>(
    BuildContext context,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (e, stack) {
      // 错误边界处理
      _showErrorDialog(context, e.toString());
      rethrow;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('操作失败'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
