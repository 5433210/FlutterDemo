import 'package:flutter/material.dart';

import '../../infrastructure/logging/logger.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.onError(_error!, _stackTrace!);
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      AppLogger.error(
        'Widget error',
        error: details.exception,
        stackTrace: details.stack,
        tag: 'ErrorBoundary',
      );

      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      return widget.onError(
          details.exception, details.stack ?? StackTrace.current);
    };
  }
}
