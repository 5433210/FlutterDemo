import 'package:flutter/material.dart';
import '../empty/empty_placeholder.dart';

class DataLoader<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final T? data;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;
  final Widget Function()? emptyBuilder;

  const DataLoader({
    super.key,
    required this.isLoading,
    this.error,
    required this.data,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return errorBuilder?.call(error!) ?? EmptyPlaceholder(
        icon: Icons.error_outline,
        message: '加载失败',
        subMessage: error,
        actions: onRetry != null ? [
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ] : null,
      );
    }

    if (data == null) {
      return emptyBuilder?.call() ?? const EmptyPlaceholder(
        icon: Icons.inbox_outlined,
        message: '暂无数据',
      );
    }

    return builder(data as T);
  }
}
